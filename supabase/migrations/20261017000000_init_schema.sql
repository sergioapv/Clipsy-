-- Clipsy: initial schema.
--
-- Security model
--   * Every table has Row Level Security enabled.
--   * The `anon` role gets nothing: all access requires a signed-in parent.
--   * Writable columns are granted explicitly per column, so clients can never
--     touch counters, moderation flags or ownership (report_count, is_hidden,
--     rating_avg, owner_id, is_available, ...). Those are maintained by
--     SECURITY DEFINER triggers, admin RPCs, or the service role (Edge Functions).
--   * Error messages raised here are stable keys (e.g. 'too_many_labels') that
--     the app maps to localised text.

create extension if not exists pg_trgm with schema extensions;

-- ---------------------------------------------------------------------------
-- Types
-- ---------------------------------------------------------------------------

create type public.playlist_visibility as enum ('private', 'public');

create type public.report_reason as enum (
  'inappropriate',
  'violent_or_scary',
  'not_for_kids',
  'misleading',
  'spam',
  'other'
);

-- ---------------------------------------------------------------------------
-- Profiles, admins, settings
-- ---------------------------------------------------------------------------

-- Public-facing parent profile. Holds no email or real name by default:
-- the display name starts as 'Parent' and is chosen by the parent.
create table public.profiles (
  id uuid primary key references auth.users (id) on delete cascade,
  display_name text not null default 'Parent'
    check (char_length(btrim(display_name)) between 1 and 40),
  created_at timestamptz not null default now()
);

comment on table public.profiles is
  'One row per parent account. Never stores children''s data.';

-- Moderators. No RLS policies: only the service role and SECURITY DEFINER
-- functions can read it. Add an admin with:
--   insert into public.admins (user_id) values ('<auth user id>');
create table public.admins (
  user_id uuid primary key references auth.users (id) on delete cascade,
  created_at timestamptz not null default now()
);

-- Single-row configuration table.
create table public.app_settings (
  id boolean primary key default true check (id),
  -- A public playlist is hidden from the community once this many
  -- unresolved reports exist, until an admin reviews it.
  report_hide_threshold integer not null default 3
    check (report_hide_threshold >= 1),
  -- Upper bound to keep playlists reasonable for kids and the UI.
  max_videos_per_playlist integer not null default 200
    check (max_videos_per_playlist >= 1)
);

insert into public.app_settings default values;

create function public.is_admin()
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select exists (select 1 from public.admins where user_id = auth.uid());
$$;

-- Create a profile for every new auth user.
create function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  insert into public.profiles (id) values (new.id);
  return new;
end;
$$;

create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();

-- ---------------------------------------------------------------------------
-- Labels
-- ---------------------------------------------------------------------------

-- Extensible: add rows to introduce new labels. The app localises by slug and
-- falls back to `name` for slugs it doesn't know yet.
create table public.labels (
  id smallint generated always as identity primary key,
  slug text not null unique check (slug ~ '^[a-z0-9]+(-[a-z0-9]+)*$'),
  name text not null check (char_length(name) between 1 and 40),
  sort_order integer not null default 0
);

-- ---------------------------------------------------------------------------
-- Playlists
-- ---------------------------------------------------------------------------

create table public.playlists (
  id uuid primary key default gen_random_uuid(),
  owner_id uuid not null default auth.uid()
    references public.profiles (id) on delete cascade,
  title text not null check (char_length(btrim(title)) between 1 and 80),
  description text check (char_length(description) <= 500),
  -- Covers are YouTube thumbnails only, so nobody can put arbitrary images in
  -- front of children through the community library.
  cover_url text
    check (cover_url ~ '^https://(i\.ytimg\.com|img\.youtube\.com)/'),
  age_min smallint not null default 2 check (age_min between 0 and 17),
  age_max smallint not null default 12 check (age_max between 0 and 17),
  visibility public.playlist_visibility not null default 'private',
  forked_from uuid references public.playlists (id) on delete set null,
  published_at timestamptz,
  -- Moderation (server-maintained).
  is_hidden boolean not null default false,
  needs_review boolean not null default false,
  reviewed_at timestamptz,
  report_count integer not null default 0 check (report_count >= 0),
  -- Ratings (server-maintained).
  rating_avg numeric(3, 2),
  rating_count integer not null default 0 check (rating_count >= 0),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint playlists_age_range check (age_min <= age_max)
);

create index playlists_owner_idx on public.playlists (owner_id, created_at desc);
create index playlists_forked_from_idx on public.playlists (forked_from);
create index playlists_community_top_idx on public.playlists
  (rating_avg desc nulls last, rating_count desc)
  where visibility = 'public' and not is_hidden;
create index playlists_community_new_idx on public.playlists (published_at desc)
  where visibility = 'public' and not is_hidden;
create index playlists_title_trgm_idx on public.playlists
  using gin (title extensions.gin_trgm_ops)
  where visibility = 'public' and not is_hidden;
create index playlists_needs_review_idx on public.playlists (needs_review)
  where needs_review;

create table public.playlist_videos (
  id uuid primary key default gen_random_uuid(),
  playlist_id uuid not null references public.playlists (id) on delete cascade,
  youtube_video_id text not null
    check (youtube_video_id ~ '^[A-Za-z0-9_-]{11}$'),
  title text not null check (char_length(title) between 1 and 300),
  channel_name text check (char_length(channel_name) <= 200),
  thumbnail_url text
    check (thumbnail_url ~ '^https://(i\.ytimg\.com|img\.youtube\.com)/'),
  duration_seconds integer check (duration_seconds >= 0),
  position integer not null check (position >= 0),
  -- Set to false by the revalidation Edge Function when a video is removed,
  -- made private or stops allowing embedding.
  is_available boolean not null default true,
  checked_at timestamptz,
  added_at timestamptz not null default now(),
  constraint playlist_videos_unique_video unique (playlist_id, youtube_video_id)
);

create index playlist_videos_order_idx
  on public.playlist_videos (playlist_id, position);

create table public.playlist_labels (
  playlist_id uuid not null references public.playlists (id) on delete cascade,
  label_id smallint not null references public.labels (id) on delete cascade,
  primary key (playlist_id, label_id)
);

create index playlist_labels_label_idx on public.playlist_labels (label_id);

-- ---------------------------------------------------------------------------
-- Ratings and reports
-- ---------------------------------------------------------------------------

create table public.ratings (
  playlist_id uuid not null references public.playlists (id) on delete cascade,
  user_id uuid not null default auth.uid()
    references public.profiles (id) on delete cascade,
  stars smallint not null check (stars between 1 and 5),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  primary key (playlist_id, user_id)
);

create index ratings_user_idx on public.ratings (user_id);

create table public.reports (
  id uuid primary key default gen_random_uuid(),
  playlist_id uuid not null references public.playlists (id) on delete cascade,
  reporter_id uuid not null default auth.uid()
    references public.profiles (id) on delete cascade,
  reason public.report_reason not null,
  details text check (char_length(details) <= 500),
  created_at timestamptz not null default now(),
  -- Set when an admin reviews the playlist. Resolved reports no longer count.
  resolved_at timestamptz,
  constraint reports_one_per_parent unique (playlist_id, reporter_id)
);

create index reports_unresolved_idx on public.reports (playlist_id)
  where resolved_at is null;

-- ---------------------------------------------------------------------------
-- Trigger functions
-- ---------------------------------------------------------------------------

create function public.set_updated_at()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
  new.updated_at := now();
  return new;
end;
$$;

create trigger playlists_set_updated_at
  before update on public.playlists
  for each row execute function public.set_updated_at();

create trigger ratings_set_updated_at
  before update on public.ratings
  for each row execute function public.set_updated_at();

-- Stamp published_at whenever a playlist becomes public.
create function public.playlists_track_publish()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
  if new.visibility = 'public'
     and (tg_op = 'INSERT' or old.visibility is distinct from 'public') then
    new.published_at := now();
  elsif new.visibility = 'private' then
    new.published_at := null;
  end if;
  return new;
end;
$$;

create trigger playlists_track_publish
  before insert or update of visibility on public.playlists
  for each row execute function public.playlists_track_publish();

-- A public playlist must have 1-3 labels and at least one available video.
-- Deferred to commit time so labels can be replaced atomically
-- (see set_playlist_labels) without tripping the check mid-transaction.
create function public.check_public_playlist()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  target uuid;
  p public.playlists;
begin
  -- Fires after insert/update on playlists, or after delete on the children.
  if tg_table_name = 'playlists' then
    target := new.id;
  else
    target := old.playlist_id;
  end if;

  select * into p from public.playlists where id = target;
  -- Deleted (e.g. cascade) or private: nothing to check.
  if not found or p.visibility <> 'public' then
    return null;
  end if;
  if not exists (select 1 from public.playlist_labels where playlist_id = target) then
    raise exception 'public_playlist_needs_label' using errcode = 'check_violation';
  end if;
  if not exists (
    select 1 from public.playlist_videos
    where playlist_id = target and is_available
  ) then
    raise exception 'public_playlist_needs_video' using errcode = 'check_violation';
  end if;
  return null;
end;
$$;

create constraint trigger playlists_check_public
  after insert or update of visibility on public.playlists
  deferrable initially deferred
  for each row execute function public.check_public_playlist();

create constraint trigger playlist_labels_check_public
  after delete on public.playlist_labels
  deferrable initially deferred
  for each row execute function public.check_public_playlist();

-- Only owner deletes are checked: when revalidation marks the last video
-- unavailable, the playlist simply drops out of the community view instead.
create constraint trigger playlist_videos_check_public
  after delete on public.playlist_videos
  deferrable initially deferred
  for each row execute function public.check_public_playlist();

-- At most 3 labels per playlist.
create function public.enforce_label_limit()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  -- Serialise concurrent inserts for the same playlist.
  perform 1 from public.playlists where id = new.playlist_id for update;
  if (select count(*) from public.playlist_labels
      where playlist_id = new.playlist_id) >= 3 then
    raise exception 'too_many_labels' using errcode = 'check_violation';
  end if;
  return new;
end;
$$;

create trigger playlist_labels_limit
  before insert on public.playlist_labels
  for each row execute function public.enforce_label_limit();

-- Cap the number of videos per playlist.
create function public.enforce_video_limit()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  max_videos integer;
begin
  perform 1 from public.playlists where id = new.playlist_id for update;
  select max_videos_per_playlist into max_videos from public.app_settings;
  if (select count(*) from public.playlist_videos
      where playlist_id = new.playlist_id) >= max_videos then
    raise exception 'too_many_videos' using errcode = 'check_violation';
  end if;
  return new;
end;
$$;

create trigger playlist_videos_limit
  before insert on public.playlist_videos
  for each row execute function public.enforce_video_limit();

-- Parents can't rate their own playlists (also enforced in RLS).
create function public.forbid_self_rating()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  if exists (
    select 1 from public.playlists
    where id = new.playlist_id and owner_id = new.user_id
  ) then
    raise exception 'cannot_rate_own_playlist' using errcode = 'check_violation';
  end if;
  return new;
end;
$$;

create trigger ratings_forbid_self
  before insert or update on public.ratings
  for each row execute function public.forbid_self_rating();

-- Keep rating_avg / rating_count in sync.
create function public.refresh_playlist_rating()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  target uuid := coalesce(new.playlist_id, old.playlist_id);
begin
  update public.playlists p
  set rating_avg = agg.avg_stars,
      rating_count = agg.n
  from (
    select round(avg(stars)::numeric, 2) as avg_stars, count(*)::integer as n
    from public.ratings
    where playlist_id = target
  ) agg
  where p.id = target;
  return null;
end;
$$;

create trigger ratings_refresh_aggregate
  after insert or update of stars or delete on public.ratings
  for each row execute function public.refresh_playlist_rating();

-- Keep report_count in sync and auto-hide at the threshold. Hiding is sticky:
-- only an admin review (admin_review_playlist) un-hides a playlist.
create function public.refresh_playlist_reports()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  target uuid := coalesce(new.playlist_id, old.playlist_id);
  threshold integer;
  n integer;
begin
  select report_hide_threshold into threshold from public.app_settings;
  select count(*)::integer into n
  from public.reports
  where playlist_id = target and resolved_at is null;

  update public.playlists
  set report_count = n,
      is_hidden = is_hidden or n >= threshold,
      needs_review = needs_review or n >= threshold
  where id = target;
  return null;
end;
$$;

create trigger reports_refresh_count
  after insert or update of resolved_at or delete on public.reports
  for each row execute function public.refresh_playlist_reports();

-- ---------------------------------------------------------------------------
-- RPCs
-- ---------------------------------------------------------------------------

-- Replace a playlist's labels atomically (owner only, via RLS).
create function public.set_playlist_labels(
  p_playlist_id uuid,
  p_label_ids smallint[]
)
returns void
language plpgsql
security invoker
set search_path = ''
as $$
begin
  if cardinality(array(select distinct unnest(p_label_ids))) > 3 then
    raise exception 'too_many_labels' using errcode = 'check_violation';
  end if;
  if not exists (
    select 1 from public.playlists
    where id = p_playlist_id and owner_id = auth.uid()
  ) then
    raise exception 'playlist_not_found' using errcode = 'no_data_found';
  end if;
  delete from public.playlist_labels where playlist_id = p_playlist_id;
  insert into public.playlist_labels (playlist_id, label_id)
  select p_playlist_id, l from (select distinct unnest(p_label_ids) as l) s;
end;
$$;

-- Persist a new video order (owner only, via RLS). Positions become 0..n-1
-- following the array order.
create function public.reorder_playlist_videos(
  p_playlist_id uuid,
  p_video_ids uuid[]
)
returns void
language sql
security invoker
set search_path = ''
as $$
  update public.playlist_videos v
  set position = o.ord - 1
  from unnest(p_video_ids) with ordinality as o(id, ord)
  where v.id = o.id and v.playlist_id = p_playlist_id;
$$;

-- Copy a community playlist into the caller's library ("Save to my library").
create function public.fork_playlist(p_source_id uuid)
returns uuid
language plpgsql
security definer
set search_path = ''
as $$
declare
  uid uuid := auth.uid();
  src public.playlists;
  new_id uuid;
begin
  if uid is null then
    raise exception 'not_authenticated' using errcode = 'insufficient_privilege';
  end if;

  select * into src from public.playlists
  where id = p_source_id
    and ((visibility = 'public' and not is_hidden) or owner_id = uid);
  if not found then
    raise exception 'playlist_not_found' using errcode = 'no_data_found';
  end if;

  insert into public.playlists
    (owner_id, title, description, cover_url, age_min, age_max, forked_from)
  values
    (uid, src.title, src.description, src.cover_url, src.age_min, src.age_max,
     src.id)
  returning id into new_id;

  insert into public.playlist_videos
    (playlist_id, youtube_video_id, title, channel_name, thumbnail_url,
     duration_seconds, position)
  select new_id, youtube_video_id, title, channel_name, thumbnail_url,
         duration_seconds, row_number() over (order by position) - 1
  from public.playlist_videos
  where playlist_id = src.id and is_available;

  insert into public.playlist_labels (playlist_id, label_id)
  select new_id, label_id from public.playlist_labels where playlist_id = src.id;

  return new_id;
end;
$$;

-- Moderation: an admin either confirms the hide or restores the playlist.
-- Either way, the outstanding reports are resolved.
create function public.admin_review_playlist(p_playlist_id uuid, p_hide boolean)
returns void
language plpgsql
security definer
set search_path = ''
as $$
begin
  if not public.is_admin() then
    raise exception 'not_admin' using errcode = 'insufficient_privilege';
  end if;
  update public.reports set resolved_at = now()
  where playlist_id = p_playlist_id and resolved_at is null;
  update public.playlists
  set is_hidden = p_hide, needs_review = false, reviewed_at = now()
  where id = p_playlist_id;
end;
$$;

-- GDPR / store requirement: delete the caller's account and, by cascade,
-- their profile, playlists, videos, labels, ratings and reports. Forks other
-- parents made of their playlists survive with forked_from set to null.
create function public.delete_my_account()
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  uid uuid := auth.uid();
begin
  if uid is null then
    raise exception 'not_authenticated' using errcode = 'insufficient_privilege';
  end if;
  delete from auth.users where id = uid;
end;
$$;

-- ---------------------------------------------------------------------------
-- Community view
-- ---------------------------------------------------------------------------

-- What the community library shows. security_invoker keeps the caller's RLS
-- in force. Filter by label with `label_slugs=cs.{science}`.
create view public.community_playlists
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
where p.visibility = 'public' and not p.is_hidden;

-- ---------------------------------------------------------------------------
-- Privileges
-- ---------------------------------------------------------------------------

-- Start from nothing (Supabase grants ALL to anon/authenticated by default),
-- then grant exactly what the app needs.
-- Later migrations must repeat this for new tables/functions.
revoke all on all tables in schema public from anon, authenticated;
revoke all on all functions in schema public from public, anon, authenticated;

grant select on public.labels to authenticated;

grant select on public.profiles to authenticated;
grant update (display_name) on public.profiles to authenticated;

grant select, delete on public.playlists to authenticated;
grant insert (id, title, description, cover_url, age_min, age_max, visibility)
  on public.playlists to authenticated;
grant update (title, description, cover_url, age_min, age_max, visibility)
  on public.playlists to authenticated;

grant select, delete on public.playlist_videos to authenticated;
grant insert (playlist_id, youtube_video_id, title, channel_name,
              thumbnail_url, duration_seconds, position)
  on public.playlist_videos to authenticated;
grant update (position) on public.playlist_videos to authenticated;

grant select, insert, delete on public.playlist_labels to authenticated;

grant select, delete on public.ratings to authenticated;
grant insert (playlist_id, stars) on public.ratings to authenticated;
grant update (stars) on public.ratings to authenticated;

-- Reports are write-only for parents (admins read them through RLS below).
grant select on public.reports to authenticated;
grant insert (playlist_id, reason, details) on public.reports to authenticated;

grant select on public.community_playlists to authenticated;

grant execute on function
  public.is_admin(),
  public.set_playlist_labels(uuid, smallint[]),
  public.reorder_playlist_videos(uuid, uuid[]),
  public.fork_playlist(uuid),
  public.admin_review_playlist(uuid, boolean),
  public.delete_my_account()
to authenticated;

-- ---------------------------------------------------------------------------
-- Row Level Security
-- ---------------------------------------------------------------------------

alter table public.profiles enable row level security;
alter table public.admins enable row level security;
alter table public.app_settings enable row level security;
alter table public.labels enable row level security;
alter table public.playlists enable row level security;
alter table public.playlist_videos enable row level security;
alter table public.playlist_labels enable row level security;
alter table public.ratings enable row level security;
alter table public.reports enable row level security;

-- labels
create policy "labels are readable by parents"
  on public.labels for select to authenticated
  using (true);

-- profiles: display names are public to signed-in parents (author bylines).
create policy "profiles are readable by parents"
  on public.profiles for select to authenticated
  using (true);

create policy "parents update their own profile"
  on public.profiles for update to authenticated
  using (id = (select auth.uid()))
  with check (id = (select auth.uid()));

-- playlists
create policy "read own, community or (admin) any playlist"
  on public.playlists for select to authenticated
  using (
    owner_id = (select auth.uid())
    or (visibility = 'public' and not is_hidden)
    or (select public.is_admin())
  );

create policy "create own playlists"
  on public.playlists for insert to authenticated
  with check (owner_id = (select auth.uid()));

create policy "update own playlists"
  on public.playlists for update to authenticated
  using (owner_id = (select auth.uid()))
  with check (owner_id = (select auth.uid()));

create policy "delete own playlists"
  on public.playlists for delete to authenticated
  using (owner_id = (select auth.uid()));

-- playlist_videos: readable when the parent playlist is readable.
create policy "read videos of readable playlists"
  on public.playlist_videos for select to authenticated
  using (exists (
    select 1 from public.playlists p where p.id = playlist_id
  ));

create policy "owners add videos"
  on public.playlist_videos for insert to authenticated
  with check (exists (
    select 1 from public.playlists p
    where p.id = playlist_id and p.owner_id = (select auth.uid())
  ));

create policy "owners update videos"
  on public.playlist_videos for update to authenticated
  using (exists (
    select 1 from public.playlists p
    where p.id = playlist_id and p.owner_id = (select auth.uid())
  ));

create policy "owners remove videos"
  on public.playlist_videos for delete to authenticated
  using (exists (
    select 1 from public.playlists p
    where p.id = playlist_id and p.owner_id = (select auth.uid())
  ));

-- playlist_labels
create policy "read labels of readable playlists"
  on public.playlist_labels for select to authenticated
  using (exists (
    select 1 from public.playlists p where p.id = playlist_id
  ));

create policy "owners add labels"
  on public.playlist_labels for insert to authenticated
  with check (exists (
    select 1 from public.playlists p
    where p.id = playlist_id and p.owner_id = (select auth.uid())
  ));

create policy "owners remove labels"
  on public.playlist_labels for delete to authenticated
  using (exists (
    select 1 from public.playlists p
    where p.id = playlist_id and p.owner_id = (select auth.uid())
  ));

-- ratings: parents see and manage only their own; aggregates live on playlists.
create policy "read own ratings"
  on public.ratings for select to authenticated
  using (user_id = (select auth.uid()));

create policy "rate community playlists of others"
  on public.ratings for insert to authenticated
  with check (
    user_id = (select auth.uid())
    and exists (
      select 1 from public.playlists p
      where p.id = playlist_id
        and p.visibility = 'public'
        and not p.is_hidden
        and p.owner_id <> (select auth.uid())
    )
  );

create policy "update own ratings"
  on public.ratings for update to authenticated
  using (user_id = (select auth.uid()))
  with check (user_id = (select auth.uid()));

create policy "delete own ratings"
  on public.ratings for delete to authenticated
  using (user_id = (select auth.uid()));

-- reports: insert-only for parents; only admins can read.
create policy "report community playlists of others"
  on public.reports for insert to authenticated
  with check (
    reporter_id = (select auth.uid())
    and exists (
      select 1 from public.playlists p
      where p.id = playlist_id
        and p.visibility = 'public'
        and p.owner_id <> (select auth.uid())
    )
  );

create policy "admins read reports"
  on public.reports for select to authenticated
  using ((select public.is_admin()));

-- admins, app_settings: no policies → no client access.
