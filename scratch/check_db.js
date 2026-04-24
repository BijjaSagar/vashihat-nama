
const { Client } = require('pg');
require('dotenv').config({ path: './backend/.env' });

async function checkStatus() {
    const client = new Client({
        connectionString: process.env.DATABASE_URL,
    });

    try {
        await client.connect();
        const res = await client.query(`
            SELECT id, name, email, last_check_in, 
                   check_in_frequency_days, check_in_frequency_hours, check_in_frequency_minutes,
                   dead_mans_switch_active, life_verification_status
            FROM users 
            ORDER BY last_check_in DESC 
            LIMIT 5
        `);
        console.log(JSON.stringify(res.rows, null, 2));
    } catch (err) {
        console.error(err);
    } finally {
        await client.end();
    }
}

checkStatus();
