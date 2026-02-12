import { Pool } from 'pg';
import dotenv from 'dotenv';
import fs from 'fs';
import path from 'path';

dotenv.config();

const pool = new Pool({
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

export const initDb = async () => {
    const client = await pool.connect();
    try {
        const schemaPath = path.join(__dirname, '../schema.sql');
        const schema = fs.readFileSync(schemaPath, 'utf8');
        await client.query(schema);
        console.log('Database initialized successfully');
    } catch (err) {
        console.error('Error initializing database', err);
    } finally {
        client.release();
    }
};

export default {
    query: (text: string, params?: any[]) => pool.query(text, params),
};
