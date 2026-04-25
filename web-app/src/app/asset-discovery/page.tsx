"use client";
import { useState, useEffect } from "react";
import { Search, Loader2, CheckCircle2, Circle, Sparkles } from "lucide-react";
import { ApiService } from "@/lib/api";
import { motion } from "framer-motion";

interface AssetItem { id: number; asset_name: string; category: string; priority: "high" | "medium" | "low"; is_completed: boolean; }
interface AssetData { items: AssetItem[]; }

const PRIORITIES = { high: "bg-red-50 border-red-100 text-red-600", medium: "bg-amber-50 border-amber-100 text-amber-600", low: "bg-blue-50 border-blue-100 text-blue-600" };

export default function AssetDiscoveryPage() {
  const [data, setData] = useState<AssetItem[]>([]);
  const [loading, setLoading] = useState(true);
  const [generating, setGenerating] = useState(false);
  const [country, setCountry] = useState("India");
  const [occupation, setOccupation] = useState("");

  const userId = ApiService.getUserId();

  const load = async () => {
    if (!userId) return;
    try { const r = await ApiService.request(`/api/asset-discovery?user_id=${userId}`); setData(r.items || r || []); }
    catch { setData([]); } finally { setLoading(false); }
  };

  useEffect(() => { load(); }, []);

  const generate = async () => {
    setGenerating(true);
    try {
      await ApiService.request("/api/asset-discovery/generate", { method: "POST", body: JSON.stringify({ user_id: userId, country, occupation }) });
      load();
    } catch { } finally { setGenerating(false); }
  };

  const toggle = async (id: number) => {
    await ApiService.request(`/api/asset-discovery/${id}/toggle`, { method: "PUT", body: JSON.stringify({ user_id: userId }) });
    setData(prev => prev.map(i => i.id === id ? { ...i, is_completed: !i.is_completed } : i));
  };

  const completed = data.filter(i => i.is_completed).length;
  const progress = data.length ? Math.round((completed / data.length) * 100) : 0;

  const grouped = data.reduce((acc, item) => { if (!acc[item.category]) acc[item.category] = []; acc[item.category].push(item); return acc; }, {} as Record<string, AssetItem[]>);

  return (
    <div className="space-y-6 max-w-4xl">
      <div className="mb-8">
        <h1 className="text-3xl font-bold text-slate-800 flex items-center gap-3 mb-2"><Search className="w-8 h-8 text-blue-600" />Smart Asset Discovery</h1>
        <p className="text-slate-600">AI generates a personalized asset checklist to ensure nothing is left out.</p>
      </div>

      {/* Generate */}
      <div className="glass-panel p-6 rounded-3xl bg-white/50 flex flex-wrap items-end gap-4">
        <div>
          <label className="block text-sm font-bold text-slate-700 mb-1">Country</label>
          <input value={country} onChange={e => setCountry(e.target.value)} className="bg-slate-50 border border-slate-200 text-slate-800 px-3 py-2 rounded-xl focus:ring-2 focus:ring-blue-400 outline-none text-sm" />
        </div>
        <div>
          <label className="block text-sm font-bold text-slate-700 mb-1">Occupation (Optional)</label>
          <input value={occupation} onChange={e => setOccupation(e.target.value)} className="bg-slate-50 border border-slate-200 text-slate-800 px-3 py-2 rounded-xl focus:ring-2 focus:ring-blue-400 outline-none text-sm" placeholder="e.g. Doctor, Business Owner" />
        </div>
        <button onClick={generate} disabled={generating} className="flex items-center gap-2 px-5 py-2.5 rounded-xl bg-blue-600 hover:bg-blue-500 text-white font-semibold shadow-md transition-all disabled:opacity-60">
          {generating ? <Loader2 className="w-4 h-4 animate-spin" /> : <Sparkles className="w-4 h-4" />} Generate AI Checklist
        </button>
      </div>

      {/* Progress */}
      {data.length > 0 && (
        <div className="glass-panel p-5 rounded-2xl bg-white/50">
          <div className="flex items-center justify-between mb-2">
            <span className="text-sm font-bold text-slate-700">Assets Documented</span>
            <span className="text-sm font-bold text-blue-600">{completed}/{data.length} ({progress}%)</span>
          </div>
          <div className="h-3 bg-slate-100 rounded-full overflow-hidden">
            <div className="h-3 bg-gradient-to-r from-blue-500 to-blue-600 rounded-full transition-all duration-700" style={{ width: `${progress}%` }} />
          </div>
        </div>
      )}

      {/* Groups */}
      {loading ? (
        <div className="glass-panel p-10 rounded-3xl text-center bg-white/50"><Loader2 className="w-8 h-8 animate-spin text-blue-400 mx-auto" /></div>
      ) : data.length === 0 ? (
        <div className="glass-panel p-10 rounded-3xl text-center bg-white/50">
          <Search className="w-10 h-10 text-blue-300 mx-auto mb-3" />
          <p className="text-slate-500">Generate an AI checklist to see your personalized asset list.</p>
        </div>
      ) : (
        <div className="space-y-6">
          {Object.entries(grouped).map(([category, items]) => (
            <div key={category} className="glass-panel p-6 rounded-3xl bg-white/50">
              <h3 className="text-base font-bold text-slate-800 mb-4">{category}</h3>
              <div className="space-y-2">
                {items.map((item, i) => (
                  <motion.div key={item.id} initial={{ opacity: 0 }} animate={{ opacity: 1 }} transition={{ delay: i * 0.05 }}
                    className="flex items-center gap-3 p-3 rounded-xl border border-slate-100 bg-slate-50 cursor-pointer hover:bg-slate-100 transition-all"
                    onClick={() => toggle(item.id)}>
                    {item.is_completed
                      ? <CheckCircle2 className="w-5 h-5 text-green-500 flex-shrink-0" />
                      : <Circle className="w-5 h-5 text-slate-300 flex-shrink-0" />}
                    <span className={`text-sm flex-1 ${item.is_completed ? "line-through text-slate-400" : "text-slate-700"}`}>{item.asset_name}</span>
                    <span className={`text-xs font-bold px-2 py-0.5 rounded border ${PRIORITIES[item.priority]}`}>{item.priority}</span>
                  </motion.div>
                ))}
              </div>
            </div>
          ))}
        </div>
      )}
    </div>
  );
}
