"use client";

import { useState, useEffect } from "react";
import { motion } from "framer-motion";
import { Heart, HeartPulse, Activity, AlertCircle, Save, Loader2, Shield, Settings } from "lucide-react";
import { ApiService } from "@/lib/api";

export default function ProofOfLifePage() {
  const [loading, setLoading] = useState(true);
  const [saving, setSaving] = useState(false);
  const [isActive, setIsActive] = useState(false);
  const [days, setDays] = useState(30);
  const [hours, setHours] = useState(0);
  const [minutes, setMinutes] = useState(0);
  const [lastCheckIn, setLastCheckIn] = useState<string | null>(null);
  const [nextDue, setNextDue] = useState<string | null>(null);

  useEffect(() => {
    loadStatus();
  }, []);

  const loadStatus = async () => {
    try {
      const userId = ApiService.getUserId();
      if (!userId) return;
      
      const res = await ApiService.request(`/heartbeat/status?user_id=${userId}`);
      setIsActive(res.dead_mans_switch_active || false);
      setDays(res.check_in_frequency_days || 30);
      setHours(res.check_in_frequency_hours || 0);
      setMinutes(res.check_in_frequency_minutes || 0);
      setLastCheckIn(res.last_check_in);
      
      if (res.last_check_in) {
        const last = new Date(res.last_check_in);
        const due = new Date(last.getTime());
        due.setDate(due.getDate() + (res.check_in_frequency_days || 30));
        due.setHours(due.getHours() + (res.check_in_frequency_hours || 0));
        due.setMinutes(due.getMinutes() + (res.check_in_frequency_minutes || 0));
        setNextDue(due.toISOString());
      }
    } catch (err) {
      console.error(err);
    } finally {
      setLoading(false);
    }
  };

  const handleCheckIn = async () => {
    setSaving(true);
    try {
      const userId = ApiService.getUserId();
      const res = await ApiService.request('/heartbeat/checkin', {
        method: 'POST',
        body: JSON.stringify({ user_id: userId })
      });
      setLastCheckIn(res.last_check_in);
      if (res.next_check_in) {
        setNextDue(res.next_check_in);
      }
    } catch (err) {
      console.error(err);
    } finally {
      setSaving(false);
    }
  };

  const handleSaveSettings = async () => {
    setSaving(true);
    try {
      const userId = ApiService.getUserId();
      await ApiService.request('/heartbeat/settings', {
        method: 'PUT',
        body: JSON.stringify({
          user_id: userId,
          active: isActive,
          days: days,
          hours: hours,
          minutes: minutes
        })
      });
      await loadStatus();
    } catch (err) {
      console.error(err);
    } finally {
      setSaving(false);
    }
  };

  if (loading) {
    return <div className="flex h-full items-center justify-center"><Loader2 className="w-8 h-8 animate-spin text-blue-600" /></div>;
  }

  return (
    <div className="space-y-6 max-w-4xl">
      <div className="mb-8">
        <h1 className="text-3xl font-bold mb-2 flex items-center gap-3 text-slate-800">
          <HeartPulse className="w-8 h-8 text-red-500" />
          Proof of Life
        </h1>
        <p className="text-slate-600">Manage your Dead Man's Switch and automated check-ins.</p>
      </div>

      <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
        {/* Status Card */}
        <motion.div 
          initial={{ opacity: 0, y: 20 }}
          animate={{ opacity: 1, y: 0 }}
          className="glass-panel p-8 rounded-3xl flex flex-col items-center justify-center text-center relative overflow-hidden bg-white/40"
        >
          <div className="absolute top-0 right-0 p-3">
            {isActive ? (
              <span className="flex items-center gap-1 text-xs font-semibold text-green-700 bg-green-100 border border-green-200 px-3 py-1 rounded-full">
                <Activity className="w-3 h-3" /> Active
              </span>
            ) : (
              <span className="flex items-center gap-1 text-xs font-semibold text-slate-600 bg-slate-100 border border-slate-200 px-3 py-1 rounded-full">
                Inactive
              </span>
            )}
          </div>

          <div className={`p-6 rounded-full mb-6 shadow-sm border ${isActive ? 'bg-red-50 border-red-100' : 'bg-slate-100 border-slate-200'}`}>
            <Heart className={`w-16 h-16 ${isActive ? 'text-red-500' : 'text-slate-400'}`} />
          </div>

          <h2 className="text-2xl font-bold mb-2 text-slate-800">
            {isActive ? "Monitoring is Active" : "Monitoring Inactive"}
          </h2>
          <p className="text-slate-600 mb-8 text-sm px-4">
            {isActive 
              ? `If you don't check in within ${days} days, ${hours} hours, and ${minutes} mins, your designated nominees will be alerted.`
              : "Enable the switch below to automatically share vault access in case of an emergency."}
          </p>

          {isActive && (
             <button
                onClick={handleCheckIn}
                disabled={saving}
                className="group relative w-32 h-32 rounded-full bg-white shadow-md flex flex-col items-center justify-center border-4 border-red-200 hover:border-red-400 transition-all"
             >
                {saving ? (
                  <Loader2 className="w-8 h-8 animate-spin text-red-500" />
                ) : (
                  <>
                    <Shield className="w-8 h-8 text-red-500 mb-2 group-hover:scale-110 transition-transform" />
                    <span className="font-bold text-red-600 text-sm">I'M SAFE</span>
                  </>
                )}
             </button>
          )}

          {isActive && lastCheckIn && (
            <div className="mt-8 grid grid-cols-2 gap-4 w-full">
              <div className="bg-white/60 border border-slate-200 p-4 rounded-xl">
                <p className="text-xs text-slate-500 uppercase tracking-wider font-semibold mb-1">Last Check-in</p>
                <p className="font-bold text-slate-800">{new Date(lastCheckIn).toLocaleString(undefined, { month: 'short', day: 'numeric', hour: '2-digit', minute: '2-digit'})}</p>
              </div>
              <div className="bg-red-50 border border-red-100 p-4 rounded-xl">
                <p className="text-xs text-red-500 uppercase tracking-wider font-semibold mb-1">Next Due</p>
                <p className="font-bold text-red-700">
                  {nextDue ? new Date(nextDue).toLocaleString(undefined, { month: 'short', day: 'numeric', hour: '2-digit', minute: '2-digit'}) : '-'}
                </p>
              </div>
            </div>
          )}
        </motion.div>

        {/* Settings Card */}
        <motion.div 
          initial={{ opacity: 0, y: 20 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ delay: 0.1 }}
          className="glass-panel p-6 rounded-3xl bg-white/40"
        >
          <div className="flex items-center gap-2 mb-6 pb-4 border-b border-white/60">
            <Settings className="w-5 h-5 text-blue-600" />
            <h3 className="text-xl font-bold text-slate-800">Configuration</h3>
          </div>

          <div className="space-y-6">
            <div className="flex items-center justify-between p-4 bg-white/60 border border-slate-200 rounded-xl">
              <div>
                <p className="font-bold text-lg text-slate-800">Dead Man's Switch</p>
                <p className="text-sm text-slate-600">Trigger handover if check-in missed</p>
              </div>
              <label className="relative inline-flex items-center cursor-pointer">
                <input type="checkbox" className="sr-only peer" checked={isActive} onChange={(e) => setIsActive(e.target.checked)} />
                <div className="w-11 h-6 bg-slate-300 peer-focus:outline-none rounded-full peer peer-checked:after:translate-x-full peer-checked:after:border-white after:content-[''] after:absolute after:top-[2px] after:left-[2px] after:bg-white after:border-gray-300 after:border after:rounded-full after:h-5 after:w-5 after:transition-all peer-checked:bg-blue-600"></div>
              </label>
            </div>

            <div className={`space-y-4 transition-opacity ${!isActive ? 'opacity-50 pointer-events-none' : ''}`}>
              <div>
                <label className="block text-sm font-bold text-slate-700 mb-2">Check-in Frequency (Days)</label>
                <select 
                  value={days} 
                  onChange={(e) => setDays(Number(e.target.value))}
                  className="w-full bg-white border border-slate-200 p-3 rounded-xl font-medium text-slate-800 focus:ring-2 focus:ring-blue-500"
                >
                  <option value={0}>0 Days</option>
                  <option value={15}>15 Days</option>
                  <option value={30}>30 Days</option>
                  <option value={60}>60 Days</option>
                  <option value={90}>90 Days</option>
                </select>
              </div>

              <div>
                <label className="block text-sm font-bold text-slate-700 mb-2">Tracking (Hours)</label>
                <select 
                  value={hours} 
                  onChange={(e) => setHours(Number(e.target.value))}
                  className="w-full bg-white border border-slate-200 p-3 rounded-xl font-medium text-slate-800 focus:ring-2 focus:ring-blue-500"
                >
                  <option value={0}>0 Hours</option>
                  <option value={2}>2 Hours</option>
                  <option value={4}>4 Hours</option>
                  <option value={8}>8 Hours</option>
                  <option value={12}>12 Hours</option>
                  <option value={24}>24 Hours</option>
                </select>
              </div>

              <div>
                <label className="block text-sm font-bold text-slate-700 mb-2">Tracking (Minutes)</label>
                <select 
                  value={minutes} 
                  onChange={(e) => setMinutes(Number(e.target.value))}
                  className="w-full bg-white border border-slate-200 p-3 rounded-xl font-medium text-slate-800 focus:ring-2 focus:ring-blue-500"
                >
                  <option value={0}>0 Mins</option>
                  <option value={1}>1 Min</option>
                  <option value={5}>5 Mins</option>
                  <option value={10}>10 Mins</option>
                  <option value={30}>30 Mins</option>
                </select>
              </div>
            </div>

            <button
              onClick={handleSaveSettings}
              disabled={saving}
              className="w-full bg-blue-600 hover:bg-blue-500 shadow-md flex justify-center items-center gap-2 py-3 px-4 rounded-xl text-sm font-bold text-white focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-blue-500 disabled:opacity-50 transition-all"
            >
              {saving ? <Loader2 className="animate-spin w-5 h-5" /> : <Save className="w-5 h-5" />}
              Save Configuration
            </button>
          </div>
        </motion.div>
      </div>
    </div>
  );
}
