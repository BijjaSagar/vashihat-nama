"use client";

import { useState } from "react";
import { motion } from "framer-motion";
import { FileSignature, Bot, Heart, Gavel, Loader2, AlertTriangle, CheckCircle } from "lucide-react";
import { ApiService } from "@/lib/api";

export default function AIWillDrafterPage() {
  const [prompt, setPrompt] = useState("");
  const [generatedWill, setGeneratedWill] = useState("");
  const [loading, setLoading] = useState(false);
  const [checkingTone, setCheckingTone] = useState(false);
  const [checkingConflicts, setCheckingConflicts] = useState(false);
  const [toneAnalysis, setToneAnalysis] = useState<any>(null);
  const [conflictAnalysis, setConflictAnalysis] = useState<any>(null);
  const [modalContent, setModalContent] = useState<any>(null);

  const handleGenerate = async () => {
    if (!prompt.trim()) return;
    setLoading(true);
    try {
      const fullPrompt = `Generate a formal and legally-structured Last Will and Testament based on the following wishes: ${prompt}. Ensure it includes standard legal clauses for revocation of prior wills, appointment of executors, and clear distribution of assets.`;
      const res = await ApiService.request('/ai/chat', {
        method: 'POST',
        body: JSON.stringify({ message: fullPrompt, history: [] })
      });
      setGeneratedWill(res.reply || "Failed to generate will.");
    } catch (err) {
      console.error(err);
      alert("Failed to generate will.");
    } finally {
      setLoading(false);
    }
  };

  const handleToneCheck = async () => {
    if (!prompt.trim()) return alert("Please enter your personal wishes first.");
    setCheckingTone(true);
    try {
      const res = await ApiService.request('/ai/analyze-tone', {
        method: 'POST',
        body: JSON.stringify({ message: prompt })
      });
      
      const analysis = res.analysis || {};
      setModalContent({
        type: 'tone',
        title: 'Emotional Tone Check',
        tone: analysis.tone || 'Neutral',
        isHarsh: analysis.is_harsh || false,
        suggestion: analysis.suggestion
      });
    } catch (err) {
      console.error(err);
      alert("Tone analysis failed.");
    } finally {
      setCheckingTone(false);
    }
  };

  const handleConflictCheck = async () => {
    if (!generatedWill.trim()) return alert("Please generate a will first.");
    setCheckingConflicts(true);
    try {
      const res = await ApiService.request('/ai/conflict-check', {
        method: 'POST',
        body: JSON.stringify({ will_text: generatedWill })
      });
      
      const check = res.conflict_check || {};
      setModalContent({
        type: 'conflict',
        title: 'Legal Conflict Check',
        hasConflict: check.has_conflict || false,
        issues: check.issues || []
      });
    } catch (err) {
      console.error(err);
      alert("Conflict check failed.");
    } finally {
      setCheckingConflicts(false);
    }
  };

  return (
    <div className="space-y-6 max-w-6xl mx-auto">
      <div className="mb-8">
        <h1 className="text-3xl font-bold mb-2 flex items-center gap-3 text-slate-800">
          <FileSignature className="w-8 h-8 text-blue-600" />
          AI Will Drafter
        </h1>
        <p className="text-slate-600">Transform your plain-English wishes into a structured, legally-sound document.</p>
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
        <div className="space-y-6">
          <motion.div 
            initial={{ opacity: 0, y: 20 }}
            animate={{ opacity: 1, y: 0 }}
            className="glass-panel p-6 rounded-3xl bg-white/40"
          >
            <h2 className="text-xl font-bold mb-4 text-slate-800">1. Describe Your Wishes</h2>
            <textarea
              className="w-full glass-input p-4 rounded-2xl h-48 resize-none mb-4 focus:ring-2 focus:ring-blue-500 bg-white/60 border-slate-200 text-slate-800"
              placeholder="E.g., I want to leave my house to my wife and my savings to my two children equally..."
              value={prompt}
              onChange={(e) => setPrompt(e.target.value)}
            />
            
            <button
              onClick={handleGenerate}
              disabled={loading}
              className="w-full bg-blue-600 hover:bg-blue-500 text-white font-bold py-3 px-4 rounded-xl transition-all shadow-md flex items-center justify-center gap-2 disabled:opacity-50"
            >
              {loading ? <Loader2 className="w-5 h-5 animate-spin" /> : <Bot className="w-5 h-5" />}
              Generate Draft
            </button>
            
            <div className="grid grid-cols-2 gap-4 mt-4">
              <button
                onClick={handleToneCheck}
                disabled={checkingTone || !prompt}
                className="flex items-center justify-center gap-2 p-3 rounded-xl border border-purple-500/30 text-purple-600 font-medium hover:bg-purple-50 transition-colors disabled:opacity-50 bg-white/60"
              >
                {checkingTone ? <Loader2 className="w-4 h-4 animate-spin" /> : <Heart className="w-4 h-4" />}
                Tone Check
              </button>
              <button
                onClick={handleConflictCheck}
                disabled={checkingConflicts || !generatedWill}
                className="flex items-center justify-center gap-2 p-3 rounded-xl border border-orange-500/30 text-orange-600 font-medium hover:bg-orange-50 transition-colors disabled:opacity-50 bg-white/60"
              >
                {checkingConflicts ? <Loader2 className="w-4 h-4 animate-spin" /> : <AlertTriangle className="w-4 h-4" />}
                Conflict Check
              </button>
            </div>
          </motion.div>
        </div>

        {/* Right Column: Output */}
        <div className="glass-panel p-6 rounded-3xl bg-white/40 min-h-[400px] flex flex-col border border-white/50">
          <h3 className="font-bold mb-4 text-slate-800">2. Generated Legal Draft</h3>
          {generatedWill ? (
            <div className="flex-1 bg-white border border-slate-200 p-4 rounded-2xl overflow-y-auto whitespace-pre-wrap text-slate-800 font-mono text-sm leading-relaxed">
              {generatedWill}
            </div>
          ) : (
            <div className="flex-1 flex flex-col items-center justify-center text-slate-500 border border-dashed border-slate-300 bg-white/50 rounded-2xl p-8 text-center">
              <FileSignature className="w-12 h-12 mb-4 opacity-30 text-slate-400" />
              <p className="font-medium">Your generated Last Will and Testament will appear here.</p>
            </div>
          )}
        </div>
      </div>

      {/* Modal */}
      {modalContent && (
        <div className="fixed inset-0 bg-slate-900/40 backdrop-blur-sm z-50 flex items-center justify-center p-4">
          <motion.div 
            initial={{ opacity: 0, scale: 0.95 }}
            animate={{ opacity: 1, scale: 1 }}
            className="glass-panel max-w-md w-full rounded-3xl p-6 relative bg-white"
          >
            <h2 className="text-xl font-bold mb-4 flex items-center gap-2 text-slate-800">
              {modalContent.type === 'tone' ? <Heart className="text-purple-600" /> : <Gavel className="text-orange-500" />}
              {modalContent.title}
            </h2>

            {modalContent.type === 'tone' && (
              <div className="space-y-4">
                <p className="text-slate-700"><strong className="text-slate-800">Detected Tone:</strong> {modalContent.tone}</p>
                {modalContent.isHarsh ? (
                  <>
                    <div className="p-3 bg-orange-50 border border-orange-100 text-orange-700 rounded-xl flex gap-3">
                      <AlertTriangle className="w-5 h-5 shrink-0 text-orange-500" />
                      <p className="text-sm">Warning: The tone seems harsh or potentially confusing.</p>
                    </div>
                    <p className="text-sm text-slate-700"><strong className="text-slate-800">Suggestion:</strong> {modalContent.suggestion}</p>
                  </>
                ) : (
                  <div className="p-3 bg-green-50 border border-green-100 text-green-700 rounded-xl flex gap-3 items-center">
                    <CheckCircle className="w-5 h-5 text-green-600" />
                    <p className="text-sm font-medium">The tone is appropriate for a legal/personal sentiment.</p>
                  </div>
                )}
              </div>
            )}

            {modalContent.type === 'conflict' && (
              <div className="space-y-4">
                {modalContent.hasConflict ? (
                  <>
                    <div className="p-3 bg-red-50 border border-red-100 text-red-700 rounded-xl flex gap-3">
                      <AlertTriangle className="w-5 h-5 shrink-0 text-red-600" />
                      <p className="text-sm font-bold">Conflicts Detected</p>
                    </div>
                    <ul className="list-disc pl-5 space-y-2 text-sm text-slate-700">
                      {modalContent.issues.map((issue: string, i: number) => (
                        <li key={i}>{issue}</li>
                      ))}
                    </ul>
                  </>
                ) : (
                  <div className="p-3 bg-green-50 border border-green-100 text-green-700 rounded-xl flex gap-3 items-center">
                    <CheckCircle className="w-5 h-5 text-green-600" />
                    <p className="text-sm font-medium">The legal clauses appear consistent. No obvious contradictions found.</p>
                  </div>
                )}
              </div>
            )}

            <button 
              onClick={() => setModalContent(null)}
              className="w-full mt-6 bg-slate-200 hover:bg-slate-300 p-3 rounded-xl text-slate-700 font-bold transition-colors"
            >
              Close
            </button>
          </motion.div>
        </div>
      )}
    </div>
  );
}
