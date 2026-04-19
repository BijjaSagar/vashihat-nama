import axios from 'axios';

const REMOTE_URL = 'http://localhost:8080/api';
const ADMIN_SECRET = 'secure_admin_123';

async function testCryptoVault() {
    console.log('--- Testing Crypto Vault Flow ---');

    try {
        // 1. Create a "Crypto Vault" entry
        const cryptoPayload = {
            user_id: 2, // Use existing User ID
            folder_id: null,
            item_type: 'crypto',
            title: 'My Ledger Seed (Hardware)',
            encrypted_data: JSON.stringify({
                category: 'seed_phrase',
                words: 'pioneer gadget modify fossil engine... (encrypted on client)',
                blockchain: 'Multi-Chain',
                notes: 'Hidden in safe box 2'
            })
        };

        console.log('Step 1: Storing encrypted seed phrase...');
        const createRes = await axios.post(`${REMOTE_URL}/vault_items`, cryptoPayload);
        const itemId = (createRes.data as any).item.id;
        console.log(`✅ Crypto Vault item created: ID ${itemId}`);

        // 2. Fetch the crypto vault items
        console.log('Step 2: Fetching vault items (User 2)...');
        const listRes = await axios.get(`${REMOTE_URL}/vault_items?user_id=2`);
        const items = (listRes.data as any).items; 
        const cryptoItem = items.find((i: any) => i.item_type === 'crypto');
        
        if (cryptoItem) {
            console.log(`✅ Found Crypto Item: ${cryptoItem.title}`);
        } else {
            throw new Error('Crypto item not found in vault');
        }

        // 3. Test "Security Score" for Crypto (New Logic)
        console.log('Step 3: Calculating Security Score for this user...');
        const scoreRes = await axios.get(`${REMOTE_URL}/security/score?user_id=2`);



        console.log(`✅ Security Score: ${(scoreRes.data as any).score}%`);
        const failedChecks = (scoreRes.data as any).checks.filter((c: any) => !c.passed);
        console.log(`🔍 Recommendations: ${failedChecks.map((c: any) => c.fix || c.label).join(', ')}`);


        console.log('\n🎉 CRYPTO VAULT TESTED SUCCESSFULLY!');
    } catch (error: any) {
        console.error('❌ Test failed:', error.response?.data || error.message);
        process.exit(1);
    }
}

testCryptoVault();
