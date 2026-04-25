"use client";
import { useState, useEffect } from "react";
import { AlertTriangle, Loader2, ShieldCheck, ShieldAlert, Filter } from "lucide-react";
import { ApiService } from "@/lib/api";
import { motion } from "framer-motion";

interface ActivityLog { id: number; action: string; description: string; is_suspicious: boolean; created_at: string; ip_address?: string; }

export default function ActivityLogPage() {
  const [logs, setLogs] = useState<ActivityLog[]>([]);
  const [loading, setLoading] = useState(true);
  const [showSuspicious, setShowSuspicious] = useState(false);

  useEffect(() => {
    const userId = ApiService.getUserId();
    if (!userId) return;
    ApiService.request(`/api/activity-log?user_id=${userId}`)
      .then(r => setLogs(r.logs || r || []))
      .catch(() => setLogs([]))
      .finally(() => setLoading(false));
  }, []);

  const filtered = showSuspicious ? logs.filter(l => l.is_suspicious) : logs;
  const suspiciousCount = logs.filter(l => l.is_suspicious).length;
  const hasSuspicious = suspiciousCount > 0;

  const actionIcon = (action: string) => {
    if (action.includes("login")) return "🔑";
    if (action.includes("delete")) return "🗑️";
    if (action.includes("create")) return "✨";
    if (action.includes("view")) return "👁️";
    return "📋";
  };

  return (
    <div className="space-y-6 max-w-4xl">
      <div className="mb-8">
        <h1 className="text-3xl font-bold text-slate-800 flex items-center gap-3 mb-2"><AlertTriangle className="w-8 h-8 text-blue-600" />Fraud Detection</h1>
        <p className="text-slate-600">AI monitors your account activity and flags suspicious behavior in real-time.</p>
      </div>

      {/* Status Card */}
      <div className={`glass-panel p-6 rounded-3xl ${hasSuspicious ? "bg-red-50/60 border border-red-100" : "bg-green-50/60 border border-green-100"}`}>
        <div className="flex items-center gap-4">
          {hasSuspicious
            ? <ShieldAlert className="w-10 h-10 text-red-500" />
            : <ShieldCheck className="w-10 h-10 text-green-500" />}
          <div>
            <h2 className={`text-xl font-bold ${hasSuspicious ? "text-red-700" : "text-green-700"}`}>
              {hasSuspicious ? `${suspiciousCount} Suspicious Event${suspiciousCount > 1 ? "s" : ""} Detected` : "All Clear"}
            </h2>
            <p className={`text-sm ${hasSuspicious ? "text-red-600" : "text-green-600"}`}>
              {hasSuspicious ? "Review flagged events below and take action if needed." : "No suspicious activity detected in your account."}
            </p>
          </div>
        </div>
      </div>

      {/* Filter */}
      <div className="flex items-center gap-3">
        <button
          onClick={() => setShowSuspicious(!showSuspicious)}
          className={`flex items-center gap-2 px-4 py-2 rounded-xl text-sm font-semibold border transition-all ${showSuspicious ? "bg-red-600 text-white border-red-600" : "bg-white/60 text-slate-600 border-slate-200 hover:border-slate-300"}`}
        >
          <Filter className="w-4 h-4" /> {showSuspicious ? "Show All" : "Suspicious Only"}
        </button>
        <span className="text-sm text-slate-500">{filtered.length} event{filtered.length !== 1 ? "s" : ""}</span>
      </div>

      {/* Timeline */}
      {loading ? (
        <div className="glass-panel p-10 rounded-3xl text-center bg-white/50"><Loader2 className="w-8 h-8 animate-spin text-blue-400 mx-auto" /></div>
      ) : filtered.length === 0 ? (
        <div className="glass-panel p-10 rounded-3xl text-center bg-white/50">
          <ShieldCheck className="w-10 h-10 text-green-400 mx-auto mb-3" />
          <p className="text-slate-500">{showSuspicious ? "No suspicious events found." : "No activity logged yet."}</p>
        </div>
      ) : (
        <div className="space-y-3">
          {filtered.map((log, i) => (
            <motion.div key={log.id} initial={{ opacity: 0, x: -10 }} animate={{ opacity: 1, x: 0 }} transition={{ delay: i * 0.04 }}
              className={`glass-panel p-4 rounded-2xl flex items-start gap-4 ${log.is_suspicious ? "bg-red-50/60 border border-red-100" : "bg-white/50"}`}>
              <span className="text-xl flex-shrink-0 mt-0.5">{actionIcon(log.action)}</span>
              <div className="flex-1 min-w-0">
                <div className="flex items-center gap-2 flex-wrap">
                  <p className="font-semibold text-slate-800 text-sm">{log.action}</p>
                  {log.is_suspicious && <span className="text-xs font-bold bg-red-100 text-red-600 px-2 py-0.5 rounded-full border border-red-200">⚠️ Suspicious</span>}
                </div>
                <p className="text-xs text-slate-500 mt-0.5">{log.description}</p>
                <p className="text-xs text-slate-400 mt-1">{new Date(log.created_at).toLocaleString()} {log.ip_address ? `· ${log.ip_address}` : ""}</p>
              </div>
            </motion.div>
          ))}
        </div>
      )}
    </div>
  );
}
