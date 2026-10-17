-- Milestone 2: parent-defined playlist order, and server-maintained covers.

-- ---------------------------------------------------------------------------
-- Playlist order in the parent's library
-- ---------------------------------------------------------------------------

alter table public.playlists
  add column sort_index integer not null default 0;

create index playlists_owner_sort_idx on public.playlists (owner_id, sort_index);

-- New playlists (and forks) go to the top of the owner's library.
create function public.playlists_set_sort_index()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  select coalesce(min(sort_index), 0) - 1 into new.sort_index
  from public.playlists
  where owner_id = new.owner_id;
  return new;
end;
$$;

create trigger playlists_set_sort_index
  before insert on public.playlists
  for each row execute function public.playlists_set_sort_index();

-- Persist the parent's playlist order: sort_index becomes 0..n-1 following
-- the array. Only the caller's own playlists are touched (RLS).
create function public.reorder_my_playlists(p_playlist_ids uuid[])
returns void
language sql
security invoker
set search_path = ''
as $$
  update public.playlists p
  set sort_index = o.ord - 1
  from unnest(p_playlist_ids) with ordinality as o(id, ord)
  where p.id = o.id and p.owner_id = auth.uid();
$$;

grant update (sort_index) on public.playlists to authenticated;

-- ---------------------------------------------------------------------------
-- Cover = thumbnail of the first available video
-- ---------------------------------------------------------------------------

create function public.refresh_playlist_cover()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  target uuid := coalesce(new.playlist_id, old.playlist_id);
  first_thumb text;
begin
  select thumbnail_url into first_thumb
  from public.playlist_videos
  where playlist_id = target and is_available
  order by position, added_at
  limit 1;

  update public.playlists
  set cover_url = first_thumb
  where id = target and cover_url is distinct from first_thumb;
  return null;
end;
$$;

create trigger playlist_videos_refresh_cover
  after insert or delete or update of position, is_available, thumbnail_url
  on public.playlist_videos
  for each row execute function public.refresh_playlist_cover();

-- The cover is now derived; clients no longer write it.
revoke insert (cover_url), update (cover_url) on public.playlists from authenticated;

revoke all on function
  public.playlists_set_sort_index(),
  public.refresh_playlist_cover(),
  public.reorder_my_playlists(uuid[])
from public, anon, authenticated;
grant execute on function public.reorder_my_playlists(uuid[]) to authenticated;
