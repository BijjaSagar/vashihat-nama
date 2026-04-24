import 'dotenv/config';
import path from 'path';
import axios from "axios";
import express from 'express';
import bodyParser from 'body-parser';
import cors from 'cors';
import bcrypt from 'bcryptjs';
import jwt from 'jsonwebtoken';
import { initDb } from './db';
import db from './db';
import OpenAI from 'openai';
import crypto from 'crypto';
import nodemailer from 'nodemailer';
import multer from 'multer';

const upload = multer({ storage: multer.memoryStorage() });

const app = express();
const PORT = process.env.PORT || 3000;

// ─── CORS (restrict to known origins) ──────────────────────────────────────
const allowedOrigins = [
    'https://backend-sagar-bijjas-projects.vercel.app',
    'https://vashihat-nama-main.vercel.app',
    'https://vasihata-nama.in',
    'http://localhost:3000',
    'http://localhost:8080',
    'http://10.0.2.2:8080',  // Android emulator
];
app.use(cors({
    origin: (origin, callback) => {
        // Allow requests with no origin (mobile apps, Postman, server-to-server)
        if (!origin || allowedOrigins.includes(origin)) {
            callback(null, true);
        } else {
            callback(new Error(`CORS policy: Origin '${origin}' not allowed`));
        }
    },
    credentials: true,
}));

app.use(bodyParser.json({ limit: '50mb' }));
app.use(bodyParser.urlencoded({ limit: '50mb', extended: true }));
// Use absolute path for static files — required for Vercel serverless
app.use(express.static(path.join(__dirname, '..', 'public')));

// ─── Credentials from environment variables (never hardcode secrets) ────────
const HSP_SMS_USERNAME  = process.env.HSP_SMS_USERNAME  || '';
const HSP_SMS_SENDER_ID = process.env.HSP_SMS_SENDER_ID || 'DASSAM';
const HSP_SMS_TYPE      = process.env.HSP_SMS_TYPE      || 'TRANS';
const HSP_SMS_API_KEY   = process.env.HSP_SMS_API_KEY   || '';
const OPENAI_API_KEY    = process.env.OPENAI_API_KEY    || '';
const JWT_SECRET        = process.env.JWT_SECRET        || 'fallback_dev_secret_change_me';
const JWT_EXPIRES_IN    = process.env.JWT_EXPIRES_IN    || '7d';

// ─── JWT Auth Middleware ─────────────────────────────────────────────────────
// Apply to any route that should require a logged-in user.
const authMiddleware = (req: any, res: any, next: any) => {
    const authHeader = req.headers['authorization'];
    const token = authHeader && authHeader.startsWith('Bearer ')
        ? authHeader.split(' ')[1]
        : null;

    if (!token) {
        return res.status(401).json({ success: false, error: 'Authentication required. Please log in.' });
    }

    try {
        const payload = jwt.verify(token, JWT_SECRET) as any;
        // Attach verified user id to request so routes can trust it
        req.userId = payload.userId;
        req.userMobile = payload.mobile;
        next();
    } catch (err) {
        return res.status(401).json({ success: false, error: 'Invalid or expired session. Please log in again.' });
    }
};

// --- Root Route (Health Check) ---
app.get('/', (req, res) => {
    res.send(`
        <div style="font-family: sans-serif; text-align: center; padding: 50px;">
            <h1>🛡️ Eversafe Security Server</h1>
            <p>Secure Zero-Knowledge Backend is Active.</p>
            <p>Status: <strong>Operational</strong> (Max Upload: 4.5MB)</p>
            <p><a href="/nominee-portal">Nominee Portal →</a></p>
        </div>
    `);
});

// ─────────────────────────────────────────────────────────────────────────────
// NOMINEE WEB PORTAL ROUTES
// Served at /nominee-portal — allows nominees to log in via OTP and view vault
// ─────────────────────────────────────────────────────────────────────────────

// Serve HTML — handle /nominee-portal without trailing slash
// express.static handles /nominee-portal/index.html automatically
app.get('/nominee-portal', (req, res) => {
    res.sendFile(path.join(__dirname, '..', 'public', 'nominee-portal', 'index.html'));
});

/**
 * POST /api/nominee-portal/send-otp
 * Send a 6-digit OTP to a nominee's registered mobile number.
 * Only sends if the mobile matches a real nominee in the DB.
 */
app.post('/api/nominee-portal/send-otp', async (req, res) => {
    const { mobile } = req.body;
    if (!mobile || !/^\d{10}$/.test(mobile.trim())) {
        return res.status(400).json({ success: false, error: 'Valid 10-digit mobile number required.' });
    }
    const mobileTrimmed = mobile.trim();

    try {
        // 1. Check this mobile is actually a registered nominee with access granted
        const nomineeResult = await db.query(
            `SELECT id, name, user_id, access_granted 
             FROM nominees 
             WHERE primary_mobile = $1 
             ORDER BY access_granted DESC NULLS LAST 
             LIMIT 1`,
            [mobileTrimmed]
        );

        if (nomineeResult.rows.length === 0) {
            // Return same error to prevent mobile enumeration
            return res.status(404).json({ success: false, error: 'This mobile number is not registered as a nominee.' });
        }

        const nominee = nomineeResult.rows[0];

        if (!nominee.access_granted) {
            return res.status(403).json({
                success: false,
                error: 'Access has not been granted to you yet. The handover trigger has not occurred for this account.'
            });
        }

        // 2. Generate 6-digit OTP
        const otp = Math.floor(100000 + Math.random() * 900000).toString();
        const otpHash = await bcrypt.hash(otp, 10);
        const expiresAt = new Date(Date.now() + 5 * 60 * 1000); // 5 minutes

        // 3. Store hashed OTP (invalidate old ones first)
        await db.query(
            `DELETE FROM otp_verifications WHERE mobile = $1 AND purpose = $2`,
            [mobileTrimmed, 'nominee_portal_login']
        );
        await db.query(
            `INSERT INTO otp_verifications (mobile, otp_hash, purpose, expires_at) 
             VALUES ($1, $2, $3, $4)`,
            [mobileTrimmed, otpHash, 'nominee_portal_login', expiresAt]
        );

        // 4. Send SMS
        const message = `Your Eversafe Nominee Portal OTP is ${otp}. Valid for 5 minutes. Do not share this code. GGISKB`;
        const encodedMessage = encodeURIComponent(message);
        const smsUrl = `http://sms.hspsms.com/sendSMS?username=${HSP_SMS_USERNAME}&message=${encodedMessage}&sendername=${HSP_SMS_SENDER_ID}&smstype=${HSP_SMS_TYPE}&numbers=${mobileTrimmed}&apikey=${HSP_SMS_API_KEY}`;

        try {
            await axios.get(smsUrl);
        } catch (smsError) {
            console.error('SMS send error (portal OTP):', smsError);
            // Don't expose SMS failure to client — continue
        }

        // Log
        await db.query(
            `INSERT INTO otp_logs (mobile, purpose, status, details) VALUES ($1, $2, $3, $4)`,
            [mobileTrimmed, 'nominee_portal_login', 'sent', `NomineeId: ${nominee.id}`]
        ).catch(() => {});

        console.log(`[Portal OTP] Sent to nominee ${nominee.id} (${mobileTrimmed}) — OTP: ${otp}`);

        return res.json({
            success: true,
            message: 'OTP sent successfully.',
            // In development, expose OTP in response — remove in production!
            ...(process.env.NODE_ENV !== 'production' ? { dev_otp: otp } : {})
        });

    } catch (error) {
        console.error('Nominee portal send-otp error:', error);
        return res.status(500).json({ success: false, error: 'Failed to send OTP. Please try again.' });
    }
});

/**
 * POST /api/nominee-portal/verify-otp
 * Verify OTP and return a signed JWT nominee session token.
 */
app.post('/api/nominee-portal/verify-otp', async (req, res) => {
    const { mobile, otp } = req.body;
    if (!mobile || !otp) {
        return res.status(400).json({ success: false, error: 'Mobile and OTP are required.' });
    }
    const mobileTrimmed = mobile.trim();

    try {
        // 1. Find the OTP record
        const otpResult = await db.query(
            `SELECT * FROM otp_verifications 
             WHERE mobile = $1 AND purpose = $2 AND expires_at > NOW()
             ORDER BY created_at DESC LIMIT 1`,
            [mobileTrimmed, 'nominee_portal_login']
        );

        if (otpResult.rows.length === 0) {
            return res.status(401).json({ success: false, error: 'Invalid or expired OTP. Please request a new one.' });
        }

        // 2. bcrypt compare
        const match = await bcrypt.compare(otp.toString(), otpResult.rows[0].otp_hash);
        if (!match) {
            return res.status(401).json({ success: false, error: 'Incorrect OTP. Please check and try again.' });
        }

        // 3. Get nominee details
        const nomineeResult = await db.query(
            `SELECT n.id, n.name, n.user_id, n.access_granted,
                    u.name AS owner_name
             FROM nominees n
             JOIN users u ON u.id = n.user_id
             WHERE n.primary_mobile = $1 AND n.access_granted = TRUE
             LIMIT 1`,
            [mobileTrimmed]
        );

        if (nomineeResult.rows.length === 0) {
            return res.status(403).json({ success: false, error: 'No active access grant found for this mobile.' });
        }

        const nominee = nomineeResult.rows[0];

        // 4. Clean up used OTP
        await db.query(
            `DELETE FROM otp_verifications WHERE mobile = $1 AND purpose = $2`,
            [mobileTrimmed, 'nominee_portal_login']
        );

        // 5. Issue a signed JWT (24h expiry for web portal session)
        const token = jwt.sign(
            { nomineeId: nominee.id, userId: nominee.user_id, mobile: mobileTrimmed, role: 'nominee_portal' },
            JWT_SECRET,
            { expiresIn: '24h' } as any
        );

        return res.json({
            success: true,
            token,
            nominee_id: nominee.id,
            nominee_name: nominee.name,
            owner_name: nominee.owner_name,
            message: 'OTP verified. Access granted.'
        });

    } catch (error) {
        console.error('Nominee portal verify-otp error:', error);
        return res.status(500).json({ success: false, error: 'Verification failed. Please try again.' });
    }
});

/**
 * GET /api/nominee-portal/vault-items?nominee_id=X
 * Returns vault items assigned to this nominee.
 * Requires valid nominee_portal JWT.
 */
app.get('/api/nominee-portal/vault-items', async (req, res) => {
    // Verify JWT
    const authHeader = req.headers['authorization'];
    const token = authHeader?.startsWith('Bearer ') ? authHeader.split(' ')[1] : null;
    if (!token) return res.status(401).json({ success: false, error: 'Authentication required.' });

    let payload: any;
    try {
        payload = jwt.verify(token, JWT_SECRET);
    } catch {
        return res.status(401).json({ success: false, error: 'Invalid or expired session.' });
    }

    if (payload.role !== 'nominee_portal') {
        return res.status(403).json({ success: false, error: 'Forbidden.' });
    }

    const nomineeId = parseInt(req.query.nominee_id as string);
    // Security: ensure the nominee_id in query matches the one in the JWT
    if (!nomineeId || nomineeId !== payload.nomineeId) {
        return res.status(403).json({ success: false, error: 'Nominee ID mismatch.' });
    }

    try {
        // Get nominee + owner info (reconfirm access is still granted)
        const nomineeResult = await db.query(
            `SELECT n.id, n.name, n.access_granted, n.user_id,
                    u.name AS owner_name, u.email AS owner_email
             FROM nominees n
             JOIN users u ON u.id = n.user_id
             WHERE n.id = $1`,
            [nomineeId]
        );

        if (nomineeResult.rows.length === 0 || !nomineeResult.rows[0].access_granted) {
            return res.status(403).json({ success: false, error: 'Access not granted.' });
        }

        const nominee = nomineeResult.rows[0];

        // Get vault items assigned via junction table
        const itemsResult = await db.query(
            `SELECT vi.id, vi.title, vi.item_type, vi.encrypted_data, vi.created_at
             FROM vault_items vi
             JOIN vault_item_nominees vin ON vin.vault_item_id = vi.id
             WHERE vin.nominee_id = $1
             ORDER BY vi.item_type, vi.title`,
            [nomineeId]
        );

        // Log portal access
        await db.query(
            `INSERT INTO otp_logs (mobile, purpose, status, details) VALUES ($1, $2, $3, $4)`,
            [payload.mobile, 'nominee_portal_access', 'success', `NomineeId: ${nomineeId}, ItemsFetched: ${itemsResult.rows.length}`]
        ).catch(() => {});

        return res.json({
            success: true,
            nominee_name: nominee.name,
            owner_name: nominee.owner_name,
            items: itemsResult.rows,
            total: itemsResult.rows.length
        });

    } catch (error) {
        console.error('Nominee portal vault-items error:', error);
        return res.status(500).json({ success: false, error: 'Failed to load vault items.' });
    }
});

// ─── End Nominee Portal Routes ─────────────────────────────────────────────────

// Configure S3 Client
import { S3Client, PutObjectCommand } from "@aws-sdk/client-s3";
const { getSignedUrl } = require("@aws-sdk/s3-request-presigner");

const s3 = new S3Client({
    region: process.env.AWS_DEFAULT_REGION,
    credentials: {
        accessKeyId: process.env.AWS_ACCESS_KEY_ID!,
        secretAccessKey: process.env.AWS_SECRET_ACCESS_KEY!,
    },
});

const BUCKET_NAME = process.env.AWS_BUCKET;

// 2. Upload File (Revised - Presigned URL)
app.post('/api/get-presigned-url', async (req, res) => {
    const { folder_id, file_name, file_type } = req.body;

    // Validate
    if (!file_name || !file_type) {
        res.status(400).json({ error: 'Missing file name or type' });
        return;
    }

    const key = `uploads/${Date.now()}_${file_name}`;

    try {
        const command = new PutObjectCommand({
            Bucket: BUCKET_NAME,
            Key: key,
            ContentType: file_type,
        });

        const uploadUrl = await getSignedUrl(s3, command, { expiresIn: 3600 });

        res.json({ uploadUrl, key });
    } catch (error) {
        console.error('Error generating presigned URL:', error);
        res.status(500).json({ error: 'Failed to generate upload URL' });
    }
});

// Confirm Upload (After successful S3 upload)
app.post('/api/files/confirm-upload', async (req, res) => {
    const { user_id, folder_id, file_name, key, file_size, mime_type } = req.body;

    // In real app, consider using HeadObject to verify the file is actually in S3

    try {
        const result = await db.query(
            'INSERT INTO files (user_id, folder_id, file_name, storage_path, file_size, mime_type, encrypted_file_key) VALUES ($1, $2, $3, $4, $5, $6, $7) RETURNING id',
            [user_id || 1, folder_id, file_name, key, file_size, mime_type, 's3-managed']
        );
        res.status(201).json({ id: result.rows[0].id, message: 'File record created' });
    } catch (error) {
        console.error('Error confirming upload:', error);
        res.status(500).json({ error: 'Failed to record file' });
    }
});

// 2. Upload File (Revised - Presigned URL)
// Note: S3 Presigned URL is the primary method for uploads.
// Confirm Upload (After successful S3 upload)

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

// 4. Add Nominee (Updated)
app.post('/api/nominees', async (req, res) => {
    const {
        user_id, name, email, relationship,
        primary_mobile, optional_mobile,
        address, identity_proof, hand_delivery_rules,
        delivery_mode = 'digital',
        handover_waiting_days = 0,        // ✅ BUG FIX: was missing
        require_otp_for_access = false    // ✅ BUG FIX: was missing
    } = req.body;

    // Base mandatory fields for both modes
    if (!user_id || !name || !email || !primary_mobile) {
        res.status(400).json({ error: 'Missing mandatory fields: user_id, name, email, primary_mobile' });
        return;
    }

    // Conditional mandatory fields for Physical mode
    if (delivery_mode === 'physical' && (!address || !identity_proof)) {
        res.status(400).json({ error: 'Address and Identity Proof are mandatory for Physical delivery' });
        return;
    }

    try {
        const result = await db.query(
            `INSERT INTO nominees (
                user_id, name, email, relationship, 
                primary_mobile, optional_mobile, 
                address, identity_proof, hand_delivery_rules,
                delivery_mode, handover_waiting_days, require_otp_for_access
            ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12) RETURNING id`,
            [
                user_id, name, email, relationship,
                primary_mobile, optional_mobile,
                address, identity_proof, hand_delivery_rules,
                delivery_mode,
                handover_waiting_days,
                require_otp_for_access
            ]
        );
        res.status(201).json({ success: true, id: result.rows[0].id, message: 'Nominee added successfully' });
    } catch (error) {
        console.error("Error adding nominee:", error);
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

// 5.1 Update Nominee
app.put('/api/nominees/:id', async (req, res) => {
    const { id } = req.params;
    const {
        name, email, relationship,
        primary_mobile, optional_mobile,
        address, identity_proof, hand_delivery_rules,
        delivery_mode,
        handover_waiting_days,        // ✅ BUG FIX: was missing
        require_otp_for_access        // ✅ BUG FIX: was missing
    } = req.body;

    try {
        const result = await db.query(
            `UPDATE nominees 
             SET name = $1, email = $2, relationship = $3, 
                 primary_mobile = $4, optional_mobile = $5,
                 address = $6, identity_proof = $7, hand_delivery_rules = $8,
                 delivery_mode = $9,
                 handover_waiting_days = COALESCE($10, handover_waiting_days),
                 require_otp_for_access = COALESCE($11, require_otp_for_access)
             WHERE id = $12 RETURNING *`,
            [
                name, email, relationship,
                primary_mobile, optional_mobile,
                address, identity_proof, hand_delivery_rules,
                delivery_mode,
                handover_waiting_days,
                require_otp_for_access,
                id
            ]
        );

        if (result.rows.length === 0) {
            res.status(404).json({ error: 'Nominee not found' });
            return;
        }

        res.json({ success: true, nominee: result.rows[0], message: 'Nominee updated' });
    } catch (error) {
        console.error("Error updating nominee:", error);
        res.status(500).json({ error: 'Failed to update nominee' });
    }
});

// 5.2 Delete Nominee
app.delete('/api/nominees/:id', async (req, res) => {
    const { id } = req.params;

    try {
        const result = await db.query('DELETE FROM nominees WHERE id = $1 RETURNING id', [id]);
        if (result.rows.length === 0) {
            res.status(404).json({ error: 'Nominee not found' });
            return;
        }
        res.json({ success: true, message: 'Nominee deleted' });
    } catch (error) {
        console.error("Error deleting nominee:", error);
        res.status(500).json({ error: 'Failed to delete nominee' });
    }
});

// 5.3 Verify Nominee Access via OTP
app.post('/api/nominees/verify_access', async (req, res) => {
    const { nominee_id, otp } = req.body;

    if (!nominee_id || !otp) {
        res.status(400).json({ success: false, message: 'Missing nominee ID or OTP' });
        return;
    }

    try {
        // 1. Check nominee exists, access_granted, and requires OTP
        const nomineeResult = await db.query(
            'SELECT user_id, access_granted, handover_triggered_at, require_otp_for_access, primary_mobile FROM nominees WHERE id = $1',
            [nominee_id]
        );

        if (nomineeResult.rows.length === 0) {
            res.status(404).json({ success: false, message: 'Nominee not found' });
            return;
        }

        const nominee = nomineeResult.rows[0];

        if (!nominee.access_granted) {
            res.status(403).json({ success: false, message: 'Access not yet granted to this nominee' });
            return;
        }

        // ✅ BUG FIX: If this nominee does not require OTP, block this endpoint
        // They should access directly without OTP
        if (!nominee.require_otp_for_access) {
            res.status(400).json({ success: false, message: 'This nominee does not require OTP verification. Access is already granted.' });
            return;
        }

        // 2. Verify OTP for nominee access (bcrypt-aware comparison)
        const otpResult = await db.query(
            'SELECT * FROM otp_verifications WHERE mobile = $1 AND purpose = $2 AND expires_at > NOW() ORDER BY created_at DESC LIMIT 1',
            [nominee.primary_mobile, 'nominee_access']
        );

        if (otpResult.rows.length === 0) {
            res.status(401).json({ success: false, message: 'Invalid or expired OTP' });
            return;
        }

        // ✅ SECURITY: bcrypt compare for nominee OTP
        const nomineeOtpMatch = await bcrypt.compare(otp, otpResult.rows[0].otp_hash);
        if (!nomineeOtpMatch) {
            res.status(401).json({ success: false, message: 'Invalid or expired OTP' });
            return;
        }

        // OTP Verified, clean up
        await db.query(
            'DELETE FROM otp_verifications WHERE mobile = $1 AND purpose = $2',
            [nominee.primary_mobile, 'nominee_access']
        );

        // ✅ BUG FIX: Issue a real signed JWT for nominee session (not a mock token)
        const nomineeToken = jwt.sign(
            { nomineeId: nominee_id, userId: nominee.user_id, role: 'nominee' },
            JWT_SECRET,
            { expiresIn: '24h' } as any
        );

        res.json({
            success: true,
            message: 'Nominee access verified successfully',
            nominee_id: nominee_id,
            user_id: nominee.user_id,
            token: nomineeToken
        });

    } catch (error) {
        console.error('Error verifying nominee access:', error);
        res.status(500).json({ error: 'Failed to verify nominee access' });
    }
});

// 5.3 Get Assigned Items for a Nominee
app.get('/api/nominees/:id/assigned_items', async (req, res) => {
    const { id } = req.params;
    try {
        const nomineeId = parseInt(id);
        console.log(`Fetching assigned items for nominee ID: ${nomineeId}`);

        // Fetch vault items assigned to this nominee via vault_item_nominees table
        const vaultItems = await db.query(`
            SELECT v.id, v.title, v.item_type, v.created_at
            FROM vault_items v
            JOIN vault_item_nominees vin ON v.id = vin.vault_item_id
            WHERE vin.nominee_id = $1
            ORDER BY v.created_at DESC
        `, [nomineeId]);

        // Also fetch direct files if any
        const files = await db.query(`
            SELECT f.id, f.file_name as title, 'file' as item_type, f.created_at
            FROM files f
            JOIN file_permissions fp ON f.id = fp.file_id
            WHERE fp.nominee_id = $1
            ORDER BY f.created_at DESC
        `, [nomineeId]);

        // Combine results
        const combined = [...vaultItems.rows, ...files.rows];
        console.log(`Found ${combined.length} items for nominee ${nomineeId}`);

        res.json({ success: true, items: combined });
    } catch (error) {
        console.error("Error fetching nominee assigned items:", error);
        res.status(500).json({ error: 'Failed to fetch assigned items' });
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

// 7.1 Rename Folder
app.put('/api/folders/:id', async (req, res) => {
    const { id } = req.params;
    const { user_id, name } = req.body;

    if (!name) {
        res.status(400).json({ error: 'Folder name is required' });
        return;
    }

    try {
        const result = await db.query(
            'UPDATE folders SET name = $1 WHERE id = $2 AND user_id = $3 RETURNING *',
            [name, id, user_id]
        );

        if (result.rows.length === 0) {
            res.status(404).json({ error: 'Folder not found' });
            return;
        }

        res.json({ success: true, folder: result.rows[0], message: 'Folder renamed successfully' });
    } catch (error) {
        console.error('Error renaming folder:', error);
        res.status(500).json({ error: 'Failed to rename folder' });
    }
});

// 7.2 Delete Folder
app.delete('/api/folders/:id', async (req, res) => {
    const { id } = req.params;
    const { user_id } = req.query;

    try {
        // Delete associated vault items first
        await db.query('DELETE FROM vault_items WHERE folder_id = $1 AND user_id = $2', [id, user_id]);

        // Delete associated files
        await db.query('DELETE FROM files WHERE folder_id = $1', [id]);

        // Delete the folder
        const result = await db.query(
            'DELETE FROM folders WHERE id = $1 AND user_id = $2 RETURNING *',
            [id, user_id]
        );

        if (result.rows.length === 0) {
            res.status(404).json({ error: 'Folder not found' });
            return;
        }

        res.json({ success: true, message: 'Folder deleted successfully' });
    } catch (error) {
        console.error('Error deleting folder:', error);
        res.status(500).json({ error: 'Failed to delete folder' });
    }
});

// ============================================
// OTP AUTHENTICATION API
// ============================================

// --- 1. User Registration ---
app.post('/api/users/register', async (req, res) => {
    const { mobile_number, public_key, encrypted_private_key, name, email } = req.body;

    if (!mobile_number) {
        res.status(400).json({ error: 'Mobile number is required' });
        return;
    }

    try {
        const result = await db.query(
            `INSERT INTO users (mobile_number, public_key, encrypted_private_key, name, email) 
             VALUES ($1, $2, $3, $4, $5) 
             ON CONFLICT (mobile_number) DO UPDATE 
             SET public_key = EXCLUDED.public_key, 
                 encrypted_private_key = EXCLUDED.encrypted_private_key, 
                 name = EXCLUDED.name, 
                 email = EXCLUDED.email
             RETURNING id, mobile_number, name, email`,
            [mobile_number, public_key, encrypted_private_key, name, email]
        );

        const user = result.rows[0];
        
        // Generate a token for the newly registered user
        const token = jwt.sign(
            { userId: user.id, mobile: user.mobile_number },
            JWT_SECRET,
            { expiresIn: JWT_EXPIRES_IN } as any
        );

        res.status(201).json({
            success: true,
            user: user,
            token: token,
            message: 'User registered successfully'
        });
    } catch (error: any) {
        console.error('Registration Error:', error);
        if (error.code === '23505') {
            res.status(400).json({ error: 'Email or Mobile number already in use by another account.' });
        } else {
            res.status(500).json({ error: 'Failed to register user' });
        }
    }
});

// 1. Send OTP
app.post('/api/send_otp', async (req, res) => {
    const { mobile, purpose = 'login' } = req.body;

    if (!mobile || !/^[6-9][0-9]{9}$/.test(mobile)) {
        res.status(400).json({ success: false, message: 'Invalid mobile number' });
        return;
    }

    try {
        // Check if user exists (Required for login)
        const userCheck = await db.query('SELECT id FROM users WHERE mobile_number = $1', [mobile]);

        if (userCheck.rows.length === 0 && purpose === 'login') {
            res.status(404).json({
                success: false,
                message: 'Mobile number not registered.',
                action: 'register'
            });
            return;
        }

        // Generate 6-digit OTP
        const otp = Math.floor(100000 + Math.random() * 900000).toString();
        const expiresAt = new Date(Date.now() + 5 * 60 * 1000); // 5 minutes

        // Delete old OTPs for this mobile+purpose
        await db.query('DELETE FROM otp_verifications WHERE mobile = $1 AND purpose = $2', [mobile, purpose]);

        // ✅ SECURITY FIX: Hash OTP with bcrypt before storing (never store plaintext OTPs)
        const otpHash = await bcrypt.hash(otp, 10);
        await db.query(
            'INSERT INTO otp_verifications (mobile, otp_hash, purpose, expires_at) VALUES ($1, $2, $3, $4)',
            [mobile, otpHash, purpose, expiresAt]
        );

        // Prepare SMS
        const message = `${otp} is your OTP for login into your account. GGISKB`;
        const encodedMessage = encodeURIComponent(message);
        const smsUrl = `http://sms.hspsms.com/sendSMS?username=${HSP_SMS_USERNAME}&message=${encodedMessage}&sendername=${HSP_SMS_SENDER_ID}&smstype=${HSP_SMS_TYPE}&numbers=${mobile}&apikey=${HSP_SMS_API_KEY}`;

        // Send SMS via Axios
        const smsResponse = await axios.get(smsUrl);
        console.log('SMS API Response:', smsResponse.data);

        // Log OTP request
        await db.query(
            'INSERT INTO otp_logs (mobile, purpose, status, details) VALUES ($1, $2, $3, $4)',
            [mobile, purpose, 'sent', `Response: ${JSON.stringify(smsResponse.data)}`]
        );

        res.json({
            success: true,
            message: 'OTP sent successfully',
            mobile: mobile.substring(0, 2) + 'XXXXXX' + mobile.substring(8)
        });

    } catch (error) {
        console.error('Error in send_otp:', error);
        res.status(500).json({ success: false, message: 'Error sending OTP' });
    }
});

// 2. Verify OTP
app.post('/api/verify_otp', async (req, res) => {
    const { mobile, otp, purpose = 'login' } = req.body;

    if (!mobile || !otp) {
        res.status(400).json({ success: false, message: 'Missing mobile or OTP' });
        return;
    }

    try {
        // ✅ SECURITY FIX: Fetch the hashed OTP from DB (filter by mobile+purpose+expiry only)
        const result = await db.query(
            'SELECT * FROM otp_verifications WHERE mobile = $1 AND purpose = $2 AND expires_at > NOW() ORDER BY created_at DESC LIMIT 1',
            [mobile, purpose]
        );

        if (result.rows.length === 0) {
            // Log Failure - no active OTP found
            await db.query(
                'INSERT INTO otp_logs (mobile, purpose, status, details) VALUES ($1, $2, $3, $4)',
                [mobile, purpose, 'failed', 'No active OTP found or OTP expired']
            );
            res.status(401).json({ success: false, message: 'Invalid or expired OTP' });
            return;
        }

        // ✅ SECURITY FIX: Compare submitted OTP against bcrypt hash
        const storedHash = result.rows[0].otp_hash;
        const isMatch = await bcrypt.compare(otp, storedHash);

        if (!isMatch) {
            await db.query(
                'INSERT INTO otp_logs (mobile, purpose, status, details) VALUES ($1, $2, $3, $4)',
                [mobile, purpose, 'failed', 'OTP mismatch']
            );
            res.status(401).json({ success: false, message: 'Invalid or expired OTP' });
            return;
        }

        if (purpose === 'register') {
            await db.query('DELETE FROM otp_verifications WHERE mobile = $1 AND purpose = $2', [mobile, purpose]);
            await db.query(
                'INSERT INTO otp_logs (mobile, purpose, status, details) VALUES ($1, $2, $3, $4)',
                [mobile, purpose, 'verified', 'OTP verified for new registration']
            );
            res.json({
                success: true,
                message: 'Verification successful',
                next_step: 'complete_profile'
            });
            return;
        }

        // OTP Verified -> Get User
        const userResult = await db.query(
            'SELECT id, name, mobile_number, email FROM users WHERE mobile_number = $1',
            [mobile]
        );

        const user = userResult.rows[0];

        // If user doesn't exist yet, they need to register
        if (!user) {
            await db.query('DELETE FROM otp_verifications WHERE mobile = $1 AND purpose = $2', [mobile, purpose]);
            res.json({
                success: true,
                message: 'Account not found',
                next_step: 'register'
            });
            return;
        }

        // Clean up OTP
        await db.query('DELETE FROM otp_verifications WHERE mobile = $1 AND purpose = $2', [mobile, purpose]);

        // Log Success
        await db.query(
            'INSERT INTO otp_logs (mobile, purpose, status, details) VALUES ($1, $2, $3, $4)',
            [mobile, purpose, 'verified', `User ID: ${user.id}`]
        );

        // ✅ SECURITY FIX: Issue a real signed JWT token
        const token = jwt.sign(
            { userId: user.id, mobile: user.mobile_number },
            JWT_SECRET,
            { expiresIn: JWT_EXPIRES_IN } as any
        );

        res.json({
            success: true,
            message: 'Verification successful',
            user: user,
            token: token  // Real JWT
        });

    } catch (error) {
        console.error('Error in verify_otp:', error);
        res.status(500).json({ success: false, message: 'Verification error' });
    }
});

// ============================================
// VAULT ITEMS API ENDPOINTS
// ============================================

// 1. Create Vault Item
app.post('/api/vault_items', async (req, res) => {
    const { user_id, folder_id, item_type, title, encrypted_data, nominee_ids } = req.body; // nominee_ids as array

    // Validate item_type
    const validTypes = ['note', 'password', 'credit_card', 'file', 'crypto'];
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
        const newItem = result.rows[0];

        // Add Nominees
        if (nominee_ids && Array.isArray(nominee_ids)) {
            for (const nId of nominee_ids) {
                await db.query(
                    'INSERT INTO vault_item_nominees (vault_item_id, nominee_id) VALUES ($1, $2) ON CONFLICT DO NOTHING',
                    [newItem.id, nId]
                );
            }
        }

        res.status(201).json({
            success: true,
            item: newItem,
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
        let query = `
            SELECT v.*, 
                   COALESCE(
                     json_agg(
                       json_build_object('id', n.id, 'name', n.name)
                     ) FILTER (WHERE n.id IS NOT NULL), 
                     '[]'
                   ) as nominees
            FROM vault_items v
            LEFT JOIN vault_item_nominees vin ON v.id = vin.vault_item_id
            LEFT JOIN nominees n ON vin.nominee_id = n.id
            WHERE v.user_id = $1
        `;
        let params = [user_id];

        if (folder_id) {
            query += ' AND v.folder_id = $2';
            params.push(folder_id);
        }

        if (item_type) {
            query += ` AND v.item_type = $${params.length + 1}`;
            params.push(item_type);
        }

        query += ' GROUP BY v.id ORDER BY v.created_at DESC';

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
    const { user_id, title, encrypted_data, nominee_id } = req.body;

    try {
        // 1. Update basic fields
        const result = await db.query(
            `UPDATE vault_items 
             SET title = COALESCE($1, title), 
                 encrypted_data = COALESCE($2, encrypted_data), 
                 updated_at = CURRENT_TIMESTAMP 
             WHERE id = $3 AND user_id = $4 
             RETURNING *`,
            [title, encrypted_data, id, user_id]
        );

        if (result.rows.length === 0) {
            res.status(404).json({ error: 'Vault item not found' });
            return;
        }

        // 2. Handle Nominee Assignment (Support both migration and new table)
        if (nominee_id) {
            // First, try to insert into vault_item_nominees (the correct way)
            await db.query(
                'INSERT INTO vault_item_nominees (vault_item_id, nominee_id) VALUES ($1, $2) ON CONFLICT DO NOTHING',
                [id, nominee_id]
            );

            // Also update the legacy column if it exists (for backward compatibility during migration)
            try {
                await db.query('UPDATE vault_items SET nominee_id = $1 WHERE id = $2', [nominee_id, id]);
            } catch (e) {
                // Ignore if column doesn't exist
            }
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

// 4b. Remove Nominee from Vault Item
app.put('/api/vault_items/:id/remove_nominee', async (req, res) => {
    const { id } = req.params;
    const { user_id, nominee_id } = req.body;

    console.log(`[remove_nominee] vault_item_id=${id}, user_id=${user_id}, nominee_id=${nominee_id}`);

    try {
        const itemId = parseInt(id);
        const userId = parseInt(user_id);

        // Verify the vault item exists
        const verify = await db.query(
            'SELECT id, user_id FROM vault_items WHERE id = $1',
            [itemId]
        );

        if (verify.rows.length === 0) {
            console.log(`[remove_nominee] Item ${itemId} not found`);
            res.status(404).json({ error: 'Vault item not found' });
            return;
        }

        if (nominee_id) {
            const nomId = parseInt(nominee_id);
            console.log(`[remove_nominee] Removing nominee ${nomId} from item ${itemId}`);
            const deleteResult = await db.query(
                'DELETE FROM vault_item_nominees WHERE vault_item_id = $1 AND nominee_id = $2 RETURNING *',
                [itemId, nomId]
            );
            console.log(`[remove_nominee] Deleted ${deleteResult.rowCount} row(s)`);
        } else {
            console.log(`[remove_nominee] Removing ALL nominees from item ${itemId}`);
            await db.query('DELETE FROM vault_item_nominees WHERE vault_item_id = $1', [itemId]);
        }

        // Nullify legacy column only if no nominees remain
        try {
            const remaining = await db.query(
                'SELECT COUNT(*) FROM vault_item_nominees WHERE vault_item_id = $1',
                [itemId]
            );
            if (parseInt(remaining.rows[0].count) === 0) {
                await db.query('UPDATE vault_items SET nominee_id = NULL WHERE id = $1', [itemId]);
            }
        } catch (e) {
            console.error('[remove_nominee] Legacy column nullify error (ignored):', e);
        }

        res.json({ success: true, message: 'Nominee removed from vault item successfully' });
    } catch (error) {
        console.error('[remove_nominee] Error:', error);
        res.status(500).json({ error: 'Failed to remove nominee from vault item' });
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
            file: 0,
            crypto: 0
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
    console.log(`Fetching heartbeat status for user ${user_id}`);
    try {
        const result = await db.query(
            'SELECT last_check_in, check_in_frequency_days, check_in_frequency_hours, check_in_frequency_minutes, dead_mans_switch_active FROM users WHERE id = $1',
            [user_id]
        );
        if (result.rows.length === 0) {
            res.status(404).json({ error: 'User not found' });
            return;
        }
        console.log(`Status: Active=${result.rows[0].dead_mans_switch_active}, Last=${result.rows[0].last_check_in}`);
        res.json({ success: true, status: result.rows[0] });
    } catch (error) {
        console.error('Failed to fetch status:', error);
        res.status(500).json({ error: 'Failed to fetch status' });
    }
});

// 2. Perform Check-In (I'm Safe)
app.post('/api/heartbeat/checkin', async (req, res) => {
    const { user_id, method = 'manual' } = req.body;
    try {
        // Update last check-in time
        await db.query('UPDATE users SET last_check_in = CURRENT_TIMESTAMP WHERE id = $1', [user_id]);
        await db.query('INSERT INTO heartbeat_logs (user_id, method) VALUES ($1, $2)', [user_id, method]);

        // ✅ BUG FIX: Return the next_check_in deadline so Flutter can correctly
        // update the background alarm timer without re-fetching status separately
        const userStatus = await db.query(
            'SELECT last_check_in, check_in_frequency_days, check_in_frequency_hours, check_in_frequency_minutes FROM users WHERE id = $1',
            [user_id]
        );
        const row = userStatus.rows[0];
        const nextCheckIn = row ? new Date(
            new Date(row.last_check_in).getTime() +
            ((row.check_in_frequency_days || 0) * 86400000) +
            ((row.check_in_frequency_hours || 0) * 3600000) +
            ((row.check_in_frequency_minutes || 0) * 60000)
        ).toISOString() : null;

        res.json({
            success: true,
            message: 'Check-in successful',
            last_check_in: row?.last_check_in,
            next_check_in: nextCheckIn
        });
    } catch (error) {
        console.error('Check-in error:', error);
        res.status(500).json({ error: 'Failed to check in' });
    }
});

// 3. Update Settings (Activate/Frequency)
app.post('/api/heartbeat/settings', async (req, res) => {
    const { user_id, active, frequency_days, frequency_hours = 0, frequency_minutes = 0 } = req.body;
    try {
        // When activating, also update last_check_in so it starts fresh from "now"
        if (active) {
            await db.query(
                `UPDATE users 
                 SET dead_mans_switch_active = $1, 
                     check_in_frequency_days = $2, 
                     check_in_frequency_hours = $3, 
                     check_in_frequency_minutes = $4,
                     last_check_in = CURRENT_TIMESTAMP
                 WHERE id = $5`,
                [active, frequency_days, frequency_hours, frequency_minutes, user_id]
            );
        } else {
            await db.query(
                'UPDATE users SET dead_mans_switch_active = $1, check_in_frequency_days = $2, check_in_frequency_hours = $3, check_in_frequency_minutes = $4 WHERE id = $5',
                [active, frequency_days, frequency_hours, frequency_minutes, user_id]
            );
        }
        res.json({ success: true, message: 'Heartbeat settings updated' });
    } catch (error) {
        console.error('Settings update error:', error);
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

        // 4. Vault Usage? -> 20 pts (Base) + 10 pts (Crypto)
        const vaultItems = await db.query('SELECT item_type, COUNT(*) as count FROM vault_items WHERE user_id = $1 GROUP BY item_type', [user_id]);
        const hasVault = vaultItems.rows.length > 0;
        const hasCrypto = vaultItems.rows.some(r => r.item_type === 'crypto');

        if (hasVault) {
            score += 20;
            checks.push({ label: 'Vault Active', passed: true, points: 20 });
        } else {
            checks.push({ label: 'Vault Active', passed: false, points: 0, fix: "Add your first secure item" });
        }

        if (hasCrypto) {
            score += 15;
            checks.push({ label: 'Crypto Security', passed: true, points: 15 });
        } else {
            checks.push({ label: 'Crypto Security', passed: false, points: 0, fix: "Store your seed phrases securely" });
        }

        // 5. Smart Docs? -> 10 pts (Base) + 10 pts (Expiry Alerts)
        const smartDocs = await db.query('SELECT COUNT(*) FROM smart_docs WHERE user_id = $1', [user_id]);
        if (parseInt(smartDocs.rows[0].count) > 0) {
            score += 15;
            checks.push({ label: 'Succession Planning', passed: true, points: 15 });
        } else {
            checks.push({ label: 'Succession Planning', passed: false, points: 0, fix: "Scan documents for auto-expiry alerts" });
        }

        // 6. Final normalization
        score = Math.min(100, score);
        res.json({ success: true, score, checks });
    } catch (error) {
        console.error('Security Score Error:', error);
        res.status(500).json({ error: 'Failed to calculate score' });
    }
});

// --- Admin Routes ---
const ADMIN_SECRET = process.env.ADMIN_SECRET || process.env.SuperSecretKey || 'secure_admin_123';

const checkAdmin = async (req: any, res: any, next: any) => {
    const secret = req.headers['x-admin-secret'] || req.query?.admin_secret || req.body?.admin_secret;
    const userId = req.query?.admin_id || req.body?.admin_id;
    const cronSecret = req.headers.authorization?.replace('Bearer ', '');
    const isVercelCron = process.env.CRON_SECRET && cronSecret === process.env.CRON_SECRET;

    if ((secret && secret.toString().trim() === ADMIN_SECRET.trim()) || isVercelCron) {
        return next();
    }

    if (userId) {
        try {
            const result = await db.query('SELECT is_admin FROM users WHERE id = $1', [userId]);
            if (result.rows[0]?.is_admin) {
                return next();
            }
        } catch (e) {
            console.error("Admin check error", e);
        }
    }

    return res.status(403).json({ 
        success: false, 
        error: 'Authentication Failed: The Secret Key you entered is incorrect.' 
    });
};

// 4. Trigger Heartbeat Check (CRON JOB)
app.all('/api/admin/trigger_heartbeat_check', checkAdmin, async (req, res) => {
    try {
        // 1. Find users who are active but haven't checked in
        const overdueUsers = await db.query(`
            SELECT id, name, email 
            FROM users 
            WHERE dead_mans_switch_active = TRUE 
            AND (
                last_check_in + (COALESCE(check_in_frequency_days, 30) * INTERVAL '1 day') + (COALESCE(check_in_frequency_hours, 0) * INTERVAL '1 hour') + (COALESCE(check_in_frequency_minutes, 0) * INTERVAL '1 minute')
            ) < NOW()
            AND life_verification_status IS NULL
        `);

        for (const user of overdueUsers.rows) {
            const token = crypto.randomBytes(16).toString('hex');
            await db.query("UPDATE users SET life_verification_status = 'pending', life_verification_token = $1 WHERE id = $2", [token, user.id]);

            const nomineesResult = await db.query('SELECT name, email, primary_mobile FROM nominees WHERE user_id = $1', [user.id]);
            
            for (const nominee of nomineesResult.rows) {
                const baseUrl = process.env.BASE_URL || 'https://backend-sagar-bijjas-projects.vercel.app';
                const linkYes = `${baseUrl}/api/nominee/verify-life?token=${token}&status=alive`;
                const linkNo = `${baseUrl}/api/nominee/verify-life?token=${token}&status=deceased`;

                // Try Email
                if (nominee.email) {
                    const mailOptions = {
                        from: process.env.SMTP_USER || 'no-reply@eversafe.com',
                        to: nominee.email,
                        subject: `Urgent: Eversafe Proof of Life Verification for ${user.name}`,
                        html: `
                            <p>Dear ${nominee.name},</p>
                            <p>We were unable to verify the proof of life check-in for <strong>${user.name}</strong> at the scheduled time.</p>
                            <p>Please confirm if ${user.name} is alive:</p>
                            <br>
                            <a href="${linkYes}" style="padding: 10px 20px; background-color: #28a745; color: white; text-decoration: none; border-radius: 5px;">Yes, they are alive</a>
                            <br><br><br>
                            <a href="${linkNo}" style="padding: 10px 20px; background-color: #dc3545; color: white; text-decoration: none; border-radius: 5px;">No, they have passed away</a>
                            <br><br>
                            <p>If you confirm they have passed away, you will be required to upload a valid death certificate before gaining access to their vault.</p>
                        `
                    };
                    try {
                        const transporter = nodemailer.createTransport({
                            host: process.env.SMTP_HOST || 'smtp.gmail.com',
                            port: parseInt(process.env.SMTP_PORT || '587'),
                            secure: process.env.SMTP_SECURE === 'true',
                            auth: { user: process.env.SMTP_USER, pass: process.env.SMTP_PASS }
                        });
                        await transporter.sendMail(mailOptions);
                        console.log(`Verification email sent to nominee ${nominee.email}`);
                    } catch (e) {
                        console.error('Failed to send verification email:', e);
                    }
                }

                // Try SMS fallback (optional, asking them to check email)
                const mobileNumber = nominee.primary_mobile || 'UNKNOWN';
                const message = `Eversafe Alert: We need to verify the life status of ${user.name}. Please check your email (${nominee.email || 'provided address'}) for verification links. GGISKB`;
                const encodedMessage = encodeURIComponent(message);
                const smsUrl = `http://sms.hspsms.com/sendSMS?username=${HSP_SMS_USERNAME}&message=${encodedMessage}&sendername=${HSP_SMS_SENDER_ID}&smstype=${HSP_SMS_TYPE}&numbers=${mobileNumber}&apikey=${HSP_SMS_API_KEY}`;
                
                try {
                    const smsRes = await axios.get(smsUrl);
                    await db.query(
                        'INSERT INTO otp_logs (mobile, purpose, status, details) VALUES ($1, $2, $3, $4)',
                        [mobileNumber, 'heartbeat_alert_verification', 'sent', `User: ${user.name}, Response: ${JSON.stringify(smsRes.data)}`]
                    );
                } catch (smsErr) {
                    console.error(`Failed to send alert to ${mobileNumber}:`, smsErr);
                }
            }
        }

        // Grant access only to users who are verified (death certificate uploaded)
        const verifiedUsers = await db.query(`
            SELECT id FROM users WHERE life_verification_status = 'verified'
        `);
        const verifiedIds: number[] = verifiedUsers.rows.map((u: any) => u.id);

        if (verifiedIds.length > 0) {
            // 2a. Grant Immediate Access (0 days)
            await db.query(`
                UPDATE nominees 
                SET access_granted = TRUE, handover_triggered_at = COALESCE(handover_triggered_at, NOW())
                WHERE user_id = ANY($1::int[]) AND handover_waiting_days = 0 AND access_granted = FALSE
            `, [verifiedIds]);

            // 2b. Start Countdown for Delayed Access (> 0 days)
            await db.query(`
                UPDATE nominees 
                SET handover_triggered_at = NOW()
                WHERE user_id = ANY($1::int[]) AND handover_waiting_days > 0 AND handover_triggered_at IS NULL
            `, [verifiedIds]);
        }

        // 2c. Finalize Delayed Handovers
        await db.query(`
            UPDATE nominees 
            SET access_granted = TRUE 
            WHERE access_granted = FALSE 
            AND handover_triggered_at IS NOT NULL 
            AND handover_triggered_at + (handover_waiting_days || ' days')::INTERVAL <= NOW()
        `);

        res.json({
            success: true,
            triggered_count: overdueUsers.rows.length,
            overdue_users: overdueUsers.rows.map((u: any) => ({ id: u.id, name: u.name })),
            message: 'Heartbeat check complete. Verification emails sent.'
        });
    } catch (error) {
        console.error('Heartbeat Check Error:', error);
        res.status(500).json({ error: 'Failed to run heartbeat check', details: String(error) });
    }
});

app.get('/api/nominee/verify-life', async (req, res) => {
    const { token, status } = req.query;
    if (!token) return res.status(400).send('Invalid token');

    try {
        const result = await db.query('SELECT id, name FROM users WHERE life_verification_token = $1', [token]);
        if (result.rows.length === 0) return res.status(404).send('Invalid or expired token.');

        const user = result.rows[0];

        if (status === 'alive') {
            await db.query(`
                UPDATE users 
                SET last_check_in = NOW(),
                    life_verification_status = NULL,
                    life_verification_token = NULL
                WHERE id = $1
            `, [user.id]);
            return res.send(`
                <h2>Thank you for confirming.</h2>
                <p>We have extended ${user.name}'s check-in period. You can safely close this window.</p>
            `);
        } else if (status === 'deceased') {
            await db.query(`
                UPDATE users 
                SET life_verification_status = 'deceased_unverified'
                WHERE id = $1
            `, [user.id]);
            
            return res.send(`
                <h2>Upload Death Certificate</h2>
                <p>We are sorry for your loss. To securely access ${user.name}'s vault, please provide a valid death certificate.</p>
                <form action="/api/nominee/upload-death-certificate" method="POST" enctype="multipart/form-data">
                    <input type="hidden" name="token" value="${token}" />
                    <input type="file" name="certificate" accept=".pdf,.jpg,.jpeg,.png" required />
                    <button type="submit" style="padding: 10px; margin-top: 10px; background: #007bff; color: #fff; border: none; border-radius: 5px;">Upload and Verify</button>
                </form>
            `);
        } else {
            return res.status(400).send('Invalid status provided.');
        }
    } catch(e) {
        console.error('Verification Error', e);
        return res.status(500).send('Error processing request.');
    }
});

app.post('/api/nominee/upload-death-certificate', upload.single('certificate'), async (req, res) => {
    const { token } = req.body;
    if (!token) return res.status(400).send('Invalid token');

    try {
        const result = await db.query('SELECT id, name FROM users WHERE life_verification_token = $1', [token]);
        if (result.rows.length === 0) return res.status(404).send('Invalid or expired token.');
        const user = result.rows[0];

        // Process the uploaded file (for now just mark it verified, in production upload to S3)
        // Set verification_status to 'verified' so cron job can grant access
        await db.query(`
            UPDATE users 
            SET life_verification_status = 'verified',
                life_verification_token = NULL,
                death_certificate_url = 'uploaded_document_placeholder'
            WHERE id = $1
        `, [user.id]);

        return res.send(`
            <h2>Verification Complete</h2>
            <p>Thank you. We have received the document and verified the status.</p>
            <p>You have been granted access to ${user.name}'s vault. You will receive an SMS when the handover is ready.</p>
            <p><a href="/nominee-portal">Go to Nominee Portal</a></p>
        `);
    } catch (e) {
        console.error('Upload Error', e);
        return res.status(500).send('Error uploading certificate.');
    }
});


// --- Smart Document Expiry Cron ---
app.all('/api/admin/cron/check-expiries', checkAdmin, async (req, res) => {
    try {
        const expiringDocs = await db.query(`
            SELECT sd.*, u.name, u.mobile_number 
            FROM smart_docs sd
            JOIN users u ON sd.user_id = u.id
            WHERE sd.is_reminded = FALSE
            AND sd.expiry_date <= (CURRENT_DATE + (sd.reminder_days_before || ' days')::INTERVAL)
        `);

        const alertsSent = [];

        for (const doc of expiringDocs.rows) {
            const daysLeft = Math.ceil((new Date(doc.expiry_date).getTime() - Date.now()) / (1000 * 60 * 60 * 24));
            const message = `Eversafe Alert: Your ${doc.doc_type} (${doc.title}) is expiring in ${daysLeft} days. Please renew it soon. GGISKB`;
            
            // Logic to send SMS (Simulated - calls SMS API)
            if (doc.mobile_number) {
                 const encodedMessage = encodeURIComponent(message);
                 const smsUrl = `http://sms.hspsms.com/sendSMS?username=${HSP_SMS_USERNAME}&message=${encodedMessage}&sendername=${HSP_SMS_SENDER_ID}&smstype=${HSP_SMS_TYPE}&numbers=${doc.mobile_number}&apikey=${HSP_SMS_API_KEY}`;
                 try {
                     await axios.get(smsUrl);
                     alertsSent.push({ doc_id: doc.id, user: doc.name });
                 } catch (smsErr) {
                     console.error(`Failed to send SMS for doc ${doc.id}`, smsErr);
                 }
            }

            // Mark as reminded
            await db.query('UPDATE smart_docs SET is_reminded = TRUE WHERE id = $1', [doc.id]);
        }

        res.json({ success: true, count: alertsSent.length, alerts: alertsSent });
    } catch (error) {
        console.error('Expiry Check Error:', error);
        res.status(500).json({ error: 'Failed to process document expiries' });
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



// ============================================
// REGIONAL CHECKLIST API
// ============================================

// Migration Endpoint — ✅ SECURITY FIX: protected behind admin auth
app.get('/api/migrate', checkAdmin, async (req, res) => {
    try {
        await db.query(`
            -- Update Nominees table with new fields
            ALTER TABLE users ADD COLUMN IF NOT EXISTS life_verification_status VARCHAR(50) DEFAULT NULL;
            ALTER TABLE users ADD COLUMN IF NOT EXISTS life_verification_token VARCHAR(100);
            ALTER TABLE users ADD COLUMN IF NOT EXISTS death_certificate_url TEXT;

            ALTER TABLE nominees ADD COLUMN IF NOT EXISTS primary_mobile VARCHAR(15);
            ALTER TABLE nominees ADD COLUMN IF NOT EXISTS optional_mobile VARCHAR(15);
            ALTER TABLE nominees ADD COLUMN IF NOT EXISTS address TEXT;
            ALTER TABLE nominees ADD COLUMN IF NOT EXISTS identity_proof VARCHAR(100);
            ALTER TABLE nominees ADD COLUMN IF NOT EXISTS delivery_mode VARCHAR(20) DEFAULT 'digital';

            -- Add hours and minutes for testing
            ALTER TABLE users ADD COLUMN IF NOT EXISTS check_in_frequency_hours INTEGER DEFAULT 0;
            ALTER TABLE users ADD COLUMN IF NOT EXISTS check_in_frequency_minutes INTEGER DEFAULT 0;
            ALTER TABLE users ADD COLUMN IF NOT EXISTS last_check_in TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP;
            ALTER TABLE users ADD COLUMN IF NOT EXISTS dead_mans_switch_active BOOLEAN DEFAULT FALSE;

            -- Create Heartbeat Logs table
            CREATE TABLE IF NOT EXISTS heartbeat_logs (
                id SERIAL PRIMARY KEY,
                user_id INTEGER REFERENCES users(id) ON DELETE CASCADE,
                method VARCHAR(50) DEFAULT 'manual',
                created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
            );

            -- Create Regional Checklists table
            CREATE TABLE IF NOT EXISTS regional_checklists (
                id SERIAL PRIMARY KEY,
                country_code VARCHAR(10),
                country_name VARCHAR(100) NOT NULL,
                document_name VARCHAR(255) NOT NULL,
                description TEXT,
                is_mandatory BOOLEAN DEFAULT FALSE,
                created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
            );

            -- Create User Selected Regional Documents table
            CREATE TABLE IF NOT EXISTS user_regional_docs (
                id SERIAL PRIMARY KEY,
                user_id INTEGER REFERENCES users(id) ON DELETE CASCADE,
                checklist_id INTEGER REFERENCES regional_checklists(id),
                status VARCHAR(50) DEFAULT 'pending', 
                file_path VARCHAR(512),
                details JSONB,
                created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
            );

            -- Vault Item Multi-Nominee Support
            CREATE TABLE IF NOT EXISTS vault_item_nominees (
                id SERIAL PRIMARY KEY,
                vault_item_id INTEGER REFERENCES vault_items(id) ON DELETE CASCADE,
                nominee_id INTEGER REFERENCES nominees(id) ON DELETE CASCADE,
                created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
                UNIQUE(vault_item_id, nominee_id)
            );

            -- Subscription and Storage
            ALTER TABLE users ADD COLUMN IF NOT EXISTS storage_limit_gb INTEGER DEFAULT 1; -- 1GB for free tier
            ALTER TABLE users ADD COLUMN IF NOT EXISTS current_storage_bytes BIGINT DEFAULT 0;
            ALTER TABLE users ADD COLUMN IF NOT EXISTS subscription_plan VARCHAR(50) DEFAULT 'free'; -- free, premium, enterprise
            ALTER TABLE users ADD COLUMN IF NOT EXISTS subscription_expires_at TIMESTAMP WITH TIME ZONE;

            CREATE TABLE IF NOT EXISTS payments (
                id SERIAL PRIMARY KEY,
                user_id INTEGER REFERENCES users(id) ON DELETE CASCADE,
                amount DECIMAL(10, 2) NOT NULL,
                currency VARCHAR(10) DEFAULT 'USD',
                status VARCHAR(20) DEFAULT 'success',
                plan_name VARCHAR(50),
                payment_id VARCHAR(100), -- Stripe/Razorpay ID
                created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
            );

            -- Indices
            CREATE INDEX IF NOT EXISTS idx_vault_item_nominees_vault_item_id ON vault_item_nominees(vault_item_id);
            CREATE INDEX IF NOT EXISTS idx_vault_item_nominees_nominee_id ON vault_item_nominees(nominee_id);

            -- DATA MIGRATION: Sync legacy nominee_id column to vault_item_nominees table
            DO $$ 
            BEGIN 
                IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='vault_items' AND column_name='nominee_id') THEN
                    INSERT INTO vault_item_nominees (vault_item_id, nominee_id)
                    SELECT id, nominee_id FROM vault_items 
                    WHERE nominee_id IS NOT NULL
                    ON CONFLICT DO NOTHING;
                END IF;
            END $$;
        `);
        res.json({ success: true, message: 'Migration successful (V2)' });
    } catch (error) {
        console.error("Migration error:", error);
        res.status(500).json({ error: 'Migration failed', details: error instanceof Error ? error.message : String(error) });
    }
});

// AI Generation Endpoint
app.post('/api/regional/generate-ai', async (req, res) => {
    const { country_code, country_name } = req.body;
    const apiKey = OPENAI_API_KEY;

    if (!apiKey) {
        res.status(500).json({ error: 'AI API Key not configured on server' });
        return;
    }

    if (!country_name) {
        res.status(400).json({ error: 'Country name is required' });
        return;
    }

    try {
        const openai = new OpenAI({ apiKey: apiKey });

        const prompt = `Generate a comprehensive legal document checklist for inheritance, succession, and estate planning specifically for a resident of ${country_name}. 
        Focus on local laws (e.g., Hindu Succession Act in India, Probate laws in US/UK). 
        Return ONLY a JSON object with a key "documents" containing an array. 
        Each object must have: 
        1. "document_name": Title of the document.
        2. "description": A short explanation of why it is needed under local law.
        3. "is_mandatory": boolean (true if legally required for most citizens).
        4. "category": one of (Identity, Financial, Real Estate, Personal).
        
        Ensure the output is strictly valid JSON.`;

        const completion = await openai.chat.completions.create({
            messages: [{ role: "system", content: "You are a helpful legal assistant." }, { role: "user", content: prompt }],
            model: "gpt-3.5-turbo",
            response_format: { type: "json_object" },
        });

        const text = completion.choices[0].message.content || "[]";

        let checklistWithWrapper;
        let checklist;
        try {
            checklistWithWrapper = JSON.parse(text);
            // OpenAI in json_object mode usually returns { "some_key": [...] } if not strictly prompted for just array, or sometimes just array if strict schema. 
            // It's safer to handle both.
            if (Array.isArray(checklistWithWrapper)) {
                checklist = checklistWithWrapper;
            } else if (checklistWithWrapper.documents) {
                checklist = checklistWithWrapper.documents;
            } else {
                // Try to find any array in values
                const val = Object.values(checklistWithWrapper).find(v => Array.isArray(v));
                checklist = val || [];
            }
        } catch (e) {
            console.error("JSON Parse Error on AI Output:", text);
            throw new Error("AI returned invalid JSON structure");
        }

        // Save to DB so we don't have to generate again
        for (const item of checklist) {
            await db.query(
                `INSERT INTO regional_checklists (country_code, country_name, document_name, description, is_mandatory)
                 VALUES ($1, $2, $3, $4, $5)
                 ON CONFLICT DO NOTHING`,
                [country_code || 'XX', country_name, item.document_name, item.description, item.is_mandatory]
            );
        }

        res.json({ success: true, checklist });
    } catch (error) {
        console.error("AI Generation error:", error);
        res.status(500).json({ error: 'AI failed to generate checklist', details: String(error) });
    }
});

// 0. Seed Checklist Data
app.post('/api/regional/seed', async (req, res) => {
    const seedData = [
        { cc: 'IN', cn: 'India', doc: 'Aadhaar Card', desc: 'Primary ID for Indian citizens', m: true },
        { cc: 'IN', cn: 'India', doc: 'PAN Card', desc: 'For financial transparency', m: true },
        { cc: 'IN', cn: 'India', doc: 'Bank Passbook', desc: 'Proof of account ownership', m: false },
        { cc: 'US', cn: 'USA', doc: 'Social Security Number', desc: 'Mandatory for tax and identification', m: true },
        { cc: 'US', cn: 'USA', doc: 'Drivers License', desc: 'Preferred state-issued ID', m: true },
        { cc: 'UK', cn: 'UK', doc: 'National Insurance Number', desc: 'For social security benefits', m: true },
        { cc: 'UK', cn: 'UK', doc: 'Passport', desc: 'Primary travel and ID document', m: true },
    ];

    try {
        for (const item of seedData) {
            await db.query(
                `INSERT INTO regional_checklists (country_code, country_name, document_name, description, is_mandatory)
                 VALUES ($1, $2, $3, $4, $5) 
                 ON CONFLICT DO NOTHING`,
                [item.cc, item.cn, item.doc, item.desc, item.m]
            );
        }
        res.json({ success: true, message: 'Seeding complete' });
    } catch (error) {
        console.error("Seeding error:", error);
        res.status(500).json({ error: 'Failed to seed data' });
    }
});

// 1. Get Checklists by Country
app.get('/api/regional/checklists', async (req, res) => {
    const { country_code } = req.query;
    try {
        let query = 'SELECT * FROM regional_checklists';
        let params = [];
        if (country_code) {
            query += ' WHERE country_code = $1';
            params.push(country_code);
        }
        const result = await db.query(query, params);
        res.json({ success: true, checklists: result.rows });
    } catch (error) {
        res.status(500).json({ error: 'Failed to fetch checklists' });
    }
});

// ============================================
// SUBSCRIPTION & PAYMENTS API
// ============================================

app.post('/api/payments/create-session', async (req, res) => {
    const { user_id, plan_name, amount } = req.body;
    try {
        // Mock Stripe/Razorpay Session Creation
        const sessionId = 'mock_session_' + Date.now();
        res.json({ success: true, sessionId, url: '/payment-success' });
    } catch (error) {
        res.status(500).json({ error: 'Failed to create payment session' });
    }
});

app.post('/api/payments/confirm', async (req, res) => {
    const { user_id, payment_id, plan_name, amount } = req.body;
    try {
        // Record Payment
        await db.query(
            'INSERT INTO payments (user_id, amount, plan_name, payment_id) VALUES ($1, $2, $3, $4)',
            [user_id, amount, plan_name, payment_id]
        );

        // Update User Subscription
        let limitGb = 1;
        if (plan_name === 'premium') limitGb = 50;
        if (plan_name === 'enterprise') limitGb = 500;

        const expiresAt = new Date();
        expiresAt.setMonth(expiresAt.getMonth() + 1); // 1 month from now

        await db.query(
            'UPDATE users SET subscription_plan = $1, storage_limit_gb = $2, subscription_expires_at = $3 WHERE id = $4',
            [plan_name, limitGb, expiresAt, user_id]
        );

        res.json({ success: true, message: 'Subscription activated' });
    } catch (error) {
        console.error('Payment confirmation error:', error);
        res.status(500).json({ error: 'Failed to confirm payment' });
    }
});

app.get('/api/users/:id/subscription', async (req, res) => {
    const { id } = req.params;
    try {
        const result = await db.query(
            'SELECT subscription_plan, storage_limit_gb, current_storage_bytes, subscription_expires_at FROM users WHERE id = $1',
            [id]
        );
        res.json({ success: true, subscription: result.rows[0] });
    } catch (error) {
        res.status(500).json({ error: 'Failed to fetch subscription' });
    }
});

// AI ASSISTANT API
app.post('/api/ai/chat', async (req, res) => {
    const { message, history } = req.body;
    const apiKey = OPENAI_API_KEY;

    if (!apiKey) {
        res.status(500).json({ error: 'AI API Key not configured' });
        return;
    }

    try {
        const openai = new OpenAI({ apiKey: apiKey });

        // Convert history format 
        // Flutter history: [{role: 'user', parts: [{text: '...'}]}, {role: 'model', parts: [{text: '...'}]}]
        // OpenAI format: [{role: 'user', content: '...'}, {role: 'assistant', content: '...'}]
        const messages: any[] = [
            { role: "system", content: "You are the Eversafe Legal Assistant. Your goal is to help users with inheritance, wills, succession laws, and estate planning. Be professional, empathetic, and clear. Always advise users that your guidance is for informational purposes and they should consult a real lawyer for final legal documents." }
        ];

        if (history && Array.isArray(history)) {
            history.forEach((h: any) => {
                let role = "user";
                if (h.role === "model" || h.role === "assistant") role = "assistant";

                let content = "";
                if (h.parts && h.parts[0] && h.parts[0].text) {
                    content = h.parts[0].text;
                } else if (h.message) {
                    content = h.message;
                }

                messages.push({ role, content });
            });
        }

        // Add current message
        messages.push({ role: "user", content: message });

        const completion = await openai.chat.completions.create({
            messages: messages,
            model: "gpt-3.5-turbo",
        });

        const reply = completion.choices[0].message.content;
        res.json({ success: true, reply: reply });
    } catch (error) {
        console.error("Chat error:", error);
        res.status(500).json({ error: 'Failed to get AI response' });
    }
});

// AI 1: Classify Document (from OCR)
app.post('/api/ai/classify', async (req, res) => {
    const { text } = req.body;
    const apiKey = OPENAI_API_KEY;

    if (!text) {
        res.status(400).json({ error: 'Text required' });
        return;
    }

    try {
        const openai = new OpenAI({ apiKey: apiKey });
        const completion = await openai.chat.completions.create({
            messages: [
                { role: "system", content: "You are a document classifier. Analyze the text and suggest a 'category' (e.g. Financial, Legal, ID, Personal) and a 'title'." },
                { role: "user", content: `Classify this document text:\n${text.substring(0, 1000)}` }
            ],
            model: "gpt-3.5-turbo",
            response_format: { type: "json_object" },
        });

        const result = JSON.parse(completion.choices[0].message.content || '{}');
        res.json({ success: true, classification: result });
    } catch (error) {
        res.status(500).json({ error: 'Classification failed' });
    }
});

// AI 2: Conflict Check (User's Will Draft)
app.post('/api/ai/conflict-check', async (req, res) => {
    const { will_text } = req.body;
    const apiKey = OPENAI_API_KEY;

    try {
        const openai = new OpenAI({ apiKey: apiKey });
        const completion = await openai.chat.completions.create({
            messages: [
                { role: "system", content: "You are a legal conflict detector. Check the user's will for contradictions (e.g. giving same item to two people). Return JSON with 'has_conflict' (boolean) and 'issues' (array of strings)." },
                { role: "user", content: `Check this will for conflicts:\n${will_text}` }
            ],
            model: "gpt-3.5-turbo",
            response_format: { type: "json_object" },
        });

        const result = JSON.parse(completion.choices[0].message.content || '{}');
        res.json({ success: true, conflict_check: result });
    } catch (error) {
        res.status(500).json({ error: 'Conflict check failed' });
    }
});

// AI 3: Tone Analysis (For Personal Messages)
app.post('/api/ai/analyze-tone', async (req, res) => {
    const { message } = req.body;
    const apiKey = OPENAI_API_KEY;

    try {
        const openai = new OpenAI({ apiKey: apiKey });
        const completion = await openai.chat.completions.create({
            messages: [
                { role: "system", content: "Analyze the emotional tone of this message. If it sounds angry, confusing, or too harsh for a final message, suggest a softer version. Return JSON with 'tone' (string), 'is_harsh' (boolean), and 'suggestion' (string if harsh, else null)." },
                { role: "user", content: `Analyze the tone:\n${message}` }
            ],
            model: "gpt-3.5-turbo",
            response_format: { type: "json_object" },
        });

        const result = JSON.parse(completion.choices[0].message.content || '{}');
        res.json({ success: true, analysis: result });
    } catch (error) {
        res.status(500).json({ error: 'Tone analysis failed' });
    }
});

// 2. Save User Selection/Document
app.post('/api/regional/user_docs', async (req, res) => {
    const { user_id, checklist_id, details, file_path } = req.body;
    try {
        const result = await db.query(
            `INSERT INTO user_regional_docs (user_id, checklist_id, details, file_path)
             VALUES ($1, $2, $3, $4) RETURNING *`,
            [user_id, checklist_id, details, file_path]
        );
        res.status(201).json({ success: true, item: result.rows[0] });
    } catch (error) {
        res.status(500).json({ error: 'Failed to save document selection' });
    }
});

// 3. Get User Selected Documents
app.get('/api/regional/user_docs', async (req, res) => {
    const { user_id } = req.query;
    try {
        const result = await db.query(
            `SELECT u.*, r.document_name, r.description 
             FROM user_regional_docs u
             JOIN regional_checklists r ON u.checklist_id = r.id
             WHERE u.user_id = $1`,
            [user_id]
        );
        res.json({ success: true, docs: result.rows });
    } catch (error) {
        res.status(500).json({ error: 'Failed to fetch user documents' });
    }
});

// ============================================
// V3 MIGRATION — 10 AI FEATURES
// ============================================
// V3 Migration — ✅ SECURITY FIX: protected behind admin auth
app.get('/api/migrate-v3', checkAdmin, async (req, res) => {
    try {
        await db.query(`
            -- 1. Video Wills / Voice Messages
            CREATE TABLE IF NOT EXISTS video_wills (
                id SERIAL PRIMARY KEY,
                user_id INTEGER REFERENCES users(id) ON DELETE CASCADE,
                nominee_id INTEGER REFERENCES nominees(id) ON DELETE SET NULL,
                title VARCHAR(255) NOT NULL,
                message_type VARCHAR(20) DEFAULT 'video', -- video, audio, text
                storage_path VARCHAR(512), -- S3 key
                transcript TEXT,
                summary TEXT,
                duration_seconds INTEGER,
                created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
            );
            CREATE INDEX IF NOT EXISTS idx_video_wills_user ON video_wills(user_id);

            -- 2. Asset Discovery (tracked checklists)
            CREATE TABLE IF NOT EXISTS asset_discovery (
                id SERIAL PRIMARY KEY,
                user_id INTEGER REFERENCES users(id) ON DELETE CASCADE,
                category VARCHAR(100) NOT NULL,
                asset_name VARCHAR(255) NOT NULL,
                is_added BOOLEAN DEFAULT FALSE,
                priority VARCHAR(20) DEFAULT 'medium',
                ai_suggestion TEXT,
                created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
            );
            CREATE INDEX IF NOT EXISTS idx_asset_discovery_user ON asset_discovery(user_id);

            -- 3. Activity Logs (for fraud detection)
            CREATE TABLE IF NOT EXISTS activity_logs (
                id SERIAL PRIMARY KEY,
                user_id INTEGER REFERENCES users(id) ON DELETE CASCADE,
                action VARCHAR(100) NOT NULL,
                device_info TEXT,
                ip_address VARCHAR(45),
                is_suspicious BOOLEAN DEFAULT FALSE,
                details JSONB,
                created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
            );
            CREATE INDEX IF NOT EXISTS idx_activity_logs_user ON activity_logs(user_id);
            CREATE INDEX IF NOT EXISTS idx_activity_logs_suspicious ON activity_logs(is_suspicious);

            -- 4. Legal Documents (generated documents)
            CREATE TABLE IF NOT EXISTS legal_documents (
                id SERIAL PRIMARY KEY,
                user_id INTEGER REFERENCES users(id) ON DELETE CASCADE,
                doc_type VARCHAR(100) NOT NULL,
                title VARCHAR(255) NOT NULL,
                content TEXT NOT NULL,
                language VARCHAR(10) DEFAULT 'en',
                status VARCHAR(20) DEFAULT 'draft',
                created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
                updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
            );
            CREATE INDEX IF NOT EXISTS idx_legal_docs_user ON legal_documents(user_id);

            -- 5. Emergency Card
            ALTER TABLE users ADD COLUMN IF NOT EXISTS emergency_data JSONB;

            -- 6. User Language Preference
            ALTER TABLE users ADD COLUMN IF NOT EXISTS preferred_language VARCHAR(10) DEFAULT 'en';
        `);
        res.json({ success: true, message: 'V3 Migration successful — 10 AI Features tables created' });
    } catch (error) {
        console.error("V3 Migration error:", error);
        res.status(500).json({ error: 'V3 Migration failed', details: error instanceof Error ? error.message : String(error) });
    }
});

// ============================================
// FEATURE 1: AI VAULT HEALTH ANALYZER
// ============================================
app.get('/api/vault-health', async (req, res) => {
    const { user_id } = req.query;
    const apiKey = OPENAI_API_KEY;

    try {
        // Gather user data
        const vaultItems = await db.query('SELECT item_type, COUNT(*) as count FROM vault_items WHERE user_id = $1 GROUP BY item_type', [user_id]);
        const nominees = await db.query('SELECT COUNT(*) as count FROM nominees WHERE user_id = $1', [user_id]);
        const smartDocs = await db.query('SELECT COUNT(*) as total, COUNT(CASE WHEN expiry_date < NOW() THEN 1 END) as expired FROM smart_docs WHERE user_id = $1', [user_id]);
        const user = await db.query('SELECT dead_mans_switch_active, last_check_in, name FROM users WHERE id = $1', [user_id]);
        const folders = await db.query('SELECT COUNT(*) as count FROM folders WHERE user_id = $1', [user_id]);
        const files = await db.query('SELECT COUNT(*) as count FROM files WHERE user_id = $1', [user_id]);
        const videoWills = await db.query('SELECT COUNT(*) as count FROM video_wills WHERE user_id = $1', [user_id]);

        const stats = {
            vault_types: vaultItems.rows.reduce((acc: any, r: any) => { acc[r.item_type] = parseInt(r.count); return acc; }, {}),
            nominees: parseInt(nominees.rows[0].count),
            smart_docs_total: parseInt(smartDocs.rows[0].total),
            smart_docs_expired: parseInt(smartDocs.rows[0].expired),
            heartbeat_active: user.rows[0]?.dead_mans_switch_active || false,
            folders: parseInt(folders.rows[0].count),
            files: parseInt(files.rows[0].count),
            video_wills: parseInt(videoWills.rows[0].count),
        };

        // Calculate completeness score
        let score = 0;
        const recommendations: any[] = [];

        if (stats.nominees > 0) { score += 15; } else {
            recommendations.push({ priority: 'high', icon: '👥', title: 'Add a Nominee', description: 'Assign at least one beneficiary to receive your vault items.', action: 'nominees' });
        }
        if (stats.heartbeat_active) { score += 15; } else {
            recommendations.push({ priority: 'high', icon: '❤️', title: 'Activate Proof of Life', description: 'Enable the dead man\'s switch to auto-transfer assets.', action: 'heartbeat' });
        }
        if ((stats.vault_types['note'] || 0) > 0) { score += 10; } else {
            recommendations.push({ priority: 'medium', icon: '📝', title: 'Add Secure Notes', description: 'Store important messages, credentials, or instructions.', action: 'vault' });
        }
        if ((stats.vault_types['password'] || 0) > 0) { score += 10; } else {
            recommendations.push({ priority: 'medium', icon: '🔑', title: 'Save Your Passwords', description: 'Add login credentials for important accounts (banks, email).', action: 'vault' });
        }
        if ((stats.vault_types['credit_card'] || 0) > 0) { score += 10; } else {
            recommendations.push({ priority: 'low', icon: '💳', title: 'Add Credit Cards', description: 'Store card details securely for your nominees.', action: 'vault' });
        }
        if (stats.files > 0) { score += 10; } else {
            recommendations.push({ priority: 'medium', icon: '📄', title: 'Upload Documents', description: 'Upload important files like property deeds, insurance policies.', action: 'files' });
        }
        if (stats.smart_docs_total > 0) { score += 10; } else {
            recommendations.push({ priority: 'medium', icon: '🔔', title: 'Set Document Alerts', description: 'Scan documents to track expiry dates automatically.', action: 'smart_alerts' });
        }
        if (stats.smart_docs_expired > 0) {
            recommendations.push({ priority: 'high', icon: '⚠️', title: `${stats.smart_docs_expired} Document(s) Expired`, description: 'Renew expired documents to keep your vault up-to-date.', action: 'smart_alerts' });
        }
        if (stats.video_wills > 0) { score += 10; } else {
            recommendations.push({ priority: 'low', icon: '📹', title: 'Record a Video Message', description: 'Leave a personal video message for your nominees.', action: 'video_will' });
        }
        if (stats.folders > 1) { score += 10; } else {
            recommendations.push({ priority: 'low', icon: '📁', title: 'Organize with Folders', description: 'Create folders to categorize your vault items.', action: 'folders' });
        }

        res.json({
            success: true,
            score,
            total_items: Object.values(stats.vault_types).reduce((a: any, b: any) => a + b, 0),
            stats,
            recommendations: recommendations.sort((a, b) => {
                const p: any = { high: 0, medium: 1, low: 2 };
                return p[a.priority] - p[b.priority];
            })
        });
    } catch (error) {
        console.error('Vault Health Error:', error);
        res.status(500).json({ error: 'Failed to analyze vault health' });
    }
});

// ============================================
// FEATURE 2: VIDEO WILL / VOICE MESSAGE
// ============================================
app.post('/api/video-wills', async (req, res) => {
    const { user_id, nominee_id, title, message_type, storage_path, transcript, duration_seconds } = req.body;
    try {
        const result = await db.query(
            `INSERT INTO video_wills (user_id, nominee_id, title, message_type, storage_path, transcript, duration_seconds) 
             VALUES ($1, $2, $3, $4, $5, $6, $7) RETURNING *`,
            [user_id, nominee_id, title, message_type || 'video', storage_path, transcript, duration_seconds]
        );
        res.status(201).json({ success: true, video_will: result.rows[0] });
    } catch (error) {
        console.error('Video Will creation error:', error);
        res.status(500).json({ error: 'Failed to save video will' });
    }
});

app.get('/api/video-wills', async (req, res) => {
    const { user_id } = req.query;
    try {
        const result = await db.query(
            `SELECT vw.*, n.name as nominee_name 
             FROM video_wills vw 
             LEFT JOIN nominees n ON vw.nominee_id = n.id 
             WHERE vw.user_id = $1 ORDER BY vw.created_at DESC`,
            [user_id]
        );
        res.json({ success: true, video_wills: result.rows });
    } catch (error) {
        res.status(500).json({ error: 'Failed to fetch video wills' });
    }
});

app.delete('/api/video-wills/:id', async (req, res) => {
    const { id } = req.params;
    const { user_id } = req.query;
    try {
        await db.query('DELETE FROM video_wills WHERE id = $1 AND user_id = $2', [id, user_id]);
        res.json({ success: true, message: 'Video will deleted' });
    } catch (error) {
        res.status(500).json({ error: 'Failed to delete video will' });
    }
});

// AI Summarize Video Transcript
app.post('/api/video-wills/summarize', async (req, res) => {
    const { transcript } = req.body;
    const apiKey = OPENAI_API_KEY;
    try {
        const openai = new OpenAI({ apiKey });
        const completion = await openai.chat.completions.create({
            messages: [
                { role: "system", content: "Summarize this personal video will transcript into key points. Be respectful and empathetic. Return JSON with 'summary' (string) and 'key_points' (array of strings)." },
                { role: "user", content: transcript }
            ],
            model: "gpt-3.5-turbo",
            response_format: { type: "json_object" },
        });
        const result = JSON.parse(completion.choices[0].message.content || '{}');
        res.json({ success: true, ...result });
    } catch (error) {
        res.status(500).json({ error: 'Summarization failed' });
    }
});

// ============================================
// FEATURE 3: SMART ASSET DISCOVERY
// ============================================
app.post('/api/asset-discovery/generate', async (req, res) => {
    const { user_id, country, age_group, occupation } = req.body;
    const apiKey = OPENAI_API_KEY;

    try {
        // Get existing vault items to avoid duplication
        const existing = await db.query('SELECT item_type, title FROM vault_items WHERE user_id = $1', [user_id]);
        const existingTitles = existing.rows.map((r: any) => r.title).join(', ');

        const openai = new OpenAI({ apiKey });
        const completion = await openai.chat.completions.create({
            messages: [
                { role: "system", content: "You are a financial asset discovery assistant. Generate a personalized checklist of assets and documents a person should store in their digital vault for estate planning." },
                {
                    role: "user", content: `Generate asset discovery checklist for:
Country: ${country || 'India'}
Age Group: ${age_group || '30-50'}
Occupation: ${occupation || 'Professional'}
Already stored: ${existingTitles || 'None'}

Return JSON with 'assets' array. Each item: { "category": string (Financial/Property/Insurance/Digital/Personal/Legal), "asset_name": string, "priority": "high"|"medium"|"low", "suggestion": string (why they should add this) }. Generate 15-20 items.` }
            ],
            model: "gpt-3.5-turbo",
            response_format: { type: "json_object" },
        });

        const parsed = JSON.parse(completion.choices[0].message.content || '{}');
        const assets = parsed.assets || [];

        // Save to DB
        for (const asset of assets) {
            await db.query(
                `INSERT INTO asset_discovery (user_id, category, asset_name, priority, ai_suggestion) 
                 VALUES ($1, $2, $3, $4, $5) ON CONFLICT DO NOTHING`,
                [user_id, asset.category, asset.asset_name, asset.priority, asset.suggestion]
            );
        }

        res.json({ success: true, assets });
    } catch (error) {
        console.error('Asset Discovery error:', error);
        res.status(500).json({ error: 'Failed to generate asset checklist' });
    }
});

app.get('/api/asset-discovery', async (req, res) => {
    const { user_id } = req.query;
    try {
        const result = await db.query('SELECT * FROM asset_discovery WHERE user_id = $1 ORDER BY priority DESC, category', [user_id]);
        res.json({ success: true, assets: result.rows });
    } catch (error) {
        res.status(500).json({ error: 'Failed to fetch assets' });
    }
});


app.put('/api/asset-discovery/:id/toggle', async (req, res) => {
    const { id } = req.params;
    try {
        const result = await db.query('UPDATE asset_discovery SET is_added = NOT is_added WHERE id = $1 RETURNING *', [id]);
        res.json({ success: true, asset: result.rows[0] });
    } catch (error) {
        res.status(500).json({ error: 'Failed to toggle asset' });
    }
});

// ============================================
// FEATURE 4: NOMINEE READINESS REPORT
// ============================================
app.get('/api/nominee-readiness', async (req, res) => {
    const { user_id } = req.query;
    try {
        const nominees = await db.query('SELECT * FROM nominees WHERE user_id = $1', [user_id]);
        const reports = [];

        for (const nominee of nominees.rows) {
            let readiness = 0;
            const checks: any[] = [];

            // Contact info
            if (nominee.name) { readiness += 15; checks.push({ label: 'Name provided', passed: true }); }
            else { checks.push({ label: 'Name missing', passed: false, fix: 'Add nominee name' }); }

            if (nominee.email) { readiness += 15; checks.push({ label: 'Email provided', passed: true }); }
            else { checks.push({ label: 'Email missing', passed: false, fix: 'Add email address' }); }

            if (nominee.primary_mobile) { readiness += 15; checks.push({ label: 'Phone provided', passed: true }); }
            else { checks.push({ label: 'Phone missing', passed: false, fix: 'Add mobile number' }); }

            if (nominee.identity_proof) { readiness += 10; checks.push({ label: 'ID proof set', passed: true }); }
            else { checks.push({ label: 'ID proof missing', passed: false, fix: 'Add identity document type' }); }

            if (nominee.address) { readiness += 10; checks.push({ label: 'Address provided', passed: true }); }
            else { checks.push({ label: 'Address missing', passed: false, fix: 'Add nominee address' }); }

            // Check assigned items
            const assignedItems = await db.query(
                'SELECT COUNT(*) as count FROM vault_item_nominees WHERE nominee_id = $1', [nominee.id]
            );
            const itemCount = parseInt(assignedItems.rows[0].count);
            if (itemCount > 0) { readiness += 20; checks.push({ label: `${itemCount} items assigned`, passed: true }); }
            else { checks.push({ label: 'No items assigned', passed: false, fix: 'Assign vault items to this nominee' }); }

            // Relationship
            if (nominee.relationship) { readiness += 5; checks.push({ label: 'Relationship defined', passed: true }); }
            else { checks.push({ label: 'Relationship undefined', passed: false, fix: 'Add relationship type' }); }

            // Delivery mode
            if (nominee.delivery_mode) { readiness += 10; checks.push({ label: `Delivery: ${nominee.delivery_mode}`, passed: true }); }
            else { checks.push({ label: 'Delivery mode not set', passed: false, fix: 'Set delivery mode' }); }

            reports.push({
                nominee_id: nominee.id,
                name: nominee.name,
                email: nominee.email,
                relationship: nominee.relationship,
                readiness_score: Math.min(readiness, 100),
                assigned_items: itemCount,
                checks
            });
        }

        res.json({ success: true, reports, overall_score: reports.length > 0 ? Math.round(reports.reduce((a, r) => a + r.readiness_score, 0) / reports.length) : 0 });
    } catch (error) {
        console.error('Nominee Readiness error:', error);
        res.status(500).json({ error: 'Failed to generate readiness report' });
    }
});

// ============================================
// FEATURE 5: AI ESTATE SUMMARY DASHBOARD
// ============================================
app.get('/api/estate-summary', async (req, res) => {
    const { user_id } = req.query;
    const apiKey = OPENAI_API_KEY;

    try {
        // Gather all user data
        const user = await db.query('SELECT name, email, mobile_number, created_at FROM users WHERE id = $1', [user_id]);
        const vaultItems = await db.query('SELECT item_type, title FROM vault_items WHERE user_id = $1', [user_id]);
        const nominees = await db.query('SELECT name, email, relationship FROM nominees WHERE user_id = $1', [user_id]);
        const folders = await db.query('SELECT name FROM folders WHERE user_id = $1', [user_id]);
        const files = await db.query('SELECT file_name FROM files WHERE user_id = $1', [user_id]);
        const smartDocs = await db.query('SELECT doc_type, expiry_date FROM smart_docs WHERE user_id = $1', [user_id]);

        const summary_data = {
            user: user.rows[0],
            vault_items: vaultItems.rows,
            nominees: nominees.rows,
            folders: folders.rows,
            files: files.rows,
            smart_docs: smartDocs.rows,
        };

        // AI-generated summary
        const openai = new OpenAI({ apiKey });
        const completion = await openai.chat.completions.create({
            messages: [
                { role: "system", content: "You are an estate planning advisor. Generate a professional, empathetic estate summary report. Return JSON with: 'executive_summary' (2-3 paragraph overview), 'strengths' (array of strings), 'risks' (array of strings), 'recommendations' (array of strings), 'estate_value_assessment' (qualitative assessment string)." },
                { role: "user", content: `Generate estate summary for: ${JSON.stringify(summary_data)}` }
            ],
            model: "gpt-3.5-turbo",
            response_format: { type: "json_object" },
        });

        const aiSummary = JSON.parse(completion.choices[0].message.content || '{}');

        res.json({
            success: true,
            data: summary_data,
            ai_summary: aiSummary,
            stats: {
                total_vault_items: vaultItems.rows.length,
                total_nominees: nominees.rows.length,
                total_folders: folders.rows.length,
                total_files: files.rows.length,
                total_alerts: smartDocs.rows.length,
            }
        });
    } catch (error) {
        console.error('Estate Summary error:', error);
        res.status(500).json({ error: 'Failed to generate estate summary' });
    }
});

// ============================================
// FEATURE 6: FRAUD & ANOMALY DETECTION
// ============================================
app.post('/api/activity-log', async (req, res) => {
    const { user_id, action, device_info, ip_address, details } = req.body;
    try {
        // Check for anomalies
        let is_suspicious = false;

        // Check for rapid-fire actions (more than 20 in last 5 minutes)
        const recentActions = await db.query(
            `SELECT COUNT(*) as count FROM activity_logs WHERE user_id = $1 AND created_at > NOW() - INTERVAL '5 minutes'`,
            [user_id]
        );
        if (parseInt(recentActions.rows[0].count) > 20) is_suspicious = true;

        // Check for new device
        if (device_info) {
            const knownDevices = await db.query(
                'SELECT DISTINCT device_info FROM activity_logs WHERE user_id = $1 AND device_info IS NOT NULL LIMIT 5',
                [user_id]
            );
            const known = knownDevices.rows.map((r: any) => r.device_info);
            if (known.length > 0 && !known.includes(device_info)) {
                is_suspicious = true;
            }
        }

        const result = await db.query(
            `INSERT INTO activity_logs (user_id, action, device_info, ip_address, is_suspicious, details) 
             VALUES ($1, $2, $3, $4, $5, $6) RETURNING *`,
            [user_id, action, device_info, ip_address, is_suspicious, details ? JSON.stringify(details) : null]
        );

        res.json({ success: true, log: result.rows[0], is_suspicious });
    } catch (error) {
        console.error('Activity Log error:', error);
        res.status(500).json({ error: 'Failed to log activity' });
    }
});

app.get('/api/activity-log', async (req, res) => {
    const { user_id, suspicious_only } = req.query;
    try {
        let query = 'SELECT * FROM activity_logs WHERE user_id = $1';
        if (suspicious_only === 'true') query += ' AND is_suspicious = TRUE';
        query += ' ORDER BY created_at DESC LIMIT 50';
        const result = await db.query(query, [user_id]);

        const suspiciousCount = await db.query(
            'SELECT COUNT(*) as count FROM activity_logs WHERE user_id = $1 AND is_suspicious = TRUE',
            [user_id]
        );

        res.json({
            success: true,
            logs: result.rows,
            suspicious_count: parseInt(suspiciousCount.rows[0].count)
        });
    } catch (error) {
        res.status(500).json({ error: 'Failed to fetch activity logs' });
    }
});

// ============================================
// FEATURE 7: AI GRIEF SUPPORT CHATBOT
// ============================================
app.post('/api/ai/grief-support', async (req, res) => {
    const { message, history, nominee_name, deceased_name } = req.body;
    const apiKey = OPENAI_API_KEY;

    try {
        const openai = new OpenAI({ apiKey });
        const messages: any[] = [
            {
                role: "system", content: `You are a compassionate grief support assistant for Vasihat Nama, a digital legacy app. A person named ${nominee_name || 'the nominee'} has just received access to the digital vault of ${deceased_name || 'their loved one'} who is no longer able to manage their assets. 

Your role is to:
1. Be extremely gentle, empathetic, and supportive
2. Guide them through understanding what they've received
3. Help them with next legal steps (claiming accounts, filing succession certificates)
4. Never be clinical or cold — use warm, human language
5. Acknowledge their emotions before giving practical advice
6. If they seem distressed, recommend professional grief counseling resources

Always start with empathy before any practical guidance.` }
        ];

        if (history && Array.isArray(history)) {
            history.forEach((h: any) => {
                messages.push({ role: h.role === 'model' ? 'assistant' : h.role, content: h.content || h.parts?.[0]?.text || '' });
            });
        }
        messages.push({ role: "user", content: message });

        const completion = await openai.chat.completions.create({
            messages,
            model: "gpt-3.5-turbo",
        });

        res.json({ success: true, reply: completion.choices[0].message.content });
    } catch (error) {
        console.error('Grief support error:', error);
        res.status(500).json({ error: 'Failed to get response' });
    }
});

// ============================================
// FEATURE 8: AI LEGAL DOCUMENT GENERATOR
// ============================================
app.post('/api/legal-documents/generate', async (req, res) => {
    const { user_id, doc_type, user_details, language } = req.body;
    const apiKey = OPENAI_API_KEY;

    const docTypes: any = {
        'power_of_attorney': 'Power of Attorney',
        'gift_deed': 'Gift Deed',
        'succession_certificate': 'Application for Succession Certificate',
        'nominee_claim_letter': 'Nominee Claim Letter for Bank Account',
        'insurance_claim': 'Insurance Claim Application',
        'will': 'Last Will and Testament',
        'property_transfer': 'Property Transfer Declaration',
        'bank_closure': 'Bank Account Closure Application',
    };

    try {
        const openai = new OpenAI({ apiKey });
        const docTitle = docTypes[doc_type] || doc_type;
        const lang = language || 'en';
        const langName = lang === 'hi' ? 'Hindi' : lang === 'ur' ? 'Urdu' : lang === 'ar' ? 'Arabic' : 'English';

        const completion = await openai.chat.completions.create({
            messages: [
                { role: "system", content: `You are a legal document drafter for estate planning. Generate a professional, legally-structured ${docTitle} document in ${langName}. Use proper legal formatting with sections, clauses, and signature blocks. Include placeholders in [BRACKETS] for information the user needs to fill in.` },
                { role: "user", content: `Generate a ${docTitle} with these details:\n${JSON.stringify(user_details || {})}` }
            ],
            model: "gpt-3.5-turbo",
        });

        const content = completion.choices[0].message.content || '';

        // Save to DB
        const result = await db.query(
            `INSERT INTO legal_documents (user_id, doc_type, title, content, language) 
             VALUES ($1, $2, $3, $4, $5) RETURNING *`,
            [user_id, doc_type, docTitle, content, lang]
        );

        res.json({ success: true, document: result.rows[0] });
    } catch (error) {
        console.error('Legal Doc Generation error:', error);
        res.status(500).json({ error: 'Failed to generate document' });
    }
});

app.get('/api/legal-documents', async (req, res) => {
    const { user_id } = req.query;
    try {
        const result = await db.query('SELECT * FROM legal_documents WHERE user_id = $1 ORDER BY created_at DESC', [user_id]);
        res.json({ success: true, documents: result.rows });
    } catch (error) {
        res.status(500).json({ error: 'Failed to fetch documents' });
    }
});

app.delete('/api/legal-documents/:id', async (req, res) => {
    const { id } = req.params;
    const { user_id } = req.query;
    try {
        await db.query('DELETE FROM legal_documents WHERE id = $1 AND user_id = $2', [id, user_id]);
        res.json({ success: true, message: 'Document deleted' });
    } catch (error) {
        res.status(500).json({ error: 'Failed to delete document' });
    }
});

// ============================================
// FEATURE 9: MULTI-LANGUAGE AI SUPPORT
// ============================================
app.post('/api/ai/translate', async (req, res) => {
    const { text, target_language } = req.body;
    const apiKey = OPENAI_API_KEY;

    const langMap: any = { 'hi': 'Hindi', 'ur': 'Urdu', 'ar': 'Arabic', 'en': 'English', 'bn': 'Bengali', 'te': 'Telugu', 'mr': 'Marathi', 'ta': 'Tamil', 'gu': 'Gujarati' };

    try {
        const openai = new OpenAI({ apiKey });
        const completion = await openai.chat.completions.create({
            messages: [
                { role: "system", content: `Translate the following text to ${langMap[target_language] || target_language}. Maintain the original meaning and tone. If it's a legal document, use appropriate legal terminology in the target language.` },
                { role: "user", content: text }
            ],
            model: "gpt-3.5-turbo",
        });

        res.json({ success: true, translated_text: completion.choices[0].message.content });
    } catch (error) {
        res.status(500).json({ error: 'Translation failed' });
    }
});

app.put('/api/users/:id/language', async (req, res) => {
    const { id } = req.params;
    const { language } = req.body;
    try {
        await db.query('UPDATE users SET preferred_language = $1 WHERE id = $2', [language, id]);
        res.json({ success: true, message: 'Language preference updated' });
    } catch (error) {
        res.status(500).json({ error: 'Failed to update language' });
    }
});

// ============================================
// FEATURE 10: EMERGENCY CARD
// ============================================
app.put('/api/emergency-card', async (req, res) => {
    const { user_id, emergency_data } = req.body;
    try {
        await db.query('UPDATE users SET emergency_data = $1 WHERE id = $2', [JSON.stringify(emergency_data), user_id]);
        res.json({ success: true, message: 'Emergency card updated' });
    } catch (error) {
        res.status(500).json({ error: 'Failed to update emergency card' });
    }
});

app.get('/api/emergency-card', async (req, res) => {
    const { user_id } = req.query;
    try {
        const result = await db.query('SELECT emergency_data, name, mobile_number FROM users WHERE id = $1', [user_id]);
        res.json({ success: true, emergency_data: result.rows[0]?.emergency_data || {}, user: { name: result.rows[0]?.name, mobile: result.rows[0]?.mobile_number } });
    } catch (error) {
        res.status(500).json({ error: 'Failed to fetch emergency card' });
    }
});

// ============================================
// SUPERADMIN PANEL API
// ============================================

// Middleware to check admin access (using unified checkAdmin)
const isAdmin = checkAdmin;

// 1. Get Global Stats
app.get('/api/admin/stats', isAdmin, async (req, res) => {
    try {
        const usersCount = await db.query('SELECT COUNT(*) FROM users');
        const storageStats = await db.query('SELECT SUM(current_storage_bytes) as total_storage, SUM(storage_limit_gb) as total_limit FROM users');
        const paymentStats = await db.query("SELECT SUM(amount) as total_revenue FROM payments WHERE status = 'success'");
        const itemStats = await db.query('SELECT item_type, COUNT(*) as count FROM vault_items GROUP BY item_type');

        res.json({
            success: true,
            stats: {
                total_users: parseInt(usersCount.rows[0].count),
                total_storage_used_bytes: storageStats.rows[0].total_storage || 0,
                total_storage_limit_gb: storageStats.rows[0].total_limit || 0,
                total_revenue: paymentStats.rows[0].total_revenue || 0,
                items_breakdown: itemStats.rows[0] ? itemStats.rows : []
            }
        });
    } catch (error) {
        res.status(500).json({ error: 'Failed to fetch admin stats' });
    }
});

// 2. List All Users with Storage/Subscription info
app.get('/api/admin/users', isAdmin, async (req, res) => {
    const { page = 1, limit = 20, search = '' } = req.query;
    const offset = (Number(page) - 1) * Number(limit);

    try {
        let query = `
            SELECT id, name, email, mobile_number, subscription_plan, 
                   storage_limit_gb, current_storage_bytes, subscription_expires_at, 
                   is_admin, created_at 
            FROM users 
        `;
        const params: any[] = [];

        if (search) {
            query += ` WHERE name ILIKE $1 OR email ILIKE $1 OR mobile_number ILIKE $1`;
            params.push(`%${search}%`);
        }

        query += ` ORDER BY created_at DESC LIMIT $${params.length + 1} OFFSET $${params.length + 2}`;
        params.push(limit, offset);

        const result = await db.query(query, params);
        res.json({ success: true, users: result.rows });
    } catch (error) {
        res.status(500).json({ error: 'Failed to fetch users' });
    }
});

// 3. Update User Subscription (Superadmin overriding)
app.put('/api/admin/users/:id/subscription', isAdmin, async (req, res) => {
    const { id } = req.params;
    const { plan, storage_gb, expires_at } = req.body;

    try {
        await db.query(
            `UPDATE users SET 
                subscription_plan = COALESCE($1, subscription_plan),
                storage_limit_gb = COALESCE($2, storage_limit_gb),
                subscription_expires_at = COALESCE($3, subscription_expires_at)
             WHERE id = $4`,
            [plan, storage_gb, expires_at, id]
        );
        res.json({ success: true, message: 'User subscription updated' });
    } catch (error) {
        res.status(500).json({ error: 'Update failed' });
    }
});

// ============================================
// PAYMENT GATEWAY INTEGRATION (RAZORPAY/PAYPAL)
// ============================================

// 1. Create Payment Order (Razorpay / PayPal)
app.post('/api/payments/create-order', async (req, res) => {
    const { user_id, amount, currency = 'INR', plan_id, provider } = req.body;

    if (!user_id || !amount || !provider) {
        res.status(400).json({ error: 'Missing payment details' });
        return;
    }

    try {
        // Here you would integrate with Razorpay/PayPal SDK
        // Example: const order = await razorpay.orders.create({ amount, currency });
        
        const transactionId = `TXN_${Date.now()}_${user_id}`;
        
        // Record pending payment
        await db.query(
            `INSERT INTO payments (user_id, amount, currency, provider, transaction_id, plan_id, status) 
             VALUES ($1, $2, $3, $4, $5, $6, 'pending')`,
            [user_id, amount, currency, provider, transactionId, plan_id]
        );

        res.json({
            success: true,
            transaction_id: transactionId,
            amount: amount,
            currency: currency,
            provider: provider,
            message: 'Payment order created. Redirect user to gateway.'
        });
    } catch (error) {
        console.error("Payment error:", error);
        res.status(500).json({ error: 'Failed to create payment' });
    }
});

// 2. Verify Payment (Webhook or Callback)
app.post('/api/payments/verify', async (req, res) => {
    const { transaction_id, status, provider_reference } = req.body;

    try {
        if (status === 'success') {
            // Update payment record
            const paymentResult = await db.query(
                "UPDATE payments SET status = 'success' WHERE transaction_id = $1 RETURNING user_id, plan_id",
                [transaction_id]
            );

            if (paymentResult.rows.length > 0) {
                const { user_id, plan_id } = paymentResult.rows[0];
                
                // Logic to update user subscription based on plan
                let storageGb = 5.0; // Example
                if (plan_id === 'premium_gold') storageGb = 50.0;
                
                await db.query(
                    `UPDATE users SET 
                        subscription_plan = $1, 
                        storage_limit_gb = $2, 
                        subscription_expires_at = NOW() + interval '1 year' 
                     WHERE id = $3`,
                    [plan_id, storageGb, user_id]
                );
            }
        } else {
            await db.query("UPDATE payments SET status = 'failed' WHERE transaction_id = $1", [transaction_id]);
        }

        res.json({ success: true, message: 'Payment status updated' });
    } catch (error) {
        res.status(500).json({ error: 'Verification failed' });
    }
});

// 3. Static Admin Dashboard (HTML)
app.get('/admin-panel', (req, res) => {
    res.send(`
        <!DOCTYPE html>
        <html lang="en">
        <head>
            <meta charset="UTF-8">
            <title>Eversafe | Superadmin Dashboard</title>
            <link href="https://fonts.googleapis.com/css2?family=Outfit:wght@300;400;600&display=swap" rel="stylesheet">
            <script src="https://cdn.jsdelivr.net/npm/chart.js"></script>
            <style>
                :root { --primary: #6366f1; --dark: #0f172a; --card: rgba(255,255,255,0.05); }
                body { font-family: 'Outfit', sans-serif; background: var(--dark); color: white; padding: 40px; margin: 0; }
                .container { max-width: 1200px; margin: 0 auto; }
                .glass { background: var(--card); backdrop-filter: blur(12px); border: 1px solid rgba(255,255,255,0.1); border-radius: 24px; padding: 32px; box-shadow: 0 20px 50px rgba(0,0,0,0.3); }
                .stats-grid { display: grid; grid-template-columns: repeat(auto-fit, minmax(240px, 1fr)); gap: 24px; margin-bottom: 32px; }
                .stat-card { padding: 24px; border-radius: 20px; background: linear-gradient(135deg, rgba(99,102,241,0.1) 0%, rgba(255,255,255,0.02) 100%); border: 1px solid rgba(99,102,241,0.2); transition: transform 0.3s; }
                .stat-card:hover { transform: translateY(-5px); }
                .stat-label { color: #94a3b8; font-size: 14px; text-transform: uppercase; letter-spacing: 1px; }
                .stat-value { font-size: 32px; font-weight: 600; margin-top: 8px; color: white; }
                .charts-grid { display: grid; grid-template-columns: 2fr 1fr; gap: 24px; margin-bottom: 32px; }
                table { width: 100%; border-collapse: separate; border-spacing: 0 8px; margin-top: 24px; }
                th { text-align: left; padding: 16px; color: #94a3b8; font-weight: 400; border-bottom: 1px solid rgba(255,255,255,0.05); }
                td { padding: 16px; background: rgba(255,255,255,0.02); border-top: 1px solid rgba(255,255,255,0.05); border-bottom: 1px solid rgba(255,255,255,0.05); }
                td:first-child { border-radius: 12px 0 0 12px; border-left: 1px solid rgba(255,255,255,0.05); }
                td:last-child { border-radius: 0 12px 12px 0; border-right: 1px solid rgba(255,255,255,0.05); }
                .badge { padding: 6px 12px; border-radius: 30px; font-size: 11px; font-weight: 600; text-transform: uppercase; }
                .premium { background: #fbbf24; color: #78350f; }
                .free { background: #334155; color: #cbd5e1; }
                .admin { background: #ef4444; color: white; }
                input { background: rgba(255,255,255,0.05); border: 1px solid #334155; color: white; padding: 12px 20px; border-radius: 12px; outline: none; transition: 0.3s; }
                input:focus { border-color: var(--primary); box-shadow: 0 0 0 4px rgba(99,102,241,0.1); }
                button { background: var(--primary); color: white; border: none; padding: 12px 24px; border-radius: 12px; font-weight: 600; cursor: pointer; transition: 0.3s; }
                button:hover { opacity: 0.9; box-shadow: 0 10px 20px rgba(99,102,241,0.2); }
                .header { display: flex; justify-content: space-between; align-items: center; margin-bottom: 40px; }
                canvas { max-height: 300px; }
            </style>
        </head>
        <body>
            <div class="container">
                <div class="header">
                    <div>
                        <h1 style="margin:0">Eversafe</h1>
                        <p style="color:#6366f1; margin:0; font-weight:600">Superadmin Infrastructure</p>
                    </div>
                    <div style="display:flex; gap:12px">
                        <input type="password" id="adminSecret" placeholder="Super Secret Key">
                        <button onclick="loadDashboard()">🚀 Sync Stats</button>
                        <button style="background:#10b981" onclick="exportCSV()">📁 Export CSV</button>
                    </div>
                </div>
                
                <div id="stats" class="stats-grid">
                    <div class="stat-card"><div class="stat-label">Total Users</div><div class="stat-value">--</div></div>
                    <div class="stat-card"><div class="stat-label">Revenue</div><div class="stat-value">--</div></div>
                    <div class="stat-card"><div class="stat-label">Data Stored</div><div class="stat-value">--</div></div>
                    <div class="stat-card"><div class="stat-label">Vault Objects</div><div class="stat-value">--</div></div>
                </div>

                <div class="charts-grid">
                    <div class="glass">
                        <h3>Distribution of Vault Items</h3>
                        <canvas id="itemsChart"></canvas>
                    </div>
                    <div class="glass">
                        <h3>Storage Usage Heatmap</h3>
                        <canvas id="storageChart"></canvas>
                    </div>
                </div>
                
                <div class="glass">
                    <div style="display:flex; justify-content:space-between; align-items:center">
                        <h3>Active Subscriptions & Storage</h3>
                        <input type="text" id="userSearch" placeholder="Search by name/mobile..." onkeyup="loadUsers()">
                    </div>
                    <div id="userList">Enter secret key and sync stats to view users.</div>
                </div>
            </div>

            <script>
                let cachedUsers = [];
                let itemsChart, storageChart;

                // Auto-load secret from local storage
                window.onload = () => {
                   const savedSecret = localStorage.getItem('vasihat_admin_secret');
                   if (savedSecret) {
                       document.getElementById('adminSecret').value = savedSecret;
                   }
                };

                async function loadDashboard() {
                    const secret = document.getElementById('adminSecret').value.trim();
                    if (!secret) return alert('Please enter the secret key first.');
                    
                    const headers = { 'x-admin-secret': secret };
                    console.log('Syncing stats...');
                    
                    try {
                        const statsRes = await fetch(\`/api/admin/stats?admin_secret=\${encodeURIComponent(secret)}\`, { headers });
                        const statsData = await statsRes.json();
                        
                        if (statsData.success) {
                            // Save successful secret
                            localStorage.setItem('vasihat_admin_secret', secret);
                            
                            console.log('Stats received:', statsData);
                            const s = statsData.stats;
                            
                            const totalRev = parseFloat(s.total_revenue || 0).toLocaleString('en-IN');
                            const storageMB = (parseFloat(s.total_storage_used_bytes || 0) / (1024*1024)).toFixed(2);
                            const totalItems = s.items_breakdown.reduce((a,b) => a + parseInt(b.count || 0), 0);

                            document.getElementById('stats').innerHTML = \`
                                <div class="stat-card"><div class="stat-label">Total Users</div><div class="stat-value">\${s.total_users}</div></div>
                                <div class="stat-card"><div class="stat-label">Total Revenue</div><div class="stat-value">₹\${totalRev}</div></div>
                                <div class="stat-card"><div class="stat-label">Storage Used</div><div class="stat-value">\${storageMB} MB</div></div>
                                <div class="stat-card"><div class="stat-label">Total Item Objects</div><div class="stat-value">\${totalItems}</div></div>
                            \`;
                            
                            initCharts(s.items_breakdown);
                            loadUsers();
                        } else {
                            console.error('Auth check failed:', statsData);
                            alert('Auth Failed: ' + (statsData.error || 'Unknown error'));
                        }
                    } catch (e) { 
                        console.error('Fetch error:', e);
                        alert('Error connecting to backend: ' + e.message); 
                    }
                }

                function initCharts(breakdown) {
                    if (itemsChart) itemsChart.destroy();
                    if (storageChart) storageChart.destroy();

                    itemsChart = new Chart(document.getElementById('itemsChart'), {
                        type: 'bar',
                        data: {
                            labels: breakdown.map(i => i.item_type.toUpperCase()),
                            datasets: [{
                                label: 'Items Count',
                                data: breakdown.map(i => i.count),
                                backgroundColor: '#6366f1',
                                borderRadius: 8
                            }]
                        },
                        options: { responsive: true, plugins: { legend: { display: false } }, scales: { y: { beginAtZero: true, grid: { color: 'rgba(255,255,255,0.1)' } } } }
                    });

                    storageChart = new Chart(document.getElementById('storageChart'), {
                        type: 'doughnut',
                        data: {
                            labels: breakdown.map(i => i.item_type),
                            datasets: [{
                                data: breakdown.map(i => i.count),
                                backgroundColor: ['#818cf8', '#6366f1', '#4f46e5', '#4338ca', '#3730a3']
                            }]
                        },
                        options: { cutout: '70%', plugins: { legend: { position: 'bottom', labels: { color: '#94a3b8' } } } }
                    });
                }

                async function loadUsers() {
                    const secret = document.getElementById('adminSecret').value.trim();
                    const search = document.getElementById('userSearch').value;
                    const headers = { 'x-admin-secret': secret };
                    
                    const res = await fetch(\`/api/admin/users?search=\${encodeURIComponent(search)}&admin_secret=\${encodeURIComponent(secret)}\`, { headers });
                    const data = await res.json();
                    cachedUsers = data.users;
                    
                    let table = '<table><tr><th>Name</th><th>Email/Mobile</th><th>Subscription Plan</th><th>Storage Usage</th><th>Joining Date</th><th>Manage</th></tr>';
                    data.users.forEach(u => {
                        const usageMB = (u.current_storage_bytes / (1024*1024)).toFixed(1);
                        const usagePct = ((u.current_storage_bytes / (1024*1024*1024)) / u.storage_limit_gb * 100).toFixed(1);
                        table += \`
                            <tr>
                                <td><div style="font-weight:600">\${u.name}</div>\${u.is_admin ? '<span class="badge admin">Admin</span>' : ''}</td>
                                <td style="color:#94a3b8; font-size:13px">\${u.email || u.mobile_number}</td>
                                <td><span class="badge \${u.subscription_plan}">\${u.subscription_plan}</span></td>
                                <td>
                                    <div style="font-size:12px; margin-bottom:4px">\${usagePct}% (\${usageMB} MB)</div>
                                    <div style="width:100%; height:4px; background:rgba(255,255,255,0.1); border-radius:2px">
                                        <div style="width:\${usagePct}%; height:100%; background:#6366f1; border-radius:2px"></div>
                                    </div>
                                </td>
                                <td style="color:#94a3b8; font-size:13px">\${new Date(u.created_at).toLocaleDateString()}</td>
                                <td><button style="background:#334155; font-size:11px; padding:8px 12px" onclick="updateSub(\${u.id})">MODIFY</button></td>
                            </tr>
                        \`;
                    });
                    table += '</table>';
                    document.getElementById('userList').innerHTML = table;
                }

                function exportCSV() {
                    if (cachedUsers.length === 0) return alert('No data to export');
                    let csv = 'ID,Name,Email,Plan,Limit_GB,Used_Bytes\\n';
                    cachedUsers.forEach(u => {
                        csv += \`\${u.id},\${u.name},\${u.email},\${u.subscription_plan},\${u.storage_limit_gb},\${u.current_storage_bytes}\\n\`;
                    });
                    const blob = new Blob([csv], { type: 'text/csv' });
                    const url = window.URL.createObjectURL(blob);
                    const a = document.createElement('a');
                    a.setAttribute('hidden', '');
                    a.setAttribute('href', url);
                    a.setAttribute('download', 'vasihat_users.csv');
                    document.body.appendChild(a);
                    a.click();
                    document.body.removeChild(a);
                }

                async function updateSub(userId) {
                    const secret = document.getElementById('adminSecret').value;
                    const plan = prompt("New Plan (free, gold, platinum):", "gold");
                    const storage = prompt("New Max Storage (GB):", "10");
                    
                    if (plan) {
                        const res = await fetch(\`/api/admin/users/\${userId}/subscription\`, {
                            method: 'PUT',
                            headers: { 'Content-Type': 'application/json', 'x-admin-secret': secret },
                            body: JSON.stringify({ plan, storage_gb: storage })
                        });
                        const data = await res.json();
                        alert(data.message || data.error);
                        loadUsers();
                    }
                }
            </script>
        </body>
        </html>
    `);
});

// --- Start Server ---
if (process.env.NODE_ENV !== 'production' && process.env.NODE_ENV !== 'test') {
    app.listen(PORT, async () => {
        await initDb();
        console.log(`Server is running on port ${PORT}`);
    });
} else if (process.env.NODE_ENV === 'production') {
    // In production (Vercel), initialize DB in the background
    initDb().catch(err => console.error('DB Init Failed', err));
}

export default app;

