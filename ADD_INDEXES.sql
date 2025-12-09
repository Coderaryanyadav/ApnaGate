-- ============================================================================
-- 🚀 CRESCENT GATE - PERFORMANCE BOOST (INDEXES)
-- ============================================================================
-- Run this script to add indexes for frequent queries. This addresses Audit Items #184 & #190.

-- 1. VISITOR LOOKUPS
-- Optimize: "Get visitors for my flat" & "Guard searching for flat"
CREATE INDEX IF NOT EXISTS idx_visitors_flat ON public.visitors (wing, flat_number);
-- Optimize: FK Joins
CREATE INDEX IF NOT EXISTS idx_visitors_resident_id ON public.visitors (resident_id);
-- Optimize: Realtime stream filtering
CREATE INDEX IF NOT EXISTS idx_visitors_status ON public.visitors (status);

-- 2. PROFILE LOOKUPS
-- Optimize: "Notify Flat" (Finding all residents in a flat)
CREATE INDEX IF NOT EXISTS idx_profiles_flat ON public.profiles (wing, flat_number);
-- Optimize: "Sync OneSignal" (finding by player id)
CREATE INDEX IF NOT EXISTS idx_profiles_onesignal ON public.profiles (onesignal_player_id);

-- 3. NOTIFICATIONS
-- Optimize: "Get my unread notifications"
CREATE INDEX IF NOT EXISTS idx_notifications_user_read ON public.notifications (user_id, read);

-- 4. STAFF ATTENDANCE
-- Optimize: "Get staff for flat"
CREATE INDEX IF NOT EXISTS idx_daily_help_flat ON public.daily_help (wing, flat_number);

-- 5. COMPLAINTS
-- Optimize: "My complaints"
CREATE INDEX IF NOT EXISTS idx_complaints_resident_id ON public.complaints (resident_id);

-- 6. GUEST PASSES
-- Optimize: "Verify Pass" (Guard Scan)
CREATE INDEX IF NOT EXISTS idx_guest_passes_token ON public.guest_passes (id); -- (UUID PK is already indexed, but good to ensure if we query by other tokens)
-- Or if we have a separate 'token' column? No, we use ID. UUID PK is clustered/B-tree indexed by default.

-- 7. CLEANUP
-- VACUUM ANALYZE; -- Removed as it cannot run inside transaction blocks in Supabase Editor
