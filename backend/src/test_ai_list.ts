
import { GoogleGenerativeAI } from "@google/generative-ai";

const apiKey = 'AIzaSyDMgI3NFNCcEGWOVaExsN5ArbtuhCB5ZGI';
// Use a generic model to initialize, but we'll try to list models via REST API since SDK doesn't always expose list easily in older versions or specific setups.
// Actually, let's use fetch directly to list models.

async function listModels() {
    const url = `https://generativelanguage.googleapis.com/v1beta/models?key=${apiKey}`;
    console.log("Listing models from:", url);

    try {
        const response = await fetch(url);
        const data = await response.json();

        if (data.error) {
            console.error("API Error:", JSON.stringify(data.error, null, 2));
        } else {
            console.log("Available Models:");
            if (data.models) {
                data.models.forEach((m: any) => {
                    if (m.supportedGenerationMethods && m.supportedGenerationMethods.includes("generateContent")) {
                        console.log("- " + m.name);
                    }
                });
            } else {
                console.log("No models found.");
            }
        }
    } catch (error) {
        console.error("Fetch Error:", error);
    }
}

listModels();
