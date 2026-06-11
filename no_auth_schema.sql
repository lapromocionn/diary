-- ================================================================
-- Sweet Diary — No-Auth Migration
-- Removes Supabase Auth dependency. PIN stored in settings table.
-- Run in: Supabase Dashboard → SQL Editor → Run
-- ================================================================

-- 1. Drop FK from profiles → auth.users
ALTER TABLE profiles DROP CONSTRAINT IF EXISTS profiles_id_fkey;

-- 2. Pre-insert fixed profiles (idempotent)
INSERT INTO profiles (id, username)
VALUES
  ('00000000-0000-0000-0000-000000000001', 'david'),
  ('00000000-0000-0000-0000-000000000002', 'luenna')
ON CONFLICT (id) DO NOTHING;

-- 3. Drop all existing RLS policies
DROP POLICY IF EXISTS "profiles_read"   ON profiles;
DROP POLICY IF EXISTS "profiles_insert" ON profiles;
DROP POLICY IF EXISTS "settings_read"   ON settings;
DROP POLICY IF EXISTS "settings_write"  ON settings;
DROP POLICY IF EXISTS "settings_update" ON settings;
DROP POLICY IF EXISTS "posts_read"      ON posts;
DROP POLICY IF EXISTS "posts_insert"    ON posts;
DROP POLICY IF EXISTS "posts_delete"    ON posts;
DROP POLICY IF EXISTS "moods_read"      ON moods;
DROP POLICY IF EXISTS "moods_write"     ON moods;
DROP POLICY IF EXISTS "moods_update"    ON moods;
DROP POLICY IF EXISTS "moods_delete"    ON moods;
DROP POLICY IF EXISTS "dates_read"      ON special_dates;
DROP POLICY IF EXISTS "dates_insert"    ON special_dates;
DROP POLICY IF EXISTS "dates_delete"    ON special_dates;
DROP POLICY IF EXISTS "notes_read"      ON notes;
DROP POLICY IF EXISTS "notes_insert"    ON notes;
DROP POLICY IF EXISTS "notes_update"    ON notes;
DROP POLICY IF EXISTS "spotify_read"    ON spotify_embeds;
DROP POLICY IF EXISTS "spotify_insert"  ON spotify_embeds;
DROP POLICY IF EXISTS "spotify_delete"  ON spotify_embeds;
DROP POLICY IF EXISTS "rec_select"      ON user_recovery;
DROP POLICY IF EXISTS "rec_insert"      ON user_recovery;
DROP POLICY IF EXISTS "rec_update"      ON user_recovery;

-- 4. New anon-open policies (app is private by URL, no public listing)
CREATE POLICY "anon_all" ON profiles       FOR ALL TO anon USING (true) WITH CHECK (true);
CREATE POLICY "anon_all" ON settings       FOR ALL TO anon USING (true) WITH CHECK (true);
CREATE POLICY "anon_all" ON posts          FOR ALL TO anon USING (true) WITH CHECK (true);
CREATE POLICY "anon_all" ON moods          FOR ALL TO anon USING (true) WITH CHECK (true);
CREATE POLICY "anon_all" ON special_dates  FOR ALL TO anon USING (true) WITH CHECK (true);
CREATE POLICY "anon_all" ON notes          FOR ALL TO anon USING (true) WITH CHECK (true);
CREATE POLICY "anon_all" ON spotify_embeds FOR ALL TO anon USING (true) WITH CHECK (true);
CREATE POLICY "anon_all" ON user_recovery  FOR ALL TO anon USING (true) WITH CHECK (true);

-- 5. Storage: allow anon uploads/reads
DROP POLICY IF EXISTS "media_read"   ON storage.objects;
DROP POLICY IF EXISTS "media_insert" ON storage.objects;
DROP POLICY IF EXISTS "media_delete" ON storage.objects;
CREATE POLICY "anon_media_read"   ON storage.objects FOR SELECT TO anon USING (bucket_id = 'media');
CREATE POLICY "anon_media_insert" ON storage.objects FOR INSERT TO anon WITH CHECK (bucket_id = 'media');
CREATE POLICY "anon_media_delete" ON storage.objects FOR DELETE TO anon USING (bucket_id = 'media');
