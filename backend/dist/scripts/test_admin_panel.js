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
const ADMIN_SECRET = 'secure_admin_123'; // Default from index.ts if not in env
function testAdminPanel() {
    return __awaiter(this, void 0, void 0, function* () {
        var _a;
        console.log('Testing Superadmin Panel & Payment Gateways...');
        try {
            const headers = { 'x-admin-secret': ADMIN_SECRET };
            // 1. Get Admins Stats
            let res = yield axios_1.default.get(`${REMOTE_URL}/admin/stats`, { headers });
            console.log('DEBUG: Full Res Data:', res.data);
            console.log('✅ Admin Stats fetched:', res.data.stats);
            // 2. List Users
            res = yield axios_1.default.get(`${REMOTE_URL}/admin/users`, { headers });
            console.log('✅ Fetched', res.data.users.length, 'users for admin panel.');
            const firstUser = res.data.users[0];
            if (firstUser) {
                // 3. Update User Subscription (Gold Plan)
                res = yield axios_1.default.put(`${REMOTE_URL}/admin/users/${firstUser.id}/subscription`, {
                    plan: 'platinum',
                    storage_gb: 100.0,
                    expires_at: new Date(Date.now() + 365 * 24 * 60 * 60 * 1000).toISOString()
                }, { headers });
                console.log('✅ User subscription updated successfully.');
            }
            // 4. Test Payment Creation (Razorpay/PayPal Simulation)
            res = yield axios_1.default.post(`${REMOTE_URL}/payments/create-order`, {
                user_id: firstUser.id,
                amount: 999,
                currency: 'INR',
                plan_id: 'premium_gold',
                provider: 'razorpay'
            });
            const txnId = res.data.transaction_id;
            console.log('✅ Payment Order Created! ID:', txnId);
            // 5. Verify Payment Success
            res = yield axios_1.default.post(`${REMOTE_URL}/payments/verify`, {
                transaction_id: txnId,
                status: 'success'
            });
            console.log('✅ Payment Verified & Subscription Provisioned!');
            console.log('\n🎉 SUPERADMIN PANEL & PAYMENTS TESTED SUCCESSFULLY!');
        }
        catch (e) {
            console.error('❌ Admin Test failed:', ((_a = e.response) === null || _a === void 0 ? void 0 : _a.data) || e.message);
        }
    });
}
testAdminPanel();
