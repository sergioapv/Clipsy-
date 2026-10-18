import { assertEquals } from "jsr:@std/assert@1";
import { handle, parseDuration } from "./handler.ts";

// A JWT whose payload is {"role":"authenticated","sub":"u1"}. The signature is
// irrelevant here: the platform verifies it before the handler runs.
const userJwt = `x.${btoa(JSON.stringify({ role: "authenticated", sub: "u1" }))}.y`;
const anonJwt = `x.${btoa(JSON.stringify({ role: "anon" }))}.y`;

function request(body: unknown, jwt = userJwt): Request {
  return new Request("http://localhost/youtube-playlist", {
    method: "POST",
    headers: { Authorization: `Bearer ${jwt}`, "Content-Type": "application/json" },
    body: JSON.stringify(body),
  });
}

/** Fake YouTube API: a playlist of 3 videos over two pages. */
function fakeYouTube(calls: string[] = []) {
  return (url: URL): Promise<Response> => {
    calls.push(url.pathname + "?" + url.searchParams.toString());
    const ok = (b: unknown) => Promise.resolve(new Response(JSON.stringify(b)));
    const path = url.pathname.split("/").pop();
    if (path === "playlists") {
      return url.searchParams.get("id") === "PLgoodgoodgood"
        ? ok({ items: [{ snippet: { title: "Dinosaurs", channelTitle: "Kids TV" } }] })
        : ok({ items: [] });
    }
    if (path === "playlistItems") {
      const first = !url.searchParams.get("pageToken");
      return ok(first
        ? {
          items: [
            { contentDetails: { videoId: "aaaaaaaaaaa" } },
            { contentDetails: { videoId: "bbbbbbbbbbb" } },
            { contentDetails: { videoId: "aaaaaaaaaaa" } }, // duplicate
          ],
          nextPageToken: "p2",
        }
        : { items: [{ contentDetails: { videoId: "ccccccccccc" } }, { contentDetails: { videoId: "ddddddddddd" } }] });
    }
    if (path === "videos") {
      return ok({
        items: [
          {
            id: "aaaaaaaaaaa",
            snippet: { title: "T-Rex", channelTitle: "Kids TV" },
            contentDetails: { duration: "PT3M5S" },
            status: { embeddable: true, privacyStatus: "public", uploadStatus: "processed" },
          },
          {
            id: "bbbbbbbbbbb",
            snippet: { title: "No embeds", channelTitle: "Other" },
            contentDetails: { duration: "PT1M" },
            status: { embeddable: false, privacyStatus: "public", uploadStatus: "processed" },
          },
          {
            id: "ccccccccccc",
            snippet: { title: "Unlisted ok", channelTitle: "Kids TV" },
            contentDetails: { duration: "PT1H" },
            status: { embeddable: true, privacyStatus: "unlisted", uploadStatus: "processed" },
          },
          // ddddddddddd missing: deleted or private.
        ],
      });
    }
    return Promise.resolve(new Response("{}", { status: 500 }));
  };
}

Deno.test("parseDuration", () => {
  assertEquals(parseDuration("PT3M5S"), 185);
  assertEquals(parseDuration("PT1H"), 3600);
  assertEquals(parseDuration("P1DT1S"), 86401);
  assertEquals(parseDuration("P0D"), null);
  assertEquals(parseDuration(undefined), null);
  assertEquals(parseDuration("nonsense"), null);
});

Deno.test("returns videos in order with playability, durations and dedupe", async () => {
  const calls: string[] = [];
  const res = await handle(request({ playlistId: "PLgoodgoodgood" }), "KEY", fakeYouTube(calls));
  assertEquals(res.status, 200);
  const body = await res.json();
  assertEquals(body.title, "Dinosaurs");
  assertEquals(body.truncated, false);
  assertEquals(
    body.videos.map((v: any) => [v.videoId, v.playable, v.durationSeconds]),
    [
      ["aaaaaaaaaaa", true, 185],
      ["bbbbbbbbbbb", false, 60],
      ["ccccccccccc", true, 3600],
      ["ddddddddddd", false, null],
    ],
  );
  // The key is sent to Google, never returned.
  assertEquals(JSON.stringify(body).includes("KEY"), false);
  assertEquals(calls.every((c) => c.includes("key=KEY")), true);
});

Deno.test("rejects anonymous callers, bad ids and unknown playlists", async () => {
  assertEquals((await handle(request({ playlistId: "PLgoodgoodgood" }, anonJwt), "KEY", fakeYouTube())).status, 401);
  assertEquals((await handle(request({ playlistId: "x" }), "KEY", fakeYouTube())).status, 400);
  assertEquals((await handle(request({}), "KEY", fakeYouTube())).status, 400);
  assertEquals((await handle(request({ playlistId: "PLmissingmissing" }), "KEY", fakeYouTube())).status, 404);
});

Deno.test("reports a missing API key and quota errors clearly", async () => {
  const noKey = await handle(request({ playlistId: "PLgoodgoodgood" }), undefined, fakeYouTube());
  assertEquals(noKey.status, 503);
  assertEquals((await noKey.json()).error, "not_configured");

  const quota = await handle(
    request({ playlistId: "PLgoodgoodgood" }),
    "KEY",
    () => Promise.resolve(new Response(JSON.stringify({ error: { errors: [{ reason: "quotaExceeded" }] } }), { status: 403 })),
  );
  assertEquals(quota.status, 429);
  assertEquals((await quota.json()).error, "quota");
});
