#!/bin/bash
# Run from root of humor-project-admin
# Usage: bash coquette-theme.sh

echo "🎀 Applying coquette theme..."

cat > app/globals.css << 'EOF'
@import url('https://fonts.googleapis.com/css2?family=Cormorant+Garamond:ital,wght@0,300;0,400;0,500;1,300;1,400&family=DM+Sans:wght@300;400;500&family=Jost:wght@300;400;500&display=swap');

@tailwind base;
@tailwind components;
@tailwind utilities;

*, *::before, *::after { box-sizing: border-box; }

:root {
  --cream: #fdf8f2;
  --blush: #f9efe8;
  --petal: #f2ddd8;
  --rose: #e8b4b8;
  --dusty: #c9848a;
  --mauve: #9e5f6a;
  --deep: #6b3a44;
  --ink: #3d2128;
  --mist: #f5eee9;
  --border: #ead5cf;
  --border2: #dfc4bc;
  --slate: #a8888e;
  --card: #fefaf7;
  --gold: #c9956a;
  --sage: #8a9e8f;
}

body {
  background: var(--cream);
  color: var(--ink);
  font-family: 'DM Sans', sans-serif;
  -webkit-font-smoothing: antialiased;
}

::-webkit-scrollbar { width: 4px; height: 4px; }
::-webkit-scrollbar-track { background: var(--blush); }
::-webkit-scrollbar-thumb { background: var(--rose); border-radius: 2px; }

.font-display { font-family: 'Cormorant Garamond', serif; }
.mono { font-family: 'Jost', sans-serif; letter-spacing: 0.04em; }

.card {
  background: var(--card);
  border: 1px solid var(--border);
  border-radius: 12px;
}

.inp {
  background: var(--mist);
  border: 1px solid var(--border);
  color: var(--ink);
  padding: 0.6rem 0.875rem;
  font-family: 'DM Sans', sans-serif;
  font-size: 0.875rem;
  width: 100%;
  outline: none;
  border-radius: 8px;
  transition: border-color 0.15s;
}
.inp:focus { border-color: var(--dusty); }
.inp::placeholder { color: var(--slate); }

.btn {
  display: inline-flex; align-items: center; gap: 6px;
  font-family: 'Jost', sans-serif; font-size: 0.72rem; font-weight: 500;
  text-transform: uppercase; letter-spacing: 0.1em; padding: 0.55rem 1.25rem;
  border-radius: 50px; cursor: pointer; transition: all 0.2s; border: none;
}
.btn-primary { background: var(--dusty); color: white; }
.btn-primary:hover { background: var(--mauve); }
.btn-primary:disabled { opacity: 0.45; cursor: not-allowed; }
.btn-danger { background: transparent; color: var(--mauve); border: 1px solid var(--rose); border-radius: 50px; }
.btn-danger:hover { background: var(--petal); }
.btn-ghost { background: transparent; color: var(--slate); border: 1px solid var(--border2); border-radius: 50px; }
.btn-ghost:hover { border-color: var(--dusty); color: var(--ink); }

.tbl-head {
  display: grid; padding: 0.65rem 1.25rem;
  font-family: 'Jost', sans-serif; font-size: 0.62rem;
  text-transform: uppercase; letter-spacing: 0.1em; color: var(--slate);
  background: var(--blush); border-bottom: 1px solid var(--border);
  border-radius: 12px 12px 0 0;
}
.tbl-row {
  display: grid; padding: 0.75rem 1.25rem; border-bottom: 1px solid var(--border);
  align-items: center; transition: background 0.1s;
}
.tbl-row:hover { background: var(--mist); }
.tbl-row:last-child { border-bottom: none; }

.badge {
  display: inline-block; font-family: 'Jost', sans-serif; font-size: 0.6rem;
  text-transform: uppercase; letter-spacing: 0.08em; padding: 0.2rem 0.6rem; border-radius: 50px;
}
.badge-green { background: #eaf3e8; color: var(--sage); }
.badge-red { background: var(--petal); color: var(--mauve); }
.badge-blue { background: #e8ecf3; color: #7a8aaa; }
.badge-purple { background: #f0eaf5; color: #9b7ab8; }
.badge-gold { background: #f5ece3; color: var(--gold); }
.badge-gray { background: var(--blush); color: var(--slate); }

@keyframes fadeUp {
  from { opacity: 0; transform: translateY(6px); }
  to { opacity: 1; transform: translateY(0); }
}
.fade-up { animation: fadeUp 0.4s ease forwards; }
.fade-up-1 { animation: fadeUp 0.4s 0.05s ease both; }
.fade-up-2 { animation: fadeUp 0.4s 0.1s ease both; }
.fade-up-3 { animation: fadeUp 0.4s 0.15s ease both; }
.fade-up-4 { animation: fadeUp 0.4s 0.2s ease both; }
.fade-up-5 { animation: fadeUp 0.4s 0.25s ease both; }
.fade-up-6 { animation: fadeUp 0.4s 0.3s ease both; }
EOF

cat > components/Sidebar.tsx << 'EOF'
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
EOF

cat > app/login/page.tsx << 'EOF'
"use client";
import { useState, Suspense } from "react";
import { useSearchParams } from "next/navigation";
import { createClient } from "@/lib/supabase/client";

function LoginForm() {
  const params = useSearchParams();
  const errorParam = params.get("error");
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState(
    errorParam === "unauthorized" ? "Access denied — superadmin privileges required." :
    errorParam === "auth_callback" ? "Authentication error. Please try again." : ""
  );

  const handleGoogleLogin = async () => {
    setLoading(true);
    setError("");
    const supabase = createClient();
    const { error: e } = await supabase.auth.signInWithOAuth({
      provider: "google",
      options: { redirectTo: `${window.location.origin}/auth/callback` },
    });
    if (e) { setError(e.message); setLoading(false); }
  };

  return (
    <div style={{ minHeight: "100vh", background: "var(--cream)", display: "flex", alignItems: "center", justifyContent: "center" }}>
      <div style={{ width: "100%", maxWidth: "400px", padding: "0 1.5rem" }}>

        {/* Decorative top */}
        <div style={{ textAlign: "center", marginBottom: "2.5rem" }}>
          <div style={{ display: "inline-block", marginBottom: "1rem" }}>
            <div style={{ width: "48px", height: "1px", background: "var(--rose)", display: "inline-block", verticalAlign: "middle", marginRight: "12px" }} />
            <span style={{ fontFamily: "'Jost'", fontSize: "0.6rem", color: "var(--slate)", textTransform: "uppercase", letterSpacing: "0.2em" }}>Admin</span>
            <div style={{ width: "48px", height: "1px", background: "var(--rose)", display: "inline-block", verticalAlign: "middle", marginLeft: "12px" }} />
          </div>
          <h1 style={{ fontFamily: "'Cormorant Garamond', serif", fontSize: "3rem", fontWeight: 300, color: "var(--deep)", margin: "0 0 4px", fontStyle: "italic", letterSpacing: "0.02em" }}>
            Humor Study
          </h1>
          <p style={{ fontFamily: "'Jost'", fontSize: "0.6rem", color: "var(--slate)", textTransform: "uppercase", letterSpacing: "0.16em", margin: 0 }}>
            Control Panel
          </p>
        </div>

        {/* Card */}
        <div style={{ background: "white", border: "1px solid var(--border)", borderRadius: "16px", padding: "2rem 2rem 2.25rem" }}>
          <p style={{ fontSize: "0.88rem", color: "var(--slate)", marginBottom: "1.5rem", textAlign: "center", lineHeight: 1.6 }}>
            Sign in with your Google account to access the admin panel.
          </p>

          {error && (
            <div style={{ marginBottom: "1.25rem", padding: "0.75rem 1rem", background: "var(--petal)", border: "1px solid var(--rose)", color: "var(--mauve)", fontSize: "0.78rem", borderRadius: "8px", fontFamily: "'Jost'" }}>
              {error}
            </div>
          )}

          <button onClick={handleGoogleLogin} disabled={loading} style={{
            width: "100%", display: "flex", alignItems: "center", justifyContent: "center",
            gap: "12px", padding: "0.875rem", background: "var(--dusty)", color: "white",
            border: "none", borderRadius: "50px", cursor: loading ? "not-allowed" : "pointer",
            opacity: loading ? 0.7 : 1, fontFamily: "'Jost', sans-serif",
            fontSize: "0.75rem", fontWeight: 500, textTransform: "uppercase",
            letterSpacing: "0.1em", transition: "all 0.2s",
          }}
            onMouseEnter={e => { if (!loading) e.currentTarget.style.background = "var(--mauve)"; }}
            onMouseLeave={e => { e.currentTarget.style.background = "var(--dusty)"; }}
          >
            {!loading && (
              <svg width="16" height="16" viewBox="0 0 24 24">
                <path fill="#fff" d="M22.56 12.25c0-.78-.07-1.53-.2-2.25H12v4.26h5.92c-.26 1.37-1.04 2.53-2.21 3.31v2.77h3.57c2.08-1.92 3.28-4.74 3.28-8.09z"/>
                <path fill="rgba(255,255,255,0.8)" d="M12 23c2.97 0 5.46-.98 7.28-2.66l-3.57-2.77c-.98.66-2.23 1.06-3.71 1.06-2.86 0-5.29-1.93-6.16-4.53H2.18v2.84C3.99 20.53 7.7 23 12 23z"/>
                <path fill="rgba(255,255,255,0.6)" d="M5.84 14.09c-.22-.66-.35-1.36-.35-2.09s.13-1.43.35-2.09V7.07H2.18C1.43 8.55 1 10.22 1 12s.43 3.45 1.18 4.93l2.85-2.22.81-.62z"/>
                <path fill="rgba(255,255,255,0.9)" d="M12 5.38c1.62 0 3.06.56 4.21 1.64l3.15-3.15C17.45 2.09 14.97 1 12 1 7.7 1 3.99 3.47 2.18 7.07l3.66 2.84c.87-2.6 3.3-4.53 6.16-4.53z"/>
              </svg>
            )}
            {loading ? "Redirecting..." : "Continue with Google"}
          </button>
        </div>

        <p style={{ textAlign: "center", marginTop: "1.5rem", fontSize: "0.68rem", color: "var(--slate)", fontFamily: "'Jost'", letterSpacing: "0.1em", textTransform: "uppercase" }}>
          Restricted to superadmins only
        </p>
      </div>
    </div>
  );
}

export default function LoginPage() {
  return (
    <Suspense fallback={<div style={{ minHeight: "100vh", background: "var(--cream)" }} />}>
      <LoginForm />
    </Suspense>
  );
}
EOF

echo ""
echo "✅ Coquette theme applied!"
echo ""
echo "Now run:"
echo "  git add ."
echo "  git commit -m 'feat: coquette theme redesign'"
echo "  git push origin main"
