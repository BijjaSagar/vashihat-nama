import axios from 'axios';

const BASE_URL = 'https://backend-1ggng7jae-sagar-bijjas-projects.vercel.app/api';

async function testHeartbeat() {
    console.log('Testing Heartbeat / Dead Man Switch Flow...');

    try {
        // 1. Register User Mock
        const mobile = `91${Math.floor(10000000 + Math.random() * 90000000)}`;
        let res = await axios.post(`${BASE_URL}/users/register`, {
            mobile_number: mobile,
            public_key: 'test_pub_key',
            encrypted_private_key: 'test_priv_key',
            name: 'Heartbeat Tester',
            email: `heartbeat${mobile}@test.com`
        });
        const userId = (res.data as any).user.id;
        console.log('✅ User created:', userId);

        // 2. Add a Nominee
        res = await axios.post(`${BASE_URL}/nominees`, {
            user_id: userId,
            name: 'Wife Nominee',
            email: `wife${mobile}@test.com`,
            primary_mobile: `99${Math.floor(10000000 + Math.random() * 90000000)}`,
            relationship: 'Husband'
        });
        const nomineeId = (res.data as any).id;
        console.log('✅ Nominee added:', nomineeId);

        // 3. Activate Heartbeat (0 days, 0 hours, 1 minute for testing)
        res = await axios.post(`${BASE_URL}/heartbeat/settings`, {
            user_id: userId,
            active: true,
            frequency_days: 0,
            frequency_hours: 0,
            frequency_minutes: 0 // instantly overdue
        });
        console.log('✅ Heartbeat Settings Updated');

        // 4. Trigger Heartbeat Job (As if Cron did it)
        // Using "x-admin-secret": "secure_admin_123" to mock admin/cron manually
        console.log('⏳ Triggering Cron Job...');
        res = await axios.post(`${BASE_URL}/admin/trigger_heartbeat_check`, {}, {
            headers: {
                'x-admin-secret': 'secure_admin_123'
            }
        });
        console.log('✅ Cron response:', res.data);

        console.log('✅ Heartbeat testing successful!');
    } catch (e: any) {
        console.error('❌ Test failed:', e.response?.data || e.message);
    }
}

testHeartbeat();
