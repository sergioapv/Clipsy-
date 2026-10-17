-- Predefined labels. Lives in a migration (not seed.sql) because production
-- needs it too. To add a label later, write a new migration with another
-- insert; the app shows `name` until it ships a translation for the slug.
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
