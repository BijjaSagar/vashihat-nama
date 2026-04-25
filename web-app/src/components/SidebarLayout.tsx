"use client";

import { useState, useEffect } from "react";
import Link from "next/link";
import { usePathname, useRouter } from "next/navigation";
import { Home, Users, HeartPulse, Settings, LogOut, Menu, X, Shield, LayoutDashboard, Folder, Scale, FileSignature } from "lucide-react";
import { ApiService } from "@/lib/api";

const navigation = [
  { name: "Dashboard", href: "/dashboard", icon: LayoutDashboard },
  { name: "My Vault", href: "/vault", icon: Folder },
  { name: "Nominees", href: "/nominees", icon: Users },
  { name: "Proof of Life", href: "/proof-of-life", icon: HeartPulse },
  { name: "Legal Assistant", href: "/legal-assistant", icon: Scale },
  { name: "AI Will Drafter", href: "/will-drafter", icon: FileSignature },
];

export default function SidebarLayout({ children }: { children: React.ReactNode }) {
  const pathname = usePathname();
  const router = useRouter();
  const [isSidebarOpen, setSidebarOpen] = useState(false);

  useEffect(() => {
    if (!ApiService.getAuthToken()) {
      router.push("/");
    }
  }, [router]);

  const handleLogout = () => {
    ApiService.logout();
    router.push("/");
  };

  return (
    <div className="min-h-screen bg-transparent flex">
      {/* Sidebar */}
      <aside className={`fixed inset-y-0 left-0 z-50 w-64 glass-panel border-r border-white/50 transform transition-transform duration-300 ease-in-out ${isSidebarOpen ? 'translate-x-0' : '-translate-x-full'} lg:translate-x-0`}>
        <div className="flex h-full flex-col">
          <div className="flex h-16 items-center justify-between px-6 border-b border-white/50">
            <Link href="/dashboard" className="flex items-center gap-2">
              <Shield className="w-8 h-8 text-blue-600" />
              <span className="text-xl font-bold text-slate-800">Eversafe</span>
            </Link>
            <button onClick={() => setSidebarOpen(false)} className="lg:hidden text-slate-600">
              <X className="w-6 h-6" />
            </button>
          </div>

          <nav className="flex-1 space-y-2 px-4 py-6">
            {navigation.map((item) => {
              const isActive = pathname === item.href || pathname.startsWith(item.href + '/');
              return (
                <Link
                  key={item.name}
                  href={item.href}
                  onClick={() => setSidebarOpen(false)}
                  className={`flex items-center gap-3 px-4 py-3 rounded-xl transition-all ${
                    isActive 
                      ? 'bg-blue-600/20 text-blue-700 font-bold border border-blue-200/50 shadow-sm' 
                      : 'text-slate-600 hover:bg-white/40 hover:text-slate-800'
                  }`}
                >
                  <item.icon className="w-5 h-5" />
                  {item.name}
                </Link>
              );
            })}
          </nav>

          <div className="p-4 border-t border-white/50 space-y-2">
            <button className="flex w-full items-center gap-3 px-4 py-3 rounded-xl text-slate-600 hover:bg-white/40 hover:text-slate-800 transition-all">
              <Settings className="w-5 h-5" />
              Settings
            </button>
            <button 
              onClick={handleLogout}
              className="flex w-full items-center gap-3 px-4 py-3 rounded-xl text-red-600 hover:bg-red-500/10 transition-all font-medium"
            >
              <LogOut className="w-5 h-5" />
              Logout
            </button>
          </div>
        </div>
      </aside>

      {/* Main content */}
      <div className="lg:pl-64 flex flex-col flex-1 min-h-screen">
        <header className="sticky top-0 z-40 flex h-16 items-center justify-between px-4 sm:px-6 glass-panel border-b border-white/50 lg:hidden">
          <button onClick={() => setSidebarOpen(true)} className="text-slate-800">
            <Menu className="w-6 h-6" />
          </button>
          <span className="font-bold text-lg text-slate-800">Eversafe</span>
          <div className="w-6"></div>
        </header>

        <main className="flex-1 p-4 sm:p-6 lg:p-8 overflow-y-auto h-full">
          <div className="mx-auto max-w-7xl h-full">
            {children}
          </div>
        </main>
      </div>
    </div>
  );
}
