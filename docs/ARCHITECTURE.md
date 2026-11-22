# 🏛️ ApnaGate System Architecture

```mermaid
flowchart TD
    subgraph Client["Frontend Client (Flutter Multiplatform)"]
        Guard["🛡️ Guard Terminal"]
        Resident["📱 Resident App"]
        Admin["💻 Admin Dashboard"]
    end

    subgraph Backend["Cloud Infrastructure"]
        Supabase["🗄️ Supabase (PostgreSQL + RLS + Realtime)"]
        EdgeFn["⚡ Supabase Edge Functions"]
        OneSignal["🔔 OneSignal Push Delivery"]
    end

    Guard -->|1. Create Visitor / Scan Pass| Supabase
    Resident -->|2. Approve / Deny Visitor| Supabase
    Resident -->|3. Trigger SOS Alert| Supabase
    
    Supabase -->|Realtime Stream| Guard
    Supabase -->|Database Trigger| EdgeFn
    EdgeFn -->|Dispatch Push API| OneSignal
    OneSignal -->|Push Notification| Resident
    OneSignal -->|Siren Alarm Push| Guard
```

---

## 🔄 Core Workflows

### 1. Visitor Arrival Notification Workflow

```mermaid
sequenceDiagram
    autonumber
    actor Guard as 🛡️ Security Guard
    participant App as 📱 ApnaGate Guard App
    participant DB as 🗄️ Supabase DB
    participant Push as 🔔 OneSignal
    actor Resident as 👤 Resident

    Guard->>App: Enters Visitor Details (Name, Wing, Flat, Purpose)
    App->>DB: INSERT into public.visitors (status: 'pending')
    DB-->>Push: Trigger notification with resident subscription ID
    Push->>Resident: 🚨 High-Priority Push ("Visitor Arrived: Approve?")
    Resident->>DB: UPDATE public.visitors (status: 'approved')
    DB-->>App: Realtime update received
    App->>Guard: ✅ Displays "ENTRY APPROVED"
```

---

### 2. Emergency SOS Alert Workflow

```mermaid
sequenceDiagram
    autonumber
    actor Resident as 👤 Resident
    participant App as 📱 ApnaGate Resident App
    participant DB as 🗄️ Supabase DB
    participant OneSignal as 🔔 OneSignal Push
    actor Guard as 🛡️ Security Guard

    Resident->>App: Press SOS Button
    App->>DB: INSERT into public.sos_alerts (status: 'active')
    DB-->>OneSignal: Broadcast to segment tag 'role=guard'
    OneSignal->>Guard: 🚨 LOUD ALARM SIREN with flat coordinates
    Guard->>App: Acknowledges SOS & Dispatches Response
```

---

## 💾 Offline Caching & Resilience

- **Local Storage:** Hive database (`user_cache`, `patrol_logs`) persists user profile and guard patrol checkpoints locally.
- **Background Synchronization:** Guard patrol logs are saved to Hive immediately and synchronized whenever network is active.
- **Dual-channel Delivery:** If OneSignal experiences delays, the app maintains an active Supabase Realtime channel while foregrounded or running through the background monitor service.
