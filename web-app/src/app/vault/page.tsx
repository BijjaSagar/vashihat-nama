"use client";

import { useState, useEffect } from "react";
import { motion } from "framer-motion";
import { Folder, FileText, Plus, ShieldAlert, Loader2, Key, CreditCard, Bitcoin, X, Download } from "lucide-react";
import { ApiService } from "@/lib/api";
import { SecurityService } from "@/lib/security";
import Link from "next/link";

export default function VaultPage() {
  const [items, setItems] = useState<any[]>([]);
  const [folders, setFolders] = useState<any[]>([]);
  const [loading, setLoading] = useState(true);

  // Modals state
  const [showFolderModal, setShowFolderModal] = useState(false);
  const [newFolderName, setNewFolderName] = useState('');
  const [savingFolder, setSavingFolder] = useState(false);

  const [viewItem, setViewItem] = useState<any | null>(null);
  const [decryptedViewData, setDecryptedViewData] = useState<any | null>(null);
  const [activeFolderId, setActiveFolderId] = useState<number | null>(null);
  const [downloading, setDownloading] = useState(false);

  useEffect(() => {
    loadVault();
  }, []);

  const loadVault = async () => {
    try {
      const userId = ApiService.getUserId();
      if (!userId) {
        setLoading(false);
        return;
      }

      const [itemsRes, foldersRes, filesRes] = await Promise.all([
        ApiService.request(`/vault_items?user_id=${userId}`),
        ApiService.request(`/folders?user_id=${userId}`),
        ApiService.request(`/files?user_id=${userId}`)
      ]);

      const rawItems = itemsRes?.items ?? (Array.isArray(itemsRes) ? itemsRes : []);
      const rawFiles = Array.isArray(filesRes) ? filesRes : (filesRes?.files ?? []);

      const parsedFiles = rawFiles.map((f: any) => ({
        ...f,
        item_type: 'file',
        title: f.file_name,
        // For files, we keep meta in encrypted_data field for the UI logic
        encrypted_data: JSON.stringify({
          file_size: f.file_size,
          type: f.mime_type,
          storage_path: f.storage_path,
          is_encrypted: f.encrypted_file_key === 'client-side-aes-gcm'
        })
      }));

      setItems([...rawItems, ...parsedFiles]);
      setFolders(Array.isArray(foldersRes) ? foldersRes : (foldersRes?.folders ?? []));
    } catch (err) {
      console.error('Vault load error:', err);
    } finally {
      setLoading(false);
    }
  };

  // Automated decryption when an item is selected
  useEffect(() => {
    if (viewItem && viewItem.item_type !== 'file') {
      decryptItem(viewItem);
    } else {
      setDecryptedViewData(null);
    }
  }, [viewItem]);

  const decryptItem = async (item: any) => {
    try {
      // Try to decrypt. If it fails, assume it's legacy plaintext.
      const decrypted = await SecurityService.decrypt(item.encrypted_data);
      setDecryptedViewData(JSON.parse(decrypted));
    } catch (e) {
      // Legacy plaintext support
      try {
        setDecryptedViewData(JSON.parse(item.encrypted_data));
      } catch {
        setDecryptedViewData({ content: item.encrypted_data });
      }
    }
  };

  const getItemIcon = (type: string) => {
    switch (type) {
      case 'password': return <Key className="w-5 h-5 text-purple-400" />;
      case 'credit_card': return <CreditCard className="w-5 h-5 text-green-400" />;
      case 'crypto': return <Bitcoin className="w-5 h-5 text-orange-400" />;
      case 'note': return <FileText className="w-5 h-5 text-yellow-400" />;
      case 'file': return <Download className="w-5 h-5 text-blue-400" />;
      default: return <FileText className="w-5 h-5 text-blue-400" />;
    }
  };

  const handleCreateFolder = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!newFolderName.trim()) return;
    setSavingFolder(true);
    try {
      const userId = ApiService.getUserId();
      await ApiService.request('/folders', {
        method: 'POST',
        body: JSON.stringify({ user_id: userId, name: newFolderName, icon: 'folder' })
      });
      setShowFolderModal(false);
      setNewFolderName('');
      await loadVault();
    } catch (err) {
      console.error(err);
      alert("Failed to create folder");
    } finally {
      setSavingFolder(false);
    }
  };

  const filteredItems = items.filter(item => activeFolderId === null || item.folder_id === activeFolderId);

  if (loading) {
    return <div className="flex h-full items-center justify-center"><Loader2 className="w-8 h-8 animate-spin text-blue-600" /></div>;
  }

  return (
    <div className="space-y-8">
      <div className="flex flex-col md:flex-row justify-between items-start md:items-end gap-4 mb-8">
        <div>
          <h1 className="text-3xl font-bold mb-2 text-slate-800 flex items-center gap-3">
            <Folder className="w-8 h-8 text-blue-600" />
            My Secure Vault
          </h1>
          <p className="text-slate-600">Manage your encrypted documents, notes, passwords, and assets.</p>
        </div>
        <div className="flex gap-3">
          <button onClick={() => setShowFolderModal(true)} className="glass-button flex items-center gap-2 px-4 py-2 rounded-xl text-white font-medium bg-slate-800 hover:bg-slate-700 transition-colors">
            <Folder className="w-4 h-4" />
            New Folder
          </button>
          <Link href="/vault/add" className="bg-blue-600 hover:bg-blue-500 flex items-center gap-2 px-4 py-2 rounded-xl text-white font-medium transition-colors">
            <Plus className="w-4 h-4" />
            Add Item
          </Link>
        </div>
      </div>

      <div className="space-y-8">
        <div>
          <div className="flex items-center justify-between mb-4">
            <h2 className="text-xl font-bold text-slate-800">Folders</h2>
            {activeFolderId && (
              <button 
                onClick={() => setActiveFolderId(null)} 
                className="text-sm text-blue-600 hover:underline"
              >
                View All Items
              </button>
            )}
          </div>
          <div className="flex gap-4 overflow-x-auto pb-4 custom-scrollbar">
            <button 
              onClick={() => setActiveFolderId(null)}
              className={`flex items-center gap-2 px-6 py-3 rounded-2xl whitespace-nowrap transition-all border ${
                activeFolderId === null 
                  ? 'bg-blue-600 text-white border-blue-600 shadow-md' 
                  : 'glass-panel text-slate-700 bg-white hover:bg-white/60 border-slate-200'
              }`}
            >
              <Folder className="w-4 h-4" />
              All Items
            </button>
            {folders.map(f => (
              <button 
                key={f.id}
                onClick={() => setActiveFolderId(f.id)}
                className={`flex items-center gap-2 px-6 py-3 rounded-2xl whitespace-nowrap transition-all border ${
                  activeFolderId === f.id 
                    ? 'bg-blue-600 text-white border-blue-600 shadow-md' 
                    : 'glass-panel text-slate-700 bg-white hover:bg-white/60 border-slate-200'
                }`}
              >
                <Folder className="w-4 h-4" />
                {f.name}
              </button>
            ))}
          </div>
        </div>

        <div>
          <h2 className="text-xl font-bold mb-4 text-slate-800">
            {activeFolderId ? folders.find(f => f.id === activeFolderId)?.name : 'All Items'}
          </h2>
          
          {loading ? (
            <div className="flex justify-center p-12"><Loader2 className="w-8 h-8 animate-spin text-blue-600" /></div>
          ) : filteredItems.length === 0 ? (
            <div className="text-center p-12 glass-panel rounded-3xl border-dashed border-2 border-slate-300">
              <p className="text-slate-500 mb-4">No items found in this folder.</p>
              <Link href="/vault/add" className="text-blue-600 font-bold hover:underline">Add your first item</Link>
            </div>
          ) : (
            <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
              {filteredItems.map((item, idx) => (
                <motion.div 
                  key={item.id || idx}
                  initial={{ opacity: 0, y: 10 }}
                  animate={{ opacity: 1, y: 0 }}
                  transition={{ delay: idx * 0.05 }}
                  onClick={() => setViewItem(item)}
                  className="glass-panel bg-white p-5 rounded-2xl border border-slate-100 shadow-sm hover:shadow-lg hover:bg-white/80 transition-all cursor-pointer group"
                >
                  <div className="flex items-start justify-between mb-4">
                    <div className="bg-slate-100 p-3 rounded-xl border border-slate-200 group-hover:bg-blue-50 transition-colors">
                      {getItemIcon(item.item_type)}
                    </div>
                  </div>
                  <h3 className="font-bold text-lg mb-1 truncate text-slate-800">{item.title}</h3>
                  <p className="text-xs text-slate-500 font-bold uppercase tracking-wider">{item.item_type.replace('_', ' ')}</p>
                </motion.div>
              ))}
            </div>
          )}
        </div>
      </div>

      {viewItem && (
        <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-slate-900/40 backdrop-blur-sm">
          <motion.div 
            initial={{ scale: 0.95, opacity: 0 }}
            animate={{ scale: 1, opacity: 1 }}
            className="glass-panel w-full max-w-lg rounded-3xl p-6 shadow-2xl bg-white"
          >
            <div className="flex items-center gap-4 mb-6 pb-4 border-b border-slate-200">
              <div className="bg-white p-3 rounded-xl shadow-sm border border-slate-100">
                {getItemIcon(viewItem.item_type)}
              </div>
              <div>
                <h2 className="text-2xl font-bold text-slate-800">{viewItem.title}</h2>
                <span className="text-xs font-bold text-slate-500 uppercase tracking-wider">{viewItem.item_type}</span>
              </div>
            </div>

            <div className="space-y-4">
              {viewItem.item_type === 'file' ? (
                <div className="bg-slate-50 p-6 rounded-xl border border-slate-200 text-center flex flex-col items-center">
                  <Download className="w-12 h-12 text-blue-600 mb-4 opacity-80" />
                  <p className="text-slate-700 mb-6 font-medium">This is a secure file stored in your AWS S3 Vault.</p>
                  <button 
                    disabled={downloading}
                    onClick={async () => {
                      try {
                        setDownloading(true);
                        const data = JSON.parse(viewItem.encrypted_data || '{}');
                        const storagePath = data.storage_path || viewItem.storage_path || null;
                        const res = await ApiService.request('/get-presigned-download-url', {
                          method: 'POST',
                          body: JSON.stringify({
                            key: storagePath || undefined,
                            file_id: storagePath ? undefined : viewItem.id,
                            user_id: ApiService.getUserId()
                          })
                        });
                        
                        if (res.downloadUrl) {
                          // If encrypted, we must fetch and decrypt
                          if (data.is_encrypted) {
                            const fileRes = await fetch(res.downloadUrl);
                            const encryptedText = await fileRes.text();
                            const decryptedBase64 = await SecurityService.decrypt(encryptedText);
                            
                            // Convert base64 back to blob
                            const binaryString = atob(decryptedBase64);
                            const bytes = new Uint8Array(binaryString.length);
                            for (let i = 0; i < binaryString.length; i++) {
                              bytes[i] = binaryString.charCodeAt(i);
                            }
                            const blob = new Blob([bytes], { type: data.type || 'application/octet-stream' });
                            
                            // Trigger download
                            const url = window.URL.createObjectURL(blob);
                            const a = document.createElement('a');
                            a.href = url;
                            a.download = viewItem.title;
                            a.click();
                            window.URL.revokeObjectURL(url);
                          } else {
                            // Legacy plaintext file
                            window.open(res.downloadUrl, '_blank');
                          }
                        } else {
                          alert("Could not generate download link.");
                        }
                      } catch (err: any) {
                        alert("Failed to get download link: " + (err?.message || 'Unknown error'));
                      } finally {
                        setDownloading(false);
                      }
                    }}
                    className="bg-blue-600 hover:bg-blue-500 px-6 py-3 rounded-xl text-white font-bold flex items-center justify-center transition-colors w-full"
                  >
                    {downloading ? <Loader2 className="w-5 h-5 animate-spin" /> : "Download Secure File"}
                  </button>
                </div>
              ) : decryptedViewData ? (
                Object.entries(decryptedViewData).map(([key, val]) => (
                  <div key={key} className="bg-slate-50 p-4 rounded-xl border border-slate-200">
                    <span className="block text-xs font-bold text-slate-500 uppercase tracking-wider mb-1">
                      {key.replace('_', ' ')}
                    </span>
                    <p className="text-slate-800 break-words font-mono text-sm">{String(val)}</p>
                  </div>
                ))
              ) : (
                <div className="flex justify-center p-4"><Loader2 className="w-5 h-5 animate-spin text-blue-600" /> Decrypting...</div>
              )}
            </div>

            <button 
              onClick={() => { setViewItem(null); setDecryptedViewData(null); }}
              className="mt-8 w-full py-3 rounded-xl bg-slate-200 text-slate-700 font-bold hover:bg-slate-300 transition-colors"
            >
              Close
            </button>
          </motion.div>
        </div>
      )}

      {/* Create Folder Modal */}
      {showFolderModal && (
        <div className="fixed inset-0 bg-slate-950/80 backdrop-blur-sm z-50 flex items-center justify-center p-4">
          <motion.div 
            initial={{ opacity: 0, scale: 0.95 }}
            animate={{ opacity: 1, scale: 1 }}
            className="glass-panel max-w-md w-full rounded-3xl p-6 relative"
          >
            <button 
              onClick={() => setShowFolderModal(false)}
              className="absolute top-4 right-4 p-2 text-slate-400 hover:text-white"
            >
              <X className="w-5 h-5" />
            </button>
            <h2 className="text-2xl font-bold mb-6">Create New Folder</h2>
            <form onSubmit={handleCreateFolder} className="space-y-4">
              <div>
                <label className="block text-sm font-medium text-slate-400 mb-1">Folder Name</label>
                <input required value={newFolderName} onChange={e => setNewFolderName(e.target.value)} type="text" className="glass-input w-full p-3 rounded-xl focus:ring-2 focus:ring-blue-500" placeholder="e.g. Bank Statements" />
              </div>
              <button disabled={savingFolder} type="submit" className="w-full bg-blue-600 hover:bg-blue-500 mt-6 p-4 rounded-xl font-bold text-white flex items-center justify-center transition-colors">
                {savingFolder ? <Loader2 className="w-5 h-5 animate-spin" /> : "Create Folder"}
              </button>
            </form>
          </motion.div>
        </div>
      )}
    </div>
  );
}
