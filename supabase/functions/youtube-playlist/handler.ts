// Request handling for the youtube-playlist function (see index.ts).
const API = "https://www.googleapis.com/youtube/v3";
// Matches app_settings.max_videos_per_playlist (default 200).
const MAX_VIDEOS = 200;
const PLAYLIST_ID = /^[A-Za-z0-9_-]{10,64}$/;

const cors = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
};

function json(body: unknown, status = 200): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...cors, "Content-Type": "application/json" },
  });
}

class YouTubeError extends Error {
  constructor(readonly code: string, readonly status: number) {
    super(code);
  }
}

type Fetch = (input: URL) => Promise<Response>;

async function yt(
  fetchFn: Fetch,
  key: string,
  path: string,
  params: Record<string, string | undefined>,
): Promise<any> {
  const url = new URL(`${API}/${path}`);
  for (const [k, v] of Object.entries(params)) {
    if (v !== undefined) url.searchParams.set(k, v);
  }
  url.searchParams.set("key", key);
  const res = await fetchFn(url);
  if (res.ok) return res.json();
  const body = await res.json().catch(() => ({}));
  const reason = body?.error?.errors?.[0]?.reason ?? "";
  if (res.status === 404 || reason === "playlistNotFound") {
    throw new YouTubeError("not_found", 404);
  }
  if (reason === "quotaExceeded" || reason === "dailyLimitExceeded") {
    throw new YouTubeError("quota", 429);
  }
  throw new YouTubeError("youtube_error", 502);
}

/** ISO 8601 duration (PT1H2M3S) → seconds; null when unknown (e.g. live). */
export function parseDuration(iso: string | undefined): number | null {
  const m = /^P(?:(\d+)D)?T?(?:(\d+)H)?(?:(\d+)M)?(?:(\d+)S)?$/.exec(iso ?? "");
  if (!m) return null;
  const [, d, h, min, s] = m.map((x) => Number(x ?? 0));
  const total = d * 86400 + h * 3600 + min * 60 + s;
  return total > 0 ? total : null;
}

/** The JWT was verified by the platform (verify_jwt); require a real user. */
function isSignedInUser(req: Request): boolean {
  const token = req.headers.get("Authorization")?.replace(/^Bearer /, "");
  const payload = token?.split(".")[1];
  if (!payload) return false;
  try {
    const claims = JSON.parse(
      atob(payload.replace(/-/g, "+").replace(/_/g, "/")),
    );
    return claims.role === "authenticated" && typeof claims.sub === "string";
  } catch {
    return false;
  }
}

export async function handle(
  req: Request,
  key: string | undefined,
  fetchFn: Fetch = fetch,
): Promise<Response> {
  if (req.method === "OPTIONS") return new Response("ok", { headers: cors });
  if (req.method !== "POST") return json({ error: "method_not_allowed" }, 405);
  if (!isSignedInUser(req)) return json({ error: "not_authenticated" }, 401);

  if (!key) return json({ error: "not_configured" }, 503);

  const { playlistId } = await req.json().catch(() => ({}));
  if (typeof playlistId !== "string" || !PLAYLIST_ID.test(playlistId)) {
    return json({ error: "invalid_playlist" }, 400);
  }

  try {
    const meta = await yt(fetchFn, key, "playlists", { part: "snippet", id: playlistId });
    const snippet = meta.items?.[0]?.snippet;
    if (!snippet) return json({ error: "not_found" }, 404);

    // Video ids in playlist order, up to the per-playlist cap.
    const ids: string[] = [];
    let pageToken: string | undefined;
    let truncated = false;
    do {
      const page = await yt(fetchFn, key, "playlistItems", {
        part: "contentDetails",
        playlistId,
        maxResults: "50",
        pageToken,
      });
      for (const item of page.items ?? []) {
        const id = item.contentDetails?.videoId;
        if (id && !ids.includes(id)) ids.push(id);
      }
      pageToken = page.nextPageToken;
      if (ids.length >= MAX_VIDEOS) {
        truncated = ids.length > MAX_VIDEOS || pageToken !== undefined;
        break;
      }
    } while (pageToken);
    const wanted = ids.slice(0, MAX_VIDEOS);

    // Details in batches of 50: title, duration, embeddability.
    const details = new Map<string, any>();
    for (let i = 0; i < wanted.length; i += 50) {
      const batch = await yt(fetchFn, key, "videos", {
        part: "snippet,contentDetails,status",
        id: wanted.slice(i, i + 50).join(","),
        maxResults: "50",
      });
      for (const v of batch.items ?? []) details.set(v.id, v);
    }

    const videos = wanted.map((videoId) => {
      const v = details.get(videoId);
      const playable = Boolean(
        v &&
          v.status?.embeddable &&
          v.status?.privacyStatus !== "private" &&
          v.status?.uploadStatus === "processed",
      );
      return {
        videoId,
        title: (v?.snippet?.title ?? "").slice(0, 300),
        channelName: v?.snippet?.channelTitle?.slice(0, 200) ?? null,
        durationSeconds: parseDuration(v?.contentDetails?.duration),
        playable,
      };
    });

    return json({
      playlistId,
      title: snippet.title ?? "",
      channelName: snippet.channelTitle ?? null,
      videos,
      truncated,
    });
  } catch (e) {
    if (e instanceof YouTubeError) return json({ error: e.code }, e.status);
    console.error(e);
    return json({ error: "internal" }, 500);
  }
}
