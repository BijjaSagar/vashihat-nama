"use strict";
var __awaiter = (this && this.__awaiter) || function (thisArg, _arguments, P, generator) {
    function adopt(value) { return value instanceof P ? value : new P(function (resolve) { resolve(value); }); }
    return new (P || (P = Promise))(function (resolve, reject) {
        function fulfilled(value) { try { step(generator.next(value)); } catch (e) { reject(e); } }
        function rejected(value) { try { step(generator["throw"](value)); } catch (e) { reject(e); } }
        function step(result) { result.done ? resolve(result.value) : adopt(result.value).then(fulfilled, rejected); }
        step((generator = generator.apply(thisArg, _arguments || [])).next());
    });
};
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.initDb = void 0;
const pg_1 = require("pg");
const dotenv_1 = __importDefault(require("dotenv"));
dotenv_1.default.config();
const pool = new pg_1.Pool(process.env.DATABASE_URL
    ? {
        connectionString: process.env.DATABASE_URL,
        ssl: { rejectUnauthorized: false }
    }
    : {
        user: process.env.DB_USER || 'postgres',
        host: process.env.DB_HOST || 'localhost',
        database: process.env.DB_NAME || 'vasihat_nama',
        password: process.env.DB_PASSWORD || 'password',
        port: parseInt(process.env.DB_PORT || '5432'),
    });
pool.on('error', (err) => {
    console.error('Unexpected error on idle client', err);
    process.exit(-1);
});
const initDb = () => __awaiter(void 0, void 0, void 0, function* () {
    const client = yield pool.connect();
    try {
        const schema = `
-- 1. Users Table
CREATE TABLE IF NOT EXISTS users (
  id SERIAL PRIMARY KEY,
  firebase_uid VARCHAR(128) UNIQUE, 
  mobile_number VARCHAR(15) UNIQUE NOT NULL, 
  email VARCHAR(255) UNIQUE, 
  name VARCHAR(255), 
  public_key TEXT, 
  encrypted_private_key TEXT, 
  created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- 2. Folders Table
CREATE TABLE IF NOT EXISTS folders (
  id SERIAL PRIMARY KEY,
  user_id INTEGER REFERENCES users(id) ON DELETE CASCADE,
  name VARCHAR(255) NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- 3. Files Table
CREATE TABLE IF NOT EXISTS files (
  id SERIAL PRIMARY KEY,
  user_id INTEGER REFERENCES users(id) ON DELETE CASCADE,
  folder_id INTEGER REFERENCES folders(id),
  file_name VARCHAR(255) NOT NULL,
  storage_path VARCHAR(512) NOT NULL,
  file_size BIGINT,
  mime_type VARCHAR(100),
  encrypted_file_key TEXT NOT NULL, 
  created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- 4. Vault Items Table (for notes, passwords, credit cards, etc.)
CREATE TABLE IF NOT EXISTS vault_items (
  id SERIAL PRIMARY KEY,
  user_id INTEGER REFERENCES users(id) ON DELETE CASCADE,
  folder_id INTEGER REFERENCES folders(id) ON DELETE CASCADE,
  item_type VARCHAR(50) NOT NULL, -- 'note', 'password', 'credit_card', 'file'
  title VARCHAR(255) NOT NULL,
  encrypted_data TEXT NOT NULL, -- JSON encrypted data containing item-specific fields
  created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);
CREATE INDEX IF NOT EXISTS idx_vault_items_user_folder ON vault_items (user_id, folder_id);
CREATE INDEX IF NOT EXISTS idx_vault_items_type ON vault_items (item_type);

-- 5. Nominees Table
CREATE TABLE IF NOT EXISTS nominees (
  id SERIAL PRIMARY KEY,
  user_id INTEGER REFERENCES users(id) ON DELETE CASCADE,
  name VARCHAR(255) NOT NULL,
  email VARCHAR(255) NOT NULL,
  primary_mobile VARCHAR(15), -- Standardized to primary_mobile
  optional_mobile VARCHAR(15),
  relationship VARCHAR(100),
  nominee_public_key TEXT, 
  access_granted BOOLEAN DEFAULT FALSE,
  handover_waiting_days INTEGER DEFAULT 0, -- 0 means immediate
  require_otp_for_access BOOLEAN DEFAULT FALSE,
  handover_triggered_at TIMESTAMP WITH TIME ZONE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Migration for advanced rules
ALTER TABLE nominees ADD COLUMN IF NOT EXISTS handover_waiting_days INTEGER DEFAULT 0;
ALTER TABLE nominees ADD COLUMN IF NOT EXISTS require_otp_for_access BOOLEAN DEFAULT FALSE;
ALTER TABLE nominees ADD COLUMN IF NOT EXISTS handover_triggered_at TIMESTAMP WITH TIME ZONE;


-- Migration for existing installs
ALTER TABLE nominees ADD COLUMN IF NOT EXISTS primary_mobile VARCHAR(15);
ALTER TABLE nominees ADD COLUMN IF NOT EXISTS optional_mobile VARCHAR(15);

-- 6. File Permissions
CREATE TABLE IF NOT EXISTS file_permissions (
  id SERIAL PRIMARY KEY,
  file_id INTEGER REFERENCES files(id) ON DELETE CASCADE,
  nominee_id INTEGER REFERENCES nominees(id) ON DELETE CASCADE,
  encrypted_file_key_for_nominee TEXT NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
  UNIQUE(file_id, nominee_id)
);

-- 7. OTP Verifications
CREATE TABLE IF NOT EXISTS otp_verifications (
    id SERIAL PRIMARY KEY,
    mobile VARCHAR(15) NOT NULL,
    otp_hash VARCHAR(255) NOT NULL,
    purpose VARCHAR(50) NOT NULL DEFAULT 'login',
    attempts INT DEFAULT 0,
    expires_at TIMESTAMP WITH TIME ZONE NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);
CREATE INDEX IF NOT EXISTS idx_mobile_purpose ON otp_verifications (mobile, purpose);

-- 8. OTP Logs
CREATE TABLE IF NOT EXISTS otp_logs (
    id SERIAL PRIMARY KEY,
    mobile VARCHAR(15) NOT NULL,
    purpose VARCHAR(50) NOT NULL,
    status VARCHAR(20) NOT NULL,
    ip_address VARCHAR(45),
    details TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- 9. Smart Docs Table (Stores extracted intelligence)
CREATE TABLE IF NOT EXISTS smart_docs (
    id SERIAL PRIMARY KEY,
    user_id INTEGER REFERENCES users(id) ON DELETE CASCADE,
    file_id INTEGER REFERENCES files(id) ON DELETE SET NULL,
    doc_type VARCHAR(100) NOT NULL, -- 'Insurance', 'Passport', 'License', 'Warranty'
    doc_number VARCHAR(100), -- Extracted Policy/ID Number
    expiry_date TIMESTAMP WITH TIME ZONE,
    renewal_date TIMESTAMP WITH TIME ZONE,
    issuing_authority VARCHAR(255),
    reminder_enabled BOOLEAN DEFAULT TRUE,
    notes TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);
CREATE INDEX IF NOT EXISTS idx_smart_docs_user ON smart_docs (user_id);
CREATE INDEX IF NOT EXISTS idx_smart_docs_expiry ON smart_docs (expiry_date);

-- 10. Update Users Table for Heartbeat and Admin/Subscription
ALTER TABLE users 
ADD COLUMN IF NOT EXISTS last_check_in TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
ADD COLUMN IF NOT EXISTS check_in_frequency_days INTEGER DEFAULT 30,
ADD COLUMN IF NOT EXISTS check_in_frequency_hours INTEGER DEFAULT 0,
ADD COLUMN IF NOT EXISTS check_in_frequency_minutes INTEGER DEFAULT 0,
ADD COLUMN IF NOT EXISTS dead_mans_switch_active BOOLEAN DEFAULT FALSE,
ADD COLUMN IF NOT EXISTS is_admin BOOLEAN DEFAULT FALSE,
ADD COLUMN IF NOT EXISTS subscription_plan VARCHAR(50) DEFAULT 'free',
ADD COLUMN IF NOT EXISTS subscription_expires_at TIMESTAMP WITH TIME ZONE,
ADD COLUMN IF NOT EXISTS storage_limit_gb DECIMAL DEFAULT 1.0,
ADD COLUMN IF NOT EXISTS current_storage_bytes BIGINT DEFAULT 0;

-- 11. Heartbeat Logs
CREATE TABLE IF NOT EXISTS heartbeat_logs (
    id SERIAL PRIMARY KEY,
    user_id INTEGER REFERENCES users(id) ON DELETE CASCADE,
    checked_in_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    method VARCHAR(50) DEFAULT 'manual'
);

-- 12. Payments Table
CREATE TABLE IF NOT EXISTS payments (
    id SERIAL PRIMARY KEY,
    user_id INTEGER REFERENCES users(id) ON DELETE CASCADE,
    amount DECIMAL(12, 2) NOT NULL,
    currency VARCHAR(10) DEFAULT 'INR',
    provider VARCHAR(50) NOT NULL, -- razorpay, paypal, stripe
    transaction_id VARCHAR(255) UNIQUE,
    status VARCHAR(50) DEFAULT 'pending', -- pending, success, failed
    plan_id VARCHAR(50),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);
CREATE INDEX IF NOT EXISTS idx_payments_user ON payments (user_id);
CREATE INDEX IF NOT EXISTS idx_payments_status ON payments (status);

-- 13. Smart Documents Table (Scanning + Alerts)
CREATE TABLE IF NOT EXISTS smart_docs (
    id SERIAL PRIMARY KEY,
    user_id INTEGER REFERENCES users(id) ON DELETE CASCADE,
    file_id INTEGER REFERENCES files(id) ON DELETE SET NULL,
    doc_type VARCHAR(50) NOT NULL, -- passport, license, visa, insurance
    doc_number VARCHAR(100),
    title VARCHAR(255), -- User provided notes
    expiry_date DATE NOT NULL,
    renewal_date DATE,
    issuing_authority VARCHAR(255),
    notes TEXT,
    reminder_days_before INTEGER DEFAULT 30,
    is_reminded BOOLEAN DEFAULT FALSE,
    s3_key VARCHAR(255), 
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);
CREATE INDEX IF NOT EXISTS idx_smart_docs_user ON smart_docs (user_id);
CREATE INDEX IF NOT EXISTS idx_smart_docs_expiry ON smart_docs (expiry_date);


-- Migration for payments table (ensuring columns exist)
ALTER TABLE payments ADD COLUMN IF NOT EXISTS provider VARCHAR(50);
ALTER TABLE payments ADD COLUMN IF NOT EXISTS transaction_id VARCHAR(255);
ALTER TABLE payments ADD COLUMN IF NOT EXISTS plan_id VARCHAR(50);
        `;
        yield client.query(schema);
        console.log('Database initialized successfully');
    }
    catch (err) {
        console.error('Error initializing database', err);
    }
    finally {
        client.release();
    }
});
exports.initDb = initDb;
exports.default = {
    query: (text, params) => pool.query(text, params),
};
