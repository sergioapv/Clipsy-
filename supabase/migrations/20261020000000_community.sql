-- Milestone 4: community library.
--
-- Most of the community schema shipped in the initial migration (view,
-- ratings, reports, auto-hide, fork). This adds what the app needs on top.

-- Rate (or re-rate) a community playlist in one call. An upsert from the
-- client can't do this: ON CONFLICT DO UPDATE would need UPDATE on every
-- column it sends, and parents may only update `stars`. SECURITY INVOKER, so
-- the ratings RLS policies (no rating your own playlist, community only)
-- still apply.
create function public.rate_playlist(p_playlist_id uuid, p_stars smallint)
returns void
language sql
security invoker
set search_path = ''
as $$
  insert into public.ratings (playlist_id, stars)
  values (p_playlist_id, p_stars)
  on conflict (playlist_id, user_id) do update set stars = excluded.stars;
$$;

revoke all on function public.rate_playlist(uuid, smallint) from public, anon;
grant execute on function public.rate_playlist(uuid, smallint) to authenticated;

-- A public playlist whose videos have all been found unavailable by the
-- revalidation job drops out of the community until its owner fixes it.
create or replace view public.community_playlists
with (security_invoker = true)
as
select
  p.id,
  p.title,
  p.description,
  p.cover_url,
  p.age_min,
  p.age_max,
  p.rating_avg,
  p.rating_count,
  p.published_at,
  p.forked_from,
  p.owner_id,
  pr.display_name as author_name,
  v.video_count,
  v.total_duration_seconds,
  coalesce(l.label_slugs, '{}') as label_slugs
from public.playlists p
join public.profiles pr on pr.id = p.owner_id
cross join lateral (
  select
    count(*)::integer as video_count,
    -- Only meaningful when every duration is known.
    case when count(*) filter (where duration_seconds is null) = 0
      then sum(duration_seconds)::integer end as total_duration_seconds
  from public.playlist_videos
  where playlist_id = p.id and is_available
) v
left join lateral (
  select array_agg(lb.slug order by lb.sort_order, lb.slug) as label_slugs
  from public.playlist_labels pl
  join public.labels lb on lb.id = pl.label_id
  where pl.playlist_id = p.id
) l on true
where p.visibility = 'public' and not p.is_hidden and v.video_count > 0;

-- The revalidation Edge Function picks the videos checked longest ago.
create index playlist_videos_checked_idx
  on public.playlist_videos (checked_at nulls first);
