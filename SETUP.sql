-- ================================================================
-- Sweet Diary — SETUP COMPLETO
-- Pega esto en: Supabase → SQL Editor → Run
-- ================================================================

-- ── TABLAS ──────────────────────────────────────────────────────

create table if not exists profiles (
  id         uuid primary key,
  username   text not null check (username in ('david','luenna')),
  created_at timestamptz default now()
);

create table if not exists settings (
  key        text primary key,
  value      text not null,
  updated_at timestamptz default now()
);

create table if not exists posts (
  id         uuid default gen_random_uuid() primary key,
  author_id  uuid references profiles(id) on delete cascade not null,
  type       text not null default 'diary'
               check (type in ('diary','photo','drawing')),
  text       text,
  sticker    text default '🌸',
  image_url  text,
  created_at timestamptz default now()
);

create table if not exists moods (
  id         uuid default gen_random_uuid() primary key,
  user_id    uuid references profiles(id) on delete cascade not null,
  date       date not null,
  mood       smallint not null check (mood between 1 and 5),
  note       text,
  created_at timestamptz default now(),
  unique(user_id, date)
);

create table if not exists special_dates (
  id         uuid default gen_random_uuid() primary key,
  created_by uuid references profiles(id) on delete cascade not null,
  name       text not null,
  emoji      text default '💕',
  date       date not null,
  color      text default '#F472B6',
  created_at timestamptz default now()
);

create table if not exists notes (
  id           uuid default gen_random_uuid() primary key,
  author_id    uuid references profiles(id) on delete cascade not null,
  recipient_id uuid references profiles(id) on delete cascade not null,
  message      text not null,
  reveal_date  date not null,
  shown        boolean default false,
  created_at   timestamptz default now()
);

create table if not exists spotify_embeds (
  id         uuid default gen_random_uuid() primary key,
  added_by   uuid references profiles(id) on delete cascade not null,
  embed_url  text not null unique,
  type       text not null,
  spotify_id text not null,
  height     integer default 152,
  ord        integer default 0,
  created_at timestamptz default now()
);

create table if not exists user_recovery (
  username   text primary key check (username in ('david','luenna')),
  secret_q   text not null,
  a_hash     text not null,
  pin_enc    text not null,
  updated_at timestamptz default now()
);

-- ── RLS: permitir todo al rol anon (service role bypasses anyway) ──

alter table profiles       enable row level security;
alter table settings       enable row level security;
alter table posts          enable row level security;
alter table moods          enable row level security;
alter table special_dates  enable row level security;
alter table notes          enable row level security;
alter table spotify_embeds enable row level security;
alter table user_recovery  enable row level security;

create policy "anon_all" on profiles       for all to anon using (true) with check (true);
create policy "anon_all" on settings       for all to anon using (true) with check (true);
create policy "anon_all" on posts          for all to anon using (true) with check (true);
create policy "anon_all" on moods          for all to anon using (true) with check (true);
create policy "anon_all" on special_dates  for all to anon using (true) with check (true);
create policy "anon_all" on notes         for all to anon using (true) with check (true);
create policy "anon_all" on spotify_embeds for all to anon using (true) with check (true);
create policy "anon_all" on user_recovery  for all to anon using (true) with check (true);

-- ── STORAGE ─────────────────────────────────────────────────────

insert into storage.buckets (id, name, public)
  values ('media','media',true)
  on conflict do nothing;

create policy "anon_media_read"   on storage.objects for select to anon using (bucket_id = 'media');
create policy "anon_media_insert" on storage.objects for insert to anon with check (bucket_id = 'media');
create policy "anon_media_delete" on storage.objects for delete to anon using (bucket_id = 'media');

-- ── PERFILES (pre-creados por admin API) ──────────────────────────

insert into profiles (id, username) values
  ('d854c0f8-7794-4c05-9852-388ec51b5176', 'david'),
  ('377bd932-af22-4bbe-bce4-cd147ee5a1da', 'luenna')
on conflict (id) do nothing;
