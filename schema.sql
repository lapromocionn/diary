-- ================================================================
-- Sweet Diary — Supabase Schema
-- Paste into: Supabase Dashboard → SQL Editor → Run
-- ================================================================

-- Profiles (extends auth.users)
create table if not exists profiles (
  id         uuid references auth.users on delete cascade primary key,
  username   text not null check (username in ('david','luenna')),
  created_at timestamptz default now()
);

-- Shared couple state (start_date, etc.)
create table if not exists settings (
  key        text primary key,
  value      text not null,
  updated_at timestamptz default now()
);

-- Unified feed: text entries, photos, drawings
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

-- Mood tracker (one per user per day)
create table if not exists moods (
  id         uuid default gen_random_uuid() primary key,
  user_id    uuid references profiles(id) on delete cascade not null,
  date       date not null,
  mood       smallint not null check (mood between 1 and 5),
  note       text,
  created_at timestamptz default now(),
  unique(user_id, date)
);

-- Special dates / anniversaries
create table if not exists special_dates (
  id         uuid default gen_random_uuid() primary key,
  created_by uuid references profiles(id) on delete cascade not null,
  name       text not null,
  emoji      text default '💕',
  date       date not null,
  color      text default '#F472B6',
  created_at timestamptz default now()
);

-- Secret love notes with a future reveal date
create table if not exists notes (
  id           uuid default gen_random_uuid() primary key,
  author_id    uuid references profiles(id) on delete cascade not null,
  recipient_id uuid references profiles(id) on delete cascade not null,
  message      text not null,
  reveal_date  date not null,
  shown        boolean default false,
  created_at   timestamptz default now()
);

-- Spotify embeds
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

-- ── RLS ──────────────────────────────────────────────────────
alter table profiles       enable row level security;
alter table settings       enable row level security;
alter table posts          enable row level security;
alter table moods          enable row level security;
alter table special_dates  enable row level security;
alter table notes          enable row level security;
alter table spotify_embeds enable row level security;

-- profiles
create policy "profiles_read"   on profiles for select to authenticated using (true);
create policy "profiles_insert" on profiles for insert to authenticated with check (auth.uid()=id);

-- settings (both users share)
create policy "settings_read"   on settings for select to authenticated using (true);
create policy "settings_write"  on settings for insert to authenticated with check (true);
create policy "settings_update" on settings for update to authenticated using (true);

-- posts
create policy "posts_read"   on posts for select to authenticated using (true);
create policy "posts_insert" on posts for insert to authenticated with check (auth.uid()=author_id);
create policy "posts_delete" on posts for delete to authenticated using (auth.uid()=author_id);

-- moods
create policy "moods_read"   on moods for select to authenticated using (true);
create policy "moods_write"  on moods for insert to authenticated with check (auth.uid()=user_id);
create policy "moods_update" on moods for update to authenticated using (auth.uid()=user_id);
create policy "moods_delete" on moods for delete to authenticated using (auth.uid()=user_id);

-- special_dates
create policy "dates_read"   on special_dates for select to authenticated using (true);
create policy "dates_insert" on special_dates for insert to authenticated with check (auth.uid()=created_by);
create policy "dates_delete" on special_dates for delete to authenticated using (auth.uid()=created_by);

-- notes (author + recipient can read; only recipient can mark shown)
create policy "notes_read"   on notes for select to authenticated using (auth.uid()=author_id or auth.uid()=recipient_id);
create policy "notes_insert" on notes for insert to authenticated with check (auth.uid()=author_id);
create policy "notes_update" on notes for update to authenticated using (auth.uid()=recipient_id);

-- spotify
create policy "spotify_read"   on spotify_embeds for select to authenticated using (true);
create policy "spotify_insert" on spotify_embeds for insert to authenticated with check (auth.uid()=added_by);
create policy "spotify_delete" on spotify_embeds for delete to authenticated using (auth.uid()=added_by);

-- ── STORAGE ──────────────────────────────────────────────────
insert into storage.buckets (id, name, public)
  values ('media','media',true)
  on conflict do nothing;

create policy "media_read"   on storage.objects for select to authenticated using (bucket_id='media');
create policy "media_insert" on storage.objects for insert to authenticated with check (bucket_id='media');
create policy "media_delete" on storage.objects for delete to authenticated using (bucket_id='media');
