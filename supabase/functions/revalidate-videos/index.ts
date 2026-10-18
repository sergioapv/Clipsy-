// Rechecks the videos of community (public) playlists with YouTube oEmbed
// and flags the ones that were removed, made private or no longer allow
// embedding (is_available = false). Videos that come back are restored.
//
// Called by pg_cron (see migration 20261021000000_revalidation_cron.sql)
// with a secret kept in Vault; nothing else can trigger it.
import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { createClient } from "jsr:@supabase/supabase-js@2";

/** Videos checked per run. The job runs hourly. */
const BATCH = 100;
/** Recheck a video at most this often. */
const RECHECK_AFTER_DAYS = 7;
const CONCURRENCY = 5;

type Status = "available" | "unavailable" | "unknown";

async function checkVideo(videoId: string): Promise<Status> {
  const url = "https://www.youtube.com/oembed?format=json&url=" +
    encodeURIComponent(`https://www.youtube.com/watch?v=${videoId}`);
  try {
    const res = await fetch(url, { signal: AbortSignal.timeout(10_000) });
    await res.body?.cancel();
    if (res.ok) return "available";
    // 401/403: embedding disabled. 400/404: removed or private.
    if ([400, 401, 403, 404].includes(res.status)) return "unavailable";
    return "unknown"; // Rate limits, outages: try again next run.
  } catch {
    return "unknown";
  }
}

Deno.serve(async (req) => {
  if (req.method !== "POST") return new Response(null, { status: 405 });

  const supabase = createClient(
    Deno.env.get("SUPABASE_URL")!,
    Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
    { auth: { persistSession: false } },
  );

  const secret = req.headers.get("x-revalidation-secret") ?? "";
  const { data: allowed, error: authError } = await supabase.rpc(
    "verify_revalidation_secret",
    { p_secret: secret },
  );
  if (authError || allowed !== true) {
    return new Response(null, { status: 401 });
  }

  const cutoff = new Date(Date.now() - RECHECK_AFTER_DAYS * 86_400_000)
    .toISOString();
  const { data: rows, error } = await supabase
    .from("playlist_videos")
    .select("id, youtube_video_id, playlists!inner(visibility)")
    .eq("playlists.visibility", "public")
    .or(`checked_at.is.null,checked_at.lt.${cutoff}`)
    .order("checked_at", { ascending: true, nullsFirst: true })
    .limit(BATCH);
  if (error) {
    console.error(error);
    return Response.json({ error: "query_failed" }, { status: 500 });
  }

  // The same video can sit in several playlists: check it once.
  const rowsByVideo = new Map<string, string[]>();
  for (const r of rows ?? []) {
    const ids = rowsByVideo.get(r.youtube_video_id) ?? [];
    ids.push(r.id);
    rowsByVideo.set(r.youtube_video_id, ids);
  }

  const videoIds = [...rowsByVideo.keys()];
  const results = new Map<string, Status>();
  let next = 0;
  await Promise.all(
    Array.from({ length: Math.min(CONCURRENCY, videoIds.length) }, async () => {
      while (next < videoIds.length) {
        const id = videoIds[next++];
        results.set(id, await checkVideo(id));
      }
    }),
  );

  const now = new Date().toISOString();
  const summary = { checked: 0, available: 0, unavailable: 0, skipped: 0 };
  for (const status of ["available", "unavailable"] as const) {
    const rowIds = videoIds
      .filter((v) => results.get(v) === status)
      .flatMap((v) => rowsByVideo.get(v)!);
    if (rowIds.length === 0) continue;
    const { error: updateError } = await supabase
      .from("playlist_videos")
      .update({ is_available: status === "available", checked_at: now })
      .in("id", rowIds);
    if (updateError) {
      console.error(updateError);
      return Response.json({ error: "update_failed" }, { status: 500 });
    }
    summary[status] = rowIds.length;
    summary.checked += rowIds.length;
  }
  summary.skipped = (rows?.length ?? 0) - summary.checked;
  return Response.json(summary);
});
