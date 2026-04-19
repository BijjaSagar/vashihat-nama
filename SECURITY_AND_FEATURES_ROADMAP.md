# SECURITY AND FEATURES ROADMAP: Vasihat Nama 2.0

This document outlines the architectural plan to transform *Vasihat Nama* into a **Zero-Knowledge, End-to-End Encrypted (E2EE)** application. The goal is to ensure that even the developers (and the server) cannot access user documents—only the user and their designated nominees hold the keys.

## 1. Zero-Knowledge Security Architecture

### The Core Principle
**"What happens on your device, stays encrypted on your device."**
We move from server-side security to client-side encryption. The server will only ever store encrypted "gibberish" blobs.

### Implementation Steps
1.  **Client-Side Encryption (THE GOLDEN RULE)**:
    -   **Algorithm**: Use **AES-256-GCM** (Advanced Encryption Standard).
    -   **Process**: When a user selects a file, the app generates a random `File Encryption Key (FEK)` locally on the phone.
    -   The file is encrypted *before* upload. The server receives only the encrypted data.

2.  **Master Key Management**:
    -   Every user has a **Master Keypair** (Public & Private Key).
    -   **Private Key Storage**: The user's Private Key is encrypted with their login password (using Argon2/PBKDF2) and stored on the server.
    -   **Login Flow**:
        1.  User logs in.
        2.  Server sends the encrypted Private Key.
        3.  App prompts for a secondary "Master Password" (or uses the login password) to decrypt the Private Key locally in memory.
    -   **Result**: The server never sees the raw Private Key.

3.  **Secure Storage on Device**:
    -   Use `flutter_secure_storage` to store session keys and the decrypted Master Key temporarily while the app is open.
    -   Clear keys from memory on logout or backgrounding.

## 2. Secure Nominee Access Protocol (The "Digital Handover")

How do we let a Nominee see the file without giving the server the key? We use **Asymmetric Cryptography**.

### The Workflow
1.  **User A (Owner)** and **User B (Nominee)** both have Keypairs generated upon account creation.
2.  **Access Granter**:
    -   User A uploads a file. The app encrypts it with a random `File Key`.
    -   User A's app fetches User B's **Public Key** from the server.
    -   User A's app encrypts the `File Key` using User B's **Public Key**.
    -   This "Wrapped Key" is uploaded to a new `document_access` table.
3.  **Access Retriever**:
    -   User B logs in.
    -   User B downloads the "Wrapped Key".
    -   User B uses their own **Private Key** to decrypt it, revealing the original `File Key`.
    -   User B uses the `File Key` to decrypt and view the document.

**Result**: The server holds the file and the key, but both are encrypted in a way the server cannot unlock.

## 3. "Best AI" Features: Privacy-First Intelligence

### A. AI Will Drafter (Islamic Inheritance / Faraid Calculator)
*   **Goal**: Help users draft a legally compliant Will without sharing PII.
*   **Implementation**:
    -   Integrate OpenAI/Gemini API or a specialized legal AI model.
    -   **Privacy Filter**: The app sends *only* structure data (e.g., "Wife: 1, Sons: 2, Daughters: 1, Assets: 100k") to the AI.
    -   **Output**: The AI returns a drafted legal text with correct Faraid shares. The user fills in the names locally on their device.

### B. On-Device OCR & Document Analysis
*   **Goal**: Auto-organize documents without sending them to the cloud for processing.
*   **Technology**: **Google ML Kit (On-Device)** for Flutter.
*   **Workflow**:
    -   User takes a photo of a deed.
    -   ML Kit runs locally to extract text.
    -   App analyzes keywords (e.g., "Life Insurance", "Property Deed") to suggest a Folder category.
    -   This metadata is encrypted before syncing.

## 4. Additional Feature Recommendations

### 🛑 "Dead Man's Switch" (Inactivity Trigger)
*   **Concept**: An automated system to ensure nominees get access only when necessary.
*   **How it works**:
    -   User sets a check-in period (e.g., every 3 months).
    -   App prompts user to "Check In" via notification.
    -   If user fails to check in after the grace period (e.g., +1 month), the system assumes the user is incapacitated/deceased.
    -   **Action**: The server automatically releases the pre-encrypted "Wrapped Keys" to the Nominees.
*   **Security**: The server *needs* to hold these keys in escrow, but they are encrypted with the Nominee's Public Key, so the server still can't read them.

### 🎥 Vasiyat-e-Video (Encrypted Video Will)
*   **Concept**: A personal, emotional message for family members, essentially a "Video Will".
*   **Implementation**: Same E2EE encryption as documents. Use chunks to stream encrypted video data securely.

### ⛓️ Blockchain Timestamping (Tamper-Proofing)
*   **Concept**: Prove *exactly when* a Will was created and that it hasn't been altered.
*   **How it works**:
    -   Calculate a SHA-256 Hash of the final PDF.
    -   Submit this Hash to a public blockchain (e.g., Polygon/Ethereum) via a smart contract.
    -   **Benefit**: In a legal dispute, this proves the document existed in that exact form at that date.

### 🛡️ Multi-Factor Authentication (MFA)
*   **Requirement**: Mandatory for accessing the "Vault".
*   **Type**: Time-based One-Time Password (TOTP) like Google Authenticator, or SMS-based if budget permits.

## 5. Technical Implementation Roadmap

### Required Flutter Packages
Add these to `pubspec.yaml`:

```yaml
dependencies:
  # Encryption
  encrypt: ^5.0.3        # For AES encryption
  pointycastle: ^3.9.1   # For RSA/ECC Key generation & handling
  crypto: ^3.0.3         # Hashing

  # Secure Storage
  flutter_secure_storage: ^9.2.2  # Store keys safely on device
  local_auth: ^2.2.0              # FaceID / Fingerprint

  # AI & OCR
  google_mlkit_text_recognition: ^0.13.0 # On-device OCR
  google_generative_ai: ^0.4.0           # For Will Drafting Assistant

  # Utilities
  uuid: ^4.4.0
  path_provider: ^2.1.3
```

### Database Schema Changes (Backend)

**New Table: `user_keys`**
- `user_id` (FK)
- `public_key` (Text)
- `encrypted_private_key` (Text - Encrypted with User Password)

**New Table: `document_access`**
- `id` (PK)
- `document_id` (FK)
- `user_id` (FK - The person who is granted access)
- `encrypted_file_key` (Text - The AES key, encrypted with receiver's Public Key)

### API Updates
- **`POST /keys/upload`**: Store the user's public/encrypted-private keys.
- **`GET /keys/{user_id}`**: Fetch a user's Public Key (to share a file with them).
- **`POST /document/share`**: Upload the encrypted key for a specific nominee.
