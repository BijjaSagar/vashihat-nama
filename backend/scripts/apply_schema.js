const { Client } = require('pg');
const fs = require('fs');
const path = require('path');

// !!!!!!! REPLACE WITH YOUR FULL NEON DATABASE URL FOR "vasihat_nama" !!!!!!!
// The one you set in Vercel. NOT the 'postgres' one.
const connectionString = 'postgresql://neondb_owner:npg_ABcgVsjy0i9l@ep-wandering-wave-ad4i4ii1-pooler.c-2.us-east-1.aws.neon.tech/vasihat_nama?sslmode=require';

const client = new Client({
    connectionString: connectionString,
});

async function applySchema() {
    try {
        await client.connect();
        console.log('Connected to Neon DB (vasihat_nama)');

        const schemaPath = path.join(__dirname, '../src/schema.sql');
        console.log(`Reading schema from: ${schemaPath}`);

        if (!fs.existsSync(schemaPath)) {
            throw new Error('Schema file not found!');
        }

        const schema = fs.readFileSync(schemaPath, 'utf8');

        console.log('Applying schema...');
        await client.query(schema);
        console.log('Schema applied successfully! Tables created.');

        // Verification
        const res = await client.query("SELECT table_name FROM information_schema.tables WHERE table_schema='public'");
        console.log('Current Tables:', res.rows.map(row => row.table_name));

    } catch (err) {
        console.error('Error applying schema:', err);
    } finally {
        await client.end();
    }
}

applySchema();
