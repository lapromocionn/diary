-- ================================================================
-- Rutina Luenna — Add to existing Supabase schema
-- Paste into: Supabase Dashboard → SQL Editor → Run
-- ================================================================

create table if not exists workout_sessions (
  id           uuid default gen_random_uuid() primary key,
  user_id      uuid references profiles(id) on delete cascade not null,
  date         date not null,
  block        smallint not null check (block between 1 and 4),
  week_num     smallint not null check (week_num between 1 and 8),
  session_num  smallint not null check (session_num between 1 and 24),
  exercises_done jsonb default '[]',
  notes        text,
  skipped      boolean default false,
  completed_at timestamptz,
  created_at   timestamptz default now(),
  unique(user_id, date)
);

alter table workout_sessions enable row level security;

create policy "workout_read"   on workout_sessions for select to authenticated using (true);
create policy "workout_insert" on workout_sessions for insert to authenticated with check (auth.uid()=user_id);
create policy "workout_update" on workout_sessions for update to authenticated using (auth.uid()=user_id);
create policy "workout_delete" on workout_sessions for delete to authenticated using (auth.uid()=user_id);
