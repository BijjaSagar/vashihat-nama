"use client";

import { useState, useEffect } from "react";
import Link from "next/link";
import { usePathname, useRouter } from "next/navigation";
import {
  Settings, LogOut, Menu, X, Shield, LayoutDashboard, Folder, Scale,
  FileSignature, Users, HeartPulse, ShieldCheck, Bell, Activity,
  Cpu, MessageSquareHeart, Map, Video, Search, ClipboardCheck,
  BarChart3, AlertTriangle, CreditCard, ChevronDown, ChevronRight,
  HeartHandshake
} from "lucide-react";
import { ApiService } from "@/lib/api";

const navGroups = [
  {
    label: "Core",
    items: [
      { name: "Dashboard", href: "/dashboard", icon: LayoutDashboard },
      { name: "My Vault", href: "/vault", icon: Folder },
      { name: "Nominees", href: "/nominees", icon: Users },
    ]
  },
  {
    label: "Protection",
    items: [
      { name: "Proof of Life", href: "/proof-of-life", icon: HeartPulse },
      { name: "Security Health", href: "/security", icon: ShieldCheck },
      { name: "Fraud Detection", href: "/activity-log", icon: AlertTriangle },
    ]
  },
  {
    label: "AI Tools",
    items: [
      { name: "Legal Assistant", href: "/legal-assistant", icon: Scale },
      { name: "AI Will Drafter", href: "/will-drafter", icon: FileSignature },
      { name: "Legal Documents", href: "/legal-documents", icon: Cpu },
      { name: "Vault Health", href: "/vault-health", icon: Activity },
    ]
  },
  {
    label: "Planning",
    items: [
      { name: "Smart Alerts", href: "/smart-alerts", icon: Bell },
      { name: "Asset Discovery", href: "/asset-discovery", icon: Search },
      { name: "Estate Summary", href: "/estate-summary", icon: BarChart3 },
      { name: "Nominee Readiness", href: "/nominee-readiness", icon: ClipboardCheck },
      { name: "Regional", href: "/regional", icon: Map },
    ]
  },
  {
    label: "Personal",
    items: [
      { name: "Video Will", href: "/video-will", icon: Video },
      { name: "Emergency Card", href: "/emergency-card", icon: CreditCard },
      { name: "Grief Support", href: "/grief-support", icon: HeartHandshake },
    ]
  },
];

export default function SidebarLayout({ children }: { children: React.ReactNode }) {
  const pathname = usePathname();
  const router = useRouter();
  const [isSidebarOpen, setSidebarOpen] = useState(false);
  const [collapsed, setCollapsed] = useState<Record<string, boolean>>({});

  useEffect(() => {
    if (!ApiService.getAuthToken()) {
      router.push("/");
    }
  }, [router]);

  const handleLogout = () => {
    ApiService.logout();
    router.push("/");
  };

  const toggleGroup = (label: string) => {
    setCollapsed(prev => ({ ...prev, [label]: !prev[label] }));
  };

  return (
    <div className="min-h-screen bg-transparent flex">
      {/* Overlay for mobile */}
      {isSidebarOpen && (
        <div className="fixed inset-0 bg-black/20 backdrop-blur-sm z-40 lg:hidden" onClick={() => setSidebarOpen(false)} />
      )}

      {/* Sidebar */}
      <aside className={`fixed inset-y-0 left-0 z-50 w-64 glass-panel border-r border-white/50 transform transition-transform duration-300 ease-in-out ${isSidebarOpen ? 'translate-x-0' : '-translate-x-full'} lg:translate-x-0 flex flex-col`}>
        {/* Logo */}
        <div className="flex h-16 items-center justify-between px-5 border-b border-white/50 flex-shrink-0">
          <Link href="/dashboard" className="flex items-center gap-2">
            <Shield className="w-7 h-7 text-blue-600" />
            <span className="text-lg font-bold text-slate-800">Eversafe</span>
          </Link>
          <button onClick={() => setSidebarOpen(false)} className="lg:hidden text-slate-600 p-1">
            <X className="w-5 h-5" />
          </button>
        </div>

        {/* Nav */}
        <nav className="flex-1 overflow-y-auto px-3 py-4 space-y-1">
          {navGroups.map((group) => {
            const isOpen = !collapsed[group.label];
            const hasActive = group.items.some(i => pathname === i.href || pathname.startsWith(i.href + '/'));
            return (
              <div key={group.label}>
                <button
                  onClick={() => toggleGroup(group.label)}
                  className={`w-full flex items-center justify-between px-3 py-1.5 text-xs font-bold uppercase tracking-wider rounded-lg transition-colors ${hasActive ? 'text-blue-600' : 'text-slate-400 hover:text-slate-600'}`}
                >
                  <span>{group.label}</span>
                  {isOpen ? <ChevronDown className="w-3 h-3" /> : <ChevronRight className="w-3 h-3" />}
                </button>
                {isOpen && (
                  <div className="mt-1 space-y-0.5">
                    {group.items.map((item) => {
                      const isActive = pathname === item.href || pathname.startsWith(item.href + '/');
                      return (
                        <Link
                          key={item.name}
                          href={item.href}
                          onClick={() => setSidebarOpen(false)}
                          className={`flex items-center gap-3 px-3 py-2.5 rounded-xl text-sm transition-all ${
                            isActive
                              ? 'bg-blue-600 text-white font-bold shadow-md shadow-blue-200'
                              : 'text-slate-600 hover:bg-white/60 hover:text-slate-800'
                          }`}
                        >
                          <item.icon className="w-4 h-4 flex-shrink-0" />
                          <span className="truncate">{item.name}</span>
                        </Link>
                      );
                    })}
                  </div>
                )}
              </div>
            );
          })}
        </nav>

        {/* Footer */}
        <div className="p-3 border-t border-white/50 space-y-1 flex-shrink-0">
          <button className="flex w-full items-center gap-3 px-3 py-2.5 rounded-xl text-sm text-slate-600 hover:bg-white/40 hover:text-slate-800 transition-all">
            <Settings className="w-4 h-4" />
            Settings
          </button>
          <button
            onClick={handleLogout}
            className="flex w-full items-center gap-3 px-3 py-2.5 rounded-xl text-sm text-red-600 hover:bg-red-50 transition-all font-medium"
          >
            <LogOut className="w-4 h-4" />
            Logout
          </button>
        </div>
      </aside>

      {/* Main content */}
      <div className="lg:pl-64 flex flex-col flex-1 min-h-screen">
        <header className="sticky top-0 z-40 flex h-16 items-center justify-between px-4 sm:px-6 glass-panel border-b border-white/50 lg:hidden">
          <button onClick={() => setSidebarOpen(true)} className="text-slate-800 p-1">
            <Menu className="w-6 h-6" />
          </button>
          <span className="font-bold text-lg text-slate-800">Eversafe</span>
          <div className="w-8" />
        </header>

        <main className="flex-1 p-4 sm:p-6 lg:p-8 overflow-y-auto">
          <div className="mx-auto max-w-7xl">
            {children}
          </div>
        </main>
      </div>
    </div>
  );
}
