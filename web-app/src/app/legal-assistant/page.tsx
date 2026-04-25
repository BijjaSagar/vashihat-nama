"use client";

import { useState, useRef, useEffect } from "react";
import { motion } from "framer-motion";
import { Bot, Send, Loader2, Scale } from "lucide-react";
import { ApiService } from "@/lib/api";

type Message = {
  role: "assistant" | "user";
  content: string;
};

type HistoryItem = {
  role: "model" | "user";
  parts: { text: string }[];
};

export default function LegalAssistantPage() {
  const [messages, setMessages] = useState<Message[]>([
    { role: "assistant", content: "Hello! I am your Eversafe Legal Assistant. How can I help you with inheritance or estate planning today?" }
  ]);
  const [history, setHistory] = useState<HistoryItem[]>([]);
  const [input, setInput] = useState("");
  const [loading, setLoading] = useState(false);
  const messagesEndRef = useRef<HTMLDivElement>(null);

  const scrollToBottom = () => {
    messagesEndRef.current?.scrollIntoView({ behavior: "smooth" });
  };

  useEffect(() => {
    scrollToBottom();
  }, [messages]);

  const handleSend = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!input.trim() || loading) return;

    const userMessage = input.trim();
    setInput("");
    
    // Add user message to UI immediately
    setMessages(prev => [...prev, { role: "user", content: userMessage }]);
    setLoading(true);

    try {
      const res = await ApiService.request('/ai/chat', {
        method: 'POST',
        body: JSON.stringify({
          message: userMessage,
          history: history
        })
      });

      const reply = res.reply || "No response from AI";

      setMessages(prev => [...prev, { role: "assistant", content: reply }]);
      
      // Update history format for the backend LLM (Google Gemini / OpenAI structure)
      setHistory(prev => [
        ...prev,
        { role: "user", parts: [{ text: userMessage }] },
        { role: "model", parts: [{ text: reply }] }
      ]);
    } catch (err) {
      console.error(err);
      setMessages(prev => [...prev, { role: "assistant", content: "Sorry, I encountered an error. Please try again." }]);
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="flex flex-col h-[calc(100vh-6rem)] max-w-4xl mx-auto w-full">
      <div className="mb-6 flex flex-col items-center text-center">
        <div className="w-16 h-16 bg-blue-100 border border-blue-200 rounded-full flex items-center justify-center mb-4 shadow-sm">
          <Scale className="w-8 h-8 text-blue-600" />
        </div>
        <h1 className="text-3xl font-bold mb-2 text-slate-800">Legal AI Assistant</h1>
        <p className="text-slate-600 max-w-lg">Ask any questions regarding inheritance laws and estate planning. Your Eversafe AI is here to help.</p>
      </div>

      <div className="flex-1 glass-panel rounded-3xl overflow-hidden flex flex-col relative bg-white/40 backdrop-blur-xl border border-white/60 shadow-xl">
        {/* Chat Messages */}
        <div className="flex-1 overflow-y-auto p-4 sm:p-6 space-y-6">
          {messages.map((msg, idx) => (
            <motion.div 
              initial={{ opacity: 0, y: 10 }}
              animate={{ opacity: 1, y: 0 }}
              key={idx} 
              className={`flex ${msg.role === "user" ? "justify-end" : "justify-start"}`}
            >
              <div className={`max-w-[85%] sm:max-w-[70%] rounded-2xl p-4 shadow-sm ${
                msg.role === "user" 
                  ? "bg-blue-600 text-white rounded-br-sm ml-auto" 
                  : "bg-white text-slate-700 rounded-bl-sm border border-slate-200 shadow"
              }`}>
                {msg.role === "assistant" && (
                  <div className="flex items-center gap-2 mb-3 border-b border-slate-100 pb-2">
                    <div className="bg-blue-50 border border-blue-100 p-1.5 rounded-lg">
                      <Bot className="w-4 h-4 text-blue-500" />
                    </div>
                    <span className="text-xs font-bold text-blue-600 uppercase tracking-wider">Eversafe AI</span>
                  </div>
                )}
                <p className="whitespace-pre-wrap leading-relaxed text-[15px]">{msg.content}</p>
              </div>
            </motion.div>
          ))}
          {loading && (
            <motion.div 
              initial={{ opacity: 0 }}
              animate={{ opacity: 1 }}
              className="flex justify-start"
            >
              <div className="bg-white rounded-2xl rounded-bl-sm p-4 border border-slate-200 shadow">
                <Loader2 className="w-5 h-5 animate-spin text-blue-500" />
              </div>
            </motion.div>
          )}
          <div ref={messagesEndRef} />
        </div>

        {/* Input Area */}
        <div className="p-4 bg-white/70 backdrop-blur-md border-t border-slate-200">
          <form onSubmit={handleSend} className="relative flex items-center max-w-4xl mx-auto">
            <input 
              type="text" 
              value={input}
              onChange={e => setInput(e.target.value)}
              placeholder="Ask a legal question..."
              className="w-full bg-white border border-slate-300 text-slate-800 rounded-full py-4 pl-6 pr-16 focus:outline-none focus:ring-2 focus:ring-blue-400/50 focus:border-blue-400 transition-all shadow-sm placeholder:text-slate-400"
              disabled={loading}
            />
            <button 
              type="submit" 
              disabled={!input.trim() || loading}
              className="absolute right-2 p-3 bg-blue-600 hover:bg-blue-500 text-white rounded-full disabled:opacity-50 disabled:cursor-not-allowed transition-all shadow-lg flex items-center justify-center"
            >
              <Send className="w-5 h-5" />
            </button>
          </form>
        </div>
      </div>
    </div>
  );
}
