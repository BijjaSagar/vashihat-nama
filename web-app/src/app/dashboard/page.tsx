"use client";

import { useEffect, useState } from "react";
import { motion } from "framer-motion";
import { Shield, Folder, FileText, Bot, AlertTriangle, Loader2 } from "lucide-react";
import Link from "next/link";
import { ApiService } from "@/lib/api";

export default function DashboardPage() {
  const [vaultItems, setVaultItems] = useState<any[]>([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    const fetchDashboardData = async () => {
      try {
        const userId = ApiService.getUserId();
        if (!userId) return;
        const [itemsRes, filesRes] = await Promise.all([
          ApiService.request(`/vault_items?user_id=${userId}`),
          ApiService.request(`/files?user_id=${userId}`)
        ]);
        
        const parsedItems = Array.isArray(itemsRes) ? itemsRes : [];
        const parsedFiles = Array.isArray(filesRes) ? filesRes.map(f => ({
          ...f,
          item_type: 'file',
          title: f.file_name,
        })) : [];

        const allItems = [...parsedItems, ...parsedFiles];
        // Sort by created_at desc if available
        allItems.sort((a, b) => new Date(b.created_at || 0).getTime() - new Date(a.created_at || 0).getTime());
        setVaultItems(allItems);
      } catch (err) {
        console.error(err);
      } finally {
        setLoading(false);
      }
    };
    fetchDashboardData();
  }, []);
  return (
    <div className="space-y-8">
      <div className="flex justify-between items-end">
        <div>
          <h1 className="text-3xl font-bold mb-2 text-slate-800">Dashboard</h1>
          <p className="text-slate-600">Securely manage your legacy and digital assets.</p>
        </div>
      </div>

      <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
        <motion.div 
          initial={{ opacity: 0, y: 20 }}
          animate={{ opacity: 1, y: 0 }}
          className="glass-panel p-6 rounded-3xl"
        >
          <div className="bg-blue-500/20 w-12 h-12 rounded-2xl flex items-center justify-center mb-4">
            <Folder className="text-blue-400 w-6 h-6" />
          </div>
          <h3 className="text-xl font-bold mb-1 text-slate-800">Documents</h3>
          <p className="text-slate-600 text-sm mb-4">{loading ? '...' : `${vaultItems.length} Secured Items`}</p>
          <Link href="/vault" className="text-blue-600 text-sm font-semibold hover:underline block">View All &rarr;</Link>
        </motion.div>

        <motion.div 
          initial={{ opacity: 0, y: 20 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ delay: 0.1 }}
          className="glass-panel p-6 rounded-3xl"
        >
          <div className="bg-purple-500/20 w-12 h-12 rounded-2xl flex items-center justify-center mb-4">
            <Bot className="text-purple-400 w-6 h-6" />
          </div>
          <h3 className="text-xl font-bold mb-1 text-slate-800">Legal Assistant</h3>
          <p className="text-slate-600 text-sm mb-4">AI-powered legal guidance</p>
          <Link href="/legal-assistant" className="text-purple-600 text-sm font-semibold hover:underline block">Chat Now &rarr;</Link>
        </motion.div>

        <motion.div 
          initial={{ opacity: 0, y: 20 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ delay: 0.2 }}
          className="glass-panel p-6 rounded-3xl"
        >
          <div className="bg-red-500/20 w-12 h-12 rounded-2xl flex items-center justify-center mb-4">
            <Shield className="text-red-400 w-6 h-6" />
          </div>
          <h3 className="text-xl font-bold mb-1 text-slate-800">Security</h3>
          <p className="text-slate-600 text-sm mb-4">Review your protection status</p>
          <Link href="/proof-of-life" className="text-red-600 text-sm font-semibold hover:underline block">Check Settings &rarr;</Link>
        </motion.div>
      </div>

      <div className="glass-panel p-6 rounded-3xl">
        <h3 className="text-xl font-bold mb-4 flex items-center gap-2 text-slate-800">
          <AlertTriangle className="w-5 h-5 text-yellow-500" />
          Recent Vault Items
        </h3>
        <div className="space-y-4">
          {loading ? (
            <div className="p-4 flex justify-center"><Loader2 className="animate-spin text-blue-500" /></div>
          ) : vaultItems.length === 0 ? (
            <div className="p-8 text-center text-slate-500 font-medium">No items found in your vault.</div>
          ) : (
            vaultItems.slice(0, 5).map((item, idx) => (
              <Link href="/vault" key={item.id || idx} className="flex items-center justify-between p-4 bg-white/40 border border-white/50 rounded-xl hover:bg-white/60 transition-colors cursor-pointer">
                <div className="flex items-center gap-4">
                  <div className="bg-blue-500/10 p-3 rounded-xl border border-blue-200/50">
                    <FileText className="w-5 h-5 text-blue-600" />
                  </div>
                  <div>
                    <p className="font-bold text-slate-800">{item.title || "Untitled Document"}</p>
                    <p className="text-xs font-bold text-slate-500 uppercase tracking-wider mt-1">{item.item_type || "Document"}</p>
                  </div>
                </div>
                {item.created_at && (
                  <span className="text-xs font-semibold text-slate-400 hidden sm:block">
                    {new Date(item.created_at).toLocaleDateString()}
                  </span>
                )}
              </Link>
            ))
          )}
        </div>
      </div>

      <div>
        <h3 className="text-xl font-bold mb-6 text-slate-800 uppercase tracking-wider text-sm opacity-60">Operational Modules</h3>
        <div className="grid grid-cols-2 md:grid-cols-4 gap-4">
          {[
            { name: "Legal AI", href: "/legal-assistant", icon: Bot, color: "bg-purple-500" },
            { name: "Video Will", href: "/video-will", icon: FileText, color: "bg-blue-500" },
            { name: "Smart Scan", href: "/smart-scan", icon: Shield, color: "bg-green-500" },
            { name: "Will Draft", href: "/will-drafter", icon: FileText, color: "bg-orange-500" },
          ].map((mod, i) => (
            <Link href={mod.href} key={i}>
              <motion.div 
                whileHover={{ y: -5 }}
                className="glass-panel p-4 rounded-2xl flex flex-col items-center text-center hover:bg-white/60 transition-all cursor-pointer group"
              >
                <div className={`${mod.color} p-3 rounded-xl mb-3 shadow-lg group-hover:scale-110 transition-transform`}>
                  <mod.icon className="w-5 h-5 text-white" />
                </div>
                <span className="text-sm font-bold text-slate-700">{mod.name}</span>
              </motion.div>
            </Link>
          ))}
        </div>
      </div>
    </div>
  );
}
