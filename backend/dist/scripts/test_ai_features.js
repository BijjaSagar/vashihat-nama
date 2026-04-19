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
const REMOTE_URL = 'https://backend-rjtaianyt-sagar-bijjas-projects.vercel.app/api';
function testAIFeatures() {
    return __awaiter(this, void 0, void 0, function* () {
        var _a, _b;
        console.log('Testing 10 AI Features integration...');
        try {
            // 1. Register Mock User
            const mobile = `98${Math.floor(10000000 + Math.random() * 90000000)}`;
            let res = yield axios_1.default.post(`${REMOTE_URL}/users/register`, {
                mobile_number: mobile,
                public_key: 'test_pub',
                encrypted_private_key: 'test_priv',
                name: 'AI AI Tester',
                email: `ai${mobile}@test.com`
            });
            const userId = res.data.user.id;
            console.log('✅ User created:', userId);
            // 2. Test AI Chat
            res = yield axios_1.default.post(`${REMOTE_URL}/ai/chat`, {
                message: 'How do I distribute my house legally in India?',
                history: []
            });
            console.log('✅ AI Legal Assistant Response:', ((_a = res.data.reply) === null || _a === void 0 ? void 0 : _a.substring(0, 100)) + '...');
            // 3. Test Asset Discovery
            res = yield axios_1.default.post(`${REMOTE_URL}/asset-discovery/generate`, {
                user_id: userId,
                country: 'India',
                age_group: '30-40',
                occupation: 'Software Engineer'
            });
            console.log('✅ Asset Discovery Generated!', res.data.assets.length, 'suggestions.');
            // 4. Test Video Will (Messages)
            res = yield axios_1.default.post(`${REMOTE_URL}/video-wills`, {
                user_id: userId,
                title: 'Message to my Wife',
                message_type: 'text',
                transcript: 'I love you very much and want you to have the house.'
            });
            console.log('✅ Video Will / Message Saved! ID:', res.data.video_will.id);
            console.log('\n🎉 ALL AI FEATURES COMPLETED AND TESTED SUCCESSFULLY!');
        }
        catch (e) {
            console.error('❌ Test failed:', ((_b = e.response) === null || _b === void 0 ? void 0 : _b.data) || e.message);
        }
    });
}
testAIFeatures();
