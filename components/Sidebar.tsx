"use client";
import Link from "next/link";
import { usePathname, useRouter } from "next/navigation";
import { createClient } from "@/lib/supabase/client";
import { LayoutDashboard, Users, Image, MessageSquare, LogOut, Zap } from "lucide-react";

const nav = [
  { href: "/dashboard", label: "Dashboard", icon: LayoutDashboard },
  { href: "/users", label: "Users", icon: Users },
  { href: "/images", label: "Images", icon: Image },
  { href: "/captions", label: "Captions", icon: MessageSquare },
];

export default function Sidebar() {
  const path = usePathname();
  const router = useRouter();

  const signOut = async () => {
    await createClient().auth.signOut();
    router.push("/login");
  };

  return (
    <aside style={{
      position: "fixed", left: 0, top: 0, height: "100vh", width: "220px",
      background: "var(--dim)", borderRight: "1px solid var(--border)",
      display: "flex", flexDirection: "column", zIndex: 50,
    }}>
      <div style={{ padding: "1.5rem 1.25rem 1.25rem", borderBottom: "1px solid var(--border)" }}>
        <div style={{ display: "flex", alignItems: "center", gap: "8px", marginBottom: "4px" }}>
          <div style={{ width: "2px", height: "22px", background: "var(--acid)" }} />
          <span className="font-display" style={{ fontSize: "1.5rem", letterSpacing: "0.1em", color: "var(--paper)" }}>HUMOR</span>
        </div>
        <div style={{ display: "flex", alignItems: "center", gap: "6px", marginLeft: "10px" }}>
          <Zap size={9} color="var(--acid)" />
          <span className="mono" style={{ fontSize: "0.55rem", color: "var(--slate)", letterSpacing: "0.12em", textTransform: "uppercase" }}>Admin Panel</span>
        </div>
      </div>
      <nav style={{ flex: 1, padding: "1rem 0.75rem", display: "flex", flexDirection: "column", gap: "2px" }}>
        {nav.map(({ href, label, icon: Icon }) => {
          const active = path === href || path.startsWith(href + "/");
          return (
            <Link key={href} href={href} style={{
              display: "flex", alignItems: "center", gap: "10px", padding: "0.55rem 0.75rem",
              borderRadius: "4px", background: active ? "rgba(184,247,35,0.07)" : "transparent",
              color: active ? "var(--acid)" : "var(--slate)",
              borderLeft: `2px solid ${active ? "var(--acid)" : "transparent"}`,
              textDecoration: "none", fontSize: "0.78rem",
              fontFamily: "'JetBrains Mono', monospace", transition: "all 0.15s",
            }}>
              <Icon size={13} />{label}
            </Link>
          );
        })}
      </nav>
      <div style={{ padding: "0.75rem", borderTop: "1px solid var(--border)" }}>
        <button onClick={signOut} style={{
          display: "flex", alignItems: "center", gap: "10px", padding: "0.55rem 0.75rem",
          width: "100%", background: "none", border: "none", color: "var(--slate)",
          cursor: "pointer", fontSize: "0.78rem", fontFamily: "'JetBrains Mono', monospace",
          borderRadius: "4px", transition: "color 0.15s",
        }}
          onMouseEnter={e => (e.currentTarget.style.color = "var(--rust)")}
          onMouseLeave={e => (e.currentTarget.style.color = "var(--slate)")}
        >
          <LogOut size={13} /> Sign Out
        </button>
      </div>
    </aside>
  );
}
