-- Milestone 3: the Kid mode player records a video's length the first time
-- it learns it (oEmbed doesn't provide durations). Owners only, via the
-- existing "owners update videos" RLS policy.
grant update (duration_seconds) on public.playlist_videos to authenticated;
