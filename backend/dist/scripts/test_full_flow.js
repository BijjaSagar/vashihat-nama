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
const BASE_URL = 'https://vasihat-nama-backend-api.vercel.app/api';
function runTests() {
    return __awaiter(this, void 0, void 0, function* () {
        var _a, _b, _c, _d, _e, _f;
        console.log('🚀 Starting API Flow Test on:', BASE_URL);
        // 1. Register User
        const mobile = `99${Math.floor(10000000 + Math.random() * 90000000)}`;
        console.log(`\n1. Registering User (Mobile: ${mobile})...`);
        let userId;
        try {
            const res = yield axios_1.default.post(`${BASE_URL}/users/register`, {
                mobile_number: mobile,
                public_key: 'test_pub_key',
                encrypted_private_key: 'test_priv_key',
                name: 'Test Tenant',
                email: `test${mobile}@example.com`
            });
            userId = res.data.id;
            console.log('✅ User Registered. ID:', userId);
        }
        catch (e) {
            console.error('❌ Register Failed:', ((_a = e.response) === null || _a === void 0 ? void 0 : _a.data) || e.message);
            return;
        }
        // 2. Add Nominee (Validating keys fix)
        console.log('\n2. Adding Nominee...');
        try {
            const res = yield axios_1.default.post(`${BASE_URL}/nominees`, {
                user_id: userId,
                name: 'Test Nominee',
                relationship: 'Brother', // Using Correct Key
                email: 'nominee@test.com' // Using Correct Key
            });
            console.log('✅ Nominee Added. ID:', res.data.id);
        }
        catch (e) {
            console.error('❌ Add Nominee Failed:', ((_b = e.response) === null || _b === void 0 ? void 0 : _b.data) || e.message);
        }
        // 3. Create Vault Item (File Type)
        console.log('\n3. Creating Vault Item (Type: File)...');
        // 3b. Create Folder
        console.log('\n3b. Creating Folder...');
        let folderId;
        try {
            const res = yield axios_1.default.post(`${BASE_URL}/folders`, {
                user_id: userId,
                name: 'Test Folder'
            });
            folderId = res.data.id;
            console.log('✅ Folder Created. ID:', folderId);
        }
        catch (e) {
            console.error('❌ Create Folder Failed:', ((_c = e.response) === null || _c === void 0 ? void 0 : _c.data) || e.message);
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
                const res = yield axios_1.default.post(`${BASE_URL}/vault_items`, {
                    user_id: userId,
                    folder_id: folderId,
                    item_type: 'file',
                    title: 'Secret File',
                    encrypted_data: encryptedData
                });
                console.log('✅ Vault Item (File) Created:', res.data.item.id);
            }
            catch (e) {
                console.error('❌ Vault Item Failed:', ((_d = e.response) === null || _d === void 0 ? void 0 : _d.data) || e.message);
            }
        }
        // 4. Get Security Score
        console.log('\n4. Getting Security Score...');
        try {
            const res = yield axios_1.default.get(`${BASE_URL}/security/score?user_id=${userId}`);
            const data = res.data;
            console.log('✅ Security Score:', data.score);
            console.log('   Checks:', data.checks.map((c) => `${c.label}: ${c.passed}`).join(', '));
        }
        catch (e) {
            console.error('❌ Security Score Failed:', ((_e = e.response) === null || _e === void 0 ? void 0 : _e.data) || e.message);
        }
        // 5. Smart Doc Check
        console.log('\n5. Creating Smart Doc Alert...');
        try {
            const res = yield axios_1.default.post(`${BASE_URL}/smart_docs`, {
                user_id: userId,
                doc_type: 'Passport',
                doc_number: 'L889988',
                expiry_date: new Date(Date.now() + 86400000).toISOString(), // Tomorrow
                issuing_authority: 'Gov',
                file_id: null
            });
            console.log('✅ Smart Doc Alert Created:', res.data.doc_alert.id);
        }
        catch (e) {
            console.error('❌ Smart Doc Failed:', ((_f = e.response) === null || _f === void 0 ? void 0 : _f.data) || e.message);
        }
        console.log('\n✅ Test Sequence Complete.');
    });
}
runTests();
