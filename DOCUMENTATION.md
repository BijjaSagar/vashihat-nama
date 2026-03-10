# 🛡️ Vasihat Nama — Project Documentation

> **"Your Digital Legacy, Secured Forever"**
>
> Vasihat Nama (Urdu: "Letter of Advice") is a **zero-knowledge, encrypted digital vault** mobile application designed to securely manage sensitive documents, credentials, and digital assets — and seamlessly transfer them to nominated beneficiaries through an intelligent **"Proof of Life" dead man's switch** mechanism.

---

## 📋 Table of Contents

1. [Project Overview](#1-project-overview)
2. [Core Philosophy & Key Points](#2-core-philosophy--key-points)
3. [Technology Stack](#3-technology-stack)
4. [Application Flow](#4-application-flow)
5. [Feature Modules](#5-feature-modules)
6. [System Architecture](#6-system-architecture)
7. [Database Schema](#7-database-schema)
8. [API Reference](#8-api-reference)
9. [Security Architecture](#9-security-architecture)
10. [Deployment](#10-deployment)

---

## 1. Project Overview

Vasihat Nama is a **cross-platform mobile application** built with Flutter that solves a critical real-world problem: *What happens to your digital assets when you're no longer around?*

The app provides a secure, encrypted vault where users can store sensitive information — bank accounts, passwords, legal documents, credit card details — and designate **nominees** who will automatically receive access when the user fails to perform regular "Proof of Life" check-ins.

### The Problem It Solves

- **Digital Asset Loss**: Billions in cryptocurrency, bank accounts, and digital assets are lost annually because heirs don't have access credentials.
- **Document Scattering**: Important legal documents (wills, property deeds, insurance policies) are scattered across physical and digital locations.
- **Identity Verification of Life**: No automated way to verify a person is alive and trigger asset transfer upon death or incapacitation.
- **Regional Compliance**: Different countries have different legal requirements for estate planning and document management.

---

## 2. Core Philosophy & Key Points

### 🔐 Zero-Knowledge Security
- The server **never sees** plaintext data. All sensitive vault items are encrypted client-side before being transmitted.
- RSA public/private key pairs are used — only the user's private key can decrypt their data.
- File encryption keys are individually encrypted per-nominee using their public keys, enabling **atomic access grants**.

### ❤️ Proof of Life (Dead Man's Switch)
- Users set a configurable check-in frequency (e.g., every 30 days).
- **Biometric authentication** (fingerprint/face recognition) is required for each check-in, ensuring it's genuinely the user.
- If the user fails to check in within the deadline, nominees are **automatically notified** and **granted access** to assigned vault items.
- Recurring notifications with **vibration alerts** remind users to check in.

### 🧑‍🤝‍🧑 Nominee Management
- Users can designate multiple nominees (beneficiaries) with full contact details.
- Supports both **Digital** (email/app access) and **Physical** (hand-delivery with identity proof) delivery modes.
- Each vault item can be selectively assigned to specific nominees — full control over who sees what.

### 🤖 AI-Powered Intelligence
- **AI Will Drafter**: Voice-to-text and AI-powered will generation with conflict detection and tone analysis.
- **Smart Scan (OCR)**: Camera-based document scanning with automatic text extraction via Google ML Kit.
- **Credit Card Scanning**: Automatically detects and extracts credit card details from photos.
- **AI Legal Assistant**: Chat with AI for legal guidance on estate planning and document requirements.
- **Document Classification**: AI automatically categorizes scanned documents.

### 📊 Security Health Score
- Dynamic score (0-100%) calculated based on the user's security posture.
- Checks: vault items stored, nominees configured, documents scanned, dead man's switch enabled.
- One-tap **"Fix"** buttons to quickly resolve security gaps.

---

## 3. Technology Stack

### Frontend (Mobile)
| Component | Technology |
|-----------|-----------|
| Framework | **Flutter** (Dart) |
| Platform | Android & iOS |
| UI Design | **Glassmorphism** (frosted glass, Apple-style) |
| Authentication | **OTP via SMS** (HSP SMS Gateway) |
| Biometrics | `local_auth` (Fingerprint / Face Recognition) |
| Notifications | `flutter_local_notifications` (Recurring, Vibration) |
| OCR | Google ML Kit Text Recognition |
| AI | Google Generative AI (Gemini) |
| Voice Input | `speech_to_text` |
| File Storage | AWS S3 (via Presigned URLs) |
| Encryption | RSA + AES (`pointycastle`, `encrypt`, `crypto`) |

### Backend
| Component | Technology |
|-----------|-----------|
| Runtime | **Node.js** with Express.js (TypeScript) |
| Database | **PostgreSQL** |
| File Storage | **AWS S3** (Presigned URL Upload) |
| AI Backend | **OpenAI GPT** (Will drafting, conflict checking, tone analysis) |
| SMS Gateway | HSP SMS API |
| Hosting | **Vercel** (Serverless Functions) |

---

## 4. Application Flow

### 4.1 Onboarding Flow

```
┌─────────────────┐     ┌──────────────┐     ┌────────────────┐     ┌─────────────────┐
│   Login Screen   │────▸│  Send OTP    │────▸│  Verify OTP    │────▸│   Dashboard     │
│  (Mobile Number) │     │ (SMS Gateway)│     │ (6-digit code) │     │  (Secure Home)  │
└─────────────────┘     └──────────────┘     └────────────────┘     └─────────────────┘
         │
         ▼ (New User)
┌─────────────────┐     ┌──────────────┐     ┌────────────────┐
│ Register Screen  │────▸│ OTP Verify   │────▸│ Complete Setup │
│ (Name, Email,    │     │              │     │ (Create Keys,  │
│  Mobile)         │     │              │     │  Auto-Login)   │
└─────────────────┘     └──────────────┘     └────────────────┘
```

### 4.2 Main Dashboard Flow

```
                              ┌─────────────────────────┐
                              │     SECURE DASHBOARD     │
                              │   "Welcome, [User]'s    │
                              │        Vault"            │
                              └────────┬────────────────┘
                                       │
         ┌─────────────┬───────────────┼───────────────┬──────────────┐
         ▼             ▼               ▼               ▼              ▼
  ┌──────────┐  ┌──────────┐   ┌──────────┐   ┌──────────┐   ┌──────────┐
  │ Secure   │  │ Nominees │   │ AI Will  │   │ Smart    │   │ Proof of │
  │ Folders  │  │          │   │ Drafter  │   │ Scan     │   │   Life   │
  └────┬─────┘  └────┬─────┘   └──────────┘   └────┬─────┘   └────┬─────┘
       ▼             ▼                              ▼              ▼
  ┌──────────┐  ┌──────────┐                 ┌──────────┐   ┌──────────┐
  │ Vault    │  │ Add/Edit │                 │ Smart    │   │ Biometric│
  │ Items    │  │ Nominee  │                 │ Alerts   │   │ Check-in │
  │(Note,Pwd,│  │ (Digital/│                 │(Expiry   │   │(Finger/  │
  │ Card,    │  │ Physical)│                 │ Tracking)│   │  Face)   │
  │ File)    │  │          │                 │          │   │          │
  └──────────┘  └──────────┘                 └──────────┘   └──────────┘
```

### 4.3 Vault Item Lifecycle

```
User Creates Vault Item
         │
         ▼
┌────────────────────┐
│ Data Encrypted     │ ◄── Client-side RSA/AES encryption
│ (Zero-Knowledge)   │
└────────┬───────────┘
         ▼
┌────────────────────┐
│ Stored on Server   │ ◄── Server ONLY stores encrypted blob
│ (PostgreSQL)       │
└────────┬───────────┘
         ▼
┌────────────────────┐
│ Assigned to Nominee│ ◄── Each nominee gets individually encrypted key
│ (Selective Access) │
└────────┬───────────┘
         ▼
┌────────────────────┐
│ Dead Man's Switch  │ ◄── If user stops checking in...
│ Triggers           │
└────────┬───────────┘
         ▼
┌────────────────────┐
│ Nominee Notified   │ ◄── Nominee receives access grant notification
│ Access Granted     │
└────────────────────┘
```

### 4.4 Proof of Life (Dead Man's Switch) Flow

```
┌──────────────────────────────────────────────────────────────────┐
│                    PROOF OF LIFE SYSTEM                          │
│                                                                  │
│  User Activates ──▸ Sets Frequency ──▸ Periodic Notifications   │
│       │              (30 days,          (Every 1 hour,           │
│       │               4 hours,           vibration alert)        │
│       │               etc.)                    │                 │
│       │                                        ▼                 │
│       │                               ┌──────────────┐          │
│       │                               │ User Taps    │          │
│       │                               │ "I'm Safe"   │          │
│       │                               └──────┬───────┘          │
│       │                                      ▼                  │
│       │                               ┌──────────────┐          │
│       │                               │ Biometric    │          │
│       │                               │ Verification │          │
│       │                               │ (Fingerprint/│          │
│       │                               │  Face ID)    │          │
│       │                               └──────┬───────┘          │
│       │                                      ▼                  │
│       │                        ┌─── ✅ Authenticated ───┐       │
│       │                        │                        │       │
│       │                   Check-in logged           Timer Reset  │
│       │                   to server                 to 0         │
│       │                                                          │
│       │         ┌─────────────────────────────────────┐          │
│       └────────▸│  IF user DOESN'T check in before   │          │
│                 │  deadline: NOMINEES ARE NOTIFIED    │          │
│                 │  and GRANTED ACCESS to vault items  │          │
│                 └─────────────────────────────────────┘          │
│                                                                  │
│  Dashboard monitors status every 10 minutes                     │
│  If OVERDUE: Full-screen modal forces user to check in          │
└──────────────────────────────────────────────────────────────────┘
```

---

## 5. Feature Modules

### 5.1 🔐 Secure Folders & Vault Items

| Feature | Description |
|---------|-------------|
| **Folder Management** | Create, rename, and delete encrypted folders |
| **Notes** | Securely store text notes (credentials, instructions, messages) |
| **Passwords** | Store website/service credentials with encrypted password field |
| **Credit Cards** | Store full credit card details with beautiful animated card widget |
| **Files** | Upload documents (PDF, images) via AWS S3 presigned URLs |
| **Nominee Assignment** | Assign any vault item to one or more nominees |
| **Filter & Search** | Filter vault items by type (Notes, Passwords, Cards, Files) |

### 5.2 🧑‍🤝‍🧑 Nominee Management

| Feature | Description |
|---------|-------------|
| **Add Nominees** | Name, email, mobile, relationship, identity proof |
| **Digital Delivery** | Access shared via email/app upon trigger |
| **Physical Delivery** | Requires address, identity proof; supports hand-delivery rules |
| **View Assigned Items** | See which vault items are assigned to each nominee |
| **Edit/Delete** | Full CRUD operations on nominees |

### 5.3 🤖 AI Will Drafter

| Feature | Description |
|---------|-------------|
| **Voice Input** | Dictate your will using speech-to-text |
| **AI Generation** | OpenAI-powered will text generation from instructions |
| **Conflict Checker** | AI analyzes will text for legal conflicts or contradictions |
| **Tone Analyzer** | Ensures the will's tone is appropriate and clear |

### 5.4 📷 Smart Scan & OCR

| Feature | Description |
|---------|-------------|
| **Document Scanning** | Camera capture with Google ML Kit OCR |
| **Credit Card Detection** | Automatically extracts card number, expiry, CVV, name |
| **Auto-Classification** | AI categorizes documents (Aadhaar, Passport, PAN, License, etc.) |
| **Smart Alert Creation** | Extracted expiry dates auto-create renewal reminders |

### 5.5 🔔 Smart Alerts

| Feature | Description |
|---------|-------------|
| **Document Expiry Tracking** | Tracks expiry dates of passports, licenses, insurance, etc. |
| **Auto-Notifications** | Push notifications for documents expiring within 30 days |
| **Stats Dashboard** | Total, Urgent, and Expired document counts |
| **One-Tap Add** | Quick document alert creation with expiry date picker |

### 5.6 ❤️ Proof of Life (Dead Man's Switch)

| Feature | Description |
|---------|-------------|
| **Biometric Check-In** | Real fingerprint/face recognition verification |
| **Configurable Frequency** | Days (0-90) + Hours (0-24) + Minutes (0-30) |
| **Recurring Notifications** | Hourly push notifications with vibration pattern |
| **Overdue Modal** | Full-screen warning when check-in deadline is passed |
| **Auto-Grant Access** | Nominees receive vault access if user stops checking in |
| **Test Notification** | Verify notification system is working correctly |

### 5.7 🛡️ Security Health Score

| Feature | Description |
|---------|-------------|
| **Dynamic Scoring** | 0-100% score based on security configurations |
| **Checklist** | Visual checklist of security items (nominees, vault items, heartbeat, docs) |
| **One-Tap Fix** | Navigate directly to fix each security gap |

### 5.8 🌍 Regional Compliance

| Feature | Description |
|---------|-------------|
| **Country-Specific Checklists** | Legal document requirements by country |
| **AI-Generated Checklists** | AI creates region-specific compliance lists |
| **Track Progress** | Mark documents as pending/uploaded/verified |

### 5.9 ⚖️ AI Legal Assistant

| Feature | Description |
|---------|-------------|
| **Chat Interface** | Interactive AI-powered legal guidance |
| **Estate Planning** | Advice on wills, trusts, and asset transfer |
| **Contextual Help** | Understands the user's vault contents for personalized advice |

### 5.10 🏥 AI Vault Health Analyzer

| Feature | Description |
|---------|-------------|
| **Completeness Score** | AI-calculated 0-100% vault health score based on item coverage |
| **Animated Dashboard** | Circular progress indicator with color-coded score (green/orange/red) |
| **Stats Cards** | Quick-view cards showing folders, nominees, and files count |
| **AI Recommendations** | Prioritized actionable suggestions to improve vault health |
| **Category Analysis** | Checks for vault type diversity: notes, passwords, cards, files |

### 5.11 📹 AI Video Will / Voice Message

| Feature | Description |
|---------|-------------|
| **Text Messages** | Write personal messages addressed to specific nominees |
| **Nominee Selection** | Assign each message to a specific nominee via dropdown |
| **AI Summarization** | OpenAI automatically summarizes long transcripts |
| **Message Management** | View, create, and delete personal will messages |
| **Multiple Types** | Support for text, audio, and video message types |

### 5.12 🔍 Smart Asset Discovery Assistant

| Feature | Description |
|---------|-------------|
| **AI Checklist Generation** | AI creates personalized asset checklist based on country, age, occupation |
| **Category Grouping** | Assets organized by: Financial, Property, Insurance, Digital, Personal, Legal |
| **Progress Tracking** | Visual progress bar shows % of suggested assets added |
| **Toggle Completion** | Tap items to mark as added/not added with visual strikethrough |
| **Priority Badges** | Each asset marked as High, Medium, or Low priority |

### 5.13 ✅ AI Nominee Readiness Report

| Feature | Description |
|---------|-------------|
| **Overall Score** | Combined readiness percentage across all nominees |
| **Per-Nominee Score** | Individual readiness % with circular progress indicators |
| **8-Point Checklist** | Checks: name, email, phone, ID proof, address, items, relationship, delivery |
| **Fix Suggestions** | "Fix" badges for each failing check with guidance |
| **Expandable Cards** | Tap to expand nominee details and see full checklist |

### 5.14 📊 AI Estate Summary Dashboard

| Feature | Description |
|---------|-------------|
| **Executive Summary** | AI-generated natural language summary of entire estate |
| **Stats Grid** | Vault items, nominees, files, and alerts at a glance |
| **Strengths Analysis** | AI identifies what the user is doing well |
| **Risk Identification** | AI highlights potential gaps and vulnerabilities |
| **Numbered Recommendations** | Prioritized action items for estate improvement |

### 5.15 🚨 AI Fraud & Anomaly Detection

| Feature | Description |
|---------|-------------|
| **Activity Logging** | All user actions logged with device info and IP address |
| **Suspicious Detection** | AI flags unusual patterns (multiple logins, bulk deletes, odd hours) |
| **Security Status Card** | Green "All Clear" or Red "Attention Required" dashboard |
| **Filter Toggle** | Show all activity or suspicious events only |
| **Timeline View** | Chronological activity feed with action icons and timestamps |

### 5.16 💙 AI Grief Support Chatbot

| Feature | Description |
|---------|-------------|
| **Compassionate AI** | GPT-powered chatbot specifically trained for grief support |
| **Chat Interface** | Modern chat bubbles with typing indicators and smooth animations |
| **Context-Aware** | Understands nominee name and deceased name for personalized support |
| **Vault Guidance** | Helps nominees understand how to access and manage inherited vault |
| **Legal Guidance** | Provides gentle guidance on legal steps and procedures |

### 5.17 📜 AI Legal Document Generator

| Feature | Description |
|---------|-------------|
| **8 Document Types** | Power of Attorney, Gift Deed, Succession Certificate, Nominee Claim Letter, Insurance Claim, Last Will, Property Transfer, Bank Closure |
| **AI Generation** | OpenAI generates professional legal document drafts |
| **Full-Screen Viewer** | Read and review generated documents with selectable text |
| **Multi-Language** | Generate documents in English, Hindi, Urdu, and other languages |
| **Document Library** | View, manage, and delete all generated legal documents |

### 5.18 🆘 AI Emergency Card

| Feature | Description |
|---------|-------------|
| **Live Preview Card** | Real-time card preview with name, blood group, allergies, contacts |
| **Medical Information** | Store blood group, allergies, conditions, medications |
| **Emergency Contacts** | Doctor name/phone + 2 emergency contacts |
| **Insurance & Donor** | Insurance policy details and organ donor status |
| **AI Suggestions** | AI recommends medical fields to fill based on age and conditions |

---

## 6. System Architecture

```
┌──────────────────────────────────────────────────────────────────────────┐
│                           CLIENT (Flutter App)                          │
│                                                                          │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌──────────┐  │
│  │  Login   │  │Dashboard │  │ Folders  │  │ Nominees │  │Heartbeat │  │
│  │  Screen  │  │  Screen  │  │  Screen  │  │  Screen  │  │  Screen  │  │
│  └────┬─────┘  └────┬─────┘  └────┬─────┘  └────┬─────┘  └────┬─────┘  │
│       │              │             │             │             │         │
│  ┌────▼──────────────▼─────────────▼─────────────▼─────────────▼─────┐  │
│  │                        SERVICE LAYER                              │  │
│  │  ┌──────────────┐  ┌─────────────────┐  ┌──────────────────────┐  │  │
│  │  │  ApiService   │  │NotificationSvc  │  │   AuthService        │  │  │
│  │  │  (HTTP/REST)  │  │(Local Notifs)   │  │   (Firebase Auth)    │  │  │
│  │  └──────┬───────┘  └─────────────────┘  └──────────────────────┘  │  │
│  │         │                                                          │  │
│  │  ┌──────▼───────┐                                                  │  │
│  │  │ Encryption   │ ◄── RSA/AES client-side encryption               │  │
│  │  │ Service      │                                                  │  │
│  │  └──────────────┘                                                  │  │
│  └────────────────────────────────────────────────────────────────────┘  │
└────────────────────────────┬─────────────────────────────────────────────┘
                             │ HTTPS REST API
                             ▼
┌──────────────────────────────────────────────────────────────────────────┐
│                      BACKEND (Node.js / Express / TypeScript)           │
│                         Hosted on Vercel (Serverless)                    │
│                                                                          │
│  ┌──────────────────────────────────────────────────────────────────┐    │
│  │                         API Routes                               │    │
│  │  /api/users     /api/folders    /api/vault_items   /api/nominees  │    │
│  │  /api/send_otp  /api/files      /api/smart_docs    /api/heartbeat│    │
│  │  /api/ai/chat   /api/security   /api/regional                    │    │
│  └──────────────────────┬───────────────────────────────────────────┘    │
│                         │                                                │
│  ┌──────────────────────▼───────────────────────────────────────────┐    │
│  │              PostgreSQL Database                                 │    │
│  │  users │ folders │ files │ nominees │ vault_items │ smart_docs   │    │
│  │  otp_verifications │ otp_logs │ heartbeat_logs │ regional_*     │    │
│  └──────────────────────────────────────────────────────────────────┘    │
│                                                                          │
│  ┌──────────────────────────────────────────────────────────────────┐    │
│  │              External Services                                   │    │
│  │  ┌──────────┐  ┌──────────────┐  ┌──────────────────────────┐   │    │
│  │  │  AWS S3   │  │ OpenAI GPT   │  │  HSP SMS Gateway         │   │    │
│  │  │ (Files)   │  │ (AI Features)│  │  (OTP Delivery)          │   │    │
│  │  └──────────┘  └──────────────┘  └──────────────────────────┘   │    │
│  └──────────────────────────────────────────────────────────────────┘    │
└──────────────────────────────────────────────────────────────────────────┘
```

---

## 7. Database Schema

### Tables Overview

| Table | Purpose |
|-------|---------|
| `users` | User accounts (mobile, name, email, RSA keys, heartbeat settings) |
| `folders` | Encrypted folder containers for organizing vault items |
| `files` | Reference to encrypted files stored in AWS S3 |
| `nominees` | Beneficiaries who receive access upon trigger |
| `file_permissions` | Per-nominee encrypted file access keys |
| `vault_items` | Encrypted notes, passwords, credit cards, files |
| `vault_item_nominees` | Many-to-many: which nominees can access which vault items |
| `smart_docs` | Document intelligence — expiry tracking and renewal alerts |
| `otp_verifications` | Active OTP codes for authentication |
| `otp_logs` | Audit trail of all OTP send/verify attempts |
| `heartbeat_logs` | Check-in audit trail |
| `regional_checklists` | Country-specific legal document requirements |
| `user_regional_docs` | User's progress on regional compliance documents |
| `video_wills` | Personal text/audio/video messages for nominees |
| `asset_discovery` | AI-generated asset checklists with completion status |
| `activity_logs` | User activity tracking for fraud & anomaly detection |
| `legal_documents` | AI-generated legal document drafts |

### Key Relationships

```
users ──┬── folders ──── vault_items ──── vault_item_nominees ──── nominees
        │                    │
        ├── files ────── file_permissions ─── nominees
        │
        ├── smart_docs (document alerts)
        │
        ├── heartbeat_logs (check-in audit)
        │
        └── otp_verifications / otp_logs (authentication)
```

---

## 8. API Reference

### Authentication
| Method | Endpoint | Description |
|--------|----------|-------------|
| POST | `/api/users/register` | Register new user |
| GET | `/api/users/:id` | Get user profile |
| PUT | `/api/users/:id` | Update user profile |
| POST | `/api/send_otp` | Send OTP via SMS |
| POST | `/api/verify_otp` | Verify OTP code |

### Folders
| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/api/folders?user_id=` | List user's folders |
| POST | `/api/folders` | Create folder |
| PUT | `/api/folders/:id` | Rename folder |
| DELETE | `/api/folders/:id?user_id=` | Delete folder (cascading) |

### Vault Items
| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/api/vault_items?user_id=&folder_id=&item_type=` | List vault items |
| GET | `/api/vault_items/:id?user_id=` | Get single item |
| POST | `/api/vault_items` | Create vault item |
| PUT | `/api/vault_items/:id` | Update vault item / assign nominee |
| DELETE | `/api/vault_items/:id?user_id=` | Delete vault item |
| GET | `/api/vault_items/stats/count?user_id=` | Get vault statistics |

### Nominees
| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/api/nominees?user_id=` | List nominees |
| POST | `/api/nominees` | Add nominee |
| PUT | `/api/nominees/:id` | Update nominee |
| DELETE | `/api/nominees/:id` | Delete nominee |
| GET | `/api/nominees/:id/assigned_items` | Get assigned vault items |

### Files (S3)
| Method | Endpoint | Description |
|--------|----------|-------------|
| POST | `/api/get-presigned-url` | Get S3 upload URL |
| POST | `/api/files/confirm-upload` | Confirm upload after S3 |
| GET | `/api/files?folder_id=` | List files in folder |

### Smart Alerts
| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/api/smart_docs?user_id=` | List smart alerts |
| POST | `/api/smart_docs` | Create smart alert |
| DELETE | `/api/smart_docs/:id?user_id=` | Delete smart alert |

### Heartbeat (Dead Man's Switch)
| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/api/heartbeat/status?user_id=` | Get heartbeat status |
| POST | `/api/heartbeat/checkin` | Perform check-in |
| POST | `/api/heartbeat/settings` | Update frequency settings |

### AI Features (Original)
| Method | Endpoint | Description |
|--------|----------|-------------|
| POST | `/api/ai/chat` | Chat with AI assistant |
| POST | `/api/ai/classify` | Classify document text |
| POST | `/api/ai/conflict-check` | Check will for conflicts |
| POST | `/api/ai/analyze-tone` | Analyze document tone |

### AI Features v2 (10 New Modules)
| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/api/vault-health?user_id=` | AI Vault Health score & recommendations |
| POST | `/api/video-wills` | Create a video will / message |
| GET | `/api/video-wills?user_id=` | List all video wills |
| DELETE | `/api/video-wills/:id?user_id=` | Delete a video will |
| POST | `/api/video-wills/summarize` | AI summarize transcript |
| POST | `/api/asset-discovery/generate` | AI generate asset checklist |
| GET | `/api/asset-discovery?user_id=` | List asset discovery items |
| PUT | `/api/asset-discovery/:id/toggle` | Toggle asset completion |
| GET | `/api/nominee-readiness?user_id=` | AI nominee readiness report |
| GET | `/api/estate-summary?user_id=` | AI estate executive summary |
| POST | `/api/activity-log` | Log user activity |
| GET | `/api/activity-log?user_id=` | Get activity logs (fraud detection) |
| POST | `/api/ai/grief-support` | Grief support chatbot |
| POST | `/api/legal-documents/generate` | Generate legal document |
| GET | `/api/legal-documents?user_id=` | List generated documents |
| DELETE | `/api/legal-documents/:id?user_id=` | Delete legal document |
| POST | `/api/ai/translate` | Translate text to target language |
| PUT | `/api/emergency-card` | Save emergency card data |
| GET | `/api/emergency-card?user_id=` | Get emergency card |
| POST | `/api/emergency-card/suggest` | AI suggestions for emergency card |

### Other
| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/api/security/score?user_id=` | Get security health score |
| GET | `/api/regional/checklists?country_code=` | Get regional checklists |
| POST | `/api/regional/user_docs` | Save regional doc progress |
| POST | `/api/regional/generate-ai` | AI-generate regional checklist |
| GET | `/api/migrate-v3` | Run V3 database migration |

---

## 9. Security Architecture

### Encryption Model

```
┌─────────────────────────────────────────────────────┐
│                 ENCRYPTION FLOW                      │
│                                                      │
│  1. User creates vault item (e.g., password)         │
│                    │                                 │
│                    ▼                                 │
│  2. Generate random AES-256 key                      │
│                    │                                 │
│                    ▼                                 │
│  3. Encrypt data with AES key ──▸ Encrypted Blob     │
│                    │                                 │
│                    ▼                                 │
│  4. Encrypt AES key with User's RSA Public Key       │
│     ──▸ Encrypted Key Blob                           │
│                    │                                 │
│                    ▼                                 │
│  5. Send both encrypted blobs to server              │
│     (Server NEVER sees plaintext)                    │
│                                                      │
│  ═══════════════════════════════════════════════════  │
│                                                      │
│  NOMINEE ACCESS GRANT:                               │
│                                                      │
│  6. When assigning to nominee:                       │
│     - Decrypt AES key with User's Private Key        │
│     - Re-encrypt AES key with Nominee's Public Key   │
│     - Store nominee's encrypted key separately       │
│                                                      │
│  7. Nominee can decrypt with THEIR Private Key       │
│     (without ever needing User's Private Key)        │
└─────────────────────────────────────────────────────┘
```

### Authentication Security

- **OTP-based**: 6-digit OTP sent via SMS with 5-minute expiry
- **Biometric**: Device-level fingerprint/face recognition for check-ins
- **No Passwords**: Users never set a password — authentication is mobile number + OTP
- **Session Tokens**: Mock JWT tokens generated on successful verification

---

## 10. Deployment

### Backend (Vercel)

```bash
cd backend
vercel --prod --yes
```

- **Production URL**: `https://backend-sagar-bijjas-projects.vercel.app/api`
- **Serverless**: `api/index.ts` re-exports from `src/index.ts`
- **Vercel Config**: Rewrites all routes to `/api/index`

### Frontend (Flutter)

```bash
# Run on device
flutter run

# Build APK
flutter build apk --release

# Build iOS
flutter build ios --release
```

### Environment Variables (Backend `.env`)

```
DATABASE_URL=<PostgreSQL connection string>
AWS_ACCESS_KEY_ID=<AWS key>
AWS_SECRET_ACCESS_KEY=<AWS secret>
AWS_DEFAULT_REGION=<region>
AWS_BUCKET=<S3 bucket name>
```

---

## 📁 Project Structure

```
vasihat-nama-main/
├── lib/
│   ├── main.dart                    # App entry point
│   ├── firebase_options.dart        # Firebase config
│   ├── screens/
│   │   ├── login_screen.dart        # OTP login
│   │   ├── register_screen.dart     # New user registration
│   │   ├── dashboard_screen.dart    # Main dashboard (18 feature tiles)
│   │   ├── folders_screen.dart      # Encrypted folder grid
│   │   ├── vault_items_screen.dart  # Items inside a folder
│   │   ├── add_vault_item_screen.dart # Create note/password/card/file
│   │   ├── add_credit_card_screen.dart # Credit card entry
│   │   ├── nominee_screen.dart      # Nominee CRUD & assignment
│   │   ├── heartbeat_screen.dart    # Proof of Life check-in
│   │   ├── smart_scan_screen.dart   # OCR document/card scanner
│   │   ├── scan_document_screen.dart # Camera capture
│   │   ├── smart_alerts_screen.dart # Document expiry alerts
│   │   ├── ai_will_drafter_screen.dart # AI will generation
│   │   ├── legal_assistant_screen.dart # AI legal chat
│   │   ├── security_score_screen.dart  # Security health dashboard
│   │   ├── regional_checklist_screen.dart # Regional compliance
│   │   ├── vault_health_screen.dart    # AI Vault Health Analyzer
│   │   ├── video_will_screen.dart      # Video Will / Voice Message
│   │   ├── asset_discovery_screen.dart # Smart Asset Discovery
│   │   ├── nominee_readiness_screen.dart # Nominee Readiness Report
│   │   ├── estate_summary_screen.dart  # AI Estate Summary
│   │   ├── fraud_detection_screen.dart # Fraud & Anomaly Detection
│   │   ├── grief_support_screen.dart   # Grief Support Chatbot
│   │   ├── legal_document_screen.dart  # Legal Document Generator
│   │   ├── emergency_card_screen.dart  # Emergency Card
│   │   ├── profile_screen.dart      # User profile
│   │   ├── subscription_screen.dart # Premium features
│   │   ├── upload_document_screen.dart # File upload
│   │   └── files_screen.dart        # File browser
│   ├── services/
│   │   ├── api_service.dart         # All REST API calls
│   │   ├── auth_service.dart        # Firebase auth wrapper
│   │   ├── notification_service.dart # Push notifications & vibration
│   │   └── encryption/             # RSA/AES encryption utilities
│   ├── widgets/
│   │   ├── credit_card_widget.dart  # Animated 3D credit card
│   │   ├── premium_detail_sheet.dart # Premium feature bottom sheet
│   │   ├── custom_button.dart       # Reusable button
│   │   └── custom_textfield.dart    # Reusable text field
│   └── theme/
│       ├── app_theme.dart           # Colors, typography, dark theme
│       └── glassmorphism.dart       # Frosted glass card widget
│
├── android/
│   └── app/src/main/AndroidManifest.xml  # Permissions (notifications, biometrics)
│
├── backend/
│   ├── api/index.ts                 # Vercel serverless entry
│   ├── src/
│   │   ├── index.ts                 # All API routes (Express)
│   │   ├── schema.sql               # PostgreSQL schema
│   │   └── db/index.ts              # Database connection
│   ├── vercel.json                  # Vercel deployment config
│   └── package.json                 # Node dependencies
│
└── pubspec.yaml                     # Flutter dependencies
```

---

## 🏆 Unique Selling Points (USPs)

1. **First-of-its-kind "Digital Will Vault"** — Combines secure storage with death-triggered asset transfer
2. **Zero-Knowledge Architecture** — Even the server operator cannot read your data
3. **Biometric Dead Man's Switch** — Fingerprint/face-verified proof of life check-ins
4. **AI-Powered Will Drafting** — Voice-dictate your will with conflict detection
5. **Smart OCR with Auto-Alerts** — Scan a document, AI auto-creates expiry reminders
6. **Regional Legal Compliance** — Country-specific estate planning requirements
7. **Dual Delivery Modes** — Digital email delivery OR physical hand-delivery with identity verification
8. **Security Health Score** — Gamified security posture with one-tap fixes
9. **AI Vault Health Analyzer** — AI-powered completeness score with animated dashboard
10. **Video Will / Voice Message** — Personal messages for nominees with AI summarization
11. **Smart Asset Discovery** — AI-generated personalized asset checklist with progress tracking
12. **Nominee Readiness Report** — 8-point readiness score per nominee with gap analysis
13. **AI Estate Summary** — GPT-generated executive summary with strengths, risks, recommendations
14. **Fraud & Anomaly Detection** — Real-time activity monitoring with AI suspicious behavior flagging
15. **Grief Support Chatbot** — Compassionate AI assistant for nominees in difficult times
16. **AI Legal Document Generator** — 8 types of legal documents with multi-language support

---

*Documentation updated on February 25, 2026*
*Version 2.0.0 — 18 Feature Modules, 50+ API Endpoints, 17 Database Tables*
