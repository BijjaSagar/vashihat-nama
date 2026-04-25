"use client";
import { useState, useEffect } from "react";
import { Activity, Loader2, TrendingUp, AlertCircle, CheckCircle2, ArrowRight } from "lucide-react";
import { ApiService } from "@/lib/api";
import { motion } from "framer-motion";

interface Rec { priority: "high" | "medium" | "low"; text: string; }
interface VaultHealth { score: number; stats: { folders: number; nominees: number; files: number; vault_items: number }; recommendations: Rec[]; }

export default function VaultHealthPage() {
  const [data, setData] = useState<VaultHealth | null>(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    const userId = ApiService.getUserId();
    if (!userId) return;
    ApiService.request(`/api/vault-health?user_id=${userId}`)
      .then(r => setData(r))
      .catch(() => {})
      .finally(() => setLoading(false));
  }, []);

  const circumference = 2 * Math.PI * 54;
  const score = data?.score ?? 0;
  const scoreColor = score >= 80 ? "stroke-green-400" : score >= 50 ? "stroke-amber-400" : "stroke-red-400";
  const scoreText = score >= 80 ? "text-green-600" : score >= 50 ? "text-amber-500" : "text-red-500";
  const prioColor = (p: string) => p === "high" ? "bg-red-50 border-red-100 text-red-600" : p === "medium" ? "bg-amber-50 border-amber-100 text-amber-600" : "bg-blue-50 border-blue-100 text-blue-600";

  return (
    <div className="space-y-6 max-w-4xl">
      <div className="mb-8">
        <h1 className="text-3xl font-bold text-slate-800 flex items-center gap-3 mb-2"><Activity className="w-8 h-8 text-blue-600" />AI Vault Health</h1>
        <p className="text-slate-600">AI-powered analysis of your vault completeness and coverage.</p>
      </div>
      {loading ? (
        <div className="glass-panel p-12 rounded-3xl text-center bg-white/50"><Loader2 className="w-10 h-10 animate-spin text-blue-400 mx-auto" /></div>
      ) : (
        <>
          <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
            <motion.div initial={{ opacity: 0 }} animate={{ opacity: 1 }} className="glass-panel p-8 rounded-3xl bg-white/50 text-center">
              <svg width="140" height="140" className="mx-auto mb-4" viewBox="0 0 120 120">
                <circle cx="60" cy="60" r="54" fill="none" stroke="#e2e8f0" strokeWidth="10" />
                <circle cx="60" cy="60" r="54" fill="none" className={scoreColor} strokeWidth="10" strokeLinecap="round"
                  strokeDasharray={circumference} strokeDashoffset={circumference - (circumference * score) / 100}
                  transform="rotate(-90 60 60)" style={{ transition: "stroke-dashoffset 1.2s ease" }} />
                <text x="60" y="65" textAnchor="middle" style={{ fontSize: 22, fill: "#1e293b", fontWeight: 700 }}>{score}%</text>
              </svg>
              <h2 className={`text-xl font-bold ${scoreText}`}>{score >= 80 ? "Healthy Vault" : score >= 50 ? "Partially Complete" : "Needs Attention"}</h2>
            </motion.div>
            <div className="grid grid-cols-2 gap-3 content-start">
              {[
                { label: "Vault Items", value: data?.stats?.vault_items ?? 0, color: "text-blue-600 bg-blue-50" },
                { label: "Nominees", value: data?.stats?.nominees ?? 0, color: "text-purple-600 bg-purple-50" },
                { label: "Folders", value: data?.stats?.folders ?? 0, color: "text-green-600 bg-green-50" },
                { label: "Files", value: data?.stats?.files ?? 0, color: "text-amber-600 bg-amber-50" },
              ].map(s => (
                <div key={s.label} className="glass-panel p-4 rounded-2xl bg-white/60 text-center">
                  <div className="text-2xl font-bold text-slate-800">{s.value}</div>
                  <div className="text-xs text-slate-500 mt-1">{s.label}</div>
                </div>
              ))}
            </div>
          </div>
          <div className="glass-panel p-6 rounded-3xl bg-white/50">
            <h3 className="text-lg font-bold text-slate-800 mb-4 flex items-center gap-2"><TrendingUp className="w-5 h-5 text-blue-600" />AI Recommendations</h3>
            <div className="space-y-3">
              {(data?.recommendations ?? []).map((r, i) => (
                <div key={i} className="flex items-start gap-3 p-4 rounded-xl border bg-slate-50 border-slate-100">
                  <span className={`text-xs font-bold px-2 py-0.5 rounded border uppercase flex-shrink-0 mt-0.5 ${prioColor(r.priority)}`}>{r.priority}</span>
                  <p className="text-sm text-slate-700">{r.text}</p>
                </div>
              ))}
              {(data?.recommendations ?? []).length === 0 && (
                <p className="text-slate-400 text-sm text-center py-4">No recommendations — your vault looks great!</p>
              )}
            </div>
          </div>
        </>
      )}
    </div>
  );
}
