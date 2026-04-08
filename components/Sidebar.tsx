"use client";
import Link from "next/link";
import { usePathname, useRouter } from "next/navigation";
import { createClient } from "@/lib/supabase/client";
import { LayoutDashboard, Users, Image, MessageSquare, LogOut, BookOpen, FlaskConical, Sliders, FileText, Cpu, Building2, Link2, MailCheck, Globe, List, HelpCircle, ChevronDown, ChevronRight, BarChart } from "lucide-react";
import { useState } from "react";

const nav = [
  { href: "/dashboard", label: "Dashboard", icon: LayoutDashboard },
  { href: "/ratings", label: "Ratings", icon: BarChart },
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
    <aside style={{
      position: "fixed", left: 0, top: 0, height: "100vh", width: "220px",
      background: "white", borderRight: "1px solid var(--border)",
      display: "flex", flexDirection: "column", zIndex: 50, overflowY: "auto",
    }}>
      <div style={{ padding: "1.5rem 1.25rem 1.25rem", borderBottom: "1px solid var(--border)" }}>
        <div style={{ marginBottom: "2px" }}>
          <span style={{ fontFamily: "'Cormorant Garamond', serif", fontSize: "1.6rem", fontWeight: 400, color: "var(--deep)", letterSpacing: "0.04em", fontStyle: "italic" }}>
            Humor Study
          </span>
        </div>
        <p style={{ fontFamily: "'Jost', sans-serif", fontSize: "0.58rem", color: "var(--slate)", textTransform: "uppercase", letterSpacing: "0.14em" }}>
          Admin Panel
        </p>
      </div>

      <nav style={{ flex: 1, padding: "1rem 0.75rem", display: "flex", flexDirection: "column", gap: "2px" }}>
        {nav.map((item) => {
          if ('children' in item) {
            const isOpen = open.includes(item.label);
            const Icon = item.icon;
            return (
              <div key={item.label}>
                <button onClick={() => toggleGroup(item.label)} style={{
                  display: "flex", alignItems: "center", justifyContent: "space-between",
                  width: "100%", padding: "0.45rem 0.75rem", background: "none", border: "none",
                  color: "var(--slate)", cursor: "pointer", borderRadius: "8px",
                  fontFamily: "'Jost', sans-serif", fontSize: "0.65rem",
                  textTransform: "uppercase", letterSpacing: "0.1em", marginTop: "6px",
                }}>
                  <div style={{ display: "flex", alignItems: "center", gap: "8px" }}><Icon size={11} />{item.label}</div>
                  {isOpen ? <ChevronDown size={10} /> : <ChevronRight size={10} />}
                </button>
                {isOpen && (
                  <div style={{ paddingLeft: "8px" }}>
                    {(item.children || []).map(({ href, label, icon: CIcon }) => {
                      const active = path === href;
                      return (
                        <Link key={href} href={href} style={{
                          display: "flex", alignItems: "center", gap: "8px",
                          padding: "0.42rem 0.75rem", borderRadius: "8px",
                          background: active ? "var(--petal)" : "transparent",
                          color: active ? "var(--deep)" : "var(--slate)",
                          borderLeft: `2px solid ${active ? "var(--dusty)" : "transparent"}`,
                          textDecoration: "none", fontSize: "0.75rem",
                          fontFamily: "'DM Sans', sans-serif", transition: "all 0.15s",
                        }}>
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
            <Link key={item.href} href={item.href} style={{
              display: "flex", alignItems: "center", gap: "10px",
              padding: "0.5rem 0.75rem", borderRadius: "8px",
              background: active ? "var(--petal)" : "transparent",
              color: active ? "var(--deep)" : "var(--ink)",
              borderLeft: `2px solid ${active ? "var(--dusty)" : "transparent"}`,
              textDecoration: "none", fontSize: "0.82rem",
              fontFamily: "'DM Sans', sans-serif", fontWeight: active ? 500 : 400,
              transition: "all 0.15s",
            }}>
              <Icon size={13} />{item.label}
            </Link>
          );
        })}
      </nav>

      <div style={{ padding: "0.75rem", borderTop: "1px solid var(--border)" }}>
        <button onClick={signOut} style={{
          display: "flex", alignItems: "center", gap: "10px",
          padding: "0.5rem 0.75rem", width: "100%", background: "none", border: "none",
          color: "var(--slate)", cursor: "pointer", fontSize: "0.78rem",
          fontFamily: "'DM Sans', sans-serif", borderRadius: "8px", transition: "color 0.15s",
        }}
          onMouseEnter={e => (e.currentTarget.style.color = "var(--mauve)")}
          onMouseLeave={e => (e.currentTarget.style.color = "var(--slate)")}
        ><LogOut size={13} /> Sign out</button>
      </div>
    </aside>
  );
}
