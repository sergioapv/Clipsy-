-- Playlist languages: 1-3 BCP 47 tags per playlist (e.g. pt-PT, pt-BR,
-- en-GB, es-419, zh-Hant), set by the parent. YouTube's oEmbed doesn't say
-- what language a video is in, so it can't be detected without the Data API.
--
-- Filtering: a bare language ("pt") matches every Portuguese playlist; a
-- variant ("pt-PT") matches that variant plus playlists tagged only "pt".

-- language[-Script][-REGION], REGION being two letters or three digits.
create function public.valid_language_tags(tags text[])
returns boolean
language sql
immutable
set search_path = ''
as $$
  select coalesce(cardinality(tags), 0) <= 3
    and not exists (
      select 1 from unnest(tags) t
      where t !~ '^[a-z]{2,3}(-[A-Z][a-z]{3})?(-([A-Z]{2}|[0-9]{3}))?$'
    )
    and cardinality(tags) = (select count(distinct t) from unnest(tags) t);
$$;

-- The language part of each tag, for "any variant" filters.
create function public.language_bases(tags text[])
returns text[]
language sql
immutable
set search_path = ''
as $$
  select coalesce(array_agg(distinct split_part(t, '-', 1)), '{}')
  from unnest(tags) t;
$$;

alter table public.playlists
  add column languages text[] not null default '{}'
    check (public.valid_language_tags(languages)),
  add column language_bases text[]
    generated always as (public.language_bases(languages)) stored;

create index playlists_languages_idx on public.playlists using gin (languages)
  where visibility = 'public' and not is_hidden;
create index playlists_language_bases_idx on public.playlists
  using gin (language_bases)
  where visibility = 'public' and not is_hidden;

grant insert (languages), update (languages) on public.playlists to authenticated;

-- Sharing now also needs a language. Checked when a playlist is shared or
-- its languages change, so playlists shared before languages existed stay
-- listed until their owner next edits them.
create or replace function public.check_public_playlist()
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
  if tg_table_name = 'playlists' and cardinality(p.languages) = 0 then
    raise exception 'public_playlist_needs_language' using errcode = 'check_violation';
  end if;
  return null;
end;
$$;

drop trigger playlists_check_public on public.playlists;
create constraint trigger playlists_check_public
  after insert or update of visibility, languages on public.playlists
  deferrable initially deferred
  for each row execute function public.check_public_playlist();

-- Copies keep the original's languages.
create or replace function public.fork_playlist(p_source_id uuid)
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
    (owner_id, title, description, cover_url, age_min, age_max, languages,
     forked_from)
  values
    (uid, src.title, src.description, src.cover_url, src.age_min, src.age_max,
     src.languages, src.id)
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

-- The community view gains the languages (appended: a view can only grow at
-- the end).
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
  coalesce(l.label_slugs, '{}') as label_slugs,
  p.languages,
  p.language_bases
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
