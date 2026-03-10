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
const apiKey = 'AIzaSyDMgI3NFNCcEGWOVaExsN5ArbtuhCB5ZGI';
// Use a generic model to initialize, but we'll try to list models via REST API since SDK doesn't always expose list easily in older versions or specific setups.
// Actually, let's use fetch directly to list models.
function listModels() {
    return __awaiter(this, void 0, void 0, function* () {
        const url = `https://generativelanguage.googleapis.com/v1beta/models?key=${apiKey}`;
        console.log("Listing models from:", url);
        try {
            const response = yield fetch(url);
            const data = yield response.json();
            if (data.error) {
                console.error("API Error:", JSON.stringify(data.error, null, 2));
            }
            else {
                console.log("Available Models:");
                if (data.models) {
                    data.models.forEach((m) => {
                        if (m.supportedGenerationMethods && m.supportedGenerationMethods.includes("generateContent")) {
                            console.log("- " + m.name);
                        }
                    });
                }
                else {
                    console.log("No models found.");
                }
            }
        }
        catch (error) {
            console.error("Fetch Error:", error);
        }
    });
}
listModels();
