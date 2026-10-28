-- Run this once in your Supabase project's SQL Editor (Dashboard -> SQL Editor -> New query).
-- It creates the tables, locks writes to an admin-only list, and sets up the image bucket policies.

create extension if not exists "pgcrypto";

-- Whoever's auth user id is listed here can edit the site. No one can read or
-- write this table through the public API (it has no policies, so Row Level
-- Security blocks it by default) -- you manage it from the SQL Editor only.
create table if not exists admin_users (
  user_id uuid primary key references auth.users(id) on delete cascade
);

-- Site-wide profile info. Always exactly one row.
create table if not exists site_info (
  id boolean primary key default true check (id),
  name text not null default 'Your Name',
  tag text not null default 'Engineer . Builder . Researcher',
  location text not null default '',
  about text not null default 'Write a short bio here.',
  email text not null default '',
  links jsonb not null default '[]'::jsonb
);
insert into site_info (id) values (true) on conflict do nothing;

-- Projects, research entries and certifications all live in one table,
-- distinguished by "type".
create table if not exists items (
  id uuid primary key default gen_random_uuid(),
  type text not null check (type in ('project','research','cert')),
  title text not null default '',
  subtitle text not null default '',
  description text not null default '',
  tags text[] not null default '{}',
  link text not null default '',
  images text[] not null default '{}',   -- storage object paths, first = cover
  sort_order int not null default 0,
  created_at timestamptz not null default now()
);

alter table admin_users enable row level security;
alter table site_info enable row level security;
alter table items enable row level security;

create or replace function is_admin() returns boolean
language sql stable as $$
  select exists(select 1 from admin_users where user_id = auth.uid());
$$;

-- Everyone (including signed-out visitors) can read the site.
create policy "site_info read" on site_info for select using (true);
create policy "items read" on items for select using (true);

-- Only an admin can write.
create policy "site_info write" on site_info for update using (is_admin());
create policy "items insert" on items for insert with check (is_admin());
create policy "items update" on items for update using (is_admin());
create policy "items delete" on items for delete using (is_admin());

-- ---------------------------------------------------------------------
-- Image storage. Before running the block below:
--   1. Go to Storage in the Supabase dashboard.
--   2. Create a new bucket named exactly  media
--   3. Toggle "Public bucket" ON when creating it.
-- Then come back and run this:
-- ---------------------------------------------------------------------
create policy "media public read" on storage.objects for select
  using (bucket_id = 'media');
create policy "media admin write" on storage.objects for insert
  with check (bucket_id = 'media' and is_admin());
create policy "media admin delete" on storage.objects for delete
  using (bucket_id = 'media' and is_admin());

-- ---------------------------------------------------------------------
-- Make yourself the admin. Do this AFTER creating your own login under
-- Authentication -> Users -> Add user (email + password) in the dashboard.
-- Replace the email below with the one you used, then run just this line:
-- ---------------------------------------------------------------------
-- insert into admin_users (user_id)
-- select id from auth.users where email = 'you@example.com';
