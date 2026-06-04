-- ================================================================
-- user_recovery — PIN recovery via secret question (AES-GCM)
-- Paste into: Supabase Dashboard → SQL Editor → Run
-- ================================================================

create table if not exists user_recovery (
  username   text primary key check (username in ('david','luenna')),
  secret_q   text not null,
  a_hash     text not null,   -- SHA-256(normalizedAnswer + username + salt)
  pin_enc    text not null,   -- base64(iv‖AES-GCM(pin, key=a_hash[0:16]))
  updated_at timestamptz default now()
);

alter table user_recovery enable row level security;

-- Anon read required: secret question must be shown BEFORE login
create policy "rec_select" on user_recovery for select using (true);

-- Write: only the profile owner
create policy "rec_insert" on user_recovery for insert to authenticated
  with check (username = (select p.username from profiles p where p.id = auth.uid() limit 1));

create policy "rec_update" on user_recovery for update to authenticated
  using (username = (select p.username from profiles p where p.id = auth.uid() limit 1));
