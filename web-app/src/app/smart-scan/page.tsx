"use client";

import { useState } from "react";
import { motion, AnimatePresence } from "framer-motion";
import { 
  Scan, Upload, Camera, FileText, CheckCircle2, 
  Loader2, AlertCircle, X, Shield, Sparkles,
  ArrowRight
} from "lucide-react";
import { ApiService } from "@/lib/api";

export default function SmartScanPage() {
  const [isScanning, setIsScanning] = useState(false);
  const [scanResult, setScanResult] = useState<any>(null);
  const [error, setError] = useState<string | null>(null);
  const [dragActive, setDragActive] = useState(false);

  const handleFileUpload = async (file: File) => {
    setIsScanning(true);
    setError(null);
    setScanResult(null);

    // Simulated OCR & AI Classification
    // In a real app, we'd upload to /api/ai/classify or similar
    try {
      await new Promise(resolve => setTimeout(resolve, 2500));
      
      const mockResult = {
        type: "Passport",
        confidence: 0.98,
        fields: {
          "Name": "John Doe",
          "Document Number": "Z1234567",
          "Expiry Date": "2030-12-31",
          "Date of Birth": "1985-05-15",
          "Nationality": "Indian"
        },
        recommendation: "Added to 'Identity Documents' folder. Smart Alert created for expiry."
      };
      
      setScanResult(mockResult);
    } catch (err) {
      setError("Failed to process document. Please try again.");
    } finally {
      setIsScanning(false);
    }
  };

  const handleDrag = (e: React.DragEvent) => {
    e.preventDefault();
    e.stopPropagation();
    if (e.type === "dragenter" || e.type === "dragover") {
      setDragActive(true);
    } else if (e.type === "dragleave") {
      setDragActive(false);
    }
  };

  const handleDrop = (e: React.DragEvent) => {
    e.preventDefault();
    e.stopPropagation();
    setDragActive(false);
    if (e.dataTransfer.files && e.dataTransfer.files[0]) {
      handleFileUpload(e.dataTransfer.files[0]);
    }
  };

  return (
    <div className="max-w-4xl mx-auto space-y-8">
      <div className="flex flex-col md:flex-row justify-between items-start md:items-end gap-4">
        <div>
          <h1 className="text-3xl font-bold mb-2 text-slate-800 flex items-center gap-3">
            <Scan className="w-8 h-8 text-blue-600" />
            Smart Scan & OCR
          </h1>
          <p className="text-slate-600">AI-powered document extraction and auto-classification.</p>
        </div>
      </div>

      <div className="grid grid-cols-1 md:grid-cols-2 gap-8">
        <div className="space-y-6">
          <div 
            onDragEnter={handleDrag}
            onDragLeave={handleDrag}
            onDragOver={handleDrag}
            onDrop={handleDrop}
            className={`relative glass-panel rounded-3xl p-10 border-2 border-dashed transition-all flex flex-col items-center justify-center text-center cursor-pointer min-h-[300px] ${
              dragActive ? 'border-blue-500 bg-blue-50/50 scale-[1.02]' : 'border-slate-300 hover:border-blue-400 hover:bg-slate-50/50'
            }`}
          >
            <input 
              type="file" 
              className="absolute inset-0 w-full h-full opacity-0 cursor-pointer"
              onChange={(e) => e.target.files && handleFileUpload(e.target.files[0])}
              accept="image/*,application/pdf"
              disabled={isScanning}
            />
            
            <div className="bg-blue-600/10 p-5 rounded-full mb-6">
              {isScanning ? (
                <Loader2 className="w-10 h-10 text-blue-600 animate-spin" />
              ) : (
                <Upload className="w-10 h-10 text-blue-600" />
              )}
            </div>

            <h3 className="text-xl font-bold text-slate-800 mb-2">
              {isScanning ? "Processing Document..." : "Upload or Drag & Drop"}
            </h3>
            <p className="text-slate-500 text-sm max-w-[240px]">
              Upload any document (Passport, ID, License) to extract data and auto-save.
            </p>

            {isScanning && (
              <motion.div 
                className="absolute inset-x-10 bottom-10 h-1 bg-slate-200 rounded-full overflow-hidden"
                initial={{ opacity: 0 }}
                animate={{ opacity: 1 }}
              >
                <motion.div 
                  className="h-full bg-blue-600"
                  animate={{ x: ["-100%", "100%"] }}
                  transition={{ repeat: Infinity, duration: 1.5, ease: "linear" }}
                />
              </motion.div>
            )}
          </div>

          <div className="glass-panel p-6 rounded-3xl bg-blue-50/50 border-blue-100">
            <div className="flex items-start gap-4">
              <div className="bg-blue-600 p-2 rounded-lg mt-1">
                <Sparkles className="w-4 h-4 text-white" />
              </div>
              <div>
                <h4 className="font-bold text-slate-800">AI Intelligence</h4>
                <p className="text-sm text-slate-600 mt-1">
                  Our Optical Character Recognition (OCR) uses neural networks to detect sensitive fields and expiration dates automatically.
                </p>
              </div>
            </div>
          </div>
        </div>

        <div className="space-y-6">
          <AnimatePresence mode="wait">
            {!scanResult && !isScanning && (
              <motion.div 
                key="empty"
                initial={{ opacity: 0 }}
                animate={{ opacity: 1 }}
                exit={{ opacity: 0 }}
                className="glass-panel p-8 rounded-3xl border border-slate-200 flex flex-col items-center justify-center text-center h-full min-h-[400px]"
              >
                <FileText className="w-16 h-16 text-slate-200 mb-4" />
                <h3 className="text-lg font-bold text-slate-400">Scan Results Will Appear Here</h3>
                <p className="text-slate-400 text-sm mt-2">Extracting data takes a few seconds.</p>
              </motion.div>
            )}

            {isScanning && (
              <motion.div 
                key="scanning"
                initial={{ opacity: 0 }}
                animate={{ opacity: 1 }}
                exit={{ opacity: 0 }}
                className="glass-panel p-8 rounded-3xl border border-slate-200 flex flex-col items-center justify-center space-y-4 h-full min-h-[400px]"
              >
                <div className="relative">
                  <div className="w-20 h-20 border-4 border-blue-100 border-t-blue-600 rounded-full animate-spin" />
                  <Scan className="w-8 h-8 text-blue-600 absolute inset-0 m-auto" />
                </div>
                <div className="text-center">
                  <h3 className="text-lg font-bold text-slate-800">Analyzing Document</h3>
                  <p className="text-slate-500 text-sm">Identifying fields and security marks...</p>
                </div>
              </motion.div>
            )}

            {scanResult && (
              <motion.div 
                key="result"
                initial={{ opacity: 0, x: 20 }}
                animate={{ opacity: 1, x: 0 }}
                className="glass-panel p-8 rounded-3xl border border-green-100 bg-white shadow-xl h-full"
              >
                <div className="flex items-center justify-between mb-6">
                  <div className="flex items-center gap-2">
                    <CheckCircle2 className="w-6 h-6 text-green-500" />
                    <h3 className="text-xl font-bold text-slate-800">Scan Complete</h3>
                  </div>
                  <div className="bg-green-100 text-green-700 text-xs font-bold px-3 py-1 rounded-full">
                    {Math.round(scanResult.confidence * 100)}% Confidence
                  </div>
                </div>

                <div className="bg-slate-50 p-4 rounded-2xl mb-6 border border-slate-100">
                  <div className="flex justify-between items-center mb-4">
                    <span className="text-sm font-bold text-slate-500 uppercase tracking-wider">Classification</span>
                    <span className="bg-blue-600 text-white text-xs font-bold px-3 py-1 rounded-lg">{scanResult.type}</span>
                  </div>
                  
                  <div className="space-y-3">
                    {Object.entries(scanResult.fields).map(([key, value]: [string, any]) => (
                      <div key={key} className="flex justify-between items-center pb-2 border-b border-slate-200/50 last:border-0">
                        <span className="text-sm text-slate-600">{key}</span>
                        <span className="text-sm font-bold text-slate-800">{value}</span>
                      </div>
                    ))}
                  </div>
                </div>

                <div className="space-y-4">
                  <div className="flex items-center gap-3 p-3 bg-blue-50 rounded-xl border border-blue-100">
                    <Shield className="w-5 h-5 text-blue-600" />
                    <p className="text-xs text-blue-800 leading-tight">
                      <strong>AI Recommendation:</strong> {scanResult.recommendation}
                    </p>
                  </div>
                  
                  <button className="w-full bg-slate-900 hover:bg-slate-800 text-white p-4 rounded-2xl font-bold flex items-center justify-center gap-2 transition-all">
                    Save to Vault <ArrowRight className="w-4 h-4" />
                  </button>
                </div>
              </motion.div>
            )}
          </AnimatePresence>

          {error && (
            <motion.div 
              initial={{ opacity: 0, y: 10 }}
              animate={{ opacity: 1, y: 0 }}
              className="p-4 bg-red-50 border border-red-100 rounded-2xl flex items-center gap-3 text-red-600"
            >
              <AlertCircle className="w-5 h-5 flex-shrink-0" />
              <p className="text-sm font-medium">{error}</p>
            </motion.div>
          )}
        </div>
      </div>
    </div>
  );
}
