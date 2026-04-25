"use client";
import { useState, useEffect } from "react";
import { Video, Plus, Trash2, Loader2, X, Sparkles } from "lucide-react";
import { ApiService } from "@/lib/api";
import { motion } from "framer-motion";

interface VideoWill { id: number; nominee_name?: string; message_type: string; content: string; created_at: string; summary?: string; }
interface Nominee { id: number; name: string; }

export default function VideoWillPage() {
  const [wills, setWills] = useState<VideoWill[]>([]);
  const [nominees, setNominees] = useState<Nominee[]>([]);
  const [loading, setLoading] = useState(true);
  const [showAdd, setShowAdd] = useState(false);
  const [content, setContent] = useState("");
  const [nomineeId, setNomineeId] = useState("");
  const [saving, setSaving] = useState(false);
  const [summarizing, setSummarizing] = useState(false);

  const userId = ApiService.getUserId();

  const load = async () => {
    if (!userId) return;
    try {
      const [w, n] = await Promise.all([
        ApiService.request(`/api/video-wills?user_id=${userId}`),
        ApiService.request(`/api/nominees?user_id=${userId}`)
      ]);
      setWills(w.wills || w || []);
      setNominees(n.nominees || n || []);
    } catch { } finally { setLoading(false); }
  };

  useEffect(() => { load(); }, []);

  const save = async (e: React.FormEvent) => {
    e.preventDefault(); setSaving(true);
    try {
      await ApiService.request("/api/video-wills", { method: "POST", body: JSON.stringify({ user_id: userId, nominee_id: nomineeId || null, message_type: "text", content }) });
      setShowAdd(false); setContent(""); setNomineeId(""); load();
    } catch { } finally { setSaving(false); }
  };

  const summarize = async () => {
    if (!content.trim()) return;
    setSummarizing(true);
    try {
      const r = await ApiService.request("/api/video-wills/summarize", { method: "POST", body: JSON.stringify({ content }) });
      setContent(r.summary || content);
    } catch { } finally { setSummarizing(false); }
  };

  const deleteWill = async (id: number) => { await ApiService.request(`/api/video-wills/${id}?user_id=${userId}`, { method: "DELETE" }); load(); };

  return (
    <div className="space-y-6 max-w-4xl">
      <div className="flex justify-between items-end mb-8">
        <div>
          <h1 className="text-3xl font-bold text-slate-800 flex items-center gap-3 mb-2"><Video className="w-8 h-8 text-blue-600" />Video Will / Messages</h1>
          <p className="text-slate-600">Leave personal messages for your nominees to be delivered after you&#39;re gone.</p>
        </div>
        <button onClick={() => setShowAdd(true)} className="bg-blue-600 hover:bg-blue-500 flex items-center gap-2 px-5 py-2.5 rounded-xl text-white font-semibold shadow-md transition-all">
          <Plus className="w-4 h-4" /> New Message
        </button>
      </div>

      {loading ? (
        <div className="glass-panel p-10 rounded-3xl text-center bg-white/50"><Loader2 className="w-8 h-8 animate-spin text-blue-400 mx-auto" /></div>
      ) : wills.length === 0 ? (
        <div className="glass-panel p-12 rounded-3xl text-center bg-white/50">
          <Video className="w-12 h-12 text-blue-300 mx-auto mb-3" />
          <h3 className="text-lg font-bold text-slate-800 mb-1">No Messages Yet</h3>
          <p className="text-slate-500 text-sm mb-5">Write personal messages for your loved ones.</p>
          <button onClick={() => setShowAdd(true)} className="bg-blue-600 hover:bg-blue-500 px-5 py-2.5 rounded-xl text-white font-semibold shadow-md">Write Your First Message</button>
        </div>
      ) : (
        <div className="space-y-4">
          {wills.map((w, i) => (
            <motion.div key={w.id} initial={{ opacity: 0, y: 10 }} animate={{ opacity: 1, y: 0 }} transition={{ delay: i * 0.07 }}
              className="glass-panel p-5 rounded-2xl bg-white/50">
              <div className="flex items-start justify-between gap-3 mb-3">
                <div>
                  <p className="font-semibold text-slate-800">To: {w.nominee_name || "All Nominees"}</p>
                  <p className="text-xs text-slate-500">{new Date(w.created_at).toLocaleDateString()}</p>
                </div>
                <button onClick={() => deleteWill(w.id)} className="p-2 text-red-400 hover:text-red-600 bg-red-50 hover:bg-red-100 rounded-lg border border-red-100 transition-all flex-shrink-0"><Trash2 className="w-4 h-4" /></button>
              </div>
              <p className="text-sm text-slate-700 line-clamp-3 leading-relaxed">{w.summary || w.content}</p>
            </motion.div>
          ))}
        </div>
      )}

      {showAdd && (
        <div className="fixed inset-0 bg-slate-900/40 backdrop-blur-sm z-50 flex items-center justify-center p-4">
          <motion.div initial={{ opacity: 0, scale: 0.95 }} animate={{ opacity: 1, scale: 1 }} className="bg-white max-w-lg w-full rounded-3xl p-6 shadow-2xl relative">
            <button onClick={() => setShowAdd(false)} className="absolute top-4 right-4 p-2 text-slate-400 hover:text-slate-600 rounded-full hover:bg-slate-100"><X className="w-5 h-5" /></button>
            <h2 className="text-xl font-bold text-slate-800 mb-5">Write a Personal Message</h2>
            <form onSubmit={save} className="space-y-4">
              <div>
                <label className="block text-sm font-bold text-slate-700 mb-1">For Nominee (Optional)</label>
                <select value={nomineeId} onChange={e => setNomineeId(e.target.value)} className="w-full bg-slate-50 border border-slate-200 text-slate-800 p-3 rounded-xl focus:ring-2 focus:ring-blue-400 outline-none">
                  <option value="">All Nominees</option>
                  {nominees.map(n => <option key={n.id} value={n.id}>{n.name}</option>)}
                </select>
              </div>
              <div>
                <label className="block text-sm font-bold text-slate-700 mb-1">Your Message</label>
                <textarea required value={content} onChange={e => setContent(e.target.value)} rows={6} className="w-full bg-slate-50 border border-slate-200 text-slate-800 p-3 rounded-xl focus:ring-2 focus:ring-blue-400 outline-none resize-none" placeholder="Write your heartfelt message here..." />
              </div>
              <div className="flex gap-3">
                <button type="button" onClick={summarize} disabled={summarizing || !content.trim()} className="flex items-center gap-2 px-4 py-2.5 rounded-xl border border-blue-200 text-blue-600 bg-blue-50 hover:bg-blue-100 font-semibold text-sm transition-all disabled:opacity-50">
                  {summarizing ? <Loader2 className="w-4 h-4 animate-spin" /> : <Sparkles className="w-4 h-4" />} AI Summarize
                </button>
                <button disabled={saving} type="submit" className="flex-1 bg-blue-600 hover:bg-blue-500 p-2.5 rounded-xl text-white font-bold flex items-center justify-center gap-2 shadow-md transition-all disabled:opacity-60">
                  {saving ? <Loader2 className="w-4 h-4 animate-spin" /> : "Save Message"}
                </button>
              </div>
            </form>
          </motion.div>
        </div>
      )}
    </div>
  );
}
