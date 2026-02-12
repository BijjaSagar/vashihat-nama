const { Client } = require('pg');

const connectionString = 'postgresql://neondb_owner:npg_ABcgVsjy0i9l@ep-wandering-wave-ad4i4ii1-pooler.c-2.us-east-1.aws.neon.tech/neondb?sslmode=require';

const client = new Client({
    connectionString: connectionString,
});

async function createDatabase() {
    try {
        await client.connect();
        console.log('Connected to Neon DB (default)');

        // Check if DB exists
        const checkRes = await client.query("SELECT 1 FROM pg_database WHERE datname = 'vasihat_nama'");
        if (checkRes.rows.length === 0) {
            console.log('Creating database vasihat_nama...');
            await client.query('CREATE DATABASE vasihat_nama');
            console.log('Database vasihat_nama created successfully.');
        } else {
            console.log('Database vasihat_nama already exists.');
        }
    } catch (err) {
        console.error('Error creating database:', err);
    } finally {
        await client.end();
    }
}

createDatabase();
