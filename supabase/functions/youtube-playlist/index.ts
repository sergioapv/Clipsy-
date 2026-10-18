// Clipsy: look up a YouTube playlist for "add whole playlist".
//
// POST { "playlistId": "PL..." }  (signed-in parents only)
// → { playlistId, title, channelName, videos: [...], truncated }
//
// Uses the YouTube Data API v3. The key lives only here, as the
// YOUTUBE_API_KEY function secret; it never ships in the app.
// Each video says whether it can actually be embedded, so the app can skip
// private, deleted or non-embeddable ones up front.
import "jsr:@supabase/functions-js/edge-runtime.d.ts";

import { handle } from "./handler.ts";

Deno.serve((req) => handle(req, Deno.env.get("YOUTUBE_API_KEY")));
