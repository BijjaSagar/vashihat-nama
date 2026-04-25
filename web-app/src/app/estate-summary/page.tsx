"use client";
import { useState, useEffect } from "react";
import { BarChart3, Loader2, TrendingUp, AlertTriangle, CheckCircle2, Sparkles } from "lucide-react";
import { ApiService } from "@/lib/api";
import { motion } from "framer-motion";

interface EstateSummary { summary: string; stats: { vault_items: number; nominees: number; files: number; smart_docs: number }; strengths: string[]; risks: string[]; recommendations: string[]; }

export default function EstateSummaryPage() {
  const [data, setData] = useState<EstateSummary | null>(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    const userId = ApiService.getUserId();
    if (!userId) return;
    ApiService.request(`/api/estate-summary?user_id=${userId}`)
      .then(r => setData(r))
      .catch(() => {})
      .finally(() => setLoading(false));
  }, []);

  return (
    <div className="space-y-6 max-w-4xl">
      <div className="mb-8">
        <h1 className="text-3xl font-bold text-slate-800 flex items-center gap-3 mb-2"><BarChart3 className="w-8 h-8 text-blue-600" />AI Estate Summary</h1>
        <p className="text-slate-600">AI-generated executive summary of your complete estate and digital legacy.</p>
      </div>
      {loading ? (
        <div className="glass-panel p-12 rounded-3xl text-center bg-white/50"><Loader2 className="w-10 h-10 animate-spin text-blue-400 mx-auto" /><p className="mt-4 text-slate-500 text-sm">Generating your estate summary...</p></div>
      ) : (
        <>
          {/* Stats */}
          <div className="grid grid-cols-2 md:grid-cols-4 gap-4">
            {[
              { label: "Vault Items", value: data?.stats?.vault_items ?? 0 },
              { label: "Nominees", value: data?.stats?.nominees ?? 0 },
              { label: "Files", value: data?.stats?.files ?? 0 },
              { label: "Alerts", value: data?.stats?.smart_docs ?? 0 },
            ].map(s => (
              <div key={s.label} className="glass-panel p-4 rounded-2xl bg-white/50 text-center">
                <div className="text-2xl font-bold text-slate-800">{s.value}</div>
                <div className="text-xs text-slate-500 mt-1">{s.label}</div>
              </div>
            ))}
          </div>

          {/* AI Summary */}
          {data?.summary && (
            <div className="glass-panel p-6 rounded-3xl bg-white/50">
              <h3 className="text-lg font-bold text-slate-800 mb-3 flex items-center gap-2"><Sparkles className="w-5 h-5 text-blue-600" />Executive Summary</h3>
              <p className="text-slate-700 leading-relaxed">{data.summary}</p>
            </div>
          )}

          <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
            {/* Strengths */}
            <div className="glass-panel p-6 rounded-3xl bg-white/50">
              <h3 className="text-lg font-bold text-slate-800 mb-4 flex items-center gap-2"><CheckCircle2 className="w-5 h-5 text-green-500" />Strengths</h3>
              <ul className="space-y-2">
                {(data?.strengths ?? []).map((s, i) => (
                  <li key={i} className="flex items-start gap-2 text-sm text-slate-700">
                    <CheckCircle2 className="w-4 h-4 text-green-500 flex-shrink-0 mt-0.5" />{s}
                  </li>
                ))}
                {(data?.strengths ?? []).length === 0 && <li className="text-slate-400 text-sm">No strengths identified yet.</li>}
              </ul>
            </div>

            {/* Risks */}
            <div className="glass-panel p-6 rounded-3xl bg-white/50">
              <h3 className="text-lg font-bold text-slate-800 mb-4 flex items-center gap-2"><AlertTriangle className="w-5 h-5 text-amber-500" />Risks</h3>
              <ul className="space-y-2">
                {(data?.risks ?? []).map((r, i) => (
                  <li key={i} className="flex items-start gap-2 text-sm text-slate-700">
                    <AlertTriangle className="w-4 h-4 text-amber-500 flex-shrink-0 mt-0.5" />{r}
                  </li>
                ))}
                {(data?.risks ?? []).length === 0 && <li className="text-slate-400 text-sm">No risks identified.</li>}
              </ul>
            </div>
          </div>

          {/* Recommendations */}
          <div className="glass-panel p-6 rounded-3xl bg-white/50">
            <h3 className="text-lg font-bold text-slate-800 mb-4 flex items-center gap-2"><TrendingUp className="w-5 h-5 text-blue-600" />Recommendations</h3>
            <ol className="space-y-2 list-decimal list-inside">
              {(data?.recommendations ?? []).map((r, i) => (
                <li key={i} className="text-sm text-slate-700">{r}</li>
              ))}
              {(data?.recommendations ?? []).length === 0 && <li className="text-slate-400 text-sm list-none">No recommendations yet.</li>}
            </ol>
          </div>
        </>
      )}
    </div>
  );
}
