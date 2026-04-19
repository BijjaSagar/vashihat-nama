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
const BASE_URL = 'http://localhost:3000/api'; // Testing against local just in case? Or remote config in test_full_flow: 'https://backend-rjtaianyt-sagar-bijjas-projects.vercel.app/api'
// Let's use the remote one
const REMOTE_URL = 'https://backend-rjtaianyt-sagar-bijjas-projects.vercel.app/api';
function testCrypto() {
    return __awaiter(this, void 0, void 0, function* () {
        var _a;
        console.log('Testing Crypto Vault Item creation...');
        try {
            // 1. Register User Mock
            const mobile = `98${Math.floor(10000000 + Math.random() * 90000000)}`;
            let res = yield axios_1.default.post(`${REMOTE_URL}/users/register`, {
                mobile_number: mobile,
                public_key: 'test_pub_key',
                encrypted_private_key: 'test_priv_key',
                name: 'Crypto Tester',
                email: `crypto${mobile}@test.com`
            });
            const userId = res.data.id;
            console.log('User created:', userId);
            // 2. Create Folder
            res = yield axios_1.default.post(`${REMOTE_URL}/folders`, {
                user_id: userId,
                name: 'Crypto Vault'
            });
            const folderId = res.data.id;
            console.log('Folder created:', folderId);
            // 3. Add Crypto Item
            const cryptoData = JSON.stringify({
                coin: 'Bitcoin',
                wallet_address: '1A1zP1eP5QGefi2DMPTfTL5SLmv7DivfNa',
                network: 'BTC',
                seed_phrase: 'apple banana cherry date elderberry fig grape hazelnut ice juice kiwi lemon',
                notes: 'Satoshi wallet'
            });
            res = yield axios_1.default.post(`${REMOTE_URL}/vault_items`, {
                user_id: userId,
                folder_id: folderId,
                item_type: 'crypto',
                title: 'My Genesis Block Wallet',
                encrypted_data: cryptoData
            });
            console.log('Crypto Vault Item created successfully:', res.data.item.id);
            // 4. Fetch the item
            res = yield axios_1.default.get(`${REMOTE_URL}/vault_items/${folderId}?user_id=${userId}`);
            console.log('Fetched Items:', JSON.stringify(res.data, null, 2));
            console.log('✅ Crypto testing successful!');
        }
        catch (e) {
            console.error('❌ Test failed:', ((_a = e.response) === null || _a === void 0 ? void 0 : _a.data) || e.message);
        }
    });
}
testCrypto();
