import express from 'express';
import bodyParser from 'body-parser';
import cors from 'cors';
import { initDb } from './db';
import db from './db';

const app = express();
const PORT = process.env.PORT || 3000;

app.use(cors());
app.use(bodyParser.json());
app.use(bodyParser.urlencoded({ extended: true }));

// --- Routes ---

import axios from 'axios';
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
    // Check if running locally (simplified check)
    const isDev = !process.env.NODE_ENV || process.env.NODE_ENV === 'development';

    if (isDev) {
        console.log(`[DEV MODE] Mock Sending SMS to ${mobile}: ${message}`);
        return true;
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

        await axios.get(url, { params });
        return true;
    } catch (error) {
        console.error('Error sending SMS:', error);
        return false;
    }
}

// --- OTP Routes ---

// 1. Send OTP
app.post('/api/send_otp', async (req, res) => {
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
        const message = `${otp} is your OTP for ${purpose}. Vasihat Nama`;
        await sendSMS(mobile, message);

        // Log
        await db.query(
            'INSERT INTO otp_logs (mobile, purpose, status) VALUES ($1, $2, $3)',
            [mobile, purpose, 'sent']
        );

        // In Dev mode, return OTP for easy testing
        const isDev = !process.env.NODE_ENV || process.env.NODE_ENV === 'development';
        res.json({
            success: true,
            message: 'OTP sent successfully',
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

// 2. Upload File (Metadata + Encrypted Key)
app.post('/api/files', async (req, res) => {
    const { user_id, file_name, file_size, mime_type, encrypted_file_key } = req.body;
    // TODO: Add Multer middleware to handle the actual file blob upload -> 'storage_path'
    const storage_path = `/uploads/${Date.now()}_${file_name}`;

    try {
        const result = await db.query(
            'INSERT INTO files (user_id, file_name, storage_path, file_size, mime_type, encrypted_file_key) VALUES ($1, $2, $3, $4, $5, $6) RETURNING id',
            [user_id, file_name, storage_path, file_size, mime_type, encrypted_file_key]
        );
        res.status(201).json({ id: result.rows[0].id, message: 'File metadata stored successfully' });
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

// --- Start Server ---
app.listen(PORT, async () => {
    await initDb();
    console.log(`Server is running on port ${PORT}`);
});
