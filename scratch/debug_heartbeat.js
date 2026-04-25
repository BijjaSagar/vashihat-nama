const { Client } = require('pg');
require('dotenv').config({ path: 'backend/.env' });

async function debugHeartbeat() {
    const client = new Client({
        connectionString: process.env.DATABASE_URL.replace('-pooler', ''), // Try without pooler if that was the issue
        ssl: { rejectUnauthorized: false }
    });
    try {
        await client.connect();
        const res = await client.query(`
            SELECT id, name, last_check_in, 
            dead_mans_switch_active,
            check_in_frequency_days,
            check_in_frequency_hours,
            check_in_frequency_minutes,
            life_verification_status,
            (last_check_in + (COALESCE(check_in_frequency_days, 30) * INTERVAL '1 day') + (COALESCE(check_in_frequency_hours, 0) * INTERVAL '1 hour') + (COALESCE(check_in_frequency_minutes, 0) * INTERVAL '1 minute')) as due_at,
            NOW() as current_time
            FROM users 
            ORDER BY id DESC LIMIT 5
        `);
        console.log(JSON.stringify(res.rows, null, 2));
    } catch (e) {
        console.error(e);
    } finally {
        await client.end();
    }
}
debugHeartbeat();
