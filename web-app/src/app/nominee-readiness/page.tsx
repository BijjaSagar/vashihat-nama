"use client";
import { useState, useEffect } from "react";
import { ClipboardCheck, Loader2, CheckCircle2, XCircle, ArrowRight, ChevronDown, ChevronUp } from "lucide-react";
import { ApiService } from "@/lib/api";
import { motion } from "framer-motion";

interface NomineeReport { nominee_id: number; name: string; readiness_score: number; checks: { label: string; passed: boolean }[]; }
interface ReadinessData { overall_score: number; nominees: NomineeReport[]; }

export default function NomineeReadinessPage() {
  const [data, setData] = useState<ReadinessData | null>(null);
  const [loading, setLoading] = useState(true);
  const [expanded, setExpanded] = useState<number | null>(null);

  useEffect(() => {
    const userId = ApiService.getUserId();
    if (!userId) return;
    ApiService.request(`/api/nominee-readiness?user_id=${userId}`)
      .then(r => setData(r))
      .catch(() => {})
      .finally(() => setLoading(false));
  }, []);

  const circumference = 2 * Math.PI * 30;
  const scoreColor = (s: number) => s >= 80 ? "stroke-green-400" : s >= 50 ? "stroke-amber-400" : "stroke-red-400";
  const textColor = (s: number) => s >= 80 ? "text-green-600" : s >= 50 ? "text-amber-500" : "text-red-500";

  return (
    <div className="space-y-6 max-w-4xl">
      <div className="mb-8">
        <h1 className="text-3xl font-bold text-slate-800 flex items-center gap-3 mb-2"><ClipboardCheck className="w-8 h-8 text-blue-600" />Nominee Readiness</h1>
        <p className="text-slate-600">8-point readiness check for each nominee to ensure zero handoff failures.</p>
      </div>

      {loading ? (
        <div className="glass-panel p-12 rounded-3xl text-center bg-white/50"><Loader2 className="w-10 h-10 animate-spin text-blue-400 mx-auto" /></div>
      ) : (
        <>
          {/* Overall Score */}
          <div className="glass-panel p-6 rounded-3xl bg-white/50 flex items-center gap-6">
            <svg width="80" height="80" viewBox="0 0 80 80">
              <circle cx="40" cy="40" r="30" fill="none" stroke="#e2e8f0" strokeWidth="8" />
              <circle cx="40" cy="40" r="30" fill="none" className={scoreColor(data?.overall_score ?? 0)} strokeWidth="8" strokeLinecap="round"
                strokeDasharray={circumference} strokeDashoffset={circumference - (circumference * (data?.overall_score ?? 0)) / 100}
                transform="rotate(-90 40 40)" />
              <text x="40" y="45" textAnchor="middle" style={{ fontSize: 16, fill: "#1e293b", fontWeight: 700 }}>{data?.overall_score ?? 0}%</text>
            </svg>
            <div>
              <h2 className="text-xl font-bold text-slate-800">Overall Readiness</h2>
              <p className={`font-semibold ${textColor(data?.overall_score ?? 0)}`}>{(data?.overall_score ?? 0) >= 80 ? "Nominees are well prepared" : "Some nominees need attention"}</p>
              <p className="text-sm text-slate-500 mt-1">{data?.nominees?.length ?? 0} nominees evaluated</p>
            </div>
          </div>

          {/* Per-Nominee */}
          <div className="space-y-4">
            {(data?.nominees ?? []).map((n, i) => (
              <motion.div key={n.nominee_id} initial={{ opacity: 0, y: 10 }} animate={{ opacity: 1, y: 0 }} transition={{ delay: i * 0.08 }}
                className="glass-panel rounded-3xl bg-white/50 overflow-hidden">
                <button className="w-full p-5 flex items-center justify-between gap-4 text-left" onClick={() => setExpanded(expanded === n.nominee_id ? null : n.nominee_id)}>
                  <div className="flex items-center gap-4">
                    <svg width="52" height="52" viewBox="0 0 52 52">
                      <circle cx="26" cy="26" r="20" fill="none" stroke="#e2e8f0" strokeWidth="6" />
                      <circle cx="26" cy="26" r="20" fill="none" className={scoreColor(n.readiness_score)} strokeWidth="6" strokeLinecap="round"
                        strokeDasharray={2 * Math.PI * 20} strokeDashoffset={2 * Math.PI * 20 - (2 * Math.PI * 20 * n.readiness_score) / 100}
                        transform="rotate(-90 26 26)" />
                      <text x="26" y="31" textAnchor="middle" style={{ fontSize: 11, fill: "#1e293b", fontWeight: 700 }}>{n.readiness_score}%</text>
                    </svg>
                    <div>
                      <p className="font-bold text-slate-800">{n.name}</p>
                      <p className="text-xs text-slate-500">{n.checks?.filter(c => c.passed).length ?? 0}/{n.checks?.length ?? 8} checks passed</p>
                    </div>
                  </div>
                  {expanded === n.nominee_id ? <ChevronUp className="w-5 h-5 text-slate-400" /> : <ChevronDown className="w-5 h-5 text-slate-400" />}
                </button>
                {expanded === n.nominee_id && (
                  <div className="px-5 pb-5 space-y-2">
                    {(n.checks ?? []).map((c, ci) => (
                      <div key={ci} className="flex items-center justify-between p-3 rounded-xl bg-slate-50 border border-slate-100">
                        <div className="flex items-center gap-2">
                          {c.passed ? <CheckCircle2 className="w-4 h-4 text-green-500" /> : <XCircle className="w-4 h-4 text-red-400" />}
                          <span className="text-sm text-slate-700">{c.label}</span>
                        </div>
                        {!c.passed && (
                          <span className="text-xs font-bold text-blue-600 bg-blue-50 border border-blue-100 px-2 py-0.5 rounded flex items-center gap-1">Fix <ArrowRight className="w-3 h-3" /></span>
                        )}
                      </div>
                    ))}
                  </div>
                )}
              </motion.div>
            ))}
            {(data?.nominees ?? []).length === 0 && (
              <div className="glass-panel p-10 rounded-3xl text-center bg-white/50">
                <ClipboardCheck className="w-10 h-10 text-blue-300 mx-auto mb-3" />
                <p className="text-slate-500">Add nominees first to see their readiness report.</p>
              </div>
            )}
          </div>
        </>
      )}
    </div>
  );
}
