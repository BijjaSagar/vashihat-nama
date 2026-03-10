import { jest, describe, it, expect, beforeEach } from '@jest/globals';
import request from 'supertest';
import app from '../src/index';

// We mock the DB so we don't need a real Postgres connection for fast unit tests.
jest.mock('../src/db', () => ({
    __esModule: true,
    initDb: jest.fn(() => Promise.resolve()),
    default: {
        query: jest.fn(() => Promise.resolve({ rows: [] }))
    }
}));

import db from '../src/db';

describe('Vasihat Nama Backend API', () => {

    beforeEach(() => {
        jest.clearAllMocks();
    });

    describe('GET /', () => {
        it('should return a 200 health check response', async () => {
            const response = await request(app).get('/');
            expect(response.status).toBe(200);
            expect(response.text).toContain('Vasihat Nama Security Server');
        });
    });

    describe('POST /api/users/register', () => {
        it('should register a user successfully', async () => {
            const mockedQuery = db.query as any;
            mockedQuery.mockResolvedValueOnce({
                rows: [
                    {
                        id: 1,
                        mobile_number: '919876543210',
                        name: 'Test Setup User',
                        email: 'test@example.com'
                    }
                ]
            });

            const payload = {
                mobile_number: '919876543210',
                public_key: 'test_pub_key',
                encrypted_private_key: 'test_priv_key',
                name: 'Test Setup User',
                email: 'test@example.com'
            };

            const response = await request(app)
                .post('/api/users/register')
                .send(payload);

            expect(response.status).toBe(201);
            expect((response.body as any).success).toBe(true);
            expect((response.body as any).user.id).toBe(1);
            
            expect(db.query).toHaveBeenCalledTimes(1);
        });
    });

    describe('POST /api/nominees', () => {
        it('should add a nominee successfully', async () => {
             const mockedQuery = db.query as any;
             mockedQuery.mockResolvedValueOnce({
                rows: [{ id: 2 }]
            });

            const payload = {
                user_id: 1,
                name: 'Test Nominee',
                email: 'nominee@example.com',
                primary_mobile: '919876543211',
                relationship: 'Friend'
            };

            const response = await request(app)
                .post('/api/nominees')
                .send(payload);

            expect(response.status).toBe(201);
            expect((response.body as any).message).toBe('Nominee added successfully');
            expect(db.query).toHaveBeenCalledTimes(1);
        });
    });

    describe('POST /api/vault_items', () => {
        it('should create a crypto vault item successfully', async () => {
            const mockedQuery = db.query as any;
            mockedQuery.mockResolvedValueOnce({
                rows: [{ id: 101, title: 'My Bitcoin Wallet' }]
            });

            const payload = {
                user_id: 1,
                folder_id: 1,
                item_type: 'crypto',
                title: 'My Bitcoin Wallet',
                encrypted_data: JSON.stringify({ coin: 'BTC', address: '123' })
            };

            const response = await request(app)
                .post('/api/vault_items')
                .send(payload);

            expect(response.status).toBe(201);
            expect((response.body as any).item.id).toBe(101);
            expect(db.query).toHaveBeenCalledTimes(1);
        });
    });

    describe('GET /api/vault_items/:id', () => {
        it('should fetch a single vault item', async () => {
            const mockedQuery = db.query as any;
            mockedQuery.mockResolvedValueOnce({
                rows: [
                    {
                        id: 10,
                        user_id: 1,
                        title: 'My Secret',
                        item_type: 'note',
                        encrypted_data: 'encrypted_content'
                    }
                ]
            });

            const response = await request(app).get('/api/vault_items/10?user_id=1');

            expect(response.status).toBe(200);
            expect((response.body as any).success).toBe(true);
            expect((response.body as any).item.title).toBe('My Secret');
            expect(db.query).toHaveBeenCalledTimes(1);
        });
    });
});
