-- =================================================================
-- 🧹 RESET HISTORY & TRANSACTIONAL DATA
-- =================================================================
-- This script deletes all HISTORY (transactional data) but keeps
-- the USERS, PROFILES, and SETTINGS (Master data) intact.
-- Run this in Supabase SQL Editor to clean the app state.
-- =================================================================

-- 1. Truncate Transactional Tables (Cascade to clean related children)
TRUNCATE TABLE 
  public.notifications,
  public.visitors,
  public.complaints,
  public.complaint_chats,
  public.guest_passes,
  public.sos_alerts,
  public.staff_attendance_logs,
  public.notices
CASCADE;

-- 2. Optional: Reset Notification Badge Counts (if stored in profiles)
-- UPDATE public.profiles SET unread_notifications = 0; 
-- (Uncomment above if you have such a column)

-- 3. Verify Empty State
SELECT 'Notifications', count(*) FROM public.notifications
UNION ALL
SELECT 'Visitors', count(*) FROM public.visitors;
