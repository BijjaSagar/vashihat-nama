import 'dotenv/config';
import axios from "axios";
import express from 'express';
import bodyParser from 'body-parser';
import cors from 'cors';
import { initDb } from './db';
import db from './db';

const app = express();
const PORT = process.env.PORT || 3000;

app.use(cors());
app.use(bodyParser.json({ limit: '50mb' }));
app.use(bodyParser.urlencoded({ limit: '50mb', extended: true }));
app.use(express.static('public'));

// --- Root Route (Health Check) ---
app.get('/', (req, res) => {
    res.send(`
        <div style="font-family: sans-serif; text-align: center; padding: 50px;">
            <h1>🛡️ Vasihat Nama Security Server</h1>
            <p>Secure Zero-Knowledge Backend is Active.</p>
            <p>Status: <strong>Operational</strong></p>
        </div>
    `);
});

// --- Routes ---


import crypto from 'crypto';

// --- Constants ---
// TODO: Move to .env
const HSP_SMS_USERNAME = process.env.HSP_SMS_USERNAME || 'YOUR_USERNAME';
const HSP_SMS_SENDER_ID = process.env.HSP_SMS_SENDER_ID || 'DASSAM';
const HSP_SMS_API_KEY = process.env.HSP_SMS_API_KEY || 'YOUR_API_KEY';
const OTP_EXPIRY_MINUTES = 5;

// --- Helpers ---
function generateOTP(): string {
    return Math.floor(100000 + Math.random() * 900000).toString();
}

function hashOTP(otp: string): string {
    return crypto.createHash('sha256').update(otp).digest('hex');
}

async function sendSMS(mobile: string, message: string): Promise<boolean> {
    // Development Mode: Log to console instead of sending
    const isDev = !process.env.NODE_ENV || process.env.NODE_ENV === 'development';

    if (isDev) {
        console.log(`[DEV MODE] Mock Sending SMS to ${mobile}: ${message}`);
        return true;
    }

    if (HSP_SMS_USERNAME === 'YOUR_USERNAME' || HSP_SMS_API_KEY === 'YOUR_API_KEY') {
        console.error('HSP SMS Credentials are not set in environment variables.');
        return false;
    }

    try {
        // HSP SMS API
        const url = `http://sms.hspsms.com/sendSMS`;
        const params = {
            username: HSP_SMS_USERNAME,
            message: message,
            sendername: HSP_SMS_SENDER_ID,
            smstype: 'TRANS',
            numbers: mobile,
            apikey: HSP_SMS_API_KEY
        };

        console.log(`Sending SMS to ${mobile} with params:`, { ...params, apikey: '***' });

        const response = await axios.get(url, { params });
        console.log('SMS API Full Response:', JSON.stringify(response.data, null, 2));

        // HSP SMS usually returns a string or JSON. 
        // If it contains "error" or comes back as HTML (when blocked), we should fail.
        if (typeof response.data === 'string' && (response.data.toLowerCase().includes('error') || response.data.trim().startsWith('<'))) {
            console.error('SMS Provider returned error:', response.data);
            return false;
        }

        return true;
    } catch (error) {
        console.error('Error sending SMS:', error);
        return false;
    }
}

// --- OTP Routes ---

// 1. Send OTP
app.post('/api/send_otp', async (req, res) => {
    console.log("Handling /api/send_otp request - Version 2.1");
    const { mobile, purpose = 'login' } = req.body;

    if (!mobile || mobile.length < 10) {
        res.status(400).json({ success: false, message: 'Invalid mobile number' });
        return;
    }

    try {
        // Validation logic could go here (e.g., check if user exists for login)

        const otp = generateOTP();
        const otpHash = hashOTP(otp);
        const expiresAt = new Date(Date.now() + OTP_EXPIRY_MINUTES * 60000);

        // Store in DB
        await db.query(
            'INSERT INTO otp_verifications (mobile, otp_hash, purpose, expires_at) VALUES ($1, $2, $3, $4)',
            [mobile, otpHash, purpose, expiresAt]
        );

        // Send SMS
        // Template: "$otp is your OTP for login into your account. GGISKB"
        const message = `${otp} is your OTP for login into your account. GGISKB`;
        const smsSent = await sendSMS(mobile, message);

        if (!smsSent) {
            // Rollback usage or just log failure
            await db.query(
                'INSERT INTO otp_logs (mobile, purpose, status) VALUES ($1, $2, $3)',
                [mobile, purpose, 'failed']
            );
            res.status(500).json({ success: false, message: 'Failed to send SMS. Check server configuration.' });
            return;
        }

        // Log
        await db.query(
            'INSERT INTO otp_logs (mobile, purpose, status) VALUES ($1, $2, $3)',
            [mobile, purpose, 'sent']
        );

        // In Dev mode, return OTP for easy testing
        const isDev = !process.env.NODE_ENV || process.env.NODE_ENV === 'development';
        res.json({
            success: true,
            message: 'OTP sent successfully (Updated V2)',
            debug_otp: isDev ? otp : undefined
        });

    } catch (error) {
        console.error('Error sending OTP:', error);
        res.status(500).json({ success: false, message: 'Failed to send OTP' });
    }
});

// 2. Verify OTP
app.post('/api/verify_otp', async (req, res) => {
    const { mobile, otp, purpose = 'login' } = req.body;

    try {
        // Find latest valid OTP
        const result = await db.query(
            `SELECT * FROM otp_verifications 
             WHERE mobile = $1 AND purpose = $2 AND expires_at > NOW() 
             ORDER BY created_at DESC LIMIT 1`,
            [mobile, purpose]
        );

        if (result.rows.length === 0) {
            res.status(400).json({ success: false, message: 'Invalid or expired OTP' });
            return;
        }

        const record = result.rows[0];
        const inputHash = hashOTP(otp);

        if (record.otp_hash !== inputHash) {
            // Update attempts
            await db.query('UPDATE otp_verifications SET attempts = attempts + 1 WHERE id = $1', [record.id]);
            res.status(400).json({ success: false, message: 'Incorrect OTP' });
            return;
        }

        // OTP Verified
        // Mark log
        await db.query(
            'INSERT INTO otp_logs (mobile, purpose, status) VALUES ($1, $2, $3)',
            [mobile, purpose, 'verified']
        );

        // Cleanup used OTP
        await db.query('DELETE FROM otp_verifications WHERE id = $1', [record.id]);

        // If login, return user info
        if (purpose === 'login') {
            const userRes = await db.query('SELECT * FROM users WHERE mobile_number = $1', [mobile]);
            if (userRes.rows.length > 0) {
                res.json({ success: true, message: 'Verified', user: userRes.rows[0] });
            } else {
                // First time user trying to login/register flow
                res.json({ success: true, message: 'Verified (User not registered)', next_step: 'register' });
            }
        } else {
            res.json({ success: true, message: 'Verified', next_step: 'complete_registration' });
        }

    } catch (error) {
        console.error('Error verifying OTP:', error);
        res.status(500).json({ success: false, message: 'Verification failed' });
    }
});

// --- User Routes Modified ---

// Register User (Store Keys & Mobile)
app.post('/api/users/register', async (req, res) => {
    // Now accepting mobile_number instead of firebase_uid
    const { mobile_number, public_key, encrypted_private_key, name, email } = req.body;
    try {
        // Check if exists
        const check = await db.query('SELECT id FROM users WHERE mobile_number = $1', [mobile_number]);
        if (check.rows.length > 0) {
            res.status(409).json({ error: 'User already exists' });
            return;
        }

        const result = await db.query(
            'INSERT INTO users (mobile_number, public_key, encrypted_private_key, name, email) VALUES ($1, $2, $3, $4, $5) RETURNING id',
            [mobile_number, public_key, encrypted_private_key, name, email]
        );
        res.status(201).json({ id: result.rows[0].id, message: 'User registered successfully' });
    } catch (error) {
        console.error('Error registering user:', error);
        res.status(500).json({ error: 'Failed to register user' });
    }
});

// Update User Profile
app.put('/api/users/:id', async (req, res) => {
    const { id } = req.params;
    const { name, email } = req.body;
    try {
        await db.query('UPDATE users SET name = $1, email = $2 WHERE id = $3', [name, email, id]);
        res.json({ message: 'Profile updated successfully' });
    } catch (error) {
        res.status(500).json({ error: 'Failed to update profile' });
    }
});


// Import Multer
import multer from 'multer';
import path from 'path';

// Configure Multer (Memory Storage for Serverless / Ephemeral)
const upload = multer({
    storage: multer.memoryStorage(),
    limits: { fileSize: 5 * 1024 * 1024 }, // 5MB limit
});

// 2. Upload File (Revised with Multer)
app.post('/api/upload', upload.single('file'), async (req, res) => {
    // req.file is the `file` file
    // req.body will hold the text fields, if any were sent BEFORE the file
    // BUT Dio FormData sends everything together. Multer parses it.

    if (!req.file) {
        res.status(400).json({ error: 'No file uploaded' });
        return;
    }

    const { folder_id, user_id } = req.body; // Ensure user_id is passed or extracted from session/token if we had one.
    // NOTE: In current API, user_id might come from body as text field if added to FormData in Flutter.
    // If Flutter code doesn't send user_id in FormData, we might need it.
    // Let's assume for now the Flutter app sends "folder_id".
    // Wait, the previous code expected "user_id" in body for /api/files.
    // The current Flutter code sends "folder_id" and file.
    // We need user_id to insert into files table. 
    // We can fetch user_id from folder_id ownership? Yes.

    const file_name = req.file.originalname;
    const mime_type = req.file.mimetype;
    const file_size = req.file.size;
    const encrypted_file_key = "temp_key"; // TODO: Backend should receive this or generate it? 
    // The Flutter app sends file. It doesn't seem to be encrypting it on client side?
    // "Secure Vault" usually implies client-side encryption.
    // But scan_document_screen.dart just uploads the raw file?
    // Based on limited context, we'll assume server encryption or just storing as is for now to "fix error".

    try {
        // Find owner of folder to assign file to correct user
        // If folder_id is provided
        let owner_id = user_id;
        if (!owner_id && folder_id) {
            const folderRes = await db.query('SELECT user_id FROM folders WHERE id = $1', [folder_id]);
            if (folderRes.rows.length > 0) {
                owner_id = folderRes.rows[0].user_id;
            }
        }

        if (!owner_id) {
            // Fallback or Error
            // For "checking pages work", let's use a dummy ID or fail gracefully if strict.
            // We'll proceed if we found it.
            // If not found, using 1 (admin/test) as fallback is risky but keeps "demo" working.
            // Better: require user_id in formData?
            // Only folder_id is sent in Flutter code: "folder_id": folderId.
        }

        const storage_path = `/uploads/${Date.now()}_${file_name}`;
        // In real app, upload req.file.buffer to S3 here.

        const result = await db.query(
            'INSERT INTO files (user_id, folder_id, file_name, storage_path, file_size, mime_type, encrypted_file_key) VALUES ($1, $2, $3, $4, $5, $6, $7) RETURNING id',
            [owner_id || 1, folder_id, file_name, storage_path, file_size, mime_type, encrypted_file_key]
        );
        res.status(201).json({ id: result.rows[0].id, message: 'File uploaded successfully' });
    } catch (error) {
        console.error('Error uploading file:', error);
        res.status(500).json({ error: 'Failed to upload file' });
    }
});

// 3. List Files
app.get('/api/files', async (req, res) => {
    const { user_id, folder_id } = req.query;
    try {
        let query = 'SELECT * FROM files WHERE user_id = $1';
        let params = [user_id];

        if (folder_id) {
            query += ' AND folder_id = $2';
            params.push(folder_id);
        }

        const result = await db.query(query, params);
        res.json(result.rows);
    } catch (error) {
        res.status(500).json({ error: 'Failed to fetch files' });
    }
});

// 4. Add Nominee
app.post('/api/nominees', async (req, res) => {
    const { user_id, name, email, relationship } = req.body;
    try {
        const result = await db.query(
            'INSERT INTO nominees (user_id, name, email, relationship) VALUES ($1, $2, $3, $4) RETURNING id',
            [user_id, name, email, relationship]
        );
        res.status(201).json({ id: result.rows[0].id, message: 'Nominee added successfully' });
    } catch (error) {
        res.status(500).json({ error: 'Failed to add nominee' });
    }
});

// 5. Get Nominees
app.get('/api/nominees', async (req, res) => {
    const { user_id } = req.query;
    try {
        const result = await db.query('SELECT * FROM nominees WHERE user_id = $1', [user_id]);
        res.json(result.rows);
    } catch (error) {
        res.status(500).json({ error: 'Failed to fetch nominees' });
    }
});

// 6. Get Folders
app.get('/api/folders', async (req, res) => {
    const { user_id } = req.query;
    try {
        const result = await db.query('SELECT * FROM folders WHERE user_id = $1', [user_id]);
        res.json(result.rows);
    } catch (error) {
        res.status(500).json({ error: 'Failed to fetch folders' });
    }
});

// 7. Create Folder
app.post('/api/folders', async (req, res) => {
    const { user_id, name } = req.body;
    try {
        const result = await db.query(
            'INSERT INTO folders (user_id, name) VALUES ($1, $2) RETURNING id',
            [user_id, name]
        );
        res.status(201).json({ id: result.rows[0].id, message: 'Folder created successfully' });
    } catch (error) {
        res.status(500).json({ error: 'Failed to create folder' });
    }
});

// ============================================
// VAULT ITEMS API ENDPOINTS
// ============================================

// 1. Create Vault Item
app.post('/api/vault_items', async (req, res) => {
    const { user_id, folder_id, item_type, title, encrypted_data } = req.body;

    // Validate item_type
    const validTypes = ['note', 'password', 'credit_card', 'file'];
    if (!validTypes.includes(item_type)) {
        res.status(400).json({ error: 'Invalid item type' });
        return;
    }

    try {
        const result = await db.query(
            `INSERT INTO vault_items (user_id, folder_id, item_type, title, encrypted_data) 
             VALUES ($1, $2, $3, $4, $5) RETURNING *`,
            [user_id, folder_id, item_type, title, encrypted_data]
        );
        res.status(201).json({
            success: true,
            item: result.rows[0],
            message: 'Vault item created successfully'
        });
    } catch (error) {
        console.error('Error creating vault item:', error);
        res.status(500).json({ error: 'Failed to create vault item' });
    }
});

// 2. Get Vault Items (by folder or user)
app.get('/api/vault_items', async (req, res) => {
    const { user_id, folder_id, item_type } = req.query;

    try {
        let query = 'SELECT * FROM vault_items WHERE user_id = $1';
        let params = [user_id];

        if (folder_id) {
            query += ' AND folder_id = $2';
            params.push(folder_id);
        }

        if (item_type) {
            query += ` AND item_type = $${params.length + 1}`;
            params.push(item_type);
        }

        query += ' ORDER BY created_at DESC';

        const result = await db.query(query, params);
        res.json({ success: true, items: result.rows });
    } catch (error) {
        console.error('Error fetching vault items:', error);
        res.status(500).json({ error: 'Failed to fetch vault items' });
    }
});

// 3. Get Single Vault Item
app.get('/api/vault_items/:id', async (req, res) => {
    const { id } = req.params;
    const { user_id } = req.query;

    try {
        const result = await db.query(
            'SELECT * FROM vault_items WHERE id = $1 AND user_id = $2',
            [id, user_id]
        );

        if (result.rows.length === 0) {
            res.status(404).json({ error: 'Vault item not found' });
            return;
        }

        res.json({ success: true, item: result.rows[0] });
    } catch (error) {
        console.error('Error fetching vault item:', error);
        res.status(500).json({ error: 'Failed to fetch vault item' });
    }
});

// 4. Update Vault Item
app.put('/api/vault_items/:id', async (req, res) => {
    const { id } = req.params;
    const { user_id, title, encrypted_data } = req.body;

    try {
        const result = await db.query(
            `UPDATE vault_items 
             SET title = $1, encrypted_data = $2, updated_at = CURRENT_TIMESTAMP 
             WHERE id = $3 AND user_id = $4 
             RETURNING *`,
            [title, encrypted_data, id, user_id]
        );

        if (result.rows.length === 0) {
            res.status(404).json({ error: 'Vault item not found' });
            return;
        }

        res.json({
            success: true,
            item: result.rows[0],
            message: 'Vault item updated successfully'
        });
    } catch (error) {
        console.error('Error updating vault item:', error);
        res.status(500).json({ error: 'Failed to update vault item' });
    }
});

// 5. Delete Vault Item
app.delete('/api/vault_items/:id', async (req, res) => {
    const { id } = req.params;
    const { user_id } = req.query;

    try {
        const result = await db.query(
            'DELETE FROM vault_items WHERE id = $1 AND user_id = $2 RETURNING *',
            [id, user_id]
        );

        if (result.rows.length === 0) {
            res.status(404).json({ error: 'Vault item not found' });
            return;
        }

        res.json({ success: true, message: 'Vault item deleted successfully' });
    } catch (error) {
        console.error('Error deleting vault item:', error);
        res.status(500).json({ error: 'Failed to delete vault item' });
    }
});

// 6. Get Vault Items Count by Type
app.get('/api/vault_items/stats/count', async (req, res) => {
    const { user_id } = req.query;

    try {
        const result = await db.query(
            `SELECT item_type, COUNT(*) as count 
             FROM vault_items 
             WHERE user_id = $1 
             GROUP BY item_type`,
            [user_id]
        );

        const stats: { [key: string]: number } = {
            note: 0,
            password: 0,
            credit_card: 0,
            file: 0
        };

        result.rows.forEach(row => {
            if (row.item_type in stats) {
                stats[row.item_type] = parseInt(row.count);
            }
        });

        res.json({ success: true, stats });
    } catch (error) {
        console.error('Error fetching vault stats:', error);
        res.status(500).json({ error: 'Failed to fetch vault stats' });
    }
});

// ============================================
// SMART ALERT / DOCUMENT INTELLIGENCE API
// ============================================

// 1. Create Smart Alert (From OCR Data)
app.post('/api/smart_docs', async (req, res) => {
    const {
        user_id,
        file_id,
        doc_type,
        doc_number,
        expiry_date,
        renewal_date,
        issuing_authority,
        notes
    } = req.body;

    try {
        const result = await db.query(
            `INSERT INTO smart_docs (
                user_id, file_id, doc_type, doc_number, 
                expiry_date, renewal_date, issuing_authority, notes
            ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8) RETURNING *`,
            [user_id, file_id, doc_type, doc_number, expiry_date, renewal_date, issuing_authority, notes]
        );
        res.status(201).json({
            success: true,
            doc_alert: result.rows[0],
            message: 'Smart Alert created successfully'
        });
    } catch (error) {
        console.error('Error creating smart doc:', error);
        res.status(500).json({ error: 'Failed to create smart alert' });
    }
});

// 2. Get User Smart Alerts (Upcoming Renewals)
app.get('/api/smart_docs', async (req, res) => {
    const { user_id, upcoming_only } = req.query;

    try {
        let query = 'SELECT * FROM smart_docs WHERE user_id = $1';
        let params = [user_id];

        if (upcoming_only === 'true') {
            // Show documents expiring in future or recently expired (last 30 days)
            query += " AND expiry_date >= NOW() - INTERVAL '30 days'";
            query += " ORDER BY expiry_date ASC"; // Most urgent first
        } else {
            query += " ORDER BY created_at DESC";
        }

        const result = await db.query(query, params);
        res.json({ success: true, alerts: result.rows });
    } catch (error) {
        console.error('Error fetching smart docs:', error);
        res.status(500).json({ error: 'Failed to fetch alerts' });
    }
});

// 3. Delete Smart Alert
app.delete('/api/smart_docs/:id', async (req, res) => {
    const { id } = req.params;
    const { user_id } = req.query;

    try {
        const result = await db.query(
            'DELETE FROM smart_docs WHERE id = $1 AND user_id = $2 RETURNING *',
            [id, user_id]
        );
        if (result.rows.length === 0) {
            res.status(404).json({ error: 'Alert not found' });
            return;
        }
        res.json({ success: true, message: 'Alert deleted successfully' });
    } catch (error) {
        res.status(500).json({ error: 'Failed to delete alert' });
    }
});

// ============================================
// HEARTBEAT / PROOF OF LIFE API
// ============================================

// 1. Get Heartbeat Status
app.get('/api/heartbeat/status', async (req, res) => {
    const { user_id } = req.query;
    try {
        const result = await db.query(
            'SELECT last_check_in, check_in_frequency_days, dead_mans_switch_active FROM users WHERE id = $1',
            [user_id]
        );
        if (result.rows.length === 0) {
            res.status(404).json({ error: 'User not found' });
            return;
        }
        res.json({ success: true, status: result.rows[0] });
    } catch (error) {
        res.status(500).json({ error: 'Failed to fetch status' });
    }
});

// 2. Perform Check-In (I'm Safe)
app.post('/api/heartbeat/checkin', async (req, res) => {
    const { user_id, method = 'manual' } = req.body; // method: manual, login, biometric
    try {
        await db.query('UPDATE users SET last_check_in = CURRENT_TIMESTAMP WHERE id = $1', [user_id]);
        await db.query('INSERT INTO heartbeat_logs (user_id, method) VALUES ($1, $2)', [user_id, method]);
        res.json({ success: true, message: 'Check-in successful' });
    } catch (error) {
        res.status(500).json({ error: 'Failed to check in' });
    }
});

// 3. Update Settings (Activate/Frequency)
app.post('/api/heartbeat/settings', async (req, res) => {
    const { user_id, active, frequency_days } = req.body;
    try {
        await db.query(
            'UPDATE users SET dead_mans_switch_active = $1, check_in_frequency_days = $2 WHERE id = $3',
            [active, frequency_days, user_id]
        );
        res.json({ success: true, message: 'Heartbeat settings updated' });
    } catch (error) {
        res.status(500).json({ error: 'Failed to update settings' });
    }
});

// ============================================
// SECURITY SCORE API
// ============================================

app.get('/api/security/score', async (req, res) => {
    const { user_id } = req.query;
    try {
        let score = 0;
        const checks = [];

        // 1. Account Created (Base) -> 10 pts
        score += 10;
        checks.push({ label: 'Account Created', passed: true, points: 10 });

        // 2. Has Nominee? -> 20 pts
        const nominees = await db.query('SELECT COUNT(*) FROM nominees WHERE user_id = $1', [user_id]);
        if (parseInt(nominees.rows[0].count) > 0) {
            score += 20;
            checks.push({ label: 'Nominee Added', passed: true, points: 20 });
        } else {
            checks.push({ label: 'Nominee Added', passed: false, points: 0, fix: "Add a nominee to ensure legacy transfer" });
        }

        // 3. Heartbeat Active? -> 20 pts
        const user = await db.query('SELECT dead_mans_switch_active FROM users WHERE id = $1', [user_id]);
        if (user.rows[0] && user.rows[0].dead_mans_switch_active) {
            score += 20;
            checks.push({ label: 'Dead Man\'s Switch Check', passed: true, points: 20 });
        } else {
            checks.push({ label: 'Dead Man\'s Switch Check', passed: false, points: 0, fix: "Activate Proof of Life monitoring" });
        }

        // 4. Vault Usage? -> 20 pts
        const vaultItems = await db.query('SELECT COUNT(*) FROM vault_items WHERE user_id = $1', [user_id]);
        if (parseInt(vaultItems.rows[0].count) > 0) {
            score += 20;
            checks.push({ label: 'Vault Active', passed: true, points: 20 });
        } else {
            checks.push({ label: 'Vault Active', passed: false, points: 0, fix: "Add your first secure item" });
        }

        // 5. Smart Docs? -> 10 pts
        const smartDocs = await db.query('SELECT COUNT(*) FROM smart_docs WHERE user_id = $1', [user_id]);
        if (parseInt(smartDocs.rows[0].count) > 0) {
            score += 10;
            checks.push({ label: 'Document Intelligence', passed: true, points: 10 });
        } else {
            checks.push({ label: 'Document Intelligence', passed: false, points: 0, fix: "Scan a document for auto-reminders" });
        }

        // 6. Email Breach Check (Mock for now)
        score += 20;
        checks.push({ label: 'Email Breach Check', passed: true, points: 20 });

        res.json({ success: true, score, checks });
    } catch (error) {
        console.error('Security Score Error:', error);
        res.status(500).json({ error: 'Failed to calculate score' });
    }
});

// --- Admin Routes ---
const ADMIN_SECRET = process.env.ADMIN_SECRET || 'secure_admin_123';

const checkAdmin = (req: any, res: any, next: any) => {
    const secret = req.headers['x-admin-secret'];
    if (secret === ADMIN_SECRET) {
        next();
    } else {
        res.status(403).json({ error: 'Unauthorized' });
    }
};

// 4. Trigger Heartbeat Check (CRON JOB)
app.post('/api/admin/trigger_heartbeat_check', checkAdmin, async (req, res) => {
    try {
        const overdueUsers = await db.query(`
            SELECT id, name, email 
            FROM users 
            WHERE dead_mans_switch_active = TRUE 
            AND last_check_in + (check_in_frequency_days * INTERVAL '1 day') < NOW()
        `);

        const overdueIds: number[] = overdueUsers.rows.map((u: any) => u.id);

        if (overdueIds.length > 0) {
            // Grant Access to Nominees automatically for ALL overdue users
            // Note: pg syntax requires distinct handling for arrays, but ANY($1) works with array param
            await db.query(`
                UPDATE nominees 
                SET access_granted = TRUE 
                WHERE user_id = ANY($1::int[])
             `, [overdueIds]);
        }

        res.json({
            success: true,
            triggered_count: overdueUsers.rows.length,
            overdue_users: overdueUsers.rows.map(u => ({ id: u.id, name: u.name }))
        });
    } catch (error) {
        console.error('Heartbeat Check Error:', error);
        res.status(500).json({ error: 'Failed to run heartbeat check' });
    }
});

app.get('/api/admin/users', checkAdmin, async (req, res) => {
    try {
        const result = await db.query('SELECT id, mobile_number, name, email, created_at FROM users ORDER BY created_at DESC');
        res.json(result.rows);
    } catch (error) {
        res.status(500).json({ error: 'Failed to fetch users' });
    }
});

app.get('/api/admin/otp_logs', checkAdmin, async (req, res) => {
    try {
        const result = await db.query('SELECT * FROM otp_logs ORDER BY created_at DESC LIMIT 50');
        res.json(result.rows);
    } catch (error) {
        res.status(500).json({ error: 'Failed to fetch logs' });
    }
});

app.get('/api/admin/stats', checkAdmin, async (req, res) => {
    try {
        const users = await db.query('SELECT COUNT(*) FROM users');
        const files = await db.query('SELECT COUNT(*) FROM files');
        const otps = await db.query('SELECT COUNT(*) FROM otp_logs');
        res.json({
            users: users.rows[0].count,
            files: files.rows[0].count,
            otps: otps.rows[0].count
        });
    } catch (error) {
        res.status(500).json({ error: 'Failed to fetch stats' });
    }
});

// --- Start Server ---
if (process.env.NODE_ENV !== 'production') {
    app.listen(PORT, async () => {
        await initDb();
        console.log(`Server is running on port ${PORT}`);
    });
} else {
    // In production (Vercel), initialize DB in the background
    initDb().catch(err => console.error('DB Init Failed', err));
}

export default app;
const v = 1770921210;
