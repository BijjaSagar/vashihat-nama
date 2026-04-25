"use client";
import { useState, useEffect } from "react";
import { Map, Loader2, CheckCircle2, Circle, Sparkles } from "lucide-react";
import { ApiService } from "@/lib/api";
import { motion } from "framer-motion";

const COUNTRIES = ["India", "Pakistan", "UAE", "UK", "USA", "Canada", "Australia", "Singapore"];
interface DocItem { id?: number; document_name: string; status: "pending" | "uploaded" | "verified"; is_required: boolean; }

export default function RegionalPage() {
  const [country, setCountry] = useState("India");
  const [docs, setDocs] = useState<DocItem[]>([]);
  const [loading, setLoading] = useState(false);
  const [generating, setGenerating] = useState(false);

  const load = async (c: string) => {
    setLoading(true);
    try { const r = await ApiService.request(`/api/regional/checklists?country_code=${c}`); setDocs(r.docs || r || []); }
    catch { setDocs([]); } finally { setLoading(false); }
  };

  const generateAI = async () => {
    setGenerating(true);
    try {
      const r = await ApiService.request("/api/regional/generate-ai", { method: "POST", body: JSON.stringify({ country, user_id: ApiService.getUserId() }) });
      setDocs(r.docs || r || []);
    } catch { } finally { setGenerating(false); }
  };

  const updateDoc = async (doc: DocItem, status: string) => {
    await ApiService.request("/api/regional/user_docs", { method: "POST", body: JSON.stringify({ user_id: ApiService.getUserId(), document_name: doc.document_name, country, status }) });
    setDocs(prev => prev.map(d => d.document_name === doc.document_name ? { ...d, status: status as DocItem["status"] } : d));
  };

  useEffect(() => { load(country); }, [country]);

  const statusBadge = (s: string) => ({
    pending: "bg-slate-100 text-slate-500 border-slate-200",
    uploaded: "bg-amber-50 text-amber-600 border-amber-100",
    verified: "bg-green-50 text-green-600 border-green-100"
  })[s] || "bg-slate-100 text-slate-500";

  const completed = docs.filter(d => d.status === "verified" || d.status === "uploaded").length;

  return (
    <div className="space-y-6 max-w-4xl">
      <div className="mb-8">
        <h1 className="text-3xl font-bold text-slate-800 flex items-center gap-3 mb-2"><Map className="w-8 h-8 text-blue-600" />Regional Compliance</h1>
        <p className="text-slate-600">Country-specific legal document requirements for estate planning.</p>
      </div>

      {/* Country Selector */}
      <div className="glass-panel p-5 rounded-3xl bg-white/50 flex flex-wrap items-end gap-4">
        <div className="flex-1 min-w-[180px]">
          <label className="block text-sm font-bold text-slate-700 mb-2">Select Country</label>
          <select value={country} onChange={e => setCountry(e.target.value)} className="w-full bg-slate-50 border border-slate-200 text-slate-800 p-3 rounded-xl focus:ring-2 focus:ring-blue-400 outline-none">
            {COUNTRIES.map(c => <option key={c}>{c}</option>)}
          </select>
        </div>
        <button onClick={generateAI} disabled={generating} className="flex items-center gap-2 px-5 py-3 rounded-xl bg-blue-600 hover:bg-blue-500 text-white font-semibold shadow-md transition-all disabled:opacity-60">
          {generating ? <Loader2 className="w-4 h-4 animate-spin" /> : <Sparkles className="w-4 h-4" />} AI Generate
        </button>
      </div>

      {/* Progress */}
      {docs.length > 0 && (
        <div className="glass-panel p-4 rounded-2xl bg-white/50">
          <div className="flex justify-between mb-2">
            <span className="text-sm font-bold text-slate-700">Compliance Progress</span>
            <span className="text-sm font-bold text-blue-600">{completed}/{docs.length}</span>
          </div>
          <div className="h-2.5 bg-slate-100 rounded-full overflow-hidden">
            <div className="h-2.5 bg-gradient-to-r from-blue-500 to-blue-600 rounded-full transition-all duration-700" style={{ width: `${docs.length ? (completed / docs.length) * 100 : 0}%` }} />
          </div>
        </div>
      )}

      {/* Docs List */}
      {loading || generating ? (
        <div className="glass-panel p-10 rounded-3xl text-center bg-white/50"><Loader2 className="w-8 h-8 animate-spin text-blue-400 mx-auto" /></div>
      ) : docs.length === 0 ? (
        <div className="glass-panel p-10 rounded-3xl text-center bg-white/50">
          <Map className="w-10 h-10 text-blue-300 mx-auto mb-3" />
          <p className="text-slate-500">Click &quot;AI Generate&quot; to get country-specific legal requirements.</p>
        </div>
      ) : (
        <div className="space-y-3">
          {docs.map((doc, i) => (
            <motion.div key={i} initial={{ opacity: 0, y: 8 }} animate={{ opacity: 1, y: 0 }} transition={{ delay: i * 0.05 }}
              className="glass-panel p-4 rounded-2xl bg-white/50 flex items-center justify-between gap-4">
              <div className="flex items-center gap-3 flex-1 min-w-0">
                {doc.status === "verified" || doc.status === "uploaded"
                  ? <CheckCircle2 className="w-5 h-5 text-green-500 flex-shrink-0" />
                  : <Circle className="w-5 h-5 text-slate-300 flex-shrink-0" />}
                <div className="min-w-0">
                  <p className="font-semibold text-slate-800 text-sm truncate">{doc.document_name}</p>
                  {doc.is_required && <p className="text-xs text-red-500 font-medium">Required</p>}
                </div>
              </div>
              <select
                value={doc.status}
                onChange={e => updateDoc(doc, e.target.value)}
                className={`text-xs font-bold px-3 py-1.5 rounded-lg border cursor-pointer outline-none ${statusBadge(doc.status)}`}
              >
                <option value="pending">Pending</option>
                <option value="uploaded">Uploaded</option>
                <option value="verified">Verified</option>
              </select>
            </motion.div>
          ))}
        </div>
      )}
    </div>
  );
}
