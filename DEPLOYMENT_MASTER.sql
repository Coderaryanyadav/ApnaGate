-- ============================================================================
-- 🌙 CRESCENT GATE - MASTER DEPLOYMENT SCRIPT
-- ============================================================================
-- This script sets up the entire database schema, RLS policies, triggers, 
-- and initial seed data for the Crescent Gate application.
-- Run this in the Supabase SQL Editor.
-- ============================================================================

-- 1. CLEANUP (OPTIONAL: Uncomment to reset schema)
-- DROP TABLE IF EXISTS public.notifications CASCADE;
-- DROP TABLE IF EXISTS public.complaint_chats CASCADE;
-- DROP TABLE IF EXISTS public.complaints CASCADE;
-- DROP TABLE IF EXISTS public.visitors CASCADE;
-- DROP TABLE IF EXISTS public.guest_passes CASCADE;
-- DROP TABLE IF EXISTS public.notices CASCADE;
-- DROP TABLE IF EXISTS public.sos_alerts CASCADE;
-- DROP TABLE IF EXISTS public.daily_help CASCADE;
-- DROP TABLE IF EXISTS public.staff_attendance_logs CASCADE;
-- DROP TABLE IF EXISTS public.household_registry CASCADE;
-- DROP TABLE IF EXISTS public.service_providers CASCADE;
-- DROP TABLE IF EXISTS public.profiles CASCADE;

-- ============================================================================
-- 2. CREATE TABLES
-- ============================================================================

-- PROFILES (Users)
CREATE TABLE IF NOT EXISTS public.profiles (
  id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  email TEXT NOT NULL,
  name TEXT,
  phone TEXT,
  role TEXT DEFAULT 'resident', -- 'resident', 'guard', 'admin'
  user_type TEXT DEFAULT 'owner', -- 'owner', 'tenant', 'family', 'staff'
  wing TEXT,
  flat_number TEXT,
  photo_url TEXT,
  onesignal_player_id TEXT, -- For Push Notifications
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  owner_id UUID -- Only for household members, points to primary owner
);

-- VISITORS
CREATE TABLE IF NOT EXISTS public.visitors (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  resident_id UUID REFERENCES public.profiles(id),
  visitor_name TEXT NOT NULL,
  visitor_phone TEXT,
  photo_url TEXT,
  purpose TEXT,
  wing TEXT, -- Added for filtering
  flat_number TEXT, -- Added for filtering
  guard_id UUID REFERENCES public.profiles(id),
  status TEXT DEFAULT 'pending', -- 'pending', 'approved', 'rejected', 'inside', 'exited'
  entry_time TIMESTAMPTZ,
  exit_time TIMESTAMPTZ,
  approved_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- NOTIFICATIONS (Realtime)
CREATE TABLE IF NOT EXISTS public.notifications (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE,
  title TEXT NOT NULL,
  message TEXT NOT NULL,
  data JSONB,
  read BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- DAILY HELP (Staff)
CREATE TABLE IF NOT EXISTS public.daily_help (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  owner_id UUID REFERENCES public.profiles(id),
  name TEXT NOT NULL,
  role TEXT, -- 'maid', 'cook', 'driver', etc.
  phone TEXT,
  photo_url TEXT,
  is_present BOOLEAN DEFAULT FALSE,
  last_entry_time TIMESTAMPTZ,
  last_exit_time TIMESTAMPTZ,
  wing TEXT, -- Synced with owner
  flat_number TEXT -- Synced with owner
);

-- HOUSEHOLD REGISTRY (Family Members)
CREATE TABLE IF NOT EXISTS public.household_registry (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  owner_id UUID REFERENCES public.profiles(id),
  name TEXT NOT NULL,
  relation TEXT, -- 'spouse', 'child', 'parent', etc.
  phone TEXT,
  photo_url TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  wing TEXT, -- Implicitly synced via query
  flat_number TEXT -- Implicitly synced via query
);

-- STAFF ATTENDANCE LOGS
CREATE TABLE IF NOT EXISTS public.staff_attendance_logs (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  staff_id UUID REFERENCES public.daily_help(id) ON DELETE CASCADE,
  owner_id UUID REFERENCES public.profiles(id),
  action TEXT, -- 'entry', 'exit'
  timestamp TIMESTAMPTZ DEFAULT NOW()
);

-- COMPLAINTS
CREATE TABLE IF NOT EXISTS public.complaints (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES public.profiles(id),
  title TEXT,
  description TEXT,
  category TEXT,
  status TEXT DEFAULT 'open', -- 'open', 'in_progress', 'resolved'
  ticket_id TEXT,
  priority TEXT DEFAULT 'medium',
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  wing TEXT,
  flat_number TEXT
);

-- COMPLAINT CHATS
CREATE TABLE IF NOT EXISTS public.complaint_chats (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  complaint_id UUID REFERENCES public.complaints(id) ON DELETE CASCADE,
  sender_id UUID REFERENCES public.profiles(id),
  message TEXT,
  image_url TEXT,
  is_admin BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- GUEST PASSES
CREATE TABLE IF NOT EXISTS public.guest_passes (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  resident_id UUID REFERENCES public.profiles(id),
  visitor_name TEXT,
  code TEXT,
  valid_until TIMESTAMPTZ,
  is_used BOOLEAN DEFAULT FALSE,
  used_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- NOTICES
CREATE TABLE IF NOT EXISTS public.notices (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  title TEXT NOT NULL,
  description TEXT,
  type TEXT DEFAULT 'info', -- 'info', 'alert', 'event'
  expires_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- SOS ALERTS
CREATE TABLE IF NOT EXISTS public.sos_alerts (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES public.profiles(id),
  status TEXT DEFAULT 'active', -- 'active', 'resolved'
  resolved_by UUID REFERENCES public.profiles(id),
  created_at TIMESTAMPTZ DEFAULT NOW(),
  wing TEXT,
  flat_number TEXT
);

-- SERVICE PROVIDERS
CREATE TABLE IF NOT EXISTS public.service_providers (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL,
  category TEXT, -- 'plumber', 'electrician'
  phone TEXT,
  rating NUMERIC DEFAULT 5.0
);

-- ============================================================================
-- 3. ENABLE ROW LEVEL SECURITY (RLS)
-- ============================================================================

ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE visitors ENABLE ROW LEVEL SECURITY;
ALTER TABLE notifications ENABLE ROW LEVEL SECURITY;
ALTER TABLE daily_help ENABLE ROW LEVEL SECURITY;
ALTER TABLE household_registry ENABLE ROW LEVEL SECURITY;
ALTER TABLE staff_attendance_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE complaints ENABLE ROW LEVEL SECURITY;
ALTER TABLE complaint_chats ENABLE ROW LEVEL SECURITY;
ALTER TABLE guest_passes ENABLE ROW LEVEL SECURITY;
ALTER TABLE notices ENABLE ROW LEVEL SECURITY;
ALTER TABLE sos_alerts ENABLE ROW LEVEL SECURITY;

-- ============================================================================
-- 4. RLS POLICIES
-- ============================================================================

-- PROFILES
-- Users can view their own profile OR profiles in the same flat (Syncing)
-- Or admins/guards can view relevant profiles
CREATE POLICY "Unified Profile Access" ON profiles FOR SELECT USING (
  auth.uid() = id OR 
  auth.uid() = owner_id OR
  role IN ('admin', 'guard') OR
  (wing, flat_number) IN (SELECT wing, flat_number FROM profiles WHERE id = auth.uid()) OR
  (user_type = 'tenant' AND EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND user_type = 'owner'))
);

CREATE POLICY "Users update own" ON profiles FOR UPDATE USING (auth.uid() = id);
CREATE POLICY "Owners insert members" ON profiles FOR INSERT WITH CHECK (true); -- Simplified for onboarding

-- VISITORS
-- Synced across flat members
CREATE POLICY "Flat Visitor Sync" ON visitors FOR SELECT USING (
  auth.uid() = resident_id OR
  (wing, flat_number) IN (SELECT wing, flat_number FROM profiles WHERE id = auth.uid()) OR
  EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role IN ('guard', 'admin'))
);
CREATE POLICY "Guards create visitors" ON visitors FOR INSERT WITH CHECK (true);
CREATE POLICY "Residents update visitors" ON visitors FOR UPDATE USING (
  auth.uid() = resident_id OR
  (wing, flat_number) IN (SELECT wing, flat_number FROM profiles WHERE id = auth.uid()) OR
  EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role IN ('guard', 'admin'))
);

-- NOTIFICATIONS
CREATE POLICY "Users view own notifications" ON notifications FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "System insert notifications" ON notifications FOR INSERT WITH CHECK (true);
CREATE POLICY "Users update own notifications" ON notifications FOR UPDATE USING (auth.uid() = user_id);

-- DAILY HELP
-- Synced across flat members
CREATE POLICY "Flat View Help" ON daily_help FOR SELECT USING (
  (wing, flat_number) IN (SELECT wing, flat_number FROM profiles WHERE id = auth.uid()) OR
  EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role IN ('guard', 'admin'))
);
CREATE POLICY "Owners Manage Help" ON daily_help FOR ALL USING (
  owner_id = auth.uid() OR
  ((wing, flat_number) IN (SELECT wing, flat_number FROM profiles WHERE id = auth.uid() AND user_type = 'owner')) OR
  EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'guard') -- Guards can mark attendance
);

-- STAFF LOGS
CREATE POLICY "View Staff Logs" ON staff_attendance_logs FOR SELECT USING (
  owner_id = auth.uid() OR
  (staff_id IN (SELECT id FROM daily_help WHERE (wing, flat_number) IN (SELECT wing, flat_number FROM profiles WHERE id = auth.uid())))
);
CREATE POLICY "Guard Insert Logs" ON staff_attendance_logs FOR INSERT WITH CHECK (
  EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'guard')
);

-- COMPLAINTS
CREATE POLICY "View Complaints" ON complaints FOR SELECT USING (
  user_id = auth.uid() OR
  EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'admin')
);
CREATE POLICY "Insert Complaints" ON complaints FOR INSERT WITH CHECK (auth.uid() = user_id);

-- NOTICES (Public Read)
CREATE POLICY "Public Read Notices" ON notices FOR SELECT USING (true);
CREATE POLICY "Admin Manage Notices" ON notices FOR ALL USING (
  EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'admin')
);

-- SOS ALERTS (Public Insert, Admin/Guard Read)
CREATE POLICY "Insert SOS" ON sos_alerts FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "View SOS" ON sos_alerts FOR SELECT USING (
  user_id = auth.uid() OR
  EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role IN ('admin', 'guard'))
);

-- ============================================================================
-- 5. FUNCTION & TRIGGERS
-- ============================================================================

-- Function to handle new user signup
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO public.profiles (id, email, name, role, user_type)
  VALUES (new.id, new.email, new.raw_user_meta_data->>'name', 'resident', 'owner')
  ON CONFLICT (id) DO NOTHING;
  RETURN new;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Trigger for auth.users
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE PROCEDURE public.handle_new_user();

-- ============================================================================
-- 6. ENABLE REALTIME
-- ============================================================================

BEGIN;
  DROP PUBLICATION IF EXISTS supabase_realtime;
  CREATE PUBLICATION supabase_realtime;
COMMIT;
ALTER PUBLICATION supabase_realtime ADD TABLE notifications;
ALTER PUBLICATION supabase_realtime ADD TABLE sos_alerts;
ALTER PUBLICATION supabase_realtime ADD TABLE visitors;

-- ============================================================================
-- 7. INDEXES (Performance)
-- ============================================================================

CREATE INDEX IF NOT EXISTS idx_visitors_flat ON visitors(wing, flat_number);
CREATE INDEX IF NOT EXISTS idx_visitors_resident ON visitors(resident_id);
CREATE INDEX IF NOT EXISTS idx_notifications_user ON notifications(user_id);
CREATE INDEX IF NOT EXISTS idx_profiles_flat ON profiles(wing, flat_number);

-- ============================================================================
-- End of Master Script
-- ============================================================================

-- =================================================================
-- CRESCENT GATE - MASTER DATABASE SETUP SCRIPT
-- =================================================================
--
-- This script performs a FULL RESET of the database.
-- 1. It TRUNCATES (Wipes) all application data tables.
-- 2. It DELETES the specified core users from Auth.
-- 3. It RECREATES the core users with password '123456'.
-- 4. It RECREATES the Profile entries linked to these users.
--
-- ⚠️ WARNING: THIS WILL DELETE ALL COMPLAINTS, VISITORS, NOTICES, ETC.
-- =================================================================

-- 1. NUCLEAR WIPE (Truncates all app data tables)
TRUNCATE TABLE 
  public.complaints,
  public.visitors,
  public.guest_passes, 
  public.notices, 
  public.sos_alerts, 
  public.household_registry,
  public.service_providers,
  public.profiles
CASCADE;

-- 2. DELETE OLD USERS (To ensure no ID conflicts)
DELETE FROM auth.users 
WHERE email IN (
  'aryanjyadav@gmail.com', 
  'crescentlandmark@gmail.com', 
  'guardawing@gmail.com', 
  'guardbwing@gmail.com'
);

-- 3. CREATE FRESH USERS (Password: 123456)

-- Resident: Aryan Yadav (A-1101)
INSERT INTO auth.users (id, instance_id, email, encrypted_password, email_confirmed_at, raw_app_meta_data, raw_user_meta_data, created_at, updated_at, role, is_super_admin)
VALUES (
  '58200724-c0f5-41a5-9f13-c8e40989151a', 
  '00000000-0000-0000-0000-000000000000', 
  'aryanjyadav@gmail.com', 
  crypt('123456', gen_salt('bf')), 
  now(), 
  '{"provider":"email","providers":["email"]}', 
  '{"role":"resident"}', 
  now(), 
  now(), 
  'authenticated', 
  false
);

-- Admin: Crescent Landmark
INSERT INTO auth.users (id, instance_id, email, encrypted_password, email_confirmed_at, raw_app_meta_data, raw_user_meta_data, created_at, updated_at, role, is_super_admin)
VALUES (
  '13a1c533-2d5c-4ad2-9aeb-926c82201b2e', 
  '00000000-0000-0000-0000-000000000000', 
  'crescentlandmark@gmail.com', 
  crypt('123456', gen_salt('bf')), 
  now(), 
  '{"provider":"email","providers":["email"]}', 
  '{"role":"admin"}', 
  now(), 
  now(), 
  'authenticated', 
  false
);

-- Guard: Wing A
INSERT INTO auth.users (id, instance_id, email, encrypted_password, email_confirmed_at, raw_app_meta_data, raw_user_meta_data, created_at, updated_at, role, is_super_admin)
VALUES (
  '1215fe7d-f1b4-41ee-9841-70dc8eda75e7', 
  '00000000-0000-0000-0000-000000000000', 
  'guardawing@gmail.com', 
  crypt('123456', gen_salt('bf')), 
  now(), 
  '{"provider":"email","providers":["email"]}', 
  '{"role":"guard"}', 
  now(), 
  now(), 
  'authenticated', 
  false
);

-- Guard: Wing B
INSERT INTO auth.users (id, instance_id, email, encrypted_password, email_confirmed_at, raw_app_meta_data, raw_user_meta_data, created_at, updated_at, role, is_super_admin)
VALUES (
  'ebfa798c-aefe-4f34-9a1f-6b2b1b446b38', 
  '00000000-0000-0000-0000-000000000000', 
  'guardbwing@gmail.com', 
  crypt('123456', gen_salt('bf')), 
  now(), 
  '{"provider":"email","providers":["email"]}', 
  '{"role":"guard"}', 
  now(), 
  now(), 
  'authenticated', 
  false
);


-- 4. CREATE FRESH PROFILES (Linked to Users)

-- Resident Profile (Owner)
INSERT INTO public.profiles (id, email, role, name, wing, flat_number, user_type, phone)
VALUES (
  '58200724-c0f5-41a5-9f13-c8e40989151a', 
  'aryanjyadav@gmail.com', 
  'resident', 
  'Aryan Yadav', 
  'A', 
  '1101', 
  'owner', 
  '9876543210'
);

-- Admin Profile
INSERT INTO public.profiles (id, email, role, name, user_type, phone)
VALUES (
  '13a1c533-2d5c-4ad2-9aeb-926c82201b2e', 
  'crescentlandmark@gmail.com', 
  'admin', 
  'Admin', 
  'admin', 
  '9999999999'
);

-- Guard A Profile
INSERT INTO public.profiles (id, email, role, name, wing, user_type, phone)
VALUES (
  '1215fe7d-f1b4-41ee-9841-70dc8eda75e7', 
  'guardawing@gmail.com', 
  'guard', 
  'Guard A', 
  'A', 
  'staff', 
  '8888888001'
);

-- Guard B Profile
INSERT INTO public.profiles (id, email, role, name, wing, user_type, phone)
VALUES (
  'ebfa798c-aefe-4f34-9a1f-6b2b1b446b38', 
  'guardbwing@gmail.com', 
  'guard', 
  'Guard B', 
  'B', 
  'staff', 
  '8888888002'
);

-- End of Script
