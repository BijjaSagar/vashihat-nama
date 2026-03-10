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
Object.defineProperty(exports, "__esModule", { value: true });
const generative_ai_1 = require("@google/generative-ai");
const apiKey = 'AIzaSyDMgI3NFNCcEGWOVaExsN5ArbtuhCB5ZGI';
function testAI() {
    return __awaiter(this, void 0, void 0, function* () {
        console.log("Testing API Key:", apiKey);
        const genAI = new generative_ai_1.GoogleGenerativeAI(apiKey);
        try {
            console.log("--- Testing gemini-flash-latest ---");
            const model = genAI.getGenerativeModel({ model: "gemini-flash-latest" });
            const result = yield model.generateContent("Hello, are you working?");
            const response = yield result.response;
            console.log("gemini-flash-latest Response:", response.text());
        }
        catch (error) {
            console.error("gemini-flash-latest Error:", error.message);
        }
    });
}
testAI();
