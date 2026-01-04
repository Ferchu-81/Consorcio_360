import { createClient } from "supabase";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type, x-push-secret",
};

type NotifyEventBody = {
  consorcio_id: string;
  unidad_id?: string | null;
  event_type: string;
  title: string;
  body: string;
  data?: Record<string, unknown>;
  actor_usuario_id?: string | null;
  target_usuario_ids?: string[]; // opcional: si viene, no calculamos admins
};

function buildBaseData(
  data: Record<string, unknown> | undefined,
  consorcioId: string,
  unidadId: string | null,
  eventType: string,
) {
  const base: Record<string, unknown> = { ...(data ?? {}) };
  if (!("deeplink" in base)) base.deeplink = "notif_inbox";
  base.consorcio_id = consorcioId;
  if (unidadId && unidadId.trim().length > 0) {
    base.unidad_id = unidadId;
  }
  base.event_type = eventType;
  return base;
}

function normalizeData(data: Record<string, unknown> | undefined) {
  const out: Record<string, string> = {};
  if (!data) return out;
  for (const [k, v] of Object.entries(data)) {
    if (v === null || v === undefined) continue;
    out[k] = typeof v === "string" ? v : JSON.stringify(v);
  }
  return out;
}

Deno.serve(async (req: Request) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: corsHeaders });

  try {
    // seguridad interna por secret (igual que send_push)
    const expected = Deno.env.get("PUSH_INTERNAL_SECRET") ?? "";
    const got = req.headers.get("x-push-secret") ?? "";
    if (!expected || got !== expected) {
      return new Response("Unauthorized", { status: 401, headers: corsHeaders });
    }

    const payload = (await req.json()) as NotifyEventBody;

    const consorcioId = (payload.consorcio_id ?? "").trim();
    const unidadId = (payload.unidad_id ?? null) ? String(payload.unidad_id).trim() : null;
    const eventType = (payload.event_type ?? "").trim();
    const title = (payload.title ?? "").trim();
    const bodyText = (payload.body ?? "").trim();
    const actorUserId = (payload.actor_usuario_id ?? null) ? String(payload.actor_usuario_id).trim() : null;
    const payloadData = payload.data ?? {};

    if (!consorcioId || !eventType || !title || !bodyText) {
      return new Response("Missing consorcio_id/event_type/title/body", {
        status: 400,
        headers: corsHeaders,
      });
    }

    // supabase service role
    const supabaseUrl = Deno.env.get("SUPABASE_URL") ?? "";
    const serviceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "";
    const supabase = createClient(supabaseUrl, serviceKey);

    // 1) Determinar destinatarios
    let targets = (payload.target_usuario_ids ?? [])
      .map((x) => String(x).trim())
      .filter((x) => x.length > 0);

    if (targets.length === 0) {
      // default MVP: todos los ADMIN del consorcio
      const { data: adminRows, error: adminErr } = await supabase
        .from("v_usuarios_unidades")
        .select("usuario_id")
        .eq("consorcio_id", consorcioId)
        .eq("rol", "ADMIN_CONSORCIO")
        .eq("activo", true);

      if (adminErr) throw new Error(`DB admins error: ${adminErr.message}`);

      targets = (adminRows ?? []).map((r: any) => String(r.usuario_id)).filter(Boolean);
    }

    // excluir autor
    if (actorUserId) {
      targets = targets.filter((id) => id !== actorUserId);
    }

    // dedupe
    targets = Array.from(new Set(targets));

    if (targets.length === 0) {
      return Response.json({ ok: true, created: 0, pushed: 0, reason: "no targets" }, {
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    // 2) Buscar rol por usuario (para preferencias)
    const { data: roleRows, error: roleErr } = await supabase
      .from("v_usuarios_unidades")
      .select("usuario_id, rol")
      .eq("consorcio_id", consorcioId)
      .in("usuario_id", targets)
      .eq("activo", true);

    if (roleErr) throw new Error(`DB roles error: ${roleErr.message}`);

    const rolByUser = new Map<string, string>();
    for (const r of roleRows ?? []) {
      const uid = String((r as any).usuario_id ?? "");
      const rol = String((r as any).rol ?? "");
      if (uid && rol && !rolByUser.has(uid)) rolByUser.set(uid, rol);
    }

    // 3) Para cada destinatario: aplicar preferencias (si no hay, default ON)
    const inAppRows: any[] = [];
    const pushTargets: string[] = [];
    const baseData = buildBaseData(payloadData, consorcioId, unidadId, eventType);
    const notificationIdByUser = new Map<string, string>();

    for (const uid of targets) {
      const userRol = rolByUser.get(uid) ?? null;

      // Preferencia: si hay row específica por rol, pisa a "aplicar_a_todos_roles=true"
      // Si no hay ninguna row, default: in_app=true, push=true (MVP vendible)
      let inAppEnabled = true;
      let pushEnabled = true;

      const prefQuery = supabase
        .from("notificacion_preferencias")
        .select("in_app_enabled, push_enabled, aplicar_a_todos_roles, rol")
        .eq("usuario_id", uid)
        .eq("consorcio_id", consorcioId)
        .eq("event_type", eventType);

      if (userRol) {
        prefQuery.or(`aplicar_a_todos_roles.eq.true,rol.eq.${userRol}`);
      } else {
        prefQuery.eq("aplicar_a_todos_roles", true);
      }

      const { data: prefRows, error: prefErr } = await prefQuery
        .order("aplicar_a_todos_roles", { ascending: true })
        .limit(1);

      if (prefErr) throw new Error(`DB prefs error: ${prefErr.message}`);

      if (prefRows && prefRows.length > 0) {
        const p: any = prefRows[0];
        inAppEnabled = Boolean(p.in_app_enabled);
        pushEnabled = Boolean(p.push_enabled);
      }

      if (inAppEnabled) {
        const notificationId = crypto.randomUUID();
        notificationIdByUser.set(uid, notificationId);
        inAppRows.push({
          id: notificationId,
          usuario_id: uid,
          consorcio_id: consorcioId,
          unidad_id: unidadId,
          event_type: eventType,
          title,
          body: bodyText,
          data: { ...baseData, notification_id: notificationId },
        });
      }

      if (pushEnabled) {
        pushTargets.push(uid);
      }
    }

    // 4) Insert IN_APP
    let created = 0;
    if (inAppRows.length > 0) {
      const { error: insErr } = await supabase.from("notificaciones").insert(inAppRows);
      if (insErr) throw new Error(`DB insert notificaciones error: ${insErr.message}`);
      created = inAppRows.length;
    }

    // 5) PUSH (llama send_push)
    let pushed = 0;
    for (const uid of pushTargets) {
      // si no hay token, send_push responde sent:0
      const r = await fetch(`${supabaseUrl}/functions/v1/send_push`, {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          "x-push-secret": expected,
        },
        body: JSON.stringify({
          usuario_id: uid,
          title,
          body: bodyText,
          data: normalizeData({
            ...baseData,
            ...(notificationIdByUser.has(uid)
              ? { notification_id: notificationIdByUser.get(uid) }
              : {}),
          }),
        }),
      });

      if (r.ok) pushed += 1;
    }

    return Response.json(
      { ok: true, created, pushed, targets },
      { headers: { ...corsHeaders, "Content-Type": "application/json" } },
    );
  } catch (e) {
    return Response.json(
      { ok: false, error: String((e as any)?.message ?? e) },
      { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } },
    );
  }
});
