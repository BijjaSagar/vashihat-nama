import axios from 'axios';

const REMOTE_URL = 'http://localhost:8080/api';
const ADMIN_SECRET = 'secure_admin_123'; // Default from index.ts if not in env

async function testAdminPanel() {
    console.log('Testing Superadmin Panel & Payment Gateways...');

    try {
        const headers = { 'x-admin-secret': ADMIN_SECRET };

        // 1. Get Admins Stats
        let res = await axios.get(`${REMOTE_URL}/admin/stats`, { headers });
        console.log('DEBUG: Full Res Data:', res.data);
        console.log('✅ Admin Stats fetched:', (res.data as any).stats);

        // 2. List Users
        res = await axios.get(`${REMOTE_URL}/admin/users`, { headers });
        console.log('✅ Fetched', (res.data as any).users.length, 'users for admin panel.');

        const firstUser = (res.data as any).users[0];
        if (firstUser) {
            // 3. Update User Subscription (Gold Plan)
            res = await axios.put(`${REMOTE_URL}/admin/users/${firstUser.id}/subscription`, {
                plan: 'platinum',
                storage_gb: 100.0,
                expires_at: new Date(Date.now() + 365*24*60*60*1000).toISOString()
            }, { headers });
            console.log('✅ User subscription updated successfully.');
        }

        // 4. Test Payment Creation (Razorpay/PayPal Simulation)
        res = await axios.post(`${REMOTE_URL}/payments/create-order`, {
            user_id: firstUser.id,
            amount: 999,
            currency: 'INR',
            plan_id: 'premium_gold',
            provider: 'razorpay'
        });
        const txnId = (res.data as any).transaction_id;
        console.log('✅ Payment Order Created! ID:', txnId);

        // 5. Verify Payment Success
        res = await axios.post(`${REMOTE_URL}/payments/verify`, {
            transaction_id: txnId,
            status: 'success'
        });
        console.log('✅ Payment Verified & Subscription Provisioned!');

        console.log('\n🎉 SUPERADMIN PANEL & PAYMENTS TESTED SUCCESSFULLY!');

    } catch (e: any) {
        console.error('❌ Admin Test failed:', e.response?.data || e.message);
    }
}

testAdminPanel();
