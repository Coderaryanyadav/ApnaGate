# 🗄️ ApnaGate Database Architecture & Setup

This directory contains the production database initialization schemas, security rules, and seed configurations for **ApnaGate**.

---

## 📁 File Structure

| File | Purpose |
|------|---------|
| [`MASTER_SETUP.sql`](MASTER_SETUP.sql) | Complete PostgreSQL schema, tables, functions, Row Level Security (RLS) policies, and seed users for Supabase. |

---

## 🚀 Setup Instructions (Supabase)

1. Open your [Supabase Dashboard](https://supabase.com/dashboard).
2. Navigate to your project -> **SQL Editor**.
3. Create a new query and paste the contents of [`MASTER_SETUP.sql`](MASTER_SETUP.sql).
4. Run the entire script. It will:
   - Configure PostgreSQL extensions (`uuid-ossp`, `pgcrypto`).
   - Create tables: `profiles`, `visitors`, `guest_passes`, `notices`, `complaints`, `complaint_chats`, `sos_alerts`, `daily_help`, `staff_attendance_logs`, `service_providers`, `household_registry`, `patrol_logs`.
   - Establish Row Level Security (RLS) policies with strict `WITH CHECK` conditions.
   - Set up security definer functions (`is_admin()`, `is_guard_or_admin()`, `is_guard()`).
   - Enable Realtime publication replication for live updates across all client apps.

---

## 🛡️ Row Level Security (RLS) Summary

| Table | Residents | Security Guards | Admins |
|-------|-----------|-----------------|--------|
| `profiles` | Read own profile; update self. | Read resident names/flats. | Full access (CRUD). |
| `visitors` | Manage own flat's visitors; approve/reject. | Insert and manage entries for all flats. | Full access. |
| `guest_passes` | Create & view own passes. | Verify passes during scan. | Full access. |
| `daily_help` | Manage assigned staff. | Log entry/exit. | Full access. |
| `sos_alerts` | Trigger SOS from flat. | Instant read and status update. | Instant read & manage. |
| `notices` | Read-only. | Read-only. | Publish & manage. |
| `complaints` | File & view own issues. | N/A. | Review & resolve. |
| `patrol_logs` | N/A. | Insert & view own logs. | View all checkpoints. |
