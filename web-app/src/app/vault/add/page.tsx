"use client";

import { useState, useEffect } from "react";
import { useRouter } from "next/navigation";
import { motion } from "framer-motion";
import { Loader2, ArrowLeft, Save, Check } from "lucide-react";
import { ApiService } from "@/lib/api";
import Link from "next/link";

export default function AddVaultItemPage() {
  const router = useRouter();
  const [selectedType, setSelectedType] = useState('note');
  const [title, setTitle] = useState('');
  const [saving, setSaving] = useState(false);
  const [nominees, setNominees] = useState<any[]>([]);
  const [selectedNominees, setSelectedNominees] = useState<number[]>([]);
  const [folders, setFolders] = useState<any[]>([]);
  const [selectedFolderId, setSelectedFolderId] = useState<number | null>(null);

  // Item Specific Data
  const [content, setContent] = useState(''); // Note
  const [username, setUsername] = useState(''); // Password
  const [password, setPassword] = useState(''); // Password
  const [url, setUrl] = useState(''); // Password
  const [cardNumber, setCardNumber] = useState(''); // Card
  const [notes, setNotes] = useState(''); // Common
  const [file, setFile] = useState<File | null>(null); // File

  useEffect(() => {
    loadData();
  }, []);

  const loadData = async () => {
    try {
      const userId = ApiService.getUserId();
      if (!userId) return;
      const [nomineesRes, foldersRes] = await Promise.all([
        ApiService.request(`/nominees?user_id=${userId}`),
        ApiService.request(`/folders?user_id=${userId}`)
      ]);
      setNominees(Array.isArray(nomineesRes) ? nomineesRes : []);
      setFolders(Array.isArray(foldersRes) ? foldersRes : []);
    } catch (err) {
      console.error(err);
    }
  };

  const toggleNominee = (id: number) => {
    if (selectedNominees.includes(id)) {
      setSelectedNominees(prev => prev.filter(n => n !== id));
    } else {
      setSelectedNominees(prev => [...prev, id]);
    }
  };

  const handleSave = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!title) return alert("Title is required");

    setSaving(true);
    try {
      const userId = ApiService.getUserId();
      let data: any = {};

      if (selectedType === 'note') {
        data = { content };
      } else if (selectedType === 'password') {
        data = { username, password, url, notes };
      } else if (selectedType === 'credit_card') {
        data = { card_number: cardNumber, notes };
      }
      
      if (selectedType === 'file') {
        if (!file) throw new Error("Please select a file to upload.");
        
        // 1. Get Presigned URL
        const presignedRes = await ApiService.request('/get-presigned-url', {
          method: 'POST',
          body: JSON.stringify({
            folder_id: selectedFolderId,
            file_name: file.name,
            file_type: file.type || 'application/octet-stream'
          })
        });

        // 2. Upload to S3 directly
        const s3Upload = await fetch(presignedRes.uploadUrl, {
          method: 'PUT',
          headers: {
            'Content-Type': file.type || 'application/octet-stream'
          },
          body: file
        });
        
        if (!s3Upload.ok) throw new Error("Failed to upload to S3.");

        // 3. Confirm upload
        await ApiService.request('/files/confirm-upload', {
          method: 'POST',
          body: JSON.stringify({
            user_id: userId,
            folder_id: selectedFolderId,
            file_name: file.name,
            key: presignedRes.key,
            file_size: file.size,
            mime_type: file.type
          })
        });

      } else {
        // Handle normal vault items
        await ApiService.request('/vault_items', {
          method: 'POST',
          body: JSON.stringify({
            user_id: userId,
            folder_id: selectedFolderId,
            item_type: selectedType,
            title,
            encrypted_data: JSON.stringify(data), // Sending as JSON string for now
            nominee_ids: selectedNominees,
          })
        });
      }

      router.push('/vault');
    } catch (err) {
      console.error(err);
      alert("Failed to save item");
    } finally {
      setSaving(false);
    }
  };

  return (
    <div className="max-w-2xl mx-auto space-y-8">
      <div className="flex items-center gap-4">
        <Link href="/vault" className="p-2 glass-button rounded-xl hover:bg-slate-800 transition-colors">
          <ArrowLeft className="w-5 h-5 text-slate-300" />
        </Link>
        <h1 className="text-3xl font-bold">Add Secure Item</h1>
      </div>

      <form onSubmit={handleSave} className="space-y-6">
        <div className="glass-panel p-6 rounded-3xl space-y-6">
          {/* Type Selection */}
          <div>
            <label className="block text-sm font-medium text-slate-400 mb-3">Item Type</label>
            <div className="flex gap-2 overflow-x-auto pb-2">
              {['note', 'password', 'credit_card', 'crypto', 'file'].map(type => (
                <button
                  key={type}
                  type="button"
                  onClick={() => setSelectedType(type)}
                  className={`px-4 py-2 rounded-xl text-sm font-medium whitespace-nowrap transition-colors ${
                    selectedType === type ? 'bg-blue-500 text-white shadow-md' : 'glass-button text-slate-400'
                  }`}
                >
                  {type.charAt(0).toUpperCase() + type.slice(1).replace('_', ' ')}
                </button>
              ))}
            </div>
          </div>

          <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
            <div>
              <label className="block text-sm font-medium text-slate-400 mb-1">Title</label>
              <input required value={title} onChange={e => setTitle(e.target.value)} type="text" className="glass-input w-full p-3 rounded-xl focus:ring-2 focus:ring-blue-500" placeholder="e.g. Work Email, Bank Login..." />
            </div>
            <div>
              <label className="block text-sm font-medium text-slate-400 mb-1">Save in Folder (Optional)</label>
              <select 
                value={selectedFolderId || ''} 
                onChange={e => setSelectedFolderId(e.target.value ? Number(e.target.value) : null)}
                className="glass-input w-full p-3 rounded-xl focus:ring-2 focus:ring-blue-500 bg-slate-900/50"
              >
                <option value="">None (Root Vault)</option>
                {folders.map(f => (
                  <option key={f.id} value={f.id}>{f.name}</option>
                ))}
              </select>
            </div>
          </div>

          {/* Dynamic Fields */}
          {selectedType === 'note' && (
            <div>
              <label className="block text-sm font-medium text-slate-400 mb-1">Secure Note Content</label>
              <textarea value={content} onChange={e => setContent(e.target.value)} className="glass-input w-full p-3 rounded-xl focus:ring-2 focus:ring-blue-500 min-h-[150px]" placeholder="Write your private note here..."></textarea>
            </div>
          )}

          {selectedType === 'password' && (
            <div className="space-y-4">
              <div>
                <label className="block text-sm font-medium text-slate-400 mb-1">Username / Email</label>
                <input value={username} onChange={e => setUsername(e.target.value)} type="text" className="glass-input w-full p-3 rounded-xl focus:ring-2 focus:ring-blue-500" />
              </div>
              <div>
                <label className="block text-sm font-medium text-slate-400 mb-1">Password</label>
                <input value={password} onChange={e => setPassword(e.target.value)} type="password" className="glass-input w-full p-3 rounded-xl focus:ring-2 focus:ring-blue-500" />
              </div>
              <div>
                <label className="block text-sm font-medium text-slate-400 mb-1">URL (Optional)</label>
                <input value={url} onChange={e => setUrl(e.target.value)} type="url" className="glass-input w-full p-3 rounded-xl focus:ring-2 focus:ring-blue-500" />
              </div>
            </div>
          )}

          {selectedType === 'credit_card' && (
            <div>
              <label className="block text-sm font-medium text-slate-400 mb-1">Card Number</label>
              <input value={cardNumber} onChange={e => setCardNumber(e.target.value)} type="text" className="glass-input w-full p-3 rounded-xl focus:ring-2 focus:ring-blue-500" placeholder="XXXX XXXX XXXX XXXX" />
            </div>
          )}

          {selectedType === 'file' && (
            <div>
              <label className="block text-sm font-medium text-slate-400 mb-1">Upload Document</label>
              <div className="border-2 border-dashed border-slate-700 rounded-2xl p-8 text-center bg-slate-900/30">
                <input 
                  type="file" 
                  onChange={e => setFile(e.target.files?.[0] || null)}
                  className="w-full"
                />
                {file && <p className="mt-2 text-sm text-green-400">Selected: {file.name}</p>}
                <p className="mt-2 text-xs text-slate-500">Will be encrypted and uploaded to secure AWS S3 storage.</p>
              </div>
            </div>
          )}

          {selectedType !== 'note' && (
            <div>
              <label className="block text-sm font-medium text-slate-400 mb-1">Additional Notes</label>
              <textarea value={notes} onChange={e => setNotes(e.target.value)} className="glass-input w-full p-3 rounded-xl focus:ring-2 focus:ring-blue-500" placeholder="Any extra details..."></textarea>
            </div>
          )}
        </div>

        {/* Nominee Assignment */}
        <div className="glass-panel p-6 rounded-3xl space-y-4">
          <h3 className="text-lg font-bold">Assign to Nominees</h3>
          <p className="text-sm text-slate-400">Select who should inherit this item when your dead man switch triggers.</p>
          
          {nominees.length === 0 ? (
            <div className="p-4 bg-slate-800/50 rounded-xl text-center text-slate-400 text-sm">
              You haven't added any nominees yet. <Link href="/nominees" className="text-blue-400 hover:underline">Add one here</Link>.
            </div>
          ) : (
            <div className="grid grid-cols-1 sm:grid-cols-2 gap-3">
              {nominees.map(n => (
                <div 
                  key={n.id}
                  onClick={() => toggleNominee(n.id)}
                  className={`p-3 rounded-xl border flex items-center justify-between cursor-pointer transition-colors ${
                    selectedNominees.includes(n.id) 
                      ? 'bg-blue-500/20 border-blue-500 text-white' 
                      : 'bg-slate-800/30 border-transparent text-slate-300 hover:bg-slate-800'
                  }`}
                >
                  <span className="font-medium">{n.name}</span>
                  {selectedNominees.includes(n.id) && <Check className="w-4 h-4 text-blue-400" />}
                </div>
              ))}
            </div>
          )}
        </div>

        <button disabled={saving} type="submit" className="w-full glass-button p-4 rounded-xl font-bold text-white flex items-center justify-center gap-2">
          {saving ? <Loader2 className="w-5 h-5 animate-spin" /> : <><Save className="w-5 h-5" /> Save Item to Vault</>}
        </button>
      </form>
    </div>
  );
}
