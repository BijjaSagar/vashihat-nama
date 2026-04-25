"use client";
import { useState, useEffect } from "react";
import { CreditCard, Loader2, Sparkles, Save } from "lucide-react";
import { ApiService } from "@/lib/api";
import { motion } from "framer-motion";

interface EmergencyCard { name: string; blood_group: string; allergies: string; conditions: string; medications: string; doctor_name: string; doctor_phone: string; emergency_contact1_name: string; emergency_contact1_phone: string; emergency_contact2_name: string; emergency_contact2_phone: string; insurance_policy: string; organ_donor: boolean; }

const defaultCard: EmergencyCard = { name: "", blood_group: "", allergies: "", conditions: "", medications: "", doctor_name: "", doctor_phone: "", emergency_contact1_name: "", emergency_contact1_phone: "", emergency_contact2_name: "", emergency_contact2_phone: "", insurance_policy: "", organ_donor: false };

export default function EmergencyCardPage() {
  const [card, setCard] = useState<EmergencyCard>(defaultCard);
  const [loading, setLoading] = useState(true);
  const [saving, setSaving] = useState(false);
  const [suggesting, setSuggesting] = useState(false);
  const [saved, setSaved] = useState(false);

  useEffect(() => {
    const userId = ApiService.getUserId();
    if (!userId) return;
    ApiService.request(`/api/emergency-card?user_id=${userId}`)
      .then(r => { if (r && r.name) setCard({ ...defaultCard, ...r }); })
      .catch(() => {})
      .finally(() => setLoading(false));
  }, []);

  const save = async () => {
    setSaving(true);
    try {
      await ApiService.request("/api/emergency-card", { method: "PUT", body: JSON.stringify({ user_id: ApiService.getUserId(), ...card }) });
      setSaved(true); setTimeout(() => setSaved(false), 2000);
    } catch { } finally { setSaving(false); }
  };

  const suggest = async () => {
    setSuggesting(true);
    try {
      const r = await ApiService.request("/api/emergency-card/suggest", { method: "POST", body: JSON.stringify({ user_id: ApiService.getUserId(), current_data: card }) });
      if (r.suggestions) setCard(prev => ({ ...prev, ...r.suggestions }));
    } catch { } finally { setSuggesting(false); }
  };

  const f = (field: keyof EmergencyCard, val: string | boolean) => setCard(prev => ({ ...prev, [field]: val }));

  if (loading) return <div className="glass-panel p-12 rounded-3xl text-center bg-white/50"><Loader2 className="w-10 h-10 animate-spin text-blue-400 mx-auto" /></div>;

  return (
    <div className="space-y-6 max-w-4xl">
      <div className="flex justify-between items-end mb-8">
        <div>
          <h1 className="text-3xl font-bold text-slate-800 flex items-center gap-3 mb-2"><CreditCard className="w-8 h-8 text-blue-600" />Emergency Card</h1>
          <p className="text-slate-600">Critical medical info first responders can access in an emergency.</p>
        </div>
        <div className="flex gap-2">
          <button onClick={suggest} disabled={suggesting} className="flex items-center gap-2 px-4 py-2.5 rounded-xl border border-blue-200 text-blue-600 bg-blue-50 hover:bg-blue-100 font-semibold text-sm transition-all">
            {suggesting ? <Loader2 className="w-4 h-4 animate-spin" /> : <Sparkles className="w-4 h-4" />} AI Fill
          </button>
          <button onClick={save} disabled={saving} className="flex items-center gap-2 px-5 py-2.5 rounded-xl bg-blue-600 hover:bg-blue-500 text-white font-semibold shadow-md transition-all">
            {saving ? <Loader2 className="w-4 h-4 animate-spin" /> : <Save className="w-4 h-4" />} {saved ? "Saved!" : "Save"}
          </button>
        </div>
      </div>

      {/* Live Preview */}
      <motion.div initial={{ opacity: 0, y: 10 }} animate={{ opacity: 1, y: 0 }}
        className="bg-gradient-to-br from-red-500 to-red-700 text-white p-6 rounded-3xl shadow-xl relative overflow-hidden">
        <div className="absolute top-0 right-0 w-40 h-40 bg-white/10 rounded-full -translate-y-20 translate-x-20" />
        <div className="flex items-center gap-3 mb-4">
          <div className="text-3xl">🆘</div>
          <div>
            <h2 className="text-xl font-bold">{card.name || "Your Name"}</h2>
            <p className="text-red-100 text-sm">Emergency Medical Card</p>
          </div>
          <div className="ml-auto text-right">
            <div className="text-2xl font-black">{card.blood_group || "—"}</div>
            <div className="text-red-200 text-xs">Blood Group</div>
          </div>
        </div>
        <div className="grid grid-cols-2 gap-3 text-sm">
          <div className="bg-white/10 rounded-xl p-3">
            <div className="text-red-200 text-xs mb-1">Allergies</div>
            <div className="font-medium">{card.allergies || "None listed"}</div>
          </div>
          <div className="bg-white/10 rounded-xl p-3">
            <div className="text-red-200 text-xs mb-1">Conditions</div>
            <div className="font-medium">{card.conditions || "None listed"}</div>
          </div>
          <div className="bg-white/10 rounded-xl p-3">
            <div className="text-red-200 text-xs mb-1">Doctor</div>
            <div className="font-medium">{card.doctor_name || "—"} {card.doctor_phone ? `· ${card.doctor_phone}` : ""}</div>
          </div>
          <div className="bg-white/10 rounded-xl p-3">
            <div className="text-red-200 text-xs mb-1">Emergency Contact</div>
            <div className="font-medium">{card.emergency_contact1_name || "—"} {card.emergency_contact1_phone ? `· ${card.emergency_contact1_phone}` : ""}</div>
          </div>
        </div>
        {card.organ_donor && <div className="mt-3 text-center text-xs font-bold bg-white/20 rounded-xl py-2">🫀 Registered Organ Donor</div>}
      </motion.div>

      {/* Form */}
      <div className="glass-panel p-6 rounded-3xl bg-white/50 space-y-4">
        <h3 className="text-lg font-bold text-slate-800">Personal Information</h3>
        <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
          {([["name","Full Name"],["blood_group","Blood Group"],["allergies","Allergies"],["conditions","Medical Conditions"],["medications","Current Medications"],["insurance_policy","Insurance Policy No."]]) .map(([k, label]) => (
            <div key={k}>
              <label className="block text-sm font-bold text-slate-700 mb-1">{label}</label>
              <input value={card[k as keyof EmergencyCard] as string} onChange={e => f(k as keyof EmergencyCard, e.target.value)} className="w-full bg-slate-50 border border-slate-200 text-slate-800 p-3 rounded-xl focus:ring-2 focus:ring-blue-400 outline-none text-sm" placeholder={label} />
            </div>
          ))}
        </div>

        <h3 className="text-lg font-bold text-slate-800 pt-2">Emergency Contacts</h3>
        <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
          {([["doctor_name","Doctor Name"],["doctor_phone","Doctor Phone"],["emergency_contact1_name","Contact 1 Name"],["emergency_contact1_phone","Contact 1 Phone"],["emergency_contact2_name","Contact 2 Name"],["emergency_contact2_phone","Contact 2 Phone"]]).map(([k, label]) => (
            <div key={k}>
              <label className="block text-sm font-bold text-slate-700 mb-1">{label}</label>
              <input value={card[k as keyof EmergencyCard] as string} onChange={e => f(k as keyof EmergencyCard, e.target.value)} className="w-full bg-slate-50 border border-slate-200 text-slate-800 p-3 rounded-xl focus:ring-2 focus:ring-blue-400 outline-none text-sm" placeholder={label} />
            </div>
          ))}
        </div>

        <div className="flex items-center gap-3 p-4 bg-blue-50 border border-blue-100 rounded-xl">
          <input type="checkbox" id="donor" checked={card.organ_donor} onChange={e => f("organ_donor", e.target.checked)} className="w-5 h-5 rounded border-slate-300 text-blue-600" />
          <label htmlFor="donor" className="text-sm font-semibold text-slate-700">Registered Organ Donor 🫀</label>
        </div>
      </div>
    </div>
  );
}
