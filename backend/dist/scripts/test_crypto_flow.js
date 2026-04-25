"use strict";
var __awaiter = (this && this.__awaiter) || function (thisArg, _arguments, P, generator) {
    function adopt(value) { return value instanceof P ? value : new P(function (resolve) { resolve(value); }); }
    return new (P || (P = Promise))(function (resolve, reject) {
        function fulfilled(value) { try { step(generator.next(value)); } catch (e) { reject(e); } }
        function rejected(value) { try { step(generator["throw"](value)); } catch (e) { reject(e); } }
        function step(result) { result.done ? resolve(result.value) : adopt(result.value).then(fulfilled, rejected); }
        step((generator = generator.apply(thisArg, _arguments || [])).next());
    });
};
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
const axios_1 = __importDefault(require("axios"));
const REMOTE_URL = 'http://localhost:8080/api';
const ADMIN_SECRET = 'secure_admin_123';
function testCryptoVault() {
    return __awaiter(this, void 0, void 0, function* () {
        var _a;
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
            const createRes = yield axios_1.default.post(`${REMOTE_URL}/vault_items`, cryptoPayload);
            const itemId = createRes.data.item.id;
            console.log(`✅ Crypto Vault item created: ID ${itemId}`);
            // 2. Fetch the crypto vault items
            console.log('Step 2: Fetching vault items (User 2)...');
            const listRes = yield axios_1.default.get(`${REMOTE_URL}/vault_items?user_id=2`);
            const items = listRes.data.items;
            const cryptoItem = items.find((i) => i.item_type === 'crypto');
            if (cryptoItem) {
                console.log(`✅ Found Crypto Item: ${cryptoItem.title}`);
            }
            else {
                throw new Error('Crypto item not found in vault');
            }
            // 3. Test "Security Score" for Crypto (New Logic)
            console.log('Step 3: Calculating Security Score for this user...');
            const scoreRes = yield axios_1.default.get(`${REMOTE_URL}/security/score?user_id=2`);
            console.log(`✅ Security Score: ${scoreRes.data.score}%`);
            const failedChecks = scoreRes.data.checks.filter((c) => !c.passed);
            console.log(`🔍 Recommendations: ${failedChecks.map((c) => c.fix || c.label).join(', ')}`);
            console.log('\n🎉 CRYPTO VAULT TESTED SUCCESSFULLY!');
        }
        catch (error) {
            console.error('❌ Test failed:', ((_a = error.response) === null || _a === void 0 ? void 0 : _a.data) || error.message);
            process.exit(1);
        }
    });
}
testCryptoVault();
