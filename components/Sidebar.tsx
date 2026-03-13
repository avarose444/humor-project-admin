"use client";
import Link from "next/link";
import { usePathname, useRouter } from "next/navigation";
import { createClient } from "@/lib/supabase/client";
import { LayoutDashboard, Users, Image, MessageSquare, LogOut, Zap, BookOpen, FlaskConical, Sliders, FileText, Cpu, Building2, Link2, MailCheck, Globe, List, HelpCircle, ChevronDown, ChevronRight } from "lucide-react";
import { useState } from "react";

const nav = [
  { href: "/dashboard", label: "Dashboard", icon: LayoutDashboard },
  { label: "Content", icon: FileText, children: [
    { href: "/users", label: "Users", icon: Users },
    { href: "/images", label: "Images", icon: Image },
    { href: "/captions", label: "Captions", icon: MessageSquare },
    { href: "/caption-requests", label: "Caption Requests", icon: HelpCircle },
    { href: "/caption-examples", label: "Caption Examples", icon: BookOpen },
    { href: "/terms", label: "Terms", icon: List },
  ]},
  { label: "Humor Engine", icon: FlaskConical, children: [
    { href: "/humor-flavors", label: "Flavors", icon: FlaskConical },
    { href: "/humor-flavor-steps", label: "Flavor Steps", icon: Sliders },
    { href: "/humor-flavor-mix", label: "Flavor Mix", icon: Sliders },
  ]},
  { label: "LLM", icon: Cpu, children: [
    { href: "/llm-providers", label: "Providers", icon: Building2 },
    { href: "/llm-models", label: "Models", icon: Cpu },
    { href: "/llm-prompt-chains", label: "Prompt Chains", icon: Link2 },
    { href: "/llm-responses", label: "Responses", icon: MessageSquare },
  ]},
  { label: "Access", icon: MailCheck, children: [
    { href: "/allowed-domains", label: "Allowed Domains", icon: Globe },
    { href: "/whitelist-emails", label: "Whitelist Emails", icon: MailCheck },
  ]},
];

export default function Sidebar() {
  const path = usePathname();
  const router = useRouter();
  const [open, setOpen] = useState<string[]>(["Content", "Humor Engine", "LLM", "Access"]);

  const signOut = async () => { await createClient().auth.signOut(); router.push("/login"); };
  const toggleGroup = (label: string) => setOpen(prev => prev.includes(label) ? prev.filter(l => l !== label) : [...prev, label]);

  return (
    <aside style={{ position: "fixed", left: 0, top: 0, height: "100vh", width: "220px", background: "var(--dim)", borderRight: "1px solid var(--border)", display: "flex", flexDirection: "column", zIndex: 50, overflowY: "auto" }}>
      <div style={{ padding: "1.25rem 1.25rem 1rem", borderBottom: "1px solid var(--border)", flexShrink: 0 }}>
        <div style={{ display: "flex", alignItems: "center", gap: "8px", marginBottom: "4px" }}>
          <div style={{ width: "2px", height: "22px", background: "var(--acid)" }} />
          <span className="font-display" style={{ fontSize: "1.5rem", letterSpacing: "0.1em", color: "var(--paper)" }}>HUMOR</span>
        </div>
        <div style={{ display: "flex", alignItems: "center", gap: "6px", marginLeft: "10px" }}>
          <Zap size={9} color="var(--acid)" />
          <span className="mono" style={{ fontSize: "0.55rem", color: "var(--slate)", letterSpacing: "0.12em", textTransform: "uppercase" }}>Admin Panel</span>
        </div>
      </div>
      <nav style={{ flex: 1, padding: "0.75rem 0.6rem", display: "flex", flexDirection: "column", gap: "1px" }}>
        {nav.map((item) => {
          if ('children' in item) {
            const isOpen = open.includes(item.label);
            const Icon = item.icon;
            return (
              <div key={item.label}>
                <button onClick={() => toggleGroup(item.label)} style={{ display: "flex", alignItems: "center", justifyContent: "space-between", width: "100%", padding: "0.45rem 0.75rem", background: "none", border: "none", color: "var(--slate)", cursor: "pointer", borderRadius: "4px", fontFamily: "'JetBrains Mono', monospace", fontSize: "0.65rem", textTransform: "uppercase", letterSpacing: "0.08em", marginTop: "4px" }}>
                  <div style={{ display: "flex", alignItems: "center", gap: "8px" }}><Icon size={11} />{item.label}</div>
                  {isOpen ? <ChevronDown size={10} /> : <ChevronRight size={10} />}
                </button>
                {isOpen && (
                  <div style={{ paddingLeft: "8px" }}>
                    {(item.children || []).map(({ href, label, icon: CIcon }) => {
                      const active = path === href;
                      return (
                        <Link key={href} href={href} style={{ display: "flex", alignItems: "center", gap: "8px", padding: "0.4rem 0.75rem", borderRadius: "4px", background: active ? "rgba(184,247,35,0.07)" : "transparent", color: active ? "var(--acid)" : "var(--muted)", borderLeft: `2px solid ${active ? "var(--acid)" : "transparent"}`, textDecoration: "none", fontSize: "0.72rem", fontFamily: "'JetBrains Mono', monospace", transition: "all 0.1s" }}>
                          <CIcon size={11} />{label}
                        </Link>
                      );
                    })}
                  </div>
                )}
              </div>
            );
          }
          const active = path === item.href;
          const Icon = item.icon;
          return (
            <Link key={item.href} href={item.href} style={{ display: "flex", alignItems: "center", gap: "10px", padding: "0.5rem 0.75rem", borderRadius: "4px", background: active ? "rgba(184,247,35,0.07)" : "transparent", color: active ? "var(--acid)" : "var(--slate)", borderLeft: `2px solid ${active ? "var(--acid)" : "transparent"}`, textDecoration: "none", fontSize: "0.78rem", fontFamily: "'JetBrains Mono', monospace", transition: "all 0.15s" }}>
              <Icon size={13} />{item.label}
            </Link>
          );
        })}
      </nav>
      <div style={{ padding: "0.75rem", borderTop: "1px solid var(--border)", flexShrink: 0 }}>
        <button onClick={signOut} style={{ display: "flex", alignItems: "center", gap: "10px", padding: "0.5rem 0.75rem", width: "100%", background: "none", border: "none", color: "var(--slate)", cursor: "pointer", fontSize: "0.72rem", fontFamily: "'JetBrains Mono', monospace", borderRadius: "4px", transition: "color 0.15s" }}
          onMouseEnter={e => (e.currentTarget.style.color = "var(--rust)")}
          onMouseLeave={e => (e.currentTarget.style.color = "var(--slate)")}
        ><LogOut size={13} /> Sign Out</button>
      </div>
    </aside>
  );
}
