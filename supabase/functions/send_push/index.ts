import { createClient } from "supabase";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type, x-push-secret",
};

let cachedToken: { value: string; exp: number } | null = null;

function base64UrlEncode(bytes: Uint8Array) {
  const b64 = btoa(String.fromCharCode(...bytes));
  return b64.replace(/\+/g, "-").replace(/\//g, "_").replace(/=+$/g, "");
}

function pemToArrayBuffer(pem: string): ArrayBuffer {
  const b64 = pem
    .replace("-----BEGIN PRIVATE KEY-----", "")
    .replace("-----END PRIVATE KEY-----", "")
    .replace(/\s+/g, "");
  const bin = atob(b64);
  const bytes = new Uint8Array(bin.length);
  for (let i = 0; i < bin.length; i++) bytes[i] = bin.charCodeAt(i);
  return bytes.buffer;
}

async function getAccessTokenFromServiceAccount(sa: any): Promise<string> {
  const now = Math.floor(Date.now() / 1000);

  if (cachedToken && cachedToken.exp > now + 30) return cachedToken.value;

  const header = { alg: "RS256", typ: "JWT" };
  const payload = {
    iss: sa.client_email,
    scope: "https://www.googleapis.com/auth/firebase.messaging",
    aud: sa.token_uri ?? "https://oauth2.googleapis.com/token",
    iat: now,
    exp: now + 3600,
  };

  const enc = new TextEncoder();
  const headerPart = base64UrlEncode(enc.encode(JSON.stringify(header)));
  const payloadPart = base64UrlEncode(enc.encode(JSON.stringify(payload)));
  const unsigned = `${headerPart}.${payloadPart}`;

  const key = await crypto.subtle.importKey(
    "pkcs8",
    pemToArrayBuffer(sa.private_key),
    { name: "RSASSA-PKCS1-v1_5", hash: "SHA-256" },
    false,
    ["sign"],
  );

  const sig = await crypto.subtle.sign(
    "RSASSA-PKCS1-v1_5",
    key,
    enc.encode(unsigned),
  );

  const jwt = `${unsigned}.${base64UrlEncode(new Uint8Array(sig))}`;

  const tokenUri = payload.aud;
  const body = new URLSearchParams({
    grant_type: "urn:ietf:params:oauth:grant-type:jwt-bearer",
    assertion: jwt,
  });

  const res = await fetch(tokenUri, {
    method: "POST",
    headers: { "Content-Type": "application/x-www-form-urlencoded" },
    body,
  });

  if (!res.ok) {
    const text = await res.text();
    throw new Error(`OAuth token error: ${res.status} ${text}`);
  }

  const json = await res.json();
  const accessToken = json.access_token as string;

  cachedToken = { value: accessToken, exp: now + 3500 };
  return accessToken;
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
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    // Auth interna por secret
    const expected = Deno.env.get("PUSH_INTERNAL_SECRET") ?? "";
    const got = req.headers.get("x-push-secret") ?? "";
    if (!expected || got !== expected) {
      return new Response("Unauthorized", {
        status: 401,
        headers: corsHeaders,
      });
    }

    const { usuario_id, title, body, data } = await req.json();

    if (!usuario_id || !title || !body) {
      return new Response("Missing usuario_id/title/body", {
        status: 400,
        headers: corsHeaders,
      });
    }

    const projectId = Deno.env.get("FCM_PROJECT_ID") ?? "";
    const saB64 = Deno.env.get("GOOGLE_SERVICE_ACCOUNT_JSON_B64") ?? "";
    if (!projectId || !saB64) {
      return new Response(
        "Missing FCM_PROJECT_ID or GOOGLE_SERVICE_ACCOUNT_JSON_B64",
        { status: 500, headers: corsHeaders },
      );
    }

    const saJson = JSON.parse(atob(saB64));

    // Supabase service role
    const supabaseUrl = Deno.env.get("SUPABASE_URL") ?? "";
    const serviceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "";
    const supabase = createClient(supabaseUrl, serviceKey);

    // Tokens Android
    const { data: rows, error } = await supabase
      .from("user_device_tokens")
      .select("token, platform")
      .eq("usuario_id", usuario_id)
      .eq("platform", "android");

    if (error) throw new Error(`DB error: ${error.message}`);

    const tokens = (rows ?? []).map((r: any) => r.token).filter(Boolean);

    if (tokens.length === 0) {
      return Response.json(
        { ok: true, sent: 0, reason: "no android tokens" },
        { headers: { ...corsHeaders, "Content-Type": "application/json" } },
      );
    }

    // OAuth token para FCM HTTP v1
    const accessToken = await getAccessTokenFromServiceAccount(saJson);

    const results: Array<
      { token_prefix: string; ok: boolean; status?: number; err?: string }
    > = [];

    for (const t of tokens) {
      const tokenPrefix = String(t).slice(0, 18);

      const fcmRes = await fetch(
        `https://fcm.googleapis.com/v1/projects/${projectId}/messages:send`,
        {
          method: "POST",
          headers: {
            Authorization: `Bearer ${accessToken}`,
            "Content-Type": "application/json",
          },
          body: JSON.stringify({
            message: {
              token: t,
              notification: { title, body },
              data: normalizeData(data),
            },
          }),
        },
      );

      if (!fcmRes.ok) {
        const text = await fcmRes.text();
        results.push({
          token_prefix: tokenPrefix,
          ok: false,
          status: fcmRes.status,
          err: text,
        });
      } else {
        results.push({ token_prefix: tokenPrefix, ok: true });
      }
    }

    const sent = results.filter((r) => r.ok).length;

    return Response.json(
      { ok: true, sent, results },
      { headers: { ...corsHeaders, "Content-Type": "application/json" } },
    );
  } catch (e) {
    return Response.json(
      { ok: false, error: String((e as any)?.message ?? e) },
      { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } },
    );
  }
});