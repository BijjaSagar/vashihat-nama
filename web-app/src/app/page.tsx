"use client";

import { useState } from "react";
import { useRouter } from "next/navigation";
import { Shield, Smartphone, KeyRound, ArrowRight, Loader2 } from "lucide-react";
import { motion } from "framer-motion";
import { ApiService } from "@/lib/api";

export default function LoginPage() {
  const router = useRouter();
  const [step, setStep] = useState<"phone" | "otp">("phone");
  const [mobile, setMobile] = useState("");
  const [otp, setOtp] = useState("");
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState("");

  const handleSendOtp = async (e: React.FormEvent) => {
    e.preventDefault();
    setError("");
    if (mobile.length < 10) {
      setError("Please enter a valid mobile number.");
      return;
    }

    setLoading(true);
    try {
      // Need to adjust the send_otp endpoint structure based on backend
      const res = await ApiService.request('/send_otp', {
        method: 'POST',
        body: JSON.stringify({ mobile, purpose: "login" }),
      });
      setStep("otp");
    } catch (err: any) {
      setError(err.message || "Failed to send OTP. Please try again.");
    } finally {
      setLoading(false);
    }
  };

  const handleVerifyOtp = async (e: React.FormEvent) => {
    e.preventDefault();
    setError("");
    if (otp.length < 4) {
      setError("Please enter a valid OTP.");
      return;
    }

    setLoading(true);
    try {
      const res = await ApiService.request('/verify_otp', {
        method: 'POST',
        body: JSON.stringify({ mobile, otp, purpose: "login" }),
      });
      
      if (res.token) {
        localStorage.setItem('authToken', res.token);
        localStorage.setItem('userId', res.user?.id || '');
        localStorage.setItem('userMobile', mobile);
        router.push("/dashboard");
      } else {
        throw new Error("Invalid response from server.");
      }
    } catch (err: any) {
      // Check if user is not registered
      if (err.message.includes('not registered') || err.message.includes('User not found')) {
         // In a real flow, we would push to a register page. For simplicity, we just show error here, 
         // but let's assume we can push to /register.
         router.push(`/register?mobile=${mobile}&otp=${otp}`);
      } else {
         setError(err.message || "Failed to verify OTP. Please try again.");
      }
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="min-h-screen flex items-center justify-center p-4">
      <motion.div 
        initial={{ opacity: 0, y: 20 }}
        animate={{ opacity: 1, y: 0 }}
        transition={{ duration: 0.5 }}
        className="glass-panel w-full max-w-md rounded-3xl p-8 overflow-hidden relative"
      >
        <div className="absolute top-0 left-0 w-full h-1 bg-gradient-to-r from-blue-500 to-purple-500"></div>
        
        <div className="flex justify-center mb-8">
          <div className="bg-blue-500/20 p-4 rounded-full">
            <Shield className="w-12 h-12 text-blue-400" />
          </div>
        </div>
        
        <h1 className="text-3xl font-bold text-center mb-2">Eversafe</h1>
        <p className="text-slate-400 text-center mb-8">Secure Zero-Knowledge Vault</p>

        {error && (
          <div className="bg-red-500/10 border border-red-500/50 text-red-400 px-4 py-3 rounded-xl mb-6 text-sm text-center">
            {error}
          </div>
        )}

        {step === "phone" ? (
          <motion.form 
            initial={{ opacity: 0, x: -20 }}
            animate={{ opacity: 1, x: 0 }}
            onSubmit={handleSendOtp}
            className="space-y-6"
          >
            <div>
              <label className="block text-sm font-medium text-slate-300 mb-2">Mobile Number</label>
              <div className="relative">
                <div className="absolute inset-y-0 left-0 pl-3 flex items-center pointer-events-none">
                  <Smartphone className="h-5 w-5 text-slate-400" />
                </div>
                <input
                  type="tel"
                  value={mobile}
                  onChange={(e) => setMobile(e.target.value.replace(/\\D/g, ''))}
                  className="glass-input block w-full pl-10 pr-3 py-3 rounded-xl focus:ring-2 focus:ring-blue-500 sm:text-sm"
                  placeholder="Enter your 10-digit number"
                  maxLength={10}
                  required
                />
              </div>
            </div>
            
            <button
              type="submit"
              disabled={loading || mobile.length < 10}
              className="glass-button w-full flex justify-center py-3 px-4 rounded-xl text-sm font-semibold text-white focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-blue-500 disabled:opacity-50 disabled:cursor-not-allowed"
            >
              {loading ? <Loader2 className="animate-spin w-5 h-5" /> : "Continue"}
            </button>
          </motion.form>
        ) : (
          <motion.form 
            initial={{ opacity: 0, x: 20 }}
            animate={{ opacity: 1, x: 0 }}
            onSubmit={handleVerifyOtp}
            className="space-y-6"
          >
            <div>
              <label className="block text-sm font-medium text-slate-300 mb-2">Enter OTP</label>
              <div className="relative">
                <div className="absolute inset-y-0 left-0 pl-3 flex items-center pointer-events-none">
                  <KeyRound className="h-5 w-5 text-slate-400" />
                </div>
                <input
                  type="text"
                  value={otp}
                  onChange={(e) => setOtp(e.target.value.replace(/\\D/g, ''))}
                  className="glass-input block w-full pl-10 pr-3 py-3 rounded-xl focus:ring-2 focus:ring-blue-500 sm:text-sm tracking-[0.5em] font-mono text-center"
                  placeholder="••••"
                  maxLength={6}
                  required
                />
              </div>
              <p className="mt-2 text-xs text-slate-400 text-center">
                OTP sent to +91 {mobile}. <button type="button" onClick={() => setStep("phone")} className="text-blue-400 hover:underline">Change</button>
              </p>
            </div>
            
            <button
              type="submit"
              disabled={loading || otp.length < 4}
              className="glass-button w-full flex justify-center py-3 px-4 rounded-xl text-sm font-semibold text-white focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-blue-500 disabled:opacity-50 disabled:cursor-not-allowed"
            >
              {loading ? <Loader2 className="animate-spin w-5 h-5" /> : "Verify & Login"}
            </button>
          </motion.form>
        )}
      </motion.div>
    </div>
  );
}
