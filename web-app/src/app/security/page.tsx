"use client";
import { useState, useEffect } from "react";
import { ShieldCheck, CheckCircle2, XCircle, ArrowRight, Loader2 } from "lucide-react";
import { ApiService } from "@/lib/api";
import { useRouter } from "next/navigation";
import { motion } from "framer-motion";

interface CheckItem { label: string; passed: boolean; fix_route?: string; fix_label?: string; }
interface SecurityData { score: number; checks: CheckItem[]; }

export default function SecurityPage() {
  const [data, setData] = useState<SecurityData | null>(null);
  const [loading, setLoading] = useState(true);
  const router = useRouter();

  useEffect(() => {
    const userId = ApiService.getUserId();
    if (!userId) return;
    ApiService.request(`/api/security/score?user_id=${userId}`)
      .then(r => setData(r))
      .catch(() => setData({ score: 0, checks: [] }))
      .finally(() => setLoading(false));
  }, []);

  const scoreColor = (s: number) => s >= 80 ? "text-green-600" : s >= 50 ? "text-amber-500" : "text-red-500";
  const scoreRing = (s: number) => s >= 80 ? "stroke-green-500" : s >= 50 ? "stroke-amber-400" : "stroke-red-400";
  const circumference = 2 * Math.PI * 54;

  return (
    <div className="space-y-6 max-w-4xl">
      <div className="mb-8">
        <h1 className="text-3xl font-bold text-slate-800 flex items-center gap-3 mb-2">
          <ShieldCheck className="w-8 h-8 text-blue-600" />
          Security Health Score
        </h1>
        <p className="text-slate-600">Your overall security posture across all Eversafe modules.</p>
      </div>

      {loading ? (
        <div className="glass-panel p-12 rounded-3xl text-center bg-white/50">
          <Loader2 className="w-10 h-10 animate-spin text-blue-400 mx-auto" />
          <p className="mt-4 text-slate-500">Analyzing your security posture...</p>
        </div>
      ) : (
        <>
          {/* Score Ring */}
          <motion.div initial={{ opacity: 0, y: 20 }} animate={{ opacity: 1, y: 0 }} className="glass-panel p-8 rounded-3xl bg-white/50 text-center">
            <svg width="140" height="140" className="mx-auto mb-4" viewBox="0 0 120 120">
              <circle cx="60" cy="60" r="54" fill="none" stroke="#e2e8f0" strokeWidth="10" />
              <circle
                cx="60" cy="60" r="54" fill="none"
                className={scoreRing(data?.score ?? 0)}
                strokeWidth="10"
                strokeLinecap="round"
                strokeDasharray={circumference}
                strokeDashoffset={circumference - (circumference * (data?.score ?? 0)) / 100}
                transform="rotate(-90 60 60)"
                style={{ transition: "stroke-dashoffset 1s ease" }}
              />
              <text x="60" y="65" textAnchor="middle" className="font-bold" style={{ fontSize: 22, fill: "#1e293b" }}>
                {data?.score ?? 0}%
              </text>
            </svg>
            <h2 className={`text-2xl font-bold ${scoreColor(data?.score ?? 0)}`}>
              {(data?.score ?? 0) >= 80 ? "Excellent" : (data?.score ?? 0) >= 50 ? "Needs Improvement" : "Critical Gaps"}
            </h2>
            <p className="text-slate-500 mt-1 text-sm">Based on {data?.checks?.length ?? 0} security checks</p>
          </motion.div>

          {/* Checklist */}
          <div className="glass-panel p-6 rounded-3xl bg-white/50">
            <h3 className="text-lg font-bold text-slate-800 mb-4">Security Checklist</h3>
            <div className="space-y-3">
              {(data?.checks ?? []).map((item, i) => (
                <motion.div
                  key={i}
                  initial={{ opacity: 0, x: -10 }}
                  animate={{ opacity: 1, x: 0 }}
                  transition={{ delay: i * 0.07 }}
                  className="flex items-center justify-between p-4 rounded-xl border border-slate-100 bg-slate-50"
                >
                  <div className="flex items-center gap-3">
                    {item.passed
                      ? <CheckCircle2 className="w-5 h-5 text-green-500 flex-shrink-0" />
                      : <XCircle className="w-5 h-5 text-red-400 flex-shrink-0" />}
                    <span className={`text-sm font-medium ${item.passed ? "text-slate-700" : "text-slate-600"}`}>{item.label}</span>
                  </div>
                  {!item.passed && item.fix_route && (
                    <button
                      onClick={() => router.push(item.fix_route!)}
                      className="flex items-center gap-1 text-xs font-bold text-blue-600 bg-blue-50 border border-blue-100 px-3 py-1.5 rounded-lg hover:bg-blue-100 transition-all"
                    >
                      Fix <ArrowRight className="w-3 h-3" />
                    </button>
                  )}
                </motion.div>
              ))}
              {(data?.checks ?? []).length === 0 && (
                <p className="text-slate-400 text-sm text-center py-6">No security checks available yet.</p>
              )}
            </div>
          </div>
        </>
      )}
    </div>
  );
}
