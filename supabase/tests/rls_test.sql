-- Behavioural tests for the schema, RLS and triggers.
-- Run with tool/test_db.sh. Everything happens in one transaction that is
-- rolled back, so it is safe against a local Supabase database too.
\set ON_ERROR_STOP on
begin;

-- Helpers ------------------------------------------------------------------

create function pg_temp.login(uid uuid) returns void language plpgsql as $$
begin
  perform set_config('role', 'authenticated', true);
  perform set_config('request.jwt.claim.sub', uid::text, true);
end $$;

create function pg_temp.logout() returns void language plpgsql as $$
begin
  perform set_config('role', 'postgres', true);
  perform set_config('request.jwt.claim.sub', '', true);
end $$;

-- Runs `stmt` and asserts it fails with a message matching `pattern`.
create function pg_temp.throws(stmt text, pattern text, label text)
returns void language plpgsql as $$
begin
  begin
    execute stmt;
  exception when others then
    if sqlerrm !~* pattern then
      raise exception 'FAIL %: expected error ~ "%", got "%"', label, pattern, sqlerrm;
    end if;
    raise notice 'ok - %', label;
    return;
  end;
  raise exception 'FAIL %: expected an error, statement succeeded', label;
end $$;

create function pg_temp.ok(cond boolean, label text) returns void
language plpgsql as $$
begin
  if cond is distinct from true then
    raise exception 'FAIL %', label;
  end if;
  raise notice 'ok - %', label;
end $$;

-- Fixtures -----------------------------------------------------------------

insert into auth.users (id, email) values
  ('00000000-0000-0000-0000-00000000000a', 'alice@example.com'),
  ('00000000-0000-0000-0000-00000000000b', 'bob@example.com'),
  ('00000000-0000-0000-0000-00000000000c', 'carol@example.com'),
  ('00000000-0000-0000-0000-00000000000d', 'dave@example.com'),
  ('00000000-0000-0000-0000-0000000000ad', 'admin@example.com');
insert into public.admins (user_id) values ('00000000-0000-0000-0000-0000000000ad');

select pg_temp.ok(
  (select count(*) from public.profiles) = 5
  and (select bool_and(display_name = 'Parent') from public.profiles),
  'profiles are created for new users with a neutral display name');

select pg_temp.ok((select count(*) from public.labels) = 16, '16 labels seeded');

-- Alice builds a playlist ----------------------------------------------------

select pg_temp.login('00000000-0000-0000-0000-00000000000a');

insert into public.playlists (id, title, age_min, age_max)
values ('11111111-1111-1111-1111-111111111111', 'Space for little ones', 3, 6);

select pg_temp.ok(
  (select owner_id from public.playlists
   where id = '11111111-1111-1111-1111-111111111111')
  = '00000000-0000-0000-0000-00000000000a',
  'owner_id defaults to the caller');

select pg_temp.throws(
  $$insert into public.playlists (title, owner_id)
    values ('x', '00000000-0000-0000-0000-00000000000b')$$,
  'permission denied', 'cannot set owner_id explicitly');

select pg_temp.throws(
  $$update public.playlists set report_count = 0, is_hidden = false
    where id = '11111111-1111-1111-1111-111111111111'$$,
  'permission denied', 'cannot write moderation columns');

select pg_temp.throws(
  $$update public.playlists set rating_avg = 5
    where id = '11111111-1111-1111-1111-111111111111'$$,
  'permission denied', 'cannot write rating aggregates');

select pg_temp.throws(
  $$insert into public.playlists (title, cover_url) values ('x', 'https://evil.example/a.png')$$,
  'permission denied|check', 'clients cannot set arbitrary covers');

select pg_temp.throws(
  $$insert into public.playlists (title, age_min, age_max) values ('x', 9, 4)$$,
  'playlists_age_range', 'age range must be ordered');

insert into public.playlist_videos
  (playlist_id, youtube_video_id, title, channel_name, thumbnail_url, duration_seconds, position)
values
  ('11111111-1111-1111-1111-111111111111', 'dQw4w9WgXcQ', 'Planets song', 'Kids Channel',
   'https://i.ytimg.com/vi/dQw4w9WgXcQ/hqdefault.jpg', 120, 0),
  ('11111111-1111-1111-1111-111111111111', 'aaaaaaaaaaa', 'Moon facts', 'Kids Channel',
   'https://i.ytimg.com/vi/aaaaaaaaaaa/hqdefault.jpg', 180, 1);

select pg_temp.throws(
  $$insert into public.playlist_videos (playlist_id, youtube_video_id, title, position)
    values ('11111111-1111-1111-1111-111111111111', 'not-an-id', 'x', 2)$$,
  'check', 'video id must look like a YouTube id');

select pg_temp.throws(
  $$insert into public.playlist_videos (playlist_id, youtube_video_id, title, position)
    values ('11111111-1111-1111-1111-111111111111', 'dQw4w9WgXcQ', 'dupe', 2)$$,
  'playlist_videos_unique_video', 'no duplicate videos in a playlist');

select pg_temp.throws(
  $$update public.playlist_videos set is_available = false
    where youtube_video_id = 'dQw4w9WgXcQ'$$,
  'permission denied', 'cannot set is_available');

-- Reorder.
select public.reorder_playlist_videos(
  '11111111-1111-1111-1111-111111111111',
  array(select id from public.playlist_videos
        where playlist_id = '11111111-1111-1111-1111-111111111111'
        order by position desc));
select pg_temp.ok(
  (select youtube_video_id from public.playlist_videos
   where playlist_id = '11111111-1111-1111-1111-111111111111' and position = 0)
  = 'aaaaaaaaaaa',
  'reorder_playlist_videos persists the new order');

-- Publishing requires labels (checked at commit → use a savepoint + SET CONSTRAINTS).
savepoint before_publish;
select pg_temp.throws(
  $$update public.playlists set visibility = 'public'
    where id = '11111111-1111-1111-1111-111111111111';
    set constraints all immediate$$,
  'public_playlist_needs_label', 'publishing without labels fails');
rollback to savepoint before_publish;
select pg_temp.login('00000000-0000-0000-0000-00000000000a');

-- Labels: max 3.
select pg_temp.throws(
  $$select public.set_playlist_labels('11111111-1111-1111-1111-111111111111',
      (select array_agg(id) from (select id from public.labels limit 4) s))$$,
  'too_many_labels', 'set_playlist_labels rejects 4 labels');

select pg_temp.throws(
  $$insert into public.playlist_labels (playlist_id, label_id)
    select '11111111-1111-1111-1111-111111111111', id from public.labels limit 4$$,
  'too_many_labels', 'trigger rejects a 4th label');

select public.set_playlist_labels('11111111-1111-1111-1111-111111111111',
  array(select id from public.labels where slug in ('space', 'science')));

update public.playlists set visibility = 'public'
where id = '11111111-1111-1111-1111-111111111111';
set constraints all immediate;
set constraints all deferred;

select pg_temp.ok(
  (select published_at is not null from public.playlists
   where id = '11111111-1111-1111-1111-111111111111'),
  'published_at is stamped on publish');

-- Replacing labels on a public playlist works atomically.
select public.set_playlist_labels('11111111-1111-1111-1111-111111111111',
  array(select id from public.labels where slug = 'space'));
set constraints all immediate;
set constraints all deferred;
select pg_temp.ok(true, 'labels can be replaced on a public playlist');

-- But removing the last label of a public playlist fails.
savepoint before_unlabel;
select pg_temp.throws(
  $$delete from public.playlist_labels
    where playlist_id = '11111111-1111-1111-1111-111111111111';
    set constraints all immediate$$,
  'public_playlist_needs_label', 'cannot strip all labels from a public playlist');
rollback to savepoint before_unlabel;

-- A private playlist for Alice only.
select pg_temp.login('00000000-0000-0000-0000-00000000000a');
insert into public.playlists (id, title)
values ('22222222-2222-2222-2222-222222222222', 'Alice private');

-- Bob's view ------------------------------------------------------------------

select pg_temp.login('00000000-0000-0000-0000-00000000000b');

select pg_temp.ok(
  (select count(*) from public.playlists) = 1,
  'other parents see public playlists only');
select pg_temp.ok(
  (select count(*) from public.playlist_videos) = 2,
  'other parents see videos of public playlists');
select pg_temp.ok(
  (select count(*) from public.playlist_videos
   where playlist_id = '22222222-2222-2222-2222-222222222222') = 0,
  'videos of private playlists are not visible');

update public.playlists set title = 'hacked'
where id = '11111111-1111-1111-1111-111111111111';
delete from public.playlist_videos
where playlist_id = '11111111-1111-1111-1111-111111111111';
select pg_temp.login('00000000-0000-0000-0000-00000000000a');
select pg_temp.ok(
  (select title from public.playlists
   where id = '11111111-1111-1111-1111-111111111111') = 'Space for little ones'
  and (select count(*) from public.playlist_videos
       where playlist_id = '11111111-1111-1111-1111-111111111111') = 2,
  'other parents cannot modify someone else''s playlist or videos');

select pg_temp.login('00000000-0000-0000-0000-00000000000b');
select pg_temp.throws(
  $$insert into public.playlist_videos (playlist_id, youtube_video_id, title, position)
    values ('11111111-1111-1111-1111-111111111111', 'bbbbbbbbbbb', 'x', 9)$$,
  'row-level security', 'cannot add videos to someone else''s playlist');

-- Community view.
select pg_temp.ok(
  (select video_count = 2 and total_duration_seconds = 300
          and label_slugs = '{space}' and author_name = 'Parent'
   from public.community_playlists
   where id = '11111111-1111-1111-1111-111111111111'),
  'community view aggregates counts, duration, labels and author');
select pg_temp.ok(
  not exists (
    select 1 from information_schema.columns
    where table_name = 'community_playlists' and column_name ilike '%email%'),
  'community view exposes no email');

-- Ratings.
insert into public.ratings (playlist_id, stars)
values ('11111111-1111-1111-1111-111111111111', 4);
select pg_temp.login('00000000-0000-0000-0000-00000000000c');
insert into public.ratings (playlist_id, stars)
values ('11111111-1111-1111-1111-111111111111', 5);
select pg_temp.ok(
  (select rating_avg = 4.5 and rating_count = 2 from public.playlists
   where id = '11111111-1111-1111-1111-111111111111'),
  'rating aggregate after two ratings');

update public.ratings set stars = 1
where playlist_id = '11111111-1111-1111-1111-111111111111';
select pg_temp.ok(
  (select rating_avg = 2.5 and rating_count = 2 from public.playlists
   where id = '11111111-1111-1111-1111-111111111111'),
  'editing a rating updates the aggregate');

select pg_temp.throws(
  $$insert into public.ratings (playlist_id, stars)
    values ('11111111-1111-1111-1111-111111111111', 3)$$,
  'ratings_pkey', 'one rating per parent per playlist');

select pg_temp.throws(
  $$insert into public.ratings (playlist_id, stars)
    values ('11111111-1111-1111-1111-111111111111', 6)$$,
  'check', 'stars must be 1-5');

select pg_temp.ok(
  (select count(*) from public.ratings) = 1,
  'parents only see their own ratings');

select pg_temp.login('00000000-0000-0000-0000-00000000000a');
select pg_temp.throws(
  $$insert into public.ratings (playlist_id, stars)
    values ('11111111-1111-1111-1111-111111111111', 5)$$,
  'row-level security|cannot_rate_own_playlist', 'cannot rate own playlist');

-- Forking.
select pg_temp.login('00000000-0000-0000-0000-00000000000d');
create temp table forked as
  select public.fork_playlist('11111111-1111-1111-1111-111111111111') as id;
select pg_temp.ok(
  (select forked_from = '11111111-1111-1111-1111-111111111111'
          and visibility = 'private'
          and owner_id = '00000000-0000-0000-0000-00000000000d'
   from public.playlists where id = (select id from forked)),
  'fork creates a private copy owned by the caller');
select pg_temp.ok(
  (select count(*) from public.playlist_videos v
   join public.playlists p on p.id = v.playlist_id
   where p.owner_id = '00000000-0000-0000-0000-00000000000d') = 2,
  'fork copies the videos');
select pg_temp.throws(
  $$select public.fork_playlist('22222222-2222-2222-2222-222222222222')$$,
  'playlist_not_found', 'cannot fork a private playlist of someone else');

-- Reports and auto-hide.
select pg_temp.login('00000000-0000-0000-0000-00000000000b');
insert into public.reports (playlist_id, reason)
values ('11111111-1111-1111-1111-111111111111', 'not_for_kids');
select pg_temp.ok(
  (select count(*) from public.reports) = 0,
  'reports are not readable by regular parents');
select pg_temp.throws(
  $$insert into public.reports (playlist_id, reason)
    values ('11111111-1111-1111-1111-111111111111', 'spam')$$,
  'reports_one_per_parent', 'one report per parent per playlist');

select pg_temp.login('00000000-0000-0000-0000-00000000000a');
select pg_temp.throws(
  $$insert into public.reports (playlist_id, reason)
    values ('11111111-1111-1111-1111-111111111111', 'spam')$$,
  'row-level security', 'cannot report own playlist');

select pg_temp.login('00000000-0000-0000-0000-00000000000c');
insert into public.reports (playlist_id, reason)
values ('11111111-1111-1111-1111-111111111111', 'violent_or_scary');
select pg_temp.ok(
  (select count(*) from public.community_playlists) = 1,
  'still listed below the threshold');

select pg_temp.login('00000000-0000-0000-0000-00000000000d');
insert into public.reports (playlist_id, reason, details)
values ('11111111-1111-1111-1111-111111111111', 'other', 'Scary thumbnail');
select pg_temp.ok(
  (select count(*) from public.community_playlists) = 0
  and (select count(*) from public.playlists
       where id = '11111111-1111-1111-1111-111111111111') = 0,
  'hidden from the community at 3 reports');

select pg_temp.login('00000000-0000-0000-0000-00000000000a');
select pg_temp.ok(
  (select is_hidden and needs_review and report_count = 3
   from public.playlists where id = '11111111-1111-1111-1111-111111111111'),
  'owner still sees the hidden playlist, flagged for review');

select pg_temp.throws(
  $$select public.admin_review_playlist('11111111-1111-1111-1111-111111111111', false)$$,
  'not_admin', 'only admins can review');

select pg_temp.login('00000000-0000-0000-0000-0000000000ad');
select pg_temp.ok((select count(*) from public.reports) = 3, 'admins read reports');
select public.admin_review_playlist('11111111-1111-1111-1111-111111111111', false);
select pg_temp.login('00000000-0000-0000-0000-00000000000b');
select pg_temp.ok(
  (select count(*) from public.community_playlists) = 1
  and (select report_count from public.playlists
       where id = '11111111-1111-1111-1111-111111111111') = 0,
  'admin restore un-hides and resolves reports');

-- Anonymous access.
select pg_temp.logout();
set local role anon;
select pg_temp.throws($$select * from public.playlists$$, 'permission denied',
  'anon cannot read playlists');
select pg_temp.throws($$select * from public.labels$$, 'permission denied',
  'anon cannot read labels');
select pg_temp.throws($$select public.delete_my_account()$$, 'permission denied',
  'anon cannot call RPCs');
reset role;

-- Settings tables are closed to clients.
select pg_temp.login('00000000-0000-0000-0000-00000000000b');
select pg_temp.throws($$select * from public.admins$$, 'permission denied',
  'admins table is closed to clients');
select pg_temp.throws($$select * from public.app_settings$$, 'permission denied',
  'app_settings is closed to clients');

-- Playlist order and covers (M2) --------------------------------------------

select pg_temp.login('00000000-0000-0000-0000-00000000000a');
insert into public.playlists (id, title)
values ('33333333-3333-3333-3333-333333333333', 'Newest');
select pg_temp.ok(
  (select id from public.playlists
   where owner_id = '00000000-0000-0000-0000-00000000000a'
   order by sort_index limit 1) = '33333333-3333-3333-3333-333333333333',
  'new playlists go to the top of the library');

select public.reorder_my_playlists(array[
  '11111111-1111-1111-1111-111111111111',
  '22222222-2222-2222-2222-222222222222',
  '33333333-3333-3333-3333-333333333333']::uuid[]);
select pg_temp.ok(
  (select array_agg(id order by sort_index) from public.playlists
   where owner_id = '00000000-0000-0000-0000-00000000000a')
  = array['11111111-1111-1111-1111-111111111111',
          '22222222-2222-2222-2222-222222222222',
          '33333333-3333-3333-3333-333333333333']::uuid[],
  'reorder_my_playlists persists the order');

select pg_temp.ok(
  (select cover_url from public.playlists
   where id = '33333333-3333-3333-3333-333333333333') is null,
  'empty playlist has no cover');
insert into public.playlist_videos
  (playlist_id, youtube_video_id, title, thumbnail_url, position)
values
  ('33333333-3333-3333-3333-333333333333', 'ccccccccccc', 'C',
   'https://i.ytimg.com/vi/ccccccccccc/hqdefault.jpg', 0),
  ('33333333-3333-3333-3333-333333333333', 'ddddddddddd', 'D',
   'https://i.ytimg.com/vi/ddddddddddd/hqdefault.jpg', 1);
select pg_temp.ok(
  (select cover_url from public.playlists
   where id = '33333333-3333-3333-3333-333333333333')
  = 'https://i.ytimg.com/vi/ccccccccccc/hqdefault.jpg',
  'cover follows the first video');
select public.reorder_playlist_videos('33333333-3333-3333-3333-333333333333',
  array(select id from public.playlist_videos
        where playlist_id = '33333333-3333-3333-3333-333333333333'
        order by position desc));
select pg_temp.ok(
  (select cover_url from public.playlists
   where id = '33333333-3333-3333-3333-333333333333')
  = 'https://i.ytimg.com/vi/ddddddddddd/hqdefault.jpg',
  'cover updates after reordering');
delete from public.playlist_videos
where playlist_id = '33333333-3333-3333-3333-333333333333';
select pg_temp.ok(
  (select cover_url from public.playlists
   where id = '33333333-3333-3333-3333-333333333333') is null,
  'cover clears when the playlist is emptied');

select pg_temp.login('00000000-0000-0000-0000-00000000000b');
select public.reorder_my_playlists(array[
  '33333333-3333-3333-3333-333333333333']::uuid[]);
select pg_temp.logout();
select pg_temp.ok(
  (select sort_index from public.playlists
   where id = '33333333-3333-3333-3333-333333333333') = 2,
  'cannot reorder someone else''s playlists');

-- Video durations (M3) ---------------------------------------------------------

select pg_temp.login('00000000-0000-0000-0000-00000000000a');
update public.playlist_videos set duration_seconds = 95
where youtube_video_id = 'dQw4w9WgXcQ'
  and playlist_id = '11111111-1111-1111-1111-111111111111';
select pg_temp.ok(
  (select duration_seconds from public.playlist_videos
   where youtube_video_id = 'dQw4w9WgXcQ'
     and playlist_id = '11111111-1111-1111-1111-111111111111') = 95,
  'owners can record a video duration');

select pg_temp.login('00000000-0000-0000-0000-00000000000c');
update public.playlist_videos set duration_seconds = 1
where playlist_id = '11111111-1111-1111-1111-111111111111';
select pg_temp.login('00000000-0000-0000-0000-00000000000a');
select pg_temp.ok(
  (select duration_seconds from public.playlist_videos
   where youtube_video_id = 'dQw4w9WgXcQ'
     and playlist_id = '11111111-1111-1111-1111-111111111111') = 95,
  'other parents cannot change durations');

-- Account deletion.
select pg_temp.login('00000000-0000-0000-0000-00000000000a');
select public.delete_my_account();
select pg_temp.logout();
select pg_temp.ok(
  not exists (select 1 from auth.users where id = '00000000-0000-0000-0000-00000000000a')
  and not exists (select 1 from public.profiles where id = '00000000-0000-0000-0000-00000000000a')
  and not exists (select 1 from public.playlists where owner_id = '00000000-0000-0000-0000-00000000000a'),
  'delete_my_account removes the user and their data');
select pg_temp.ok(
  (select forked_from is null from public.playlists
   where owner_id = '00000000-0000-0000-0000-00000000000d'),
  'forks by other parents survive with forked_from cleared');
select pg_temp.ok(
  not exists (select 1 from public.ratings
              where playlist_id = '11111111-1111-1111-1111-111111111111'),
  'ratings on deleted playlists are gone');

\echo 'All database tests passed.'
rollback;
