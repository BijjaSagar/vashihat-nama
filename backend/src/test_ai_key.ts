
import { GoogleGenerativeAI } from "@google/generative-ai";

const apiKey = 'AIzaSyDMgI3NFNCcEGWOVaExsN5ArbtuhCB5ZGI';

async function testAI() {
    console.log("Testing API Key:", apiKey);
    const genAI = new GoogleGenerativeAI(apiKey);

    try {
        console.log("--- Testing gemini-flash-latest ---");
        const model = genAI.getGenerativeModel({ model: "gemini-flash-latest" });
        const result = await model.generateContent("Hello, are you working?");
        const response = await result.response;
        console.log("gemini-flash-latest Response:", response.text());
    } catch (error: any) {
        console.error("gemini-flash-latest Error:", error.message);
    }
}

testAI();
