"use client";
import { useState, useEffect } from "react";
import { Cpu, Plus, Trash2, Loader2, X, FileText, Eye } from "lucide-react";
import { ApiService } from "@/lib/api";
import { motion } from "framer-motion";

const DOC_TYPES = ["Last Will & Testament","Power of Attorney","Gift Deed","Succession Certificate","Nominee Claim Letter","Insurance Claim","Property Transfer","Bank Closure Letter"];
const LANGUAGES = ["English","Hindi","Urdu","Marathi","Bengali"];

interface LegalDoc { id: number; document_type: string; language: string; created_at: string; content?: string; }

export default function LegalDocumentsPage() {
  const [docs, setDocs] = useState<LegalDoc[]>([]);
  const [loading, setLoading] = useState(true);
  const [showGen, setShowGen] = useState(false);
  const [viewDoc, setViewDoc] = useState<LegalDoc | null>(null);
  const [docType, setDocType] = useState(DOC_TYPES[0]);
  const [language, setLanguage] = useState("English");
  const [details, setDetails] = useState("");
  const [generating, setGenerating] = useState(false);

  const load = async () => {
    const userId = ApiService.getUserId();
    if (!userId) return;
    try { const r = await ApiService.request(`/api/legal-documents?user_id=${userId}`); setDocs(r.documents || r || []); }
    catch { setDocs([]); } finally { setLoading(false); }
  };

  useEffect(() => { load(); }, []);

  const generate = async (e: React.FormEvent) => {
    e.preventDefault(); setGenerating(true);
    try {
      const r = await ApiService.request("/api/legal-documents/generate", { method: "POST", body: JSON.stringify({ user_id: ApiService.getUserId(), document_type: docType, language, additional_details: details }) });
      setShowGen(false); setDetails(""); load();
      if (r.document) setViewDoc(r.document);
    } catch { } finally { setGenerating(false); }
  };

  const deleteDoc = async (id: number) => { await ApiService.request(`/api/legal-documents/${id}?user_id=${ApiService.getUserId()}`, { method: "DELETE" }); load(); };

  return (
    <div className="space-y-6 max-w-4xl">
      <div className="flex justify-between items-end mb-8">
        <div>
          <h1 className="text-3xl font-bold text-slate-800 flex items-center gap-3 mb-2"><Cpu className="w-8 h-8 text-blue-600" />Legal Document Generator</h1>
          <p className="text-slate-600">AI-generated legal documents — Power of Attorney, Wills, Gift Deeds & more.</p>
        </div>
        <button onClick={() => setShowGen(true)} className="bg-blue-600 hover:bg-blue-500 flex items-center gap-2 px-5 py-2.5 rounded-xl text-white font-semibold shadow-md transition-all">
          <Plus className="w-4 h-4" /> Generate Document
        </button>
      </div>

      {loading ? (
        <div className="glass-panel p-10 rounded-3xl text-center bg-white/50"><Loader2 className="w-8 h-8 animate-spin text-blue-400 mx-auto" /></div>
      ) : docs.length === 0 ? (
        <div className="glass-panel p-12 rounded-3xl text-center bg-white/50">
          <FileText className="w-12 h-12 text-blue-300 mx-auto mb-3" />
          <h3 className="text-lg font-bold text-slate-800 mb-1">No Documents Yet</h3>
          <p className="text-slate-500 text-sm mb-5">Generate AI-powered legal documents in multiple languages.</p>
          <button onClick={() => setShowGen(true)} className="bg-blue-600 hover:bg-blue-500 px-5 py-2.5 rounded-xl text-white font-semibold shadow-md">Generate Your First Document</button>
        </div>
      ) : (
        <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
          {docs.map((doc, i) => (
            <motion.div key={doc.id} initial={{ opacity: 0, y: 10 }} animate={{ opacity: 1, y: 0 }} transition={{ delay: i * 0.07 }}
              className="glass-panel p-5 rounded-2xl bg-white/50 flex items-start justify-between gap-3">
              <div className="flex items-start gap-3 flex-1 min-w-0">
                <div className="w-10 h-10 bg-blue-50 border border-blue-100 rounded-xl flex items-center justify-center flex-shrink-0"><FileText className="w-5 h-5 text-blue-500" /></div>
                <div className="min-w-0">
                  <p className="font-semibold text-slate-800 truncate">{doc.document_type}</p>
                  <p className="text-xs text-slate-500">{doc.language} · {new Date(doc.created_at).toLocaleDateString()}</p>
                </div>
              </div>
              <div className="flex gap-2 flex-shrink-0">
                <button onClick={() => setViewDoc(doc)} className="p-2 text-blue-500 hover:text-blue-700 bg-blue-50 hover:bg-blue-100 rounded-lg border border-blue-100 transition-all"><Eye className="w-4 h-4" /></button>
                <button onClick={() => deleteDoc(doc.id)} className="p-2 text-red-400 hover:text-red-600 bg-red-50 hover:bg-red-100 rounded-lg border border-red-100 transition-all"><Trash2 className="w-4 h-4" /></button>
              </div>
            </motion.div>
          ))}
        </div>
      )}

      {/* Generate Modal */}
      {showGen && (
        <div className="fixed inset-0 bg-slate-900/40 backdrop-blur-sm z-50 flex items-center justify-center p-4">
          <motion.div initial={{ opacity: 0, scale: 0.95 }} animate={{ opacity: 1, scale: 1 }} className="bg-white max-w-md w-full rounded-3xl p-6 shadow-2xl relative">
            <button onClick={() => setShowGen(false)} className="absolute top-4 right-4 p-2 text-slate-400 hover:text-slate-600 rounded-full hover:bg-slate-100"><X className="w-5 h-5" /></button>
            <h2 className="text-xl font-bold text-slate-800 mb-5">Generate Legal Document</h2>
            <form onSubmit={generate} className="space-y-4">
              <div>
                <label className="block text-sm font-bold text-slate-700 mb-1">Document Type</label>
                <select value={docType} onChange={e => setDocType(e.target.value)} className="w-full bg-slate-50 border border-slate-200 text-slate-800 p-3 rounded-xl focus:ring-2 focus:ring-blue-400 outline-none">
                  {DOC_TYPES.map(t => <option key={t}>{t}</option>)}
                </select>
              </div>
              <div>
                <label className="block text-sm font-bold text-slate-700 mb-1">Language</label>
                <select value={language} onChange={e => setLanguage(e.target.value)} className="w-full bg-slate-50 border border-slate-200 text-slate-800 p-3 rounded-xl focus:ring-2 focus:ring-blue-400 outline-none">
                  {LANGUAGES.map(l => <option key={l}>{l}</option>)}
                </select>
              </div>
              <div>
                <label className="block text-sm font-bold text-slate-700 mb-1">Additional Details</label>
                <textarea value={details} onChange={e => setDetails(e.target.value)} rows={4} className="w-full bg-slate-50 border border-slate-200 text-slate-800 p-3 rounded-xl focus:ring-2 focus:ring-blue-400 outline-none resize-none" placeholder="Names, assets, specific instructions..." />
              </div>
              <button disabled={generating} type="submit" className="w-full bg-blue-600 hover:bg-blue-500 p-3 rounded-xl text-white font-bold flex items-center justify-center gap-2 shadow-md transition-all disabled:opacity-60">
                {generating ? <><Loader2 className="w-4 h-4 animate-spin" /> Generating...</> : "Generate with AI"}
              </button>
            </form>
          </motion.div>
        </div>
      )}

      {/* View Modal */}
      {viewDoc && (
        <div className="fixed inset-0 bg-slate-900/60 backdrop-blur-sm z-50 flex items-center justify-center p-4">
          <motion.div initial={{ opacity: 0, scale: 0.95 }} animate={{ opacity: 1, scale: 1 }} className="bg-white max-w-2xl w-full rounded-3xl shadow-2xl relative flex flex-col max-h-[90vh]">
            <div className="flex items-center justify-between p-6 border-b border-slate-100">
              <h2 className="text-lg font-bold text-slate-800">{viewDoc.document_type}</h2>
              <button onClick={() => setViewDoc(null)} className="p-2 text-slate-400 hover:text-slate-600 rounded-full hover:bg-slate-100"><X className="w-5 h-5" /></button>
            </div>
            <div className="flex-1 overflow-y-auto p-6">
              <p className="text-sm text-slate-700 whitespace-pre-wrap leading-relaxed">{viewDoc.content || "Document content not available."}</p>
            </div>
          </motion.div>
        </div>
      )}
    </div>
  );
}
