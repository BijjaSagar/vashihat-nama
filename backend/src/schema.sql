-- Enable UUID extension if needed (good for distributed IDs, but serial is fine for now)

-- 1. Users Table
CREATE TABLE IF NOT EXISTS users (
  id SERIAL PRIMARY KEY,
  firebase_uid VARCHAR(128) UNIQUE, -- Make optional or keep for legacy/compatibility
  mobile_number VARCHAR(15) UNIQUE NOT NULL, -- Added for SMS Auth
  email VARCHAR(255) UNIQUE, -- Added for profile
  name VARCHAR(255), -- Added for profile
  public_key TEXT, -- Made optional until key generation step
  encrypted_private_key TEXT, -- Made optional until key generation step
  created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- 2. Folders Table (Optional, for organizing)
CREATE TABLE IF NOT EXISTS folders (
  id SERIAL PRIMARY KEY,
  user_id INTEGER REFERENCES users(id) ON DELETE CASCADE,
  name VARCHAR(255) NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- 3. Files Table (Stores encrypted blob references)
CREATE TABLE IF NOT EXISTS files (
  id SERIAL PRIMARY KEY,
  user_id INTEGER REFERENCES users(id) ON DELETE CASCADE,
  folder_id INTEGER REFERENCES folders(id),
  file_name VARCHAR(255) NOT NULL,
  storage_path VARCHAR(512) NOT NULL, -- S3/Blob Path
  file_size BIGINT,
  mime_type VARCHAR(100),
  
  -- The file's AES Key, Encrypted with the User's Public Key.
  -- Only the user (with their Private Key) can decrypt this to get the AES key, 
  -- and then decrypt the actual file content.
  encrypted_file_key TEXT NOT NULL, 
  
  created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- 4. Nominees Table
CREATE TABLE IF NOT EXISTS nominees (
  id SERIAL PRIMARY KEY,
  user_id INTEGER REFERENCES users(id) ON DELETE CASCADE,
  name VARCHAR(255) NOT NULL,
  email VARCHAR(255) NOT NULL,
  relationship VARCHAR(100),
  primary_mobile VARCHAR(15) NOT NULL,
  optional_mobile VARCHAR(15),
  address TEXT NOT NULL,
  identity_proof VARCHAR(100) NOT NULL, -- Aadhaar, Passport, etc.
  hand_delivery_rules TEXT, -- Special instructions for hand delivery
  
  -- Nominee's own RSA Public Key (if they have an account).
  nominee_public_key TEXT, 
  
  access_granted BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- 5. File Permissions (Sharing Keys)
CREATE TABLE IF NOT EXISTS file_permissions (
  id SERIAL PRIMARY KEY,
  file_id INTEGER REFERENCES files(id) ON DELETE CASCADE,
  nominee_id INTEGER REFERENCES nominees(id) ON DELETE CASCADE,
  
  -- The file's AES Key, Encrypted with the Nominee's Public Key.
  -- This allows the nominee to decrypt the file without the user's private key.
  encrypted_file_key_for_nominee TEXT NOT NULL,
  
  created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
  UNIQUE(file_id, nominee_id)
);

-- 6. OTP Verifications (Active OTPs)
CREATE TABLE IF NOT EXISTS otp_verifications (
    id SERIAL PRIMARY KEY,
    mobile VARCHAR(15) NOT NULL,
    otp_hash VARCHAR(255) NOT NULL,
    purpose VARCHAR(50) NOT NULL DEFAULT 'login', -- login, register
    attempts INT DEFAULT 0,
    expires_at TIMESTAMP WITH TIME ZONE NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);
CREATE INDEX IF NOT EXISTS idx_mobile_purpose ON otp_verifications (mobile, purpose);

-- 7. OTP Logs (Audit)
CREATE TABLE IF NOT EXISTS otp_logs (
    id SERIAL PRIMARY KEY,
    mobile VARCHAR(15) NOT NULL,
    purpose VARCHAR(50) NOT NULL,
    status VARCHAR(20) NOT NULL, -- sent, verified, failed, expired
    ip_address VARCHAR(45),
    details TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);
-- 8. Regional Checklists
CREATE TABLE IF NOT EXISTS regional_checklists (
    id SERIAL PRIMARY KEY,
    country_code VARCHAR(10) NOT NULL,
    country_name VARCHAR(100) NOT NULL,
    document_name VARCHAR(255) NOT NULL,
    description TEXT,
    is_mandatory BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- 9. User Selected Regional Documents
CREATE TABLE IF NOT EXISTS user_regional_docs (
    id SERIAL PRIMARY KEY,
    user_id INTEGER REFERENCES users(id) ON DELETE CASCADE,
    checklist_id INTEGER REFERENCES regional_checklists(id),
    status VARCHAR(50) DEFAULT 'pending', -- pending, uploaded, verified
    file_path VARCHAR(512),
    details JSONB,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);
