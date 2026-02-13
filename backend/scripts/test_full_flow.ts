import axios from 'axios';

const BASE_URL = 'https://backend-oj9t8kb7y-sagar-bijjas-projects.vercel.app/api';

async function runTests() {
    console.log('🚀 Starting API Flow Test on:', BASE_URL);

    // 1. Register User
    const mobile = `99${Math.floor(10000000 + Math.random() * 90000000)}`;
    console.log(`\n1. Registering User (Mobile: ${mobile})...`);
    let userId;
    try {
        const res = await axios.post(`${BASE_URL}/users/register`, {
            mobile_number: mobile,
            public_key: 'test_pub_key',
            encrypted_private_key: 'test_priv_key',
            name: 'Test Tenant',
            email: `test${mobile}@example.com`
        });
        userId = (res.data as any).id;
        console.log('✅ User Registered. ID:', userId);
    } catch (e: any) {
        console.error('❌ Register Failed:', e.response?.data || e.message);
        return;
    }

    // 2. Add Nominee (Validating keys fix)
    console.log('\n2. Adding Nominee...');
    try {
        const res = await axios.post(`${BASE_URL}/nominees`, {
            user_id: userId,
            name: 'Test Nominee',
            relationship: 'Brother', // Using Correct Key
            email: 'nominee@test.com'   // Using Correct Key
        });
        console.log('✅ Nominee Added. ID:', (res.data as any).id);
    } catch (e: any) {
        console.error('❌ Add Nominee Failed:', e.response?.data || e.message);
    }

    // 3. Create Vault Item (File Type)
    console.log('\n3. Creating Vault Item (Type: File)...');

    // 3b. Create Folder
    console.log('\n3b. Creating Folder...');
    let folderId;
    try {
        const res = await axios.post(`${BASE_URL}/folders`, {
            user_id: userId,
            name: 'Test Folder'
        });
        folderId = (res.data as any).id;
        console.log('✅ Folder Created. ID:', folderId);
    } catch (e: any) {
        console.error('❌ Create Folder Failed:', e.response?.data || e.message);
    }

    // 3c. Create Vault Item
    if (folderId) {
        console.log('\n3c. Create Vault Item (Type: File)...');
        try {
            const fileContent = Buffer.from('Hello Secure Vault').toString('base64');
            const encryptedData = JSON.stringify({
                file_name: 'secret.txt',
                file_content: fileContent,
                file_size: 18
            });

            const res = await axios.post(`${BASE_URL}/vault_items`, {
                user_id: userId,
                folder_id: folderId,
                item_type: 'file',
                title: 'Secret File',
                encrypted_data: encryptedData
            });
            console.log('✅ Vault Item (File) Created:', (res.data as any).item.id);
        } catch (e: any) {
            console.error('❌ Vault Item Failed:', e.response?.data || e.message);
        }
    }

    // 4. Get Security Score
    console.log('\n4. Getting Security Score...');
    try {
        const res = await axios.get(`${BASE_URL}/security/score?user_id=${userId}`);
        const data = res.data as any;
        console.log('✅ Security Score:', data.score);
        console.log('   Checks:', data.checks.map((c: any) => `${c.label}: ${c.passed}`).join(', '));
    } catch (e: any) {
        console.error('❌ Security Score Failed:', e.response?.data || e.message);
    }

    // 5. Smart Doc Check
    console.log('\n5. Creating Smart Doc Alert...');
    try {
        const res = await axios.post(`${BASE_URL}/smart_docs`, {
            user_id: userId,
            doc_type: 'Passport',
            doc_number: 'L889988',
            expiry_date: new Date(Date.now() + 86400000).toISOString(), // Tomorrow
            issuing_authority: 'Gov',
            file_id: null
        });
        console.log('✅ Smart Doc Alert Created:', (res.data as any).doc_alert.id);
    } catch (e: any) {
        console.error('❌ Smart Doc Failed:', e.response?.data || e.message);
    }

    console.log('\n✅ Test Sequence Complete.');
}

runTests();
