-- ================================================================
-- Sweet Diary — SETUP LIMPIO (borra y recrea todo)
-- Pega en: Supabase → SQL Editor → Run
-- ================================================================

-- 1. Borrar tablas viejas (si existen) en orden correcto
drop table if exists spotify_embeds  cascade;
drop table if exists notes           cascade;
drop table if exists special_dates   cascade;
drop table if exists moods           cascade;
drop table if exists posts           cascade;
drop table if exists user_recovery   cascade;
drop table if exists settings        cascade;
drop table if exists profiles        cascade;

-- 2. Borrar policies de storage si existen
drop policy if exists "media_read"         on storage.objects;
drop policy if exists "media_insert"       on storage.objects;
drop policy if exists "media_delete"       on storage.objects;
drop policy if exists "anon_media_read"    on storage.objects;
drop policy if exists "anon_media_insert"  on storage.objects;
drop policy if exists "anon_media_delete"  on storage.objects;

-- 3. Crear tablas desde cero (profiles SIN FK a auth.users)
create table profiles (
  id         uuid primary key,
  username   text not null check (username in ('david','luenna')),
  created_at timestamptz default now()
);

create table settings (
  key        text primary key,
  value      text not null,
  updated_at timestamptz default now()
);

create table posts (
  id         uuid default gen_random_uuid() primary key,
  author_id  uuid references profiles(id) on delete cascade not null,
  type       text not null default 'diary'
               check (type in ('diary','photo','drawing')),
  text       text,
  sticker    text default '🌸',
  image_url  text,
  created_at timestamptz default now()
);

create table moods (
  id         uuid default gen_random_uuid() primary key,
  user_id    uuid references profiles(id) on delete cascade not null,
  date       date not null,
  mood       smallint not null check (mood between 1 and 5),
  note       text,
  created_at timestamptz default now(),
  unique(user_id, date)
);

create table special_dates (
  id         uuid default gen_random_uuid() primary key,
  created_by uuid references profiles(id) on delete cascade not null,
  name       text not null,
  emoji      text default '💕',
  date       date not null,
  color      text default '#F472B6',
  created_at timestamptz default now()
);

create table notes (
  id           uuid default gen_random_uuid() primary key,
  author_id    uuid references profiles(id) on delete cascade not null,
  recipient_id uuid references profiles(id) on delete cascade not null,
  message      text not null,
  reveal_date  date not null,
  shown        boolean default false,
  created_at   timestamptz default now()
);

create table spotify_embeds (
  id         uuid default gen_random_uuid() primary key,
  added_by   uuid references profiles(id) on delete cascade not null,
  embed_url  text not null unique,
  type       text not null,
  spotify_id text not null,
  height     integer default 152,
  ord        integer default 0,
  created_at timestamptz default now()
);

create table user_recovery (
  username   text primary key check (username in ('david','luenna')),
  secret_q   text not null,
  a_hash     text not null,
  pin_enc    text not null,
  updated_at timestamptz default now()
);

-- 4. Activar RLS
alter table profiles       enable row level security;
alter table settings       enable row level security;
alter table posts          enable row level security;
alter table moods          enable row level security;
alter table special_dates  enable row level security;
alter table notes          enable row level security;
alter table spotify_embeds enable row level security;
alter table user_recovery  enable row level security;

-- 5. Policies abiertas para rol anon
create policy "anon_all" on profiles       for all to anon using (true) with check (true);
create policy "anon_all" on settings       for all to anon using (true) with check (true);
create policy "anon_all" on posts          for all to anon using (true) with check (true);
create policy "anon_all" on moods          for all to anon using (true) with check (true);
create policy "anon_all" on special_dates  for all to anon using (true) with check (true);
create policy "anon_all" on notes          for all to anon using (true) with check (true);
create policy "anon_all" on spotify_embeds for all to anon using (true) with check (true);
create policy "anon_all" on user_recovery  for all to anon using (true) with check (true);

-- 6. Storage
insert into storage.buckets (id, name, public)
  values ('media', 'media', true)
  on conflict (id) do nothing;

create policy "anon_media_read"   on storage.objects for select to anon using (bucket_id = 'media');
create policy "anon_media_insert" on storage.objects for insert to anon with check (bucket_id = 'media');
create policy "anon_media_delete" on storage.objects for delete to anon using (bucket_id = 'media');

-- 7. Pre-insertar perfiles de David y Luenna
insert into profiles (id, username) values
  ('d854c0f8-7794-4c05-9852-388ec51b5176', 'david'),
  ('377bd932-af22-4bbe-bce4-cd147ee5a1da', 'luenna');
