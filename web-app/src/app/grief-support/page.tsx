"use client";
import { useState, useEffect, useRef } from "react";
import { HeartHandshake, Send, Loader2 } from "lucide-react";
import { ApiService } from "@/lib/api";
import { motion, AnimatePresence } from "framer-motion";

interface Message { role: "user" | "assistant"; content: string; }

const INITIAL_MESSAGE: Message = {
  role: "assistant",
  content: "I'm here for you. 💙\n\nI understand this is an incredibly difficult time. I'm the Eversafe support assistant, and I'm here to gently guide you through the process of understanding and accessing the digital legacy that has been entrusted to you.\n\nTake your time. There's no rush. Whenever you're ready, you can ask me anything — about the vault, about next legal steps, or just share how you're feeling."
};

export default function GriefSupportPage() {
  const [messages, setMessages] = useState<Message[]>([INITIAL_MESSAGE]);
  const [input, setInput] = useState("");
  const [sending, setSending] = useState(false);
  const [nomineeName, setNomineeName] = useState("");
  const [deceasedName, setDeceasedName] = useState("");
  const [setup, setSetup] = useState(true);
  const bottomRef = useRef<HTMLDivElement>(null);

  useEffect(() => {
    bottomRef.current?.scrollIntoView({ behavior: "smooth" });
  }, [messages, sending]);

  const startChat = (e: React.FormEvent) => {
    e.preventDefault();
    if (!nomineeName.trim()) return;
    setSetup(false);
    setMessages([{
      role: "assistant",
      content: `I'm here for you, ${nomineeName}. 💙\n\nI understand this is an incredibly difficult time. I'm here to gently guide you through accessing ${deceasedName ? `${deceasedName}'s` : "their"} digital legacy and to support you however I can.\n\nTake your time. You can ask me about the vault, legal next steps, or just share how you're feeling.`
    }]);
  };

  const send = async () => {
    if (!input.trim() || sending) return;
    const userMsg: Message = { role: "user", content: input.trim() };
    setMessages(prev => [...prev, userMsg]);
    setInput("");
    setSending(true);

    try {
      const history = [...messages, userMsg].map(m => ({ role: m.role, content: m.content }));
      const r = await ApiService.request("/api/ai/grief-support", {
        method: "POST",
        body: JSON.stringify({ message: userMsg.content, history, nominee_name: nomineeName, deceased_name: deceasedName })
      });
      setMessages(prev => [...prev, { role: "assistant", content: r.reply || "I'm here for you. Please try again in a moment." }]);
    } catch {
      setMessages(prev => [...prev, { role: "assistant", content: "I apologize — I'm having a moment. Please try again shortly." }]);
    } finally {
      setSending(false);
    }
  };

  if (setup) {
    return (
      <div className="max-w-lg mx-auto pt-10">
        <div className="text-center mb-8">
          <div className="w-16 h-16 bg-purple-100 border border-purple-200 rounded-full flex items-center justify-center mx-auto mb-4">
            <HeartHandshake className="w-8 h-8 text-purple-600" />
          </div>
          <h1 className="text-2xl font-bold text-slate-800 mb-2">Grief Support</h1>
          <p className="text-slate-500 text-sm">A compassionate AI assistant to help nominees navigate this difficult time.</p>
        </div>
        <div className="glass-panel p-6 rounded-3xl bg-white/60">
          <form onSubmit={startChat} className="space-y-4">
            <div>
              <label className="block text-sm font-bold text-slate-700 mb-1">Your Name</label>
              <input required value={nomineeName} onChange={e => setNomineeName(e.target.value)} className="w-full bg-slate-50 border border-slate-200 text-slate-800 p-3 rounded-xl focus:ring-2 focus:ring-purple-400 outline-none" placeholder="e.g. Sarah" />
            </div>
            <div>
              <label className="block text-sm font-bold text-slate-700 mb-1">Name of Deceased (Optional)</label>
              <input value={deceasedName} onChange={e => setDeceasedName(e.target.value)} className="w-full bg-slate-50 border border-slate-200 text-slate-800 p-3 rounded-xl focus:ring-2 focus:ring-purple-400 outline-none" placeholder="e.g. John" />
            </div>
            <button type="submit" className="w-full bg-purple-600 hover:bg-purple-500 p-3 rounded-xl text-white font-bold shadow-md transition-all">
              Begin Session
            </button>
          </form>
        </div>
      </div>
    );
  }

  return (
    <div className="flex flex-col h-[calc(100vh-8rem)] max-w-3xl mx-auto">
      {/* Header */}
      <div className="flex items-center gap-3 pb-4 border-b border-white/50 mb-4 flex-shrink-0">
        <div className="w-10 h-10 bg-purple-100 border border-purple-200 rounded-full flex items-center justify-center">
          <HeartHandshake className="w-5 h-5 text-purple-600" />
        </div>
        <div>
          <h1 className="font-bold text-slate-800">Grief Support</h1>
          <p className="text-xs text-slate-500">Compassionate AI · Context-aware · Confidential</p>
        </div>
        <div className="ml-auto flex items-center gap-1.5">
          <div className="w-2 h-2 rounded-full bg-green-400 animate-pulse" />
          <span className="text-xs text-slate-500">Active</span>
        </div>
      </div>

      {/* Messages */}
      <div className="flex-1 overflow-y-auto space-y-4 pb-4 pr-1">
        <AnimatePresence initial={false}>
          {messages.map((msg, i) => (
            <motion.div
              key={i}
              initial={{ opacity: 0, y: 10 }}
              animate={{ opacity: 1, y: 0 }}
              className={`flex ${msg.role === "user" ? "justify-end" : "justify-start"}`}
            >
              {msg.role === "assistant" && (
                <div className="w-8 h-8 bg-purple-100 border border-purple-200 rounded-full flex items-center justify-center flex-shrink-0 mr-2 mt-1">
                  <HeartHandshake className="w-4 h-4 text-purple-600" />
                </div>
              )}
              <div className={`max-w-[80%] px-5 py-4 rounded-2xl text-sm leading-relaxed whitespace-pre-wrap shadow-sm ${
                msg.role === "user"
                  ? "bg-blue-600 text-white rounded-br-sm"
                  : "bg-white/80 border border-white/60 text-slate-800 rounded-bl-sm"
              }`}>
                {msg.content}
              </div>
            </motion.div>
          ))}
          {sending && (
            <motion.div initial={{ opacity: 0 }} animate={{ opacity: 1 }} className="flex justify-start">
              <div className="w-8 h-8 bg-purple-100 border border-purple-200 rounded-full flex items-center justify-center flex-shrink-0 mr-2 mt-1">
                <HeartHandshake className="w-4 h-4 text-purple-600" />
              </div>
              <div className="bg-white/80 border border-white/60 px-5 py-4 rounded-2xl rounded-bl-sm flex items-center gap-2 shadow-sm">
                <Loader2 className="w-4 h-4 animate-spin text-purple-400" />
                <span className="text-slate-400 text-sm italic">Thinking with care...</span>
              </div>
            </motion.div>
          )}
        </AnimatePresence>
        <div ref={bottomRef} />
      </div>

      {/* Input */}
      <div className="flex-shrink-0 pt-4 border-t border-white/50">
        <div className="flex gap-3 items-end">
          <textarea
            value={input}
            onChange={e => setInput(e.target.value)}
            onKeyDown={e => { if (e.key === "Enter" && !e.shiftKey) { e.preventDefault(); send(); } }}
            rows={2}
            className="flex-1 bg-white/70 border border-white/60 text-slate-800 p-4 rounded-2xl focus:ring-2 focus:ring-purple-300 outline-none resize-none text-sm placeholder-slate-400"
            placeholder="Share what's on your mind... (Enter to send, Shift+Enter for new line)"
          />
          <button
            onClick={send}
            disabled={sending || !input.trim()}
            className="p-4 bg-purple-600 hover:bg-purple-500 text-white rounded-2xl shadow-md transition-all disabled:opacity-50 flex-shrink-0"
          >
            <Send className="w-5 h-5" />
          </button>
        </div>
        <p className="text-xs text-slate-400 text-center mt-2">This is an AI assistant. For emotional crises, please contact a mental health professional.</p>
      </div>
    </div>
  );
}
