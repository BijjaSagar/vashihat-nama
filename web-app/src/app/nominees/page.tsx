"use client";

import { useState, useEffect } from "react";
import { motion } from "framer-motion";
import { Users, Plus, ShieldAlert, Loader2, Edit2, Trash2, X } from "lucide-react";
import { ApiService } from "@/lib/api";

export default function NomineesPage() {
  const [nominees, setNominees] = useState<any[]>([]);
  const [loading, setLoading] = useState(true);
  const [showAddModal, setShowAddModal] = useState(false);
  const [saving, setSaving] = useState(false);

  // Form State
  const [name, setName] = useState('');
  const [relationship, setRelationship] = useState('');
  const [email, setEmail] = useState('');
  const [primaryMobile, setPrimaryMobile] = useState('');
  const [delayDays, setDelayDays] = useState(0);
  const [isEmergencyContact, setIsEmergencyContact] = useState(false);

  useEffect(() => {
    loadNominees();
  }, []);

  const loadNominees = async () => {
    try {
      const userId = ApiService.getUserId();
      if (!userId) return;
      const res = await ApiService.request(`/nominees?user_id=${userId}`);
      setNominees(res);
    } catch (err) {
      console.error(err);
    } finally {
      setLoading(false);
    }
  };

  const deleteNominee = async (id: number) => {
    if (!confirm("Are you sure you want to delete this nominee?")) return;
    try {
      await ApiService.request(`/nominees/${id}`, { method: 'DELETE' });
      await loadNominees();
    } catch (err) {
      console.error(err);
      alert("Failed to delete nominee.");
    }
  };

  const handleAddNominee = async (e: React.FormEvent) => {
    e.preventDefault();
    setSaving(true);
    try {
      const userId = ApiService.getUserId();
      await ApiService.request('/nominees', {
        method: 'POST',
        body: JSON.stringify({
          user_id: userId,
          name,
          relationship,
          email,
          primary_mobile: primaryMobile,
          handover_waiting_days: delayDays,
          is_proof_of_life_contact: isEmergencyContact,
          delivery_mode: 'digital',
          require_otp_for_access: false
        })
      });
      setShowAddModal(false);
      // reset form
      setName(''); setRelationship(''); setEmail(''); setPrimaryMobile(''); setDelayDays(0); setIsEmergencyContact(false);
      await loadNominees();
    } catch (err) {
      console.error(err);
      alert("Failed to add nominee");
    } finally {
      setSaving(false);
    }
  };

  if (loading) {
    return <div className="flex h-full items-center justify-center"><Loader2 className="w-8 h-8 animate-spin text-blue-500" /></div>;
  }

  return (
    <div className="space-y-6 max-w-5xl">
      <div className="flex justify-between items-end mb-8">
        <div>
          <h1 className="text-3xl font-bold mb-2 flex items-center gap-3 text-slate-800">
            <Users className="w-8 h-8 text-blue-600" />
            Trusted Nominees
          </h1>
          <p className="text-slate-600">People who will receive your vault if the Dead Man's Switch triggers.</p>
        </div>
        <button onClick={() => setShowAddModal(true)} className="bg-blue-600 hover:bg-blue-500 flex items-center gap-2 px-5 py-2.5 rounded-xl text-white font-semibold shadow-md transition-all">
          <Plus className="w-4 h-4" />
          Add Nominee
        </button>
      </div>

      {nominees.length === 0 ? (
        <div className="glass-panel p-12 rounded-3xl text-center flex flex-col items-center bg-white/40">
          <div className="w-20 h-20 bg-blue-50 border border-blue-100 rounded-full flex items-center justify-center mb-4">
            <Users className="w-10 h-10 text-blue-400" />
          </div>
          <h3 className="text-xl font-bold mb-2 text-slate-800">No Nominees Yet</h3>
          <p className="text-slate-500 mb-6 max-w-md mx-auto">Add trusted family members or lawyers to ensure your vault is passed on securely.</p>
          <button onClick={() => setShowAddModal(true)} className="bg-blue-600 hover:bg-blue-500 px-6 py-3 rounded-xl text-white font-semibold shadow-md transition-all">Add Your First Nominee</button>
        </div>
      ) : (
        <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
          {nominees.map((nominee, idx) => (
            <motion.div 
              key={nominee.id}
              initial={{ opacity: 0, y: 20 }}
              animate={{ opacity: 1, y: 0 }}
              transition={{ delay: idx * 0.1 }}
              className="glass-panel p-6 rounded-3xl relative overflow-hidden bg-white/50 border border-white/60"
            >
              <div className="flex justify-between items-start mb-4">
                <div className="flex items-center gap-4">
                  <div className="w-12 h-12 bg-blue-100 text-blue-700 border border-blue-200 rounded-full flex items-center justify-center font-bold text-xl uppercase shadow-sm">
                    {nominee.name.charAt(0)}
                  </div>
                  <div>
                    <h3 className="text-lg font-bold text-slate-800">{nominee.name}</h3>
                    <p className="text-sm text-slate-500">{nominee.relation}</p>
                  </div>
                </div>
                <div className="flex gap-2">
                  <button className="p-2 text-slate-500 hover:text-slate-700 transition-colors bg-slate-100 hover:bg-slate-200 rounded-lg">
                    <Edit2 className="w-4 h-4" />
                  </button>
                  <button onClick={() => deleteNominee(nominee.id)} className="p-2 text-red-500 hover:text-red-600 transition-colors bg-red-50 hover:bg-red-100 rounded-lg border border-red-100">
                    <Trash2 className="w-4 h-4" />
                  </button>
                </div>
              </div>

              <div className="space-y-2 mt-4 text-sm">
                <div className="flex justify-between p-2.5 bg-slate-50 border border-slate-100 rounded-lg">
                  <span className="text-slate-500 font-medium">Contact</span>
                  <span className="text-slate-700 font-semibold">{nominee.email || nominee.primary_mobile || 'Not provided'}</span>
                </div>
                <div className="flex justify-between p-2.5 bg-slate-50 border border-slate-100 rounded-lg">
                  <span className="text-slate-500 font-medium">Access Delay</span>
                  <span className="text-slate-700 font-semibold">{nominee.handover_waiting_days} Days</span>
                </div>
                <div className="flex justify-between p-2.5 bg-slate-50 border border-slate-100 rounded-lg">
                  <span className="text-slate-500 font-medium">Access Granted</span>
                  <span className={nominee.access_granted ? "text-green-600 font-bold" : "text-slate-600"}>{nominee.access_granted ? "Yes ✓" : "No"}</span>
                </div>
              </div>

              {nominee.is_proof_of_life_contact && (
                <div className="mt-4 flex items-center gap-2 text-xs font-semibold text-red-600 bg-red-50 p-3 rounded-xl border border-red-100">
                  <ShieldAlert className="w-4 h-4" />
                  Proof of Life Emergency Contact
                </div>
              )}
            </motion.div>
          ))}
        </div>
      )}

      {showAddModal && (
        <div className="fixed inset-0 bg-slate-900/40 backdrop-blur-sm z-50 flex items-center justify-center p-4">
          <motion.div 
            initial={{ opacity: 0, scale: 0.95 }}
            animate={{ opacity: 1, scale: 1 }}
            className="bg-white max-w-md w-full rounded-3xl p-6 relative shadow-2xl"
          >
            <button 
              onClick={() => setShowAddModal(false)}
              className="absolute top-4 right-4 p-2 text-slate-500 hover:text-slate-700 hover:bg-slate-100 rounded-full transition-colors"
            >
              <X className="w-5 h-5" />
            </button>
            <h2 className="text-2xl font-bold mb-6 text-slate-800">Add Trusted Nominee</h2>
            <form onSubmit={handleAddNominee} className="space-y-4">
              <div>
                <label className="block text-sm font-bold text-slate-700 mb-1">Full Name</label>
                <input required value={name} onChange={e => setName(e.target.value)} type="text" className="w-full bg-slate-50 border border-slate-200 text-slate-800 p-3 rounded-xl focus:ring-2 focus:ring-blue-400 focus:border-blue-400 outline-none" placeholder="e.g. John Doe" />
              </div>
              <div>
                <label className="block text-sm font-bold text-slate-700 mb-1">Relationship</label>
                <input required value={relationship} onChange={e => setRelationship(e.target.value)} type="text" className="w-full bg-slate-50 border border-slate-200 text-slate-800 p-3 rounded-xl focus:ring-2 focus:ring-blue-400 focus:border-blue-400 outline-none" placeholder="e.g. Spouse" />
              </div>
              <div className="grid grid-cols-2 gap-4">
                <div>
                  <label className="block text-sm font-bold text-slate-700 mb-1">Mobile Number</label>
                  <input required value={primaryMobile} onChange={e => setPrimaryMobile(e.target.value)} type="tel" className="w-full bg-slate-50 border border-slate-200 text-slate-800 p-3 rounded-xl focus:ring-2 focus:ring-blue-400 focus:border-blue-400 outline-none" placeholder="10 digits" />
                </div>
                <div>
                  <label className="block text-sm font-bold text-slate-700 mb-1">Email (Optional)</label>
                  <input value={email} onChange={e => setEmail(e.target.value)} type="email" className="w-full bg-slate-50 border border-slate-200 text-slate-800 p-3 rounded-xl focus:ring-2 focus:ring-blue-400 focus:border-blue-400 outline-none" placeholder="Email" />
                </div>
              </div>
              <div>
                <label className="block text-sm font-bold text-slate-700 mb-1">Access Delay (Days)</label>
                <input required value={delayDays} onChange={e => setDelayDays(Number(e.target.value))} type="number" min="0" className="w-full bg-slate-50 border border-slate-200 text-slate-800 p-3 rounded-xl focus:ring-2 focus:ring-blue-400 focus:border-blue-400 outline-none" />
                <p className="text-xs text-slate-500 mt-1">Wait this many days after your death is confirmed before granting them access.</p>
              </div>
              <div className="flex items-center gap-3 p-4 bg-blue-50 border border-blue-100 rounded-xl mt-4">
                <input 
                  type="checkbox" 
                  id="emergency" 
                  checked={isEmergencyContact}
                  onChange={e => setIsEmergencyContact(e.target.checked)}
                  className="w-5 h-5 rounded border-slate-300 text-blue-600"
                />
                <label htmlFor="emergency" className="text-sm text-slate-700">
                  Make this person a <strong className="text-slate-800">Proof of Life Emergency Contact</strong>
                </label>
              </div>
              
              <button disabled={saving} type="submit" className="w-full bg-blue-600 hover:bg-blue-500 mt-6 p-4 rounded-xl font-bold text-white flex items-center justify-center shadow-md transition-all disabled:opacity-60">
                {saving ? <Loader2 className="w-5 h-5 animate-spin" /> : "Save Nominee"}
              </button>
            </form>
          </motion.div>
        </div>
      )}
    </div>
  );
}
