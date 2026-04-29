"use client";
import { useState, useEffect } from "react";
import { Bell, Plus, Trash2, AlertTriangle, CheckCircle2, Clock, Loader2, X } from "lucide-react";
import { ApiService } from "@/lib/api";
import { motion } from "framer-motion";
import { SecurityService } from "@/lib/security";

interface SmartDoc { id: number; document_name: string; expiry_date: string; status: string; days_until_expiry: number; }

export default function SmartAlertsPage() {
  const [docs, setDocs] = useState<SmartDoc[]>([]);
  const [loading, setLoading] = useState(true);
  const [showAdd, setShowAdd] = useState(false);
  const [name, setName] = useState("");
  const [expiry, setExpiry] = useState("");
  const [saving, setSaving] = useState(false);

  const load = async () => {
    const userId = ApiService.getUserId();
    if (!userId) return;
    try {
      const r = await ApiService.request(`/api/smart_docs?user_id=${userId}`);
      const rawDocs = r.docs || r || [];
      
      // Decrypt document names
      const decryptedDocs = await Promise.all(rawDocs.map(async (d: any) => {
        try {
          const decryptedName = await SecurityService.decrypt(d.document_name);
          return { ...d, document_name: decryptedName };
        } catch (e) {
          // Legacy or failed decryption
          return d;
        }
      }));
      
      setDocs(decryptedDocs);
    } catch { setDocs([]); } finally { setLoading(false); }
  };

  useEffect(() => { load(); }, []);

  const addDoc = async (e: React.FormEvent) => {
    e.preventDefault();
    setSaving(true);
    try {
      // ENCRYPT DOCUMENT NAME
      const encryptedName = await SecurityService.encrypt(name);
      
      await ApiService.request("/api/smart_docs", { 
        method: "POST", 
        body: JSON.stringify({ 
          user_id: ApiService.getUserId(), 
          document_name: encryptedName, 
          expiry_date: expiry 
        }) 
      });
      setShowAdd(false); setName(""); setExpiry(""); load();
    } catch { } finally { setSaving(false); }
  };

  const deleteDoc = async (id: number) => {
    await ApiService.request(`/api/smart_docs/${id}?user_id=${ApiService.getUserId()}`, { method: "DELETE" });
    load();
  };

  const total = docs.length;
  const urgent = docs.filter(d => d.days_until_expiry !== undefined && d.days_until_expiry <= 30 && d.days_until_expiry >= 0).length;
  const expired = docs.filter(d => d.days_until_expiry < 0 || d.status === "expired").length;

  const getStatus = (d: SmartDoc) => {
    if (d.days_until_expiry < 0 || d.status === "expired") return { label: "Expired", color: "text-red-600 bg-red-50 border-red-100" };
    if (d.days_until_expiry <= 30) return { label: `${d.days_until_expiry}d left`, color: "text-amber-600 bg-amber-50 border-amber-100" };
    return { label: "Valid", color: "text-green-600 bg-green-50 border-green-100" };
  };

  return (
    <div className="space-y-6 max-w-4xl">
      <div className="flex justify-between items-end mb-8">
        <div>
          <h1 className="text-3xl font-bold text-slate-800 flex items-center gap-3 mb-2"><Bell className="w-8 h-8 text-blue-600" />Smart Alerts</h1>
          <p className="text-slate-600">Track document expiry dates and get timely renewal reminders.</p>
        </div>
        <button onClick={() => setShowAdd(true)} className="bg-blue-600 hover:bg-blue-500 flex items-center gap-2 px-5 py-2.5 rounded-xl text-white font-semibold shadow-md transition-all">
          <Plus className="w-4 h-4" /> Add Alert
        </button>
      </div>

      {/* Stats */}
      <div className="grid grid-cols-3 gap-4">
        {[
          { label: "Total", value: total, icon: CheckCircle2, color: "text-blue-600 bg-blue-50" },
          { label: "Urgent (30d)", value: urgent, icon: Clock, color: "text-amber-600 bg-amber-50" },
          { label: "Expired", value: expired, icon: AlertTriangle, color: "text-red-600 bg-red-50" },
        ].map(s => (
          <div key={s.label} className="glass-panel p-5 rounded-2xl bg-white/50 text-center">
            <div className={`w-10 h-10 rounded-full ${s.color} flex items-center justify-center mx-auto mb-2`}>
              <s.icon className="w-5 h-5" />
            </div>
            <div className="text-2xl font-bold text-slate-800">{s.value}</div>
            <div className="text-xs text-slate-500 font-medium">{s.label}</div>
          </div>
        ))}
      </div>

      {/* List */}
      {loading ? (
        <div className="glass-panel p-10 rounded-3xl text-center bg-white/50"><Loader2 className="w-8 h-8 animate-spin text-blue-400 mx-auto" /></div>
      ) : docs.length === 0 ? (
        <div className="glass-panel p-12 rounded-3xl text-center bg-white/50">
          <Bell className="w-12 h-12 text-blue-300 mx-auto mb-3" />
          <h3 className="text-lg font-bold text-slate-800 mb-1">No Alerts Yet</h3>
          <p className="text-slate-500 text-sm">Add document expiry dates to get renewal reminders.</p>
        </div>
      ) : (
        <div className="space-y-3">
          {docs.map((doc, i) => {
            const status = getStatus(doc);
            return (
              <motion.div key={doc.id} initial={{ opacity: 0, y: 10 }} animate={{ opacity: 1, y: 0 }} transition={{ delay: i * 0.06 }}
                className="glass-panel p-5 rounded-2xl bg-white/50 flex items-center justify-between">
                <div className="flex items-center gap-4">
                  <div className="w-10 h-10 bg-blue-50 border border-blue-100 rounded-xl flex items-center justify-center">
                    <Bell className="w-5 h-5 text-blue-500" />
                  </div>
                  <div>
                    <p className="font-semibold text-slate-800">{doc.document_name}</p>
                    <p className="text-xs text-slate-500">Expires: {new Date(doc.expiry_date).toLocaleDateString("en-IN", { day: "numeric", month: "short", year: "numeric" })}</p>
                  </div>
                </div>
                <div className="flex items-center gap-3">
                  <span className={`text-xs font-bold px-3 py-1 rounded-full border ${status.color}`}>{status.label}</span>
                  <button onClick={() => deleteDoc(doc.id)} className="p-2 text-red-400 hover:text-red-600 bg-red-50 hover:bg-red-100 rounded-lg border border-red-100 transition-all">
                    <Trash2 className="w-4 h-4" />
                  </button>
                </div>
              </motion.div>
            );
          })}
        </div>
      )}

      {/* Add Modal */}
      {showAdd && (
        <div className="fixed inset-0 bg-slate-900/40 backdrop-blur-sm z-50 flex items-center justify-center p-4">
          <motion.div initial={{ opacity: 0, scale: 0.95 }} animate={{ opacity: 1, scale: 1 }} className="bg-white max-w-md w-full rounded-3xl p-6 shadow-2xl relative">
            <button onClick={() => setShowAdd(false)} className="absolute top-4 right-4 p-2 text-slate-400 hover:text-slate-600 hover:bg-slate-100 rounded-full"><X className="w-5 h-5" /></button>
            <h2 className="text-xl font-bold text-slate-800 mb-5">Add Document Alert</h2>
            <form onSubmit={addDoc} className="space-y-4">
              <div>
                <label className="block text-sm font-bold text-slate-700 mb-1">Document Name</label>
                <input required value={name} onChange={e => setName(e.target.value)} className="w-full bg-slate-50 border border-slate-200 text-slate-800 p-3 rounded-xl focus:ring-2 focus:ring-blue-400 outline-none" placeholder="e.g. Passport, Driving License" />
              </div>
              <div>
                <label className="block text-sm font-bold text-slate-700 mb-1">Expiry Date</label>
                <input required type="date" value={expiry} onChange={e => setExpiry(e.target.value)} className="w-full bg-slate-50 border border-slate-200 text-slate-800 p-3 rounded-xl focus:ring-2 focus:ring-blue-400 outline-none" />
              </div>
              <button disabled={saving} type="submit" className="w-full bg-blue-600 hover:bg-blue-500 p-3 rounded-xl text-white font-bold flex items-center justify-center gap-2 shadow-md transition-all mt-2 disabled:opacity-60">
                {saving ? <Loader2 className="w-4 h-4 animate-spin" /> : "Save Alert"}
              </button>
            </form>
          </motion.div>
        </div>
      )}
    </div>
  );
}
