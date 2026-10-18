-- Clipsy: remaining database setup.

-- Paste all of this into Supabase → SQL Editor and click Run.

-- (The tables were already created through the connector.)

begin;

create function public.is_admin()
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select exists (select 1 from public.admins where user_id = auth.uid());
$$;

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

create constraint trigger playlist_videos_check_public
  after delete on public.playlist_videos
  deferrable initially deferred
  for each row execute function public.check_public_playlist();

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

create policy "labels are readable by parents"
  on public.labels for select to authenticated
  using (true);

create policy "profiles are readable by parents"
  on public.profiles for select to authenticated
  using (true);

create policy "parents update their own profile"
  on public.profiles for update to authenticated
  using (id = (select auth.uid()))
  with check (id = (select auth.uid()));

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

-- ===== 20261017000100_seed_labels.sql =====

insert into public.labels (slug, name, sort_order) values
  ('science',   'Science',   10),
  ('nature',    'Nature',    20),
  ('animals',   'Animals',   30),
  ('football',  'Football',  40),
  ('sports',    'Sports',    50),
  ('music',     'Music',     60),
  ('art',       'Art',       70),
  ('languages', 'Languages', 80),
  ('maths',     'Maths',     90),
  ('stories',   'Stories',   100),
  ('bedtime',   'Bedtime',   110),
  ('cartoons',  'Cartoons',  120),
  ('history',   'History',   130),
  ('space',     'Space',     140),
  ('cooking',   'Cooking',   150),
  ('crafts',    'Crafts',    160)
on conflict (slug) do nothing;

-- ===== 20261018000000_playlist_order_and_cover.sql =====

alter table public.playlists
  add column sort_index integer not null default 0;

create index playlists_owner_sort_idx on public.playlists (owner_id, sort_index);

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

revoke insert (cover_url), update (cover_url) on public.playlists from authenticated;

revoke all on function
  public.playlists_set_sort_index(),
  public.refresh_playlist_cover(),
  public.reorder_my_playlists(uuid[])
from public, anon, authenticated;

grant execute on function public.reorder_my_playlists(uuid[]) to authenticated;

-- ===== 20261019000000_video_duration.sql =====

grant update (duration_seconds) on public.playlist_videos to authenticated;

commit;
