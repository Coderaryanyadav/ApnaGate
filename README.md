<div align="center">

# 🚪 ApnaGate

### _Smart Society Gatekeeper & Resident Security Management System_

[![Flutter](https://img.shields.io/badge/Flutter-3.47+-02569B?style=for-the-badge&logo=flutter&logoColor=white)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.13+-0175C2?style=for-the-badge&logo=dart&logoColor=white)](https://dart.dev)
[![Supabase](https://img.shields.io/badge/Supabase-PostgreSQL_RLS-3ECF8E?style=for-the-badge&logo=supabase&logoColor=white)](https://supabase.com)
[![OneSignal](https://img.shields.io/badge/OneSignal-Push_Notifications-E54B4D?style=for-the-badge&logo=onesignal&logoColor=white)](https://onesignal.com)
[![Riverpod](https://img.shields.io/badge/Riverpod-2.6_State_Mgmt-2E7D32?style=for-the-badge&logo=flutter&logoColor=white)](https://riverpod.dev)
[![Hive](https://img.shields.io/badge/Hive-Offline_Cache-F39C12?style=for-the-badge&logo=dart&logoColor=white)](https://pub.dev/packages/hive_flutter)
[![Test Suite](https://img.shields.io/badge/Flutter_Tests-14%2F14_Passing-brightgreen?style=for-the-badge&logo=checkmarx&logoColor=white)]()
[![License: MIT](https://img.shields.io/badge/License-MIT-F39C12?style=for-the-badge&logo=open-source-initiative&logoColor=white)](LICENSE)

<br/>

**[🏛️ System Architecture](./docs/ARCHITECTURE.md)** &nbsp;•&nbsp;
**[🗄️ Database Setup](./database/README.md)** &nbsp;•&nbsp;
**[🔔 Operations Manual](./docs/QUICK_REFERENCE.md)** &nbsp;•&nbsp;
**[💰 Cost Analysis](./docs/COST_ANALYSIS.md)** &nbsp;•&nbsp;
**[🤝 Contributing](./docs/CONTRIBUTING.md)** &nbsp;•&nbsp;
**[🛡️ Security Policy](./docs/SECURITY.md)**

</div>

---

## 📖 Overview

**ApnaGate** is a smart building, apartment complex, and gated society security
management platform engineered for real-time visitor gatekeeping, digital
invitation passes, domestic help attendance tracking, and instant emergency
alerts.

Residential complexes frequently rely on physical visitor register books and
security intercom calls that are slow, lack auditability, and delay visitor
entries. **ApnaGate** bridges security guards, residents, and society
administrators into one synchronized real-time ecosystem powered by **Flutter**,
**Supabase PostgreSQL with Row Level Security (RLS)**, and **OneSignal Push
Notifications**.

### ✨ Key Capabilities

- 🔔 **Sub-Second Multi-Layer Push Notifications**: Instant visitor arrival
  alerts delivered directly to residents via OneSignal and Supabase Realtime
  webhooks.
- 🚨 **High-Priority Audible SOS Siren**: One-tap emergency broadcast
  dispatching loud audio alarms and exact apartment coordinates to on-duty
  security guards.
- 🛡️ **Zero-Friction Guard Gatekeeper Mode**: Lightning-fast check-in with flat
  lookups, digital QR pass scanning via `mobile_scanner`, and daily staff
  logging.
- 👥 **Resident Management Portal**: One-tap approval/denial of guests, visitor
  history logs, household member registries, and maintenance complaints.
- 🗄️ **Dual-Channel Offline Caching**: Embedded Hive local database
  (`user_cache`, `patrol_logs`) ensures seamless gate operations during
  intermittent network drops.
- 🔒 **Enterprise-Grade Data Isolation**: Strict PostgreSQL Row Level Security
  (RLS) policies with `WITH CHECK` validations enforce airtight tenant
  boundaries.
- 🧪 **Production Tested**: Comprehensive automated test suites (14/14 passing),
  strict static analysis (`0 issues`), and clean code architecture.

---

## 📑 Table of Contents

- [🏛️ System Architecture Diagram](#️-system-architecture-diagram)
- [🔄 Core Engineering Flow Patterns](#-core-engineering-flow-patterns)
  - [1. Visitor Lifecycle & Approval State Machine](#1-visitor-lifecycle--approval-state-machine)
  - [2. Multi-Channel Emergency SOS Incident Response](#2-multi-channel-emergency-sos-incident-response)
  - [3. Digital Guest Pass & Live QR Scanner Lifecycle](#3-digital-guest-pass--live-qr-scanner-lifecycle)
  - [4. Dual-Channel Offline Resilience & Sync Flow](#4-dual-channel-offline-resilience--sync-flow)
- [🗄️ Entity-Relationship Diagram (Database Schema)](#️-entity-relationship-diagram-database-schema)
- [👥 Specialized Experience & Roles Matrix](#-specialized-experience--roles-matrix)
- [📁 Clean Repository Directory Tree](#-clean-repository-directory-tree)
- [🛡️ Database & Row Level Security (RLS) Matrix](#️-database--row-level-security-rls-matrix)
- [💻 Technology Stack & Ecosystem](#-technology-stack--ecosystem)
- [🚀 Getting Started & Installation Guide](#-getting-started--installation-guide)
- [🧪 Automated Testing & Static Analysis](#-automated-testing--static-analysis)
- [📱 Production Build & Release](#-production-build--release)
- [🤝 Contributing, Security & License](#-contributing-security--license)

---

## 🏛️ System Architecture Diagram

```mermaid
flowchart TD
    subgraph Clients["Frontend Client Tier (Flutter Multiplatform)"]
        Guard["🛡️ Security Guard Terminal<br/>(Check-in, QR Scanner, Staff Entry)"]
        Resident["📱 Resident Mobile Portal<br/>(Approvals, Guest Passes, SOS, Notices)"]
        Admin["💻 Society Operations Hub<br/>(User Management, Analytics, Triage)"]
    end

    subgraph StateAndStorage["Local Client State & Offline Engine"]
        Riverpod["Flutter Riverpod 2.6<br/>(Reactive State Management & DI)"]
        HiveDB["Hive Key-Value Cache<br/>(user_cache & patrol_logs)"]
        AlarmAudio["AudioPlayers Engine<br/>(High-Decibel Siren Playback)"]
    end

    subgraph CloudBackend["Supabase Cloud Infrastructure"]
        SupaAuth["Supabase GoTrue Auth<br/>(JWT Sessions & Role Verification)"]
        Postgres["PostgreSQL 17 Database<br/>(Row Level Security & Functions)"]
        RealtimePub["Supabase Realtime Engine<br/>(Full Replica Identity Streaming)"]
        EdgeFunc["Deno TypeScript Edge Functions<br/>(send-notification service)"]
    end

    subgraph PushGateway["Notification & Delivery Tier"]
        OneSignal["OneSignal Push Delivery Engine<br/>(Subscription IDs & Role Filters)"]
        APNs["Apple Push Notification service (APNs)"]
        FCM["Firebase Cloud Messaging (FCM Gateway)"]
    end

    Guard --> Riverpod
    Resident --> Riverpod
    Admin --> Riverpod

    Riverpod <--> HiveDB
    Riverpod --> SupaAuth
    Riverpod <--> Postgres
    Riverpod -.-> AlarmAudio

    Postgres --> RealtimePub
    RealtimePub -->|Sub-second WebSockets| Guard
    RealtimePub -->|Sub-second WebSockets| Resident
    RealtimePub -->|Sub-second WebSockets| Admin

    Postgres -->|Database Trigger Webhook| EdgeFunc
    EdgeFunc -->|REST API Request| OneSignal
    OneSignal --> APNs
    OneSignal --> FCM
    APNs --> Resident
    FCM --> Guard
```

---

## 🔄 Core Engineering Flow Patterns

### 1. Visitor Lifecycle & Approval State Machine

The state transition pattern managing visitor ingress, authorization, and
egress:

```mermaid
stateDiagram-v2
    [*] --> VisitorAtGate: Visitor Arrives at Checkpoint
    VisitorAtGate --> FormSubmission: Guard inputs details (Name, Wing, Flat, Purpose)
    FormSubmission --> PendingApproval: Stored in DB with status 'pending'
    
    state PendingApproval {
        [*] --> NotificationDispatched: OneSignal push dispatched to Resident
        NotificationDispatched --> WaitingForResident: Realtime socket listening
    }

    PendingApproval --> Approved: Resident clicks 'Approve'
    PendingApproval --> Rejected: Resident clicks 'Deny'
    PendingApproval --> AutoExpired: Timeout after 5 minutes

    state Approved {
        [*] --> EntryGranted: Guard notified via Realtime socket
        EntryGranted --> InSociety: Entry timestamp logged
    }

    state Rejected {
        [*] --> EntryDenied: Guard terminal flashes RED alert
    }

    InSociety --> Completed: Guard logs departure (Exit timestamp logged)
    Completed --> [*]
    Rejected --> [*]
    AutoExpired --> [*]
```

---

### 2. Multi-Channel Emergency SOS Incident Response

High-reliability emergency alert dispatch designed to wake devices and cut
through silence:

```mermaid
flowchart TD
    A["👤 Resident Taps Emergency SOS Button"] --> B["INSERT into public.sos_alerts<br/>(status: 'active', flat_coords)"]
    
    B --> C1["Supabase Realtime WebSocket Event"]
    B --> C2["Edge Function Trigger: send-notification"]
    
    C1 --> D1["All On-Duty Guards & Admin Screens<br/>Flash Persistent Red Banner"]
    
    C2 --> D2["OneSignal Priority 10 Push Broadcast<br/>Target filter: role = 'guard'"]
    
    D2 --> E["Guard Mobile Hardware Trigger"]
    E --> F1["Wakes Screen / Heads-Up Notification"]
    E --> F2["High-Decibel Siren Audio (alarm.mp3)<br/>Loops continuously until acknowledged"]
    
    D1 & F1 --> G["Guard Acknowledges Alert & Dispatches Field Response"]
    G --> H["UPDATE public.sos_alerts SET status = 'resolved'"]
    H --> I["Realtime Event Broadcasts All Clear to Resident & Admins"]
```

---

### 3. Digital Guest Pass & Live QR Scanner Lifecycle

Contactless digital invitation pass creation, verification, and hardware
scanning:

```mermaid
sequenceDiagram
    autonumber
    actor Resident as 👤 Resident
    participant ResApp as 📱 Resident App
    participant DB as 🗄️ Supabase PostgreSQL
    actor Guest as 🧑‍🤝‍🧑 Guest
    actor Guard as 🛡️ Security Guard
    participant GuardApp as 📱 Guard Terminal (Scanner)

    Resident->>ResApp: Enters Guest Name, Phone & Valid Time Window
    ResApp->>DB: INSERT into public.guest_passes (pass_code, status: 'active')
    ResApp->>Resident: Displays Dynamic QR Code & 6-Digit Pass
    Resident->>Guest: Shares pass via WhatsApp / SMS invitation card
    Guest->>Guard: Presents QR Code on mobile screen at main gate
    Guard->>GuardApp: Points camera using mobile_scanner
    GuardApp->>DB: SELECT * FROM guest_passes WHERE pass_code = :scannedCode
    alt Pass Valid & Active
        DB-->>GuardApp: Returns valid pass record
        GuardApp->>DB: UPDATE guest_passes SET status = 'used'
        GuardApp->>Guard: ✅ Displays Green Check: "PASS VERIFIED - ACCESS GRANTED"
    else Pass Expired or Already Used
        GuardApp->>Guard: ❌ Displays Red Alert: "INVALID OR EXPIRED PASS"
    end
```

---

### 4. Dual-Channel Offline Resilience & Sync Flow

Guaranteeing gate continuity during broadband outages or intermittent cell
coverage:

```mermaid
flowchart LR
    subgraph Device["Mobile Client Device"]
        UI["Guard / Resident Action"]
        Repo["Data Repository Layer"]
        HiveStore[("Hive Local Box<br/>user_cache & patrol_logs")]
    end

    subgraph NetworkEngine["Network Connectivity Watcher"]
        ConnCheck{"Internet<br/>Available?"}
    end

    subgraph Remote["Supabase Cloud"]
        CloudDB[("PostgreSQL Remote DB")]
        RTChannel["Realtime WebSocket"]
    end

    UI --> Repo
    Repo --> ConnCheck

    ConnCheck -- "YES (Online)" --> CloudDB
    CloudDB --> RTChannel
    RTChannel --> Repo

    ConnCheck -- "NO (Offline)" --> HiveStore
    HiveStore -.->|"Instant Offline Read/Write"| UI

    HiveStore -->|"Background Auto-Replay on Reconnection"| CloudDB
```

---

## 🗄️ Entity-Relationship Diagram (Database Schema)

Visual representation of all relational tables, primary keys, and foreign keys
defined in [`database/MASTER_SETUP.sql`](database/MASTER_SETUP.sql):

```mermaid
erDiagram
    PROFILES ||--o{ VISITORS : "receives"
    PROFILES ||--o{ GUEST_PASSES : "issues"
    PROFILES ||--o{ DAILY_HELP : "employs"
    PROFILES ||--o{ COMPLAINTS : "files"
    COMPLAINTS ||--o{ COMPLAINT_CHATS : "contains"
    PROFILES ||--o{ SOS_ALERTS : "triggers"
    PROFILES ||--o{ HOUSEHOLD_REGISTRY : "heads"
    PROFILES ||--o{ PATROL_LOGS : "logs"
    PROFILES ||--o{ NOTICES : "publishes"
    DAILY_HELP ||--o{ STAFF_ATTENDANCE_LOGS : "records"

    PROFILES {
        uuid id PK
        string email
        string name
        string role
        string wing
        string flat_number
        string phone
        string user_type
        string onesignal_player_id
        timestamp created_at
    }

    VISITORS {
        uuid id PK
        uuid resident_id FK
        string wing
        string flat_number
        string visitor_name
        string purpose
        string status
        string phone
        string vehicle_number
        timestamp entry_time
        timestamp exit_time
        timestamp approved_at
    }

    GUEST_PASSES {
        uuid id PK
        uuid resident_id FK
        string guest_name
        string guest_phone
        string pass_code
        timestamp valid_from
        timestamp valid_until
        string status
    }

    DAILY_HELP {
        uuid id PK
        uuid owner_id FK
        string name
        string role
        string phone
        boolean is_inside
    }

    COMPLAINTS {
        uuid id PK
        uuid resident_id FK
        string title
        string description
        string status
        timestamp created_at
    }

    SOS_ALERTS {
        uuid id PK
        uuid resident_id FK
        string wing
        string flat_number
        string status
        timestamp created_at
    }

    PATROL_LOGS {
        uuid id PK
        uuid guard_id FK
        string checkpoint
        string notes
        timestamp created_at
    }
```

---

## 👥 Specialized Experience & Roles Matrix

The platform provides dedicated, role-gated interfaces designed for distinct
operations:

| Capability / Feature          |   🛡️ Security Guard    | 👤 Society Resident  |   👑 Society Admin    |
| :---------------------------- | :--------------------: | :------------------: | :-------------------: |
| **Visitor Entry Logging**     |  ✅ Create & Dispatch  |     ❌ View Only     |     ✅ Full Audit     |
| **One-Tap Visitor Approval**  |     ❌ Read Status     |  ✅ Approve / Deny   |     ✅ Full Audit     |
| **QR Guest Pass Scanning**    | ✅ Live Camera Scanner | ❌ (Creates Passes)  | ✅ Verification Logs  |
| **Digital Pass Generation**   |           ❌           | ✅ QR & 6-Digit Code |   ✅ Administrative   |
| **Emergency SOS Trigger**     |  ❌ (Receives Sirens)  | ✅ Instant Broadcast |  ✅ Receives Alerts   |
| **Daily Staff (Maids/Cooks)** |  ✅ Log Entry & Exit   | ✅ Household Roster  |   ✅ Society Roster   |
| **Security Patrol Logging**   |  ✅ Scan Checkpoints   |          ❌          |  ✅ Checkpoint Logs   |
| **Complaints & Maintenance**  |           ❌           |   ✅ File & Track    |  ✅ Triage & Resolve  |
| **Notice Board**              |    ✅ Read Notices     |   ✅ Read Notices    |  ✅ Create & Publish  |
| **User & Tenant Management**  |           ❌           |   ❌ (Own Family)    | ✅ Full CRUD Profiles |
| **Analytics & Gate Metrics**  |           ❌           |          ❌          |  ✅ Volume & Reports  |

---

## 📁 Clean Repository Directory Tree

```text
ApnaGate/
├── 📄 README.md                           # Main engineering documentation & setup guide
├── 📄 LICENSE                             # MIT Open Source License
│
├── 📁 app/                                # Flutter cross-platform mobile/desktop application
│   ├── 📄 pubspec.yaml                    # Flutter dependencies & asset declarations
│   ├── 📄 analysis_options.yaml           # Strict Dart analyzer rules (0 errors, 0 warnings)
│   ├── 📄 l10n.yaml                       # Localization generation manifest
│   ├── 📁 assets/                         # Application bundled static assets
│   │   ├── 📄 logo.png                    # High-resolution brand logo
│   │   └── 📁 sounds/
│   │       └── 📄 alarm.mp3               # High-decibel SOS emergency siren audio
│   ├── 📁 lib/
│   │   ├── 📄 main.dart                   # Application bootstrap, background config & error boundary
│   │   ├── 📄 app.dart                    # MaterialApp, dark/light theme binding & 26 named routes
│   │   ├── 📄 auth_wrapper.dart           # Role-based route guard & auth state consumer
│   │   ├── 📄 supabase_config.dart        # Production Supabase URL, anon key & OneSignal app ID
│   │   ├── 📁 models/                     # Strongly-typed domain models with JSON serialization
│   │   │   ├── 📄 user.dart               # AppUser model with roles, wing, flat & subscription ID
│   │   │   ├── 📄 visitor.dart            # Visitor entry model with timestamps & lifecycle states
│   │   │   ├── 📄 guest_pass.dart         # GuestPass model with QR code & expiration window
│   │   │   ├── 📄 daily_help.dart         # DailyHelp model (Maid, Cook, Driver, Housekeeping)
│   │   │   ├── 📄 notice.dart             # Notice model for society announcements
│   │   │   ├── 📄 complaint.dart          # Complaint & ComplaintChat ticket models
│   │   │   ├── 📄 sos_alert.dart          # SosAlert model with apartment coordinates
│   │   │   └── 📄 service_provider.dart   # ServiceProvider directory model
│   │   ├── 📁 services/                   # Business logic, state providers & cloud APIs
│   │   │   ├── 📄 auth_service.dart       # Supabase GoTrue Auth service & stream provider
│   │   │   ├── 📄 firestore_service.dart  # Data access layer with Hive offline caching
│   │   │   ├── 📄 onesignal_manager.dart  # OneSignal user login & subscription synchronization
│   │   │   ├── 📄 ads_service.dart        # Google Mobile Ads safe initializer
│   │   │   └── 📄 background_service.dart # Continuous background monitoring service
│   │   ├── 📁 utils/                      # Common design system & routing constants
│   │   │   ├── 📄 app_constants.dart      # Society wings, roles, statuses & cache box keys
│   │   │   ├── 📄 app_routes.dart         # Exhaustive registry of 26 application route identifiers
│   │   │   └── 📄 app_theme.dart          # Cyberpunk dark theme & clean light theme
│   │   ├── 📁 widgets/                    # Reusable atomic UI widgets
│   │   │   └── 📄 error_boundary.dart     # Production error boundary catching unhandled UI exceptions
│   │   └── 📁 screens/                    # View layer segmented by user role
│   │       ├── 📄 splash_screen.dart      # Animated startup splash screen
│   │       ├── 📁 auth/
│   │       │   └── 📄 login_screen.dart   # Email & password authentication with form validation
│   │       ├── 📁 guard/
│   │       │   ├── 📄 guard_home.dart     # Guard quick actions grid
│   │       │   ├── 📄 add_visitor.dart    # Visitor check-in form with instant notification dispatch
│   │       │   ├── 📄 scan_pass.dart      # Live camera QR scanner using mobile_scanner
│   │       │   ├── 📄 visitor_status.dart # Real-time visitor logs and status filters
│   │       │   ├── 📄 staff_entry.dart    # Domestic help check-in & check-out toggle
│   │       │   └── 📄 patrol_screen.dart  # Security patrol checkpoint verification
│   │       ├── 📁 resident/
│   │       │   ├── 📄 resident_home.dart  # Resident home dashboard with quick SOS banner
│   │       │   ├── 📄 approval_screen.dart# Pending visitor approval/denial cards
│   │       │   ├── 📄 visitor_history.dart# Filterable visitor entry history
│   │       │   ├── 📄 guest_pass_screen.dart # Digital invite generator
│   │       │   ├── 📄 my_pass.dart        # Active QR code invitation cards
│   │       │   ├── 📄 household_screen.dart# Family member management
│   │       │   ├── 📄 househelp_screen.dart# Assigned domestic staff directory
│   │       │   ├── 📄 notice_list.dart    # Official society notice board
│   │       │   ├── 📄 complaint_list.dart # Maintenance ticket submission & list
│   │       │   ├── 📄 service_directory.dart # Emergency technicians directory (Plumber, Electrician)
│   │       │   └── 📄 sos_screen.dart     # Emergency SOS button with confirmation
│   │       └── 📁 admin/
│   │           ├── 📄 admin_dashboard.dart# Society operations control center
│   │           ├── 📄 admin_extras.dart   # Complaint management & service provider admin
│   │           ├── 📄 user_management.dart# Resident, guard, and administrator directory
│   │           ├── 📄 notice_admin.dart   # Society-wide announcement publisher
│   │           ├── 📄 patrol_logs.dart    # Security patrol audit trail
│   │           └── 📄 analytics_dashboard.dart # Visitor volume and staff occupancy metrics
│   ├── 📁 test/                           # Automated test suites
│   │   ├── 📄 models_test.dart            # Unit tests for JSON serialization & copyWith
│   │   ├── 📄 theme_test.dart             # Theme brightness, color scheme & typography tests
│   │   ├── 📄 routes_test.dart            # Route registry uniqueness & formatting validation
│   │   ├── 📄 error_boundary_test.dart    # ErrorBoundary widget rendering tests
│   │   └── 📄 widget_test.dart            # Application smoke test
│   └── 📁 scripts/
│       └── 📄 build_optimized.sh          # Release APK build script with ABI splitting & obfuscation
│
├── 📁 database/                           # Database schemas & security policies
│   ├── 📄 README.md                       # Complete database setup & RLS policy documentation
│   └── 📄 MASTER_SETUP.sql                # Complete PostgreSQL schema, RLS policies & seed data
│
├── 📁 docs/                               # System documentation & technical reports
│   ├── 📄 ARCHITECTURE.md                 # Detailed architecture overview & sequence diagrams
│   ├── 📄 COST_ANALYSIS.md                # Lifecycle infrastructure cost breakdown & tiers
│   ├── 📄 QUICK_REFERENCE.md              # Operations manual & notification troubleshooting
│   ├── 📄 CONTRIBUTING.md                 # Contribution guidelines & PR checklist
│   └── 📄 SECURITY.md                     # Vulnerability reporting & security architecture
│
└── 📁 supabase/                           # Supabase configuration & Edge Functions
    ├── 📄 config.toml                     # Supabase CLI local development configuration
    └── 📁 functions/
        ├── 📄 deno.json                   # Deno runtime configuration
        └── 📁 send-notification/
            └── 📄 index.ts                # TypeScript Edge Function for OneSignal push dispatch
```

---

## 🛡️ Database & Row Level Security (RLS) Matrix

Every table in Supabase PostgreSQL enforces strict Row Level Security (RLS) with
non-recursive security definer functions (`is_admin()`, `is_guard()`,
`is_guard_or_admin()`):

| Database Table      | Residents Permission                     | Security Guards Permission              | Admins Permission        |
| :------------------ | :--------------------------------------- | :-------------------------------------- | :----------------------- |
| `profiles`          | `SELECT` own; `UPDATE` own profile       | `SELECT` flat & name directory          | `ALL` (Full CRUD)        |
| `visitors`          | `SELECT`/`UPDATE` own flat's visitors    | `ALL` (Check-in & update all entries)   | `ALL` (Full CRUD)        |
| `guest_passes`      | `ALL` on own generated passes            | `SELECT` during camera QR scan          | `ALL` (Full CRUD)        |
| `daily_help`        | `ALL` on assigned household staff        | `SELECT` & `UPDATE` is_inside status    | `ALL` (Full CRUD)        |
| `sos_alerts`        | `INSERT` & `SELECT` own emergency alerts | `SELECT` & `UPDATE` active sirens       | `ALL` (Full CRUD)        |
| `notices`           | `SELECT` (Read-only broadcast)           | `SELECT` (Read-only broadcast)          | `ALL` (Publish & Delete) |
| `complaints`        | `ALL` on own filed complaints            | None                                    | `ALL` (Triage & Resolve) |
| `complaint_chats`   | `SELECT`/`INSERT` on own complaints      | None                                    | `ALL` (Manage Chat)      |
| `patrol_logs`       | None                                     | `INSERT` & `SELECT` own checkpoint logs | `SELECT` (Audit Logs)    |
| `service_providers` | `SELECT` (Read-only directory)           | `SELECT` (Read-only directory)          | `ALL` (Manage Providers) |

---

## 💻 Technology Stack & Ecosystem

- **Frontend Framework:** [Flutter 3.47+](https://flutter.dev) (Dart 3.13+)
  targeting Android, iOS, and macOS.
- **State Management:** [Flutter Riverpod 2.6+](https://riverpod.dev) with
  reactive dependency injection.
- **Backend & Database:** [Supabase](https://supabase.com) (PostgreSQL 17 with
  Row Level Security, Auth & Realtime replication).
- **Push Notification Service:** [OneSignal](https://onesignal.com)
  (`onesignal_flutter 5.x`) with subscription IDs and fallback channels.
- **Local Embedded Storage:** [Hive](https://pub.dev/packages/hive_flutter)
  (`hive_flutter 1.1+`) for offline user profiles and patrol checkpoint
  persistence.
- **Hardware Integrations:**
  - `mobile_scanner`: High-performance hardware camera barcode & QR reader.
  - `qr_flutter`: Dynamic QR pass code rendering.
  - `local_auth`: Biometric authentication support.
  - `audioplayers`: Emergency high-decibel alarm playback.
  - `flutter_background_service`: Continuous background socket and event
    monitoring.
- **Edge Compute:**
  [Supabase Edge Functions](https://supabase.com/docs/guides/functions) written
  in TypeScript on Deno.

---

## 🚀 Getting Started & Installation Guide

### 1. Prerequisites

- [Flutter SDK](https://docs.flutter.dev/get-started/install) (`v3.10` or
  higher)
- [Dart SDK](https://dart.dev/get-dart) (`v3.0` or higher)
- A [Supabase](https://supabase.com) account and project
- A [OneSignal](https://onesignal.com) application

### 2. Clone Repository

```bash
git clone https://github.com/Coderaryanyadav/ApnaGate.git
cd ApnaGate
```

### 3. Database Initialization

1. Navigate to your [Supabase Project Dashboard](https://supabase.com/dashboard)
   -> **SQL Editor**.
2. Open [`database/MASTER_SETUP.sql`](database/MASTER_SETUP.sql).
3. Copy and run the entire script. It sets up all tables, security definer
   functions, RLS policies, and default seed accounts:
   - `aryanjyadav@gmail.com` (Resident, Wing A, Flat 1101)
   - `guardawing@gmail.com` (Guard, Wing A)
   - `crescentlandmark@gmail.com` (Admin, Wing A, Flat 101)

### 4. Configure Application Credentials

Verify credentials in
[`app/lib/supabase_config.dart`](app/lib/supabase_config.dart):

```dart
class SupabaseConfig {
  static const String supabaseUrl = 'YOUR_SUPABASE_PROJECT_URL';
  static const String supabaseAnonKey = 'YOUR_SUPABASE_ANON_KEY';
  static const String oneSignalAppId = 'YOUR_ONESIGNAL_APP_ID';
}
```

### 5. Install Dependencies

```bash
cd app
flutter pub get
```

### 6. Run the Application

```bash
# Launch on connected mobile device or desktop
flutter run
```

---

## 🧪 Automated Testing & Static Analysis

The repository includes strict Dart static analysis and comprehensive automated
unit and widget test suites:

```bash
# Run static analysis (Strict linting - 0 errors, 0 warnings)
cd app
flutter analyze

# Run full test suite (14/14 tests passing)
cd app
flutter test
```

### Automated Test Suite Coverage

- `test/models_test.dart`: Serialization, deserialization, and `copyWith`
  validation for `AppUser`, `Visitor`, `GuestPass`, `DailyHelp`, `Notice`,
  `Complaint`, `SosAlert`, and `ServiceProvider`.
- `test/theme_test.dart`: Dark and light theme properties, color schemes, and
  brightness checks.
- `test/routes_test.dart`: Route registry completeness, formatting, and
  uniqueness validation across all 26 named routes.
- `test/error_boundary_test.dart`: Error boundary child rendering and exception
  shielding.
- `test/widget_test.dart`: Root application widget smoke test.

---

## 📱 Production Build & Release

To build an optimized, obfuscated release APK with split ABI architectures:

```bash
cd app
bash scripts/build_optimized.sh
```

Optimized artifacts will be generated at:

- `app/build/app/outputs/flutter-apk/app-arm64-v8a-release.apk`
- `app/build/app/outputs/flutter-apk/app-armeabi-v7a-release.apk`
- `app/build/app/outputs/flutter-apk/app-x86_64-release.apk`

---

## 🤝 Contributing, Security & License

- **Contributing**: Please review the
  [Contributing Guidelines](docs/CONTRIBUTING.md) before submitting pull
  requests.
- **Security Policy**: To report security vulnerabilities, review our
  [Security Policy](docs/SECURITY.md).
- **License**: This project is open-source and licensed under the
  [MIT License](LICENSE).
