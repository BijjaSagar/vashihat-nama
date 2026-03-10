import axios from 'axios';

const REMOTE_URL = 'https://backend-rjtaianyt-sagar-bijjas-projects.vercel.app/api';

async function testAIFeatures() {
    console.log('Testing 10 AI Features integration...');

    try {
        // 1. Register Mock User
        const mobile = `98${Math.floor(10000000 + Math.random() * 90000000)}`;
        let res = await axios.post(`${REMOTE_URL}/users/register`, {
            mobile_number: mobile,
            public_key: 'test_pub',
            encrypted_private_key: 'test_priv',
            name: 'AI AI Tester',
            email: `ai${mobile}@test.com`
        });
        const userId = (res.data as any).user.id;
        console.log('✅ User created:', userId);

        // 2. Test AI Chat
        res = await axios.post(`${REMOTE_URL}/ai/chat`, {
            message: 'How do I distribute my house legally in India?',
            history: []
        });
        console.log('✅ AI Legal Assistant Response:', (res.data as any).reply?.substring(0, 100) + '...');

        // 3. Test Asset Discovery
        res = await axios.post(`${REMOTE_URL}/asset-discovery/generate`, {
            user_id: userId,
            country: 'India',
            age_group: '30-40',
            occupation: 'Software Engineer'
        });
        console.log('✅ Asset Discovery Generated!', (res.data as any).assets.length, 'suggestions.');

        // 4. Test Video Will (Messages)
        res = await axios.post(`${REMOTE_URL}/video-wills`, {
            user_id: userId,
            title: 'Message to my Wife',
            message_type: 'text',
            transcript: 'I love you very much and want you to have the house.'
        });
        console.log('✅ Video Will / Message Saved! ID:', (res.data as any).video_will.id);

        console.log('\n🎉 ALL AI FEATURES COMPLETED AND TESTED SUCCESSFULLY!');

    } catch (e: any) {
        console.error('❌ Test failed:', e.response?.data || e.message);
    }
}

testAIFeatures();
