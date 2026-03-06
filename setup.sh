#!/bin/bash

# Run this from the root of your humor-project-admin repo
# Usage: bash setup.sh

echo "🚀 Setting up Humor Admin Panel..."

# Install dependencies
echo "📦 Installing dependencies..."
npm install @supabase/supabase-js @supabase/ssr recharts lucide-react

# Create directories
mkdir -p app/login
mkdir -p app/dashboard
mkdir -p app/users
mkdir -p app/images
mkdir -p app/captions
mkdir -p app/api/auth/callback
mkdir -p components
mkdir -p lib/supabase

echo "📝 Writing files..."

# ============================================================
# tailwind.config.js
# ============================================================
cat > tailwind.config.js << 'EOF'
/** @type {import('tailwindcss').Config} */
module.exports = {
  content: ["./app/**/*.{ts,tsx}", "./components/**/*.{ts,tsx}"],
  theme: {
    extend: {
      fontFamily: {
        display: ["'Bebas Neue'", "cursive"],
        mono: ["'JetBrains Mono'", "monospace"],
        body: ["'DM Sans'", "sans-serif"],
      },
    },
  },
  plugins: [],
};
EOF

# ============================================================
# middleware.ts
# ============================================================
cat > middleware.ts << 'EOF'
import { createServerClient } from "@supabase/ssr";
import { NextResponse, type NextRequest } from "next/server";

export async function middleware(request: NextRequest) {
  let supabaseResponse = NextResponse.next({ request });

  const supabase = createServerClient(
    process.env.NEXT_PUBLIC_SUPABASE_URL!,
    process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY!,
    {
      cookies: {
        getAll() { return request.cookies.getAll(); },
        setAll(cookiesToSet) {
          cookiesToSet.forEach(({ name, value }) => request.cookies.set(name, value));
          supabaseResponse = NextResponse.next({ request });
          cookiesToSet.forEach(({ name, value, options }) =>
            supabaseResponse.cookies.set(name, value, options)
          );
        },
      },
    }
  );

  const { data: { user } } = await supabase.auth.getUser();

  const isLoginPage = request.nextUrl.pathname === "/login";
  const isPublic = request.nextUrl.pathname.startsWith("/_next") ||
    request.nextUrl.pathname.startsWith("/api/auth") ||
    request.nextUrl.pathname === "/favicon.ico";

  if (isPublic) return supabaseResponse;

  if (!user && !isLoginPage) {
    const url = request.nextUrl.clone();
    url.pathname = "/login";
    return NextResponse.redirect(url);
  }

  if (user && !isLoginPage) {
    const { data: profile } = await supabase
      .from("profiles")
      .select("is_superadmin")
      .eq("id", user.id)
      .single();

    if (!profile?.is_superadmin) {
      const url = request.nextUrl.clone();
      url.pathname = "/login";
      url.searchParams.set("error", "unauthorized");
      return NextResponse.redirect(url);
    }
  }

  if (user && isLoginPage) {
    const { data: profile } = await supabase
      .from("profiles")
      .select("is_superadmin")
      .eq("id", user.id)
      .single();
    if (profile?.is_superadmin) {
      const url = request.nextUrl.clone();
      url.pathname = "/dashboard";
      return NextResponse.redirect(url);
    }
  }

  return supabaseResponse;
}

export const config = {
  matcher: ["/((?!_next/static|_next/image|favicon.ico|.*\\.(?:svg|png|jpg|jpeg|gif|webp)$).*)"],
};
EOF

# ============================================================
# lib/supabase/client.ts
# ============================================================
cat > lib/supabase/client.ts << 'EOF'
import { createBrowserClient } from "@supabase/ssr";

export function createClient() {
  return createBrowserClient(
    process.env.NEXT_PUBLIC_SUPABASE_URL!,
    process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY!
  );
}
EOF

# ============================================================
# lib/supabase/server.ts
# ============================================================
cat > lib/supabase/server.ts << 'EOF'
import { createServerClient } from "@supabase/ssr";
import { cookies } from "next/headers";

export async function createClient() {
  const cookieStore = await cookies();
  return createServerClient(
    process.env.NEXT_PUBLIC_SUPABASE_URL!,
    process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY!,
    {
      cookies: {
        getAll() { return cookieStore.getAll(); },
        setAll(cookiesToSet) {
          try {
            cookiesToSet.forEach(({ name, value, options }) =>
              cookieStore.set(name, value, options)
            );
          } catch {}
        },
      },
    }
  );
}
EOF

# ============================================================
# app/globals.css
# ============================================================
cat > app/globals.css << 'EOF'
@import url('https://fonts.googleapis.com/css2?family=Bebas+Neue&family=DM+Sans:ital,opsz,wght@0,9..40,300;0,9..40,400;0,9..40,500;0,9..40,600;1,9..40,400&family=JetBrains+Mono:wght@400;500&display=swap');

@tailwind base;
@tailwind components;
@tailwind utilities;

*, *::before, *::after { box-sizing: border-box; }

:root {
  --ink: #080810;
  --dim: #111118;
  --card: #16161f;
  --border: #222232;
  --border2: #2e2e42;
  --slate: #6b7280;
  --muted: #9ca3af;
  --paper: #f0ece3;
  --acid: #b8f723;
  --rust: #f04f23;
  --blue: #4f8ef0;
  --purple: #9b6dff;
  --gold: #f0b823;
}

body {
  background: var(--ink);
  color: var(--paper);
  font-family: 'DM Sans', sans-serif;
  -webkit-font-smoothing: antialiased;
}

::-webkit-scrollbar { width: 3px; height: 3px; }
::-webkit-scrollbar-track { background: var(--dim); }
::-webkit-scrollbar-thumb { background: var(--border2); border-radius: 2px; }

.card { background: var(--card); border: 1px solid var(--border); border-radius: 6px; }

.inp {
  background: var(--dim); border: 1px solid var(--border); color: var(--paper);
  padding: 0.6rem 0.875rem; font-family: 'DM Sans', sans-serif; font-size: 0.875rem;
  width: 100%; outline: none; border-radius: 4px; transition: border-color 0.15s;
}
.inp:focus { border-color: var(--acid); }
.inp::placeholder { color: var(--slate); }

.btn {
  display: inline-flex; align-items: center; gap: 6px;
  font-family: 'JetBrains Mono', monospace; font-size: 0.7rem; font-weight: 500;
  text-transform: uppercase; letter-spacing: 0.06em; padding: 0.55rem 1.1rem;
  border-radius: 3px; cursor: pointer; transition: all 0.15s; border: none;
}
.btn-primary { background: var(--acid); color: var(--ink); }
.btn-primary:hover { opacity: 0.88; }
.btn-primary:disabled { opacity: 0.35; cursor: not-allowed; }
.btn-danger { background: transparent; color: var(--rust); border: 1px solid var(--rust); }
.btn-danger:hover { background: var(--rust); color: white; }
.btn-ghost { background: transparent; color: var(--muted); border: 1px solid var(--border2); }
.btn-ghost:hover { border-color: var(--muted); color: var(--paper); }

.tbl-head {
  display: grid; padding: 0.6rem 1.25rem;
  font-family: 'JetBrains Mono', monospace; font-size: 0.6rem;
  text-transform: uppercase; letter-spacing: 0.1em; color: var(--slate);
  background: rgba(255,255,255,0.02); border-bottom: 1px solid var(--border);
}
.tbl-row {
  display: grid; padding: 0.75rem 1.25rem; border-bottom: 1px solid var(--border);
  align-items: center; transition: background 0.1s;
}
.tbl-row:hover { background: rgba(255,255,255,0.015); }
.tbl-row:last-child { border-bottom: none; }

.badge {
  display: inline-block; font-family: 'JetBrains Mono', monospace; font-size: 0.6rem;
  text-transform: uppercase; letter-spacing: 0.08em; padding: 0.2rem 0.5rem; border-radius: 3px;
}
.badge-green { background: rgba(184,247,35,0.12); color: var(--acid); }
.badge-red { background: rgba(240,79,35,0.12); color: var(--rust); }
.badge-blue { background: rgba(79,142,240,0.12); color: var(--blue); }
.badge-purple { background: rgba(155,109,255,0.12); color: var(--purple); }
.badge-gold { background: rgba(240,184,35,0.12); color: var(--gold); }
.badge-gray { background: rgba(107,114,128,0.15); color: var(--muted); }

.mono { font-family: 'JetBrains Mono', monospace; }

@keyframes fadeUp {
  from { opacity: 0; transform: translateY(6px); }
  to { opacity: 1; transform: translateY(0); }
}
.fade-up { animation: fadeUp 0.35s ease forwards; }
.fade-up-1 { animation: fadeUp 0.35s 0.04s ease both; }
.fade-up-2 { animation: fadeUp 0.35s 0.08s ease both; }
.fade-up-3 { animation: fadeUp 0.35s 0.12s ease both; }
.fade-up-4 { animation: fadeUp 0.35s 0.16s ease both; }
.fade-up-5 { animation: fadeUp 0.35s 0.20s ease both; }
.fade-up-6 { animation: fadeUp 0.35s 0.24s ease both; }
EOF

# ============================================================
# app/layout.tsx
# ============================================================
cat > app/layout.tsx << 'EOF'
import type { Metadata } from "next";
import "./globals.css";

export const metadata: Metadata = {
  title: "Humor Study — Admin",
  description: "Superadmin control panel",
};

export default function RootLayout({ children }: { children: React.ReactNode }) {
  return (
    <html lang="en">
      <body>{children}</body>
    </html>
  );
}
EOF

# ============================================================
# app/page.tsx
# ============================================================
cat > app/page.tsx << 'EOF'
import { redirect } from "next/navigation";
export default function Home() { redirect("/dashboard"); }
EOF

# ============================================================
# app/api/auth/callback/route.ts
# ============================================================
cat > app/api/auth/callback/route.ts << 'EOF'
import { createClient } from "@/lib/supabase/server";
import { NextResponse } from "next/server";

export async function GET(request: Request) {
  const { searchParams, origin } = new URL(request.url);
  const code = searchParams.get("code");
  if (code) {
    const supabase = await createClient();
    const { error } = await supabase.auth.exchangeCodeForSession(code);
    if (!error) return NextResponse.redirect(`${origin}/dashboard`);
  }
  return NextResponse.redirect(`${origin}/login?error=auth_callback`);
}
EOF

# ============================================================
# app/login/page.tsx
# ============================================================
cat > app/login/page.tsx << 'EOF'
"use client";
import { useState, useEffect, Suspense } from "react";
import { useRouter, useSearchParams } from "next/navigation";
import { createClient } from "@/lib/supabase/client";

function LoginForm() {
  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState("");
  const router = useRouter();
  const params = useSearchParams();

  useEffect(() => {
    if (params.get("error") === "unauthorized") setError("Access denied — superadmin privileges required.");
    if (params.get("error") === "auth_callback") setError("Authentication error. Please try again.");
  }, [params]);

  const handleLogin = async () => {
    if (!email || !password) return;
    setLoading(true);
    setError("");
    const supabase = createClient();
    const { error: e } = await supabase.auth.signInWithPassword({ email, password });
    if (e) { setError(e.message); setLoading(false); return; }
    router.push("/dashboard");
    router.refresh();
  };

  return (
    <div style={{ minHeight: "100vh", background: "var(--ink)", display: "flex", alignItems: "center", justifyContent: "center" }}>
      <div style={{ width: "100%", maxWidth: "380px", padding: "0 1rem" }} className="fade-up">
        <div style={{ textAlign: "center", marginBottom: "2.5rem" }}>
          <div style={{ display: "inline-flex", alignItems: "center", gap: "10px", marginBottom: "0.5rem" }}>
            <div style={{ width: "3px", height: "32px", background: "var(--acid)" }} />
            <span className="font-display" style={{ fontSize: "2.25rem", letterSpacing: "0.12em", color: "var(--paper)" }}>HUMOR</span>
            <span className="font-display" style={{ fontSize: "2.25rem", letterSpacing: "0.12em", color: "var(--rust)" }}>STUDY</span>
            <div style={{ width: "3px", height: "32px", background: "var(--rust)" }} />
          </div>
          <p className="mono" style={{ fontSize: "0.6rem", color: "var(--slate)", letterSpacing: "0.15em", textTransform: "uppercase" }}>
            Admin Control Panel
          </p>
        </div>
        <div className="card" style={{ padding: "2rem" }}>
          <div style={{ marginBottom: "1.25rem" }}>
            <label className="mono" style={{ display: "block", fontSize: "0.6rem", color: "var(--slate)", textTransform: "uppercase", letterSpacing: "0.1em", marginBottom: "0.5rem" }}>Email</label>
            <input type="email" className="inp" placeholder="you@university.edu" value={email}
              onChange={e => setEmail(e.target.value)} onKeyDown={e => e.key === "Enter" && handleLogin()} />
          </div>
          <div style={{ marginBottom: "1.5rem" }}>
            <label className="mono" style={{ display: "block", fontSize: "0.6rem", color: "var(--slate)", textTransform: "uppercase", letterSpacing: "0.1em", marginBottom: "0.5rem" }}>Password</label>
            <input type="password" className="inp" placeholder="••••••••••" value={password}
              onChange={e => setPassword(e.target.value)} onKeyDown={e => e.key === "Enter" && handleLogin()} />
          </div>
          {error && (
            <div className="mono" style={{ marginBottom: "1.25rem", padding: "0.75rem", background: "rgba(240,79,35,0.08)", border: "1px solid rgba(240,79,35,0.25)", color: "var(--rust)", fontSize: "0.7rem", borderRadius: "3px" }}>
              {error}
            </div>
          )}
          <button className="btn btn-primary" style={{ width: "100%", justifyContent: "center", padding: "0.75rem" }}
            onClick={handleLogin} disabled={loading || !email || !password}>
            {loading ? "Authenticating..." : "Sign In →"}
          </button>
        </div>
        <p className="mono" style={{ textAlign: "center", marginTop: "1.5rem", fontSize: "0.6rem", color: "var(--slate)", letterSpacing: "0.08em" }}>
          Restricted to superadmins only
        </p>
      </div>
    </div>
  );
}

export default function LoginPage() {
  return (
    <Suspense fallback={<div style={{ minHeight: "100vh", background: "var(--ink)" }} />}>
      <LoginForm />
    </Suspense>
  );
}
EOF

# ============================================================
# components/Sidebar.tsx
# ============================================================
cat > components/Sidebar.tsx << 'EOF'
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
EOF

# ============================================================
# app/dashboard/page.tsx
# ============================================================
cat > app/dashboard/page.tsx << 'EOF'
import { createClient } from "@/lib/supabase/server";
import Sidebar from "@/components/Sidebar";
import DashboardClient from "./DashboardClient";

export const dynamic = "force-dynamic";

export default async function DashboardPage() {
  const sb = await createClient();

  const [
    { count: totalUsers },
    { count: totalImages },
    { count: totalCaptions },
    { count: totalVotes },
    { count: totalLikes },
    { count: bugReports },
    { count: studyUsers },
    { count: publicCaptions },
    { count: featuredCaptions },
    { data: captionsByDay },
    { data: topCaptions },
    { data: recentBugs },
    { data: flavorBreakdown },
  ] = await Promise.all([
    sb.from("profiles").select("*", { count: "exact", head: true }),
    sb.from("images").select("*", { count: "exact", head: true }),
    sb.from("captions").select("*", { count: "exact", head: true }),
    sb.from("caption_votes").select("*", { count: "exact", head: true }),
    sb.from("caption_likes").select("*", { count: "exact", head: true }),
    sb.from("bug_reports").select("*", { count: "exact", head: true }),
    sb.from("profiles").select("*", { count: "exact", head: true }).eq("is_in_study", true),
    sb.from("captions").select("*", { count: "exact", head: true }).eq("is_public", true),
    sb.from("captions").select("*", { count: "exact", head: true }).eq("is_featured", true),
    sb.from("captions").select("created_datetime_utc")
      .gte("created_datetime_utc", new Date(Date.now() - 21 * 86400000).toISOString())
      .order("created_datetime_utc", { ascending: true }),
    sb.from("captions").select("id, content, like_count, is_featured, is_public")
      .order("like_count", { ascending: false }).limit(5),
    sb.from("bug_reports").select("id, subject, created_datetime_utc")
      .order("created_datetime_utc", { ascending: false }).limit(4),
    sb.from("captions").select("humor_flavor_id, humor_flavors(slug)")
      .not("humor_flavor_id", "is", null).limit(500),
  ]);

  const days = Array.from({ length: 21 }, (_, i) => {
    const d = new Date(); d.setDate(d.getDate() - (20 - i));
    return d.toISOString().split("T")[0];
  });
  const dayMap: Record<string, number> = {};
  (captionsByDay || []).forEach(c => {
    const day = c.created_datetime_utc?.split("T")[0];
    if (day) dayMap[day] = (dayMap[day] || 0) + 1;
  });
  const chartData = days.map(d => ({ day: d.slice(5), count: dayMap[d] || 0 }));

  const flavorMap: Record<string, number> = {};
  (flavorBreakdown || []).forEach((c: { humor_flavor_id: number | null; humor_flavors: { slug: string } | null }) => {
    const slug = (c.humor_flavors as { slug: string } | null)?.slug || `flavor_${c.humor_flavor_id}`;
    flavorMap[slug] = (flavorMap[slug] || 0) + 1;
  });
  const flavorData = Object.entries(flavorMap).sort((a, b) => b[1] - a[1]).slice(0, 6)
    .map(([slug, count]) => ({ slug, count }));

  return (
    <div style={{ display: "flex", minHeight: "100vh" }}>
      <Sidebar />
      <main style={{ flex: 1, marginLeft: "220px", padding: "2.5rem 2rem" }}>
        <DashboardClient stats={{
          totalUsers: totalUsers || 0, totalImages: totalImages || 0,
          totalCaptions: totalCaptions || 0, totalVotes: totalVotes || 0,
          totalLikes: totalLikes || 0, bugReports: bugReports || 0,
          studyUsers: studyUsers || 0, publicCaptions: publicCaptions || 0,
          featuredCaptions: featuredCaptions || 0,
          chartData, topCaptions: topCaptions || [],
          recentBugs: recentBugs || [], flavorData,
        }} />
      </main>
    </div>
  );
}
EOF

# ============================================================
# app/dashboard/DashboardClient.tsx
# ============================================================
cat > app/dashboard/DashboardClient.tsx << 'EOF'
"use client";
import { AreaChart, Area, BarChart, Bar, XAxis, YAxis, Tooltip, ResponsiveContainer, Cell } from "recharts";
import { Users, Image, MessageSquare, ThumbsUp, Heart, Bug, Star, Globe } from "lucide-react";

interface Stats {
  totalUsers: number; totalImages: number; totalCaptions: number;
  totalVotes: number; totalLikes: number; bugReports: number;
  studyUsers: number; publicCaptions: number; featuredCaptions: number;
  chartData: { day: string; count: number }[];
  topCaptions: { id: string; content: string | null; like_count: number | null; is_featured: boolean | null; is_public: boolean | null }[];
  recentBugs: { id: number; subject: string | null; created_datetime_utc: string | null }[];
  flavorData: { slug: string; count: number }[];
}

const COLORS = ["#b8f723", "#4f8ef0", "#9b6dff", "#f0b823", "#f04f23", "#4ade80"];

const Tip = ({ active, payload, label }: { active?: boolean; payload?: { value: number }[]; label?: string }) => {
  if (!active || !payload?.length) return null;
  return (
    <div style={{ background: "var(--card)", border: "1px solid var(--border2)", padding: "0.5rem 0.75rem", borderRadius: "4px" }}>
      <p className="mono" style={{ fontSize: "0.65rem", color: "var(--slate)", marginBottom: "2px" }}>{label}</p>
      <p className="mono" style={{ fontSize: "0.75rem", color: "var(--acid)" }}>{payload[0].value} captions</p>
    </div>
  );
};

const FlavorTip = ({ active, payload }: { active?: boolean; payload?: { value: number; payload: { slug: string } }[] }) => {
  if (!active || !payload?.length) return null;
  return (
    <div style={{ background: "var(--card)", border: "1px solid var(--border2)", padding: "0.5rem 0.75rem", borderRadius: "4px" }}>
      <p className="mono" style={{ fontSize: "0.65rem", color: "var(--slate)" }}>{payload[0].payload.slug}</p>
      <p className="mono" style={{ fontSize: "0.75rem", color: "var(--acid)" }}>{payload[0].value}</p>
    </div>
  );
};

function StatCard({ icon: Icon, label, value, sub, color, delay }: {
  icon: React.ElementType; label: string; value: string | number; sub?: string; color: string; delay: number;
}) {
  return (
    <div className={`card fade-up-${delay}`} style={{ padding: "1.25rem 1.5rem", position: "relative", overflow: "hidden" }}>
      <div style={{ position: "absolute", top: "-20px", right: "-20px", width: "80px", height: "80px", borderRadius: "50%", background: color, opacity: 0.06 }} />
      <div style={{ display: "flex", justifyContent: "space-between", alignItems: "flex-start", marginBottom: "1rem" }}>
        <div style={{ padding: "6px", borderRadius: "4px", background: `${color}18`, color }}><Icon size={14} /></div>
        <span className="mono" style={{ fontSize: "0.58rem", color: "var(--slate)", textTransform: "uppercase", letterSpacing: "0.1em" }}>{label}</span>
      </div>
      <div className="font-display" style={{ fontSize: "2.75rem", color: "var(--paper)", letterSpacing: "0.02em", lineHeight: 1 }}>
        {typeof value === "number" ? value.toLocaleString() : value}
      </div>
      {sub && <div className="mono" style={{ fontSize: "0.62rem", color: "var(--slate)", marginTop: "4px" }}>{sub}</div>}
    </div>
  );
}

export default function DashboardClient({ stats }: { stats: Stats }) {
  const { totalUsers, totalImages, totalCaptions, totalVotes, totalLikes, bugReports,
    studyUsers, publicCaptions, featuredCaptions, chartData, topCaptions, recentBugs, flavorData } = stats;

  const studyPct = totalUsers > 0 ? Math.round((studyUsers / totalUsers) * 100) : 0;
  const publicPct = totalCaptions > 0 ? Math.round((publicCaptions / totalCaptions) * 100) : 0;
  const avgVotes = totalCaptions > 0 ? (totalVotes / totalCaptions).toFixed(1) : "0";

  return (
    <div>
      <div className="fade-up" style={{ marginBottom: "2.5rem" }}>
        <div style={{ display: "flex", alignItems: "center", gap: "10px", marginBottom: "6px" }}>
          <div style={{ width: "28px", height: "1px", background: "var(--acid)" }} />
          <span className="mono" style={{ fontSize: "0.6rem", color: "var(--acid)", textTransform: "uppercase", letterSpacing: "0.12em" }}>Overview</span>
        </div>
        <h1 className="font-display" style={{ fontSize: "4rem", color: "var(--paper)", letterSpacing: "0.04em", lineHeight: 1 }}>DASHBOARD</h1>
        <p style={{ color: "var(--slate)", fontSize: "0.85rem", marginTop: "6px" }}>Platform health at a glance</p>
      </div>

      <div style={{ display: "grid", gridTemplateColumns: "repeat(4, 1fr)", gap: "12px", marginBottom: "12px" }}>
        <StatCard icon={Users} label="Total Users" value={totalUsers} sub={`${studyUsers} in study (${studyPct}%)`} color="var(--acid)" delay={1} />
        <StatCard icon={Image} label="Images" value={totalImages} sub="in library" color="var(--blue)" delay={2} />
        <StatCard icon={MessageSquare} label="Captions" value={totalCaptions} sub={`${publicPct}% public`} color="var(--purple)" delay={3} />
        <StatCard icon={ThumbsUp} label="Votes Cast" value={totalVotes} sub={`${avgVotes} avg per caption`} color="var(--gold)" delay={4} />
      </div>
      <div style={{ display: "grid", gridTemplateColumns: "repeat(4, 1fr)", gap: "12px", marginBottom: "2rem" }}>
        <StatCard icon={Heart} label="Caption Likes" value={totalLikes} sub="total engagements" color="var(--rust)" delay={1} />
        <StatCard icon={Star} label="Featured" value={featuredCaptions} sub="hand-picked captions" color="var(--gold)" delay={2} />
        <StatCard icon={Globe} label="Public Captions" value={publicCaptions} sub="visible to all" color="var(--blue)" delay={3} />
        <StatCard icon={Bug} label="Bug Reports" value={bugReports} sub="submitted reports" color="var(--rust)" delay={4} />
      </div>

      <div style={{ display: "grid", gridTemplateColumns: "2fr 1fr", gap: "16px", marginBottom: "16px" }}>
        <div className="card fade-up-5" style={{ padding: "1.5rem" }}>
          <p className="mono" style={{ fontSize: "0.58rem", color: "var(--slate)", textTransform: "uppercase", letterSpacing: "0.1em", marginBottom: "4px" }}>Activity</p>
          <h2 className="font-display" style={{ fontSize: "1.5rem", color: "var(--paper)", marginBottom: "1.25rem" }}>CAPTION VOLUME — 21 DAYS</h2>
          <ResponsiveContainer width="100%" height={200}>
            <AreaChart data={chartData} margin={{ top: 5, right: 5, left: -25, bottom: 0 }}>
              <defs>
                <linearGradient id="grad" x1="0" y1="0" x2="0" y2="1">
                  <stop offset="0%" stopColor="#b8f723" stopOpacity={0.25} />
                  <stop offset="100%" stopColor="#b8f723" stopOpacity={0} />
                </linearGradient>
              </defs>
              <XAxis dataKey="day" tick={{ fill: "var(--slate)", fontFamily: "'JetBrains Mono'", fontSize: 9 }} axisLine={false} tickLine={false} interval={3} />
              <YAxis tick={{ fill: "var(--slate)", fontFamily: "'JetBrains Mono'", fontSize: 9 }} axisLine={false} tickLine={false} allowDecimals={false} />
              <Tooltip content={<Tip />} />
              <Area type="monotone" dataKey="count" stroke="#b8f723" strokeWidth={1.5} fill="url(#grad)" dot={false} />
            </AreaChart>
          </ResponsiveContainer>
        </div>
        <div className="card fade-up-6" style={{ padding: "1.5rem" }}>
          <p className="mono" style={{ fontSize: "0.58rem", color: "var(--slate)", textTransform: "uppercase", letterSpacing: "0.1em", marginBottom: "4px" }}>Distribution</p>
          <h2 className="font-display" style={{ fontSize: "1.5rem", color: "var(--paper)", marginBottom: "1.25rem" }}>HUMOR FLAVORS</h2>
          {flavorData.length === 0 ? <p style={{ color: "var(--slate)", fontSize: "0.8rem" }}>No flavor data yet.</p> : (
            <ResponsiveContainer width="100%" height={200}>
              <BarChart data={flavorData} layout="vertical" margin={{ top: 0, right: 10, left: 0, bottom: 0 }}>
                <XAxis type="number" tick={{ fill: "var(--slate)", fontFamily: "'JetBrains Mono'", fontSize: 9 }} axisLine={false} tickLine={false} />
                <YAxis type="category" dataKey="slug" tick={{ fill: "var(--muted)", fontFamily: "'JetBrains Mono'", fontSize: 9 }} axisLine={false} tickLine={false} width={80} />
                <Tooltip content={<FlavorTip />} />
                <Bar dataKey="count" radius={[0, 3, 3, 0]}>
                  {flavorData.map((_, i) => <Cell key={i} fill={COLORS[i % COLORS.length]} />)}
                </Bar>
              </BarChart>
            </ResponsiveContainer>
          )}
        </div>
      </div>

      <div style={{ display: "grid", gridTemplateColumns: "1fr 1fr", gap: "16px" }}>
        <div className="card" style={{ padding: "1.5rem" }}>
          <p className="mono" style={{ fontSize: "0.58rem", color: "var(--slate)", textTransform: "uppercase", letterSpacing: "0.1em", marginBottom: "3px" }}>Leaderboard</p>
          <h2 className="font-display" style={{ fontSize: "1.25rem", color: "var(--paper)", marginBottom: "1rem" }}>TOP CAPTIONS</h2>
          {topCaptions.length === 0 ? <p style={{ color: "var(--slate)", fontSize: "0.8rem" }}>No captions yet.</p> : topCaptions.map((cap, i) => (
            <div key={cap.id} style={{ display: "flex", gap: "12px", alignItems: "flex-start", padding: "0.6rem 0", borderBottom: i < topCaptions.length - 1 ? "1px solid var(--border)" : "none" }}>
              <span className="font-display" style={{ fontSize: "1.5rem", color: "var(--border2)", minWidth: "24px", lineHeight: 1, marginTop: "2px" }}>{String(i + 1).padStart(2, "0")}</span>
              <div style={{ flex: 1, minWidth: 0 }}>
                <p style={{ fontSize: "0.82rem", color: "var(--paper)", overflow: "hidden", textOverflow: "ellipsis", whiteSpace: "nowrap", marginBottom: "4px" }}>&ldquo;{cap.content || "—"}&rdquo;</p>
                <div style={{ display: "flex", gap: "6px" }}>
                  <span className="badge badge-green">{cap.like_count ?? 0} likes</span>
                  {cap.is_featured && <span className="badge badge-gold">Featured</span>}
                  {cap.is_public ? <span className="badge badge-blue">Public</span> : <span className="badge badge-gray">Private</span>}
                </div>
              </div>
            </div>
          ))}
        </div>
        <div className="card" style={{ padding: "1.5rem" }}>
          <p className="mono" style={{ fontSize: "0.58rem", color: "var(--slate)", textTransform: "uppercase", letterSpacing: "0.1em", marginBottom: "3px" }}>Support</p>
          <h2 className="font-display" style={{ fontSize: "1.25rem", color: "var(--paper)", marginBottom: "1rem" }}>RECENT BUG REPORTS</h2>
          {recentBugs.length === 0 ? (
            <div style={{ display: "flex", flexDirection: "column", alignItems: "center", justifyContent: "center", height: "120px" }}>
              <p style={{ color: "var(--acid)", fontSize: "0.85rem" }}>✓ No bugs reported</p>
            </div>
          ) : recentBugs.map((bug, i) => (
            <div key={bug.id} style={{ padding: "0.6rem 0", borderBottom: i < recentBugs.length - 1 ? "1px solid var(--border)" : "none" }}>
              <div style={{ display: "flex", justifyContent: "space-between", marginBottom: "3px" }}>
                <p style={{ fontSize: "0.82rem", color: "var(--paper)", fontWeight: 500 }}>{bug.subject || "No subject"}</p>
                <span className="badge badge-red">Open</span>
              </div>
              <p className="mono" style={{ fontSize: "0.62rem", color: "var(--slate)" }}>
                {bug.created_datetime_utc ? new Date(bug.created_datetime_utc).toLocaleDateString() : "—"}
              </p>
            </div>
          ))}
        </div>
      </div>
    </div>
  );
}
EOF

# ============================================================
# app/users/page.tsx
# ============================================================
cat > app/users/page.tsx << 'EOF'
import { createClient } from "@/lib/supabase/server";
import Sidebar from "@/components/Sidebar";

export const dynamic = "force-dynamic";

export default async function UsersPage() {
  const sb = await createClient();
  const { data: profiles, error } = await sb
    .from("profiles")
    .select("id, first_name, last_name, email, is_superadmin, is_in_study, is_matrix_admin, created_datetime_utc")
    .order("created_datetime_utc", { ascending: false });

  return (
    <div style={{ display: "flex", minHeight: "100vh" }}>
      <Sidebar />
      <main style={{ flex: 1, marginLeft: "220px", padding: "2.5rem 2rem" }}>
        <div className="fade-up" style={{ marginBottom: "2.5rem" }}>
          <div style={{ display: "flex", alignItems: "center", gap: "10px", marginBottom: "6px" }}>
            <div style={{ width: "28px", height: "1px", background: "var(--acid)" }} />
            <span className="mono" style={{ fontSize: "0.6rem", color: "var(--acid)", textTransform: "uppercase", letterSpacing: "0.12em" }}>Read-only</span>
          </div>
          <h1 className="font-display" style={{ fontSize: "4rem", color: "var(--paper)", letterSpacing: "0.04em", lineHeight: 1 }}>USERS</h1>
          <p style={{ color: "var(--slate)", fontSize: "0.85rem", marginTop: "6px" }}>{profiles?.length ?? 0} registered profiles</p>
        </div>
        {error && <div className="mono" style={{ marginBottom: "1rem", padding: "0.75rem 1rem", background: "rgba(240,79,35,0.08)", border: "1px solid rgba(240,79,35,0.25)", color: "var(--rust)", fontSize: "0.75rem", borderRadius: "4px" }}>Error: {error.message}</div>}
        <div className="card fade-up-1">
          <div className="tbl-head" style={{ gridTemplateColumns: "2fr 2fr 2fr 80px 80px 80px 100px" }}>
            <span>Name</span><span>Email</span><span>User ID</span>
            <span>Study</span><span>Admin</span><span>Matrix</span><span>Joined</span>
          </div>
          {!profiles || profiles.length === 0 ? (
            <div style={{ padding: "2rem 1.25rem", color: "var(--slate)", fontSize: "0.85rem" }}>No users found.</div>
          ) : profiles.map(p => (
            <div key={p.id} className="tbl-row" style={{ gridTemplateColumns: "2fr 2fr 2fr 80px 80px 80px 100px" }}>
              <span style={{ fontSize: "0.875rem", color: "var(--paper)", fontWeight: 500 }}>
                {[p.first_name, p.last_name].filter(Boolean).join(" ") || <span style={{ color: "var(--slate)" }}>—</span>}
              </span>
              <span className="mono" style={{ fontSize: "0.72rem", color: "var(--muted)" }}>{p.email || "—"}</span>
              <span className="mono" style={{ fontSize: "0.65rem", color: "var(--slate)" }}>{p.id?.slice(0, 14)}…</span>
              <span>{p.is_in_study ? <span className="badge badge-green">Yes</span> : <span className="badge badge-gray">No</span>}</span>
              <span>{p.is_superadmin ? <span className="badge badge-purple">Yes</span> : <span className="badge badge-gray">No</span>}</span>
              <span>{p.is_matrix_admin ? <span className="badge badge-blue">Yes</span> : <span className="badge badge-gray">No</span>}</span>
              <span className="mono" style={{ fontSize: "0.65rem", color: "var(--slate)" }}>
                {p.created_datetime_utc ? new Date(p.created_datetime_utc).toLocaleDateString() : "—"}
              </span>
            </div>
          ))}
        </div>
      </main>
    </div>
  );
}
EOF

# ============================================================
# app/images/page.tsx
# ============================================================
cat > app/images/page.tsx << 'EOF'
import { createClient } from "@/lib/supabase/server";
import Sidebar from "@/components/Sidebar";
import ImagesClient from "./ImagesClient";

export const dynamic = "force-dynamic";

export default async function ImagesPage() {
  const sb = await createClient();
  const { data: images, error } = await sb
    .from("images")
    .select("id, url, image_description, additional_context, is_public, is_common_use, created_datetime_utc")
    .order("created_datetime_utc", { ascending: false });

  return (
    <div style={{ display: "flex", minHeight: "100vh" }}>
      <Sidebar />
      <main style={{ flex: 1, marginLeft: "220px", padding: "2.5rem 2rem" }}>
        <ImagesClient initialImages={images || []} fetchError={error?.message} />
      </main>
    </div>
  );
}
EOF

# ============================================================
# app/images/ImagesClient.tsx
# ============================================================
cat > app/images/ImagesClient.tsx << 'EOF'
"use client";
import { useState } from "react";
import { createClient } from "@/lib/supabase/client";
import { Plus, Pencil, Trash2, X, Check, ExternalLink } from "lucide-react";

interface Img {
  id: string; url: string | null; image_description: string | null;
  additional_context: string | null; is_public: boolean | null;
  is_common_use: boolean | null; created_datetime_utc: string | null;
}

export default function ImagesClient({ initialImages, fetchError }: { initialImages: Img[]; fetchError?: string }) {
  const [images, setImages] = useState(initialImages);
  const [creating, setCreating] = useState(false);
  const [editId, setEditId] = useState<string | null>(null);
  const [loading, setLoading] = useState(false);
  const [toast, setToast] = useState<{ msg: string; ok: boolean } | null>(null);
  const [cUrl, setCUrl] = useState(""); const [cDesc, setCDesc] = useState("");
  const [cCtx, setCCtx] = useState(""); const [cPublic, setCPublic] = useState(false); const [cCommon, setCCommon] = useState(false);
  const [eUrl, setEUrl] = useState(""); const [eDesc, setEDesc] = useState("");
  const [eCtx, setECtx] = useState(""); const [ePublic, setEPublic] = useState(false); const [eCommon, setECommon] = useState(false);

  const sb = createClient();
  const pop = (msg: string, ok: boolean) => { setToast({ msg, ok }); setTimeout(() => setToast(null), 3000); };

  const handleCreate = async () => {
    if (!cUrl.trim()) return;
    setLoading(true);
    const { data, error } = await sb.from("images")
      .insert({ url: cUrl.trim(), image_description: cDesc.trim() || null, additional_context: cCtx.trim() || null, is_public: cPublic, is_common_use: cCommon })
      .select().single();
    if (error) pop(error.message, false);
    else { setImages([data, ...images]); setCUrl(""); setCDesc(""); setCCtx(""); setCPublic(false); setCCommon(false); setCreating(false); pop("Image created", true); }
    setLoading(false);
  };

  const startEdit = (img: Img) => { setEditId(img.id); setEUrl(img.url || ""); setEDesc(img.image_description || ""); setECtx(img.additional_context || ""); setEPublic(img.is_public ?? false); setECommon(img.is_common_use ?? false); };

  const handleUpdate = async (id: string) => {
    setLoading(true);
    const { data, error } = await sb.from("images")
      .update({ url: eUrl.trim(), image_description: eDesc.trim() || null, additional_context: eCtx.trim() || null, is_public: ePublic, is_common_use: eCommon, modified_datetime_utc: new Date().toISOString() })
      .eq("id", id).select().single();
    if (error) pop(error.message, false);
    else { setImages(images.map(i => i.id === id ? data : i)); setEditId(null); pop("Image updated", true); }
    setLoading(false);
  };

  const handleDelete = async (id: string) => {
    if (!confirm("Delete this image?")) return;
    setLoading(true);
    const { error } = await sb.from("images").delete().eq("id", id);
    if (error) pop(error.message, false);
    else { setImages(images.filter(i => i.id !== id)); pop("Image deleted", true); }
    setLoading(false);
  };

  return (
    <div>
      {toast && (
        <div className="mono" style={{ position: "fixed", top: "1.5rem", right: "1.5rem", zIndex: 100, padding: "0.65rem 1rem", borderRadius: "4px", fontSize: "0.7rem", background: toast.ok ? "rgba(184,247,35,0.1)" : "rgba(240,79,35,0.1)", border: `1px solid ${toast.ok ? "rgba(184,247,35,0.4)" : "rgba(240,79,35,0.4)"}`, color: toast.ok ? "var(--acid)" : "var(--rust)" }}>{toast.msg}</div>
      )}
      <div className="fade-up" style={{ marginBottom: "2.5rem", display: "flex", alignItems: "flex-end", justifyContent: "space-between" }}>
        <div>
          <div style={{ display: "flex", alignItems: "center", gap: "10px", marginBottom: "6px" }}>
            <div style={{ width: "28px", height: "1px", background: "var(--acid)" }} />
            <span className="mono" style={{ fontSize: "0.6rem", color: "var(--acid)", textTransform: "uppercase", letterSpacing: "0.12em" }}>CRUD</span>
          </div>
          <h1 className="font-display" style={{ fontSize: "4rem", color: "var(--paper)", letterSpacing: "0.04em", lineHeight: 1 }}>IMAGES</h1>
          <p style={{ color: "var(--slate)", fontSize: "0.85rem", marginTop: "6px" }}>{images.length} images in library</p>
        </div>
        <button className="btn btn-primary" onClick={() => setCreating(true)}><Plus size={12} /> Add Image</button>
      </div>

      {creating && (
        <div className="card fade-up" style={{ padding: "1.5rem", marginBottom: "1.25rem", borderColor: "var(--acid)" }}>
          <p className="mono" style={{ fontSize: "0.6rem", color: "var(--acid)", textTransform: "uppercase", letterSpacing: "0.1em", marginBottom: "1.25rem" }}>New Image</p>
          <div style={{ display: "grid", gridTemplateColumns: "1fr 1fr", gap: "12px", marginBottom: "12px" }}>
            <div>
              <label className="mono" style={{ display: "block", fontSize: "0.58rem", color: "var(--slate)", textTransform: "uppercase", letterSpacing: "0.1em", marginBottom: "6px" }}>URL *</label>
              <input className="inp" placeholder="https://..." value={cUrl} onChange={e => setCUrl(e.target.value)} />
            </div>
            <div>
              <label className="mono" style={{ display: "block", fontSize: "0.58rem", color: "var(--slate)", textTransform: "uppercase", letterSpacing: "0.1em", marginBottom: "6px" }}>Additional Context</label>
              <input className="inp" placeholder="Optional..." value={cCtx} onChange={e => setCCtx(e.target.value)} />
            </div>
          </div>
          <div style={{ marginBottom: "1rem" }}>
            <label className="mono" style={{ display: "block", fontSize: "0.58rem", color: "var(--slate)", textTransform: "uppercase", letterSpacing: "0.1em", marginBottom: "6px" }}>Image Description</label>
            <textarea className="inp" placeholder="Describe the image..." value={cDesc} onChange={e => setCDesc(e.target.value)} rows={2} style={{ resize: "vertical" }} />
          </div>
          <div style={{ display: "flex", gap: "1.5rem", marginBottom: "1.25rem" }}>
            {[["Public", cPublic, setCPublic], ["Common Use", cCommon, setCCommon]].map(([label, val, setter]) => (
              <label key={label as string} style={{ display: "flex", alignItems: "center", gap: "8px", cursor: "pointer" }}>
                <input type="checkbox" checked={val as boolean} onChange={e => (setter as (v: boolean) => void)(e.target.checked)} />
                <span className="mono" style={{ fontSize: "0.65rem", color: "var(--muted)", textTransform: "uppercase", letterSpacing: "0.08em" }}>{label as string}</span>
              </label>
            ))}
          </div>
          <div style={{ display: "flex", gap: "8px" }}>
            <button className="btn btn-primary" onClick={handleCreate} disabled={loading || !cUrl}><Check size={11} /> Create</button>
            <button className="btn btn-ghost" onClick={() => { setCreating(false); setCUrl(""); setCDesc(""); }}><X size={11} /> Cancel</button>
          </div>
        </div>
      )}

      {fetchError && <div className="mono" style={{ marginBottom: "1rem", padding: "0.75rem 1rem", background: "rgba(240,79,35,0.08)", border: "1px solid rgba(240,79,35,0.25)", color: "var(--rust)", fontSize: "0.75rem", borderRadius: "4px" }}>{fetchError}</div>}

      <div className="card fade-up-1">
        <div className="tbl-head" style={{ gridTemplateColumns: "3fr 2fr 70px 70px 100px 80px" }}>
          <span>Description / URL</span><span>Context</span><span>Public</span><span>Common</span><span>Added</span><span>Actions</span>
        </div>
        {images.length === 0 && <div style={{ padding: "2rem 1.25rem", color: "var(--slate)", fontSize: "0.85rem" }}>No images yet.</div>}
        {images.map(img => (
          <div key={img.id}>
            {editId === img.id ? (
              <div style={{ padding: "1rem 1.25rem", borderBottom: "1px solid var(--border)", background: "rgba(184,247,35,0.02)" }}>
                <div style={{ display: "grid", gridTemplateColumns: "1fr 1fr", gap: "10px", marginBottom: "10px" }}>
                  <div>
                    <label className="mono" style={{ display: "block", fontSize: "0.55rem", color: "var(--slate)", textTransform: "uppercase", letterSpacing: "0.08em", marginBottom: "4px" }}>URL</label>
                    <input className="inp" value={eUrl} onChange={e => setEUrl(e.target.value)} />
                  </div>
                  <div>
                    <label className="mono" style={{ display: "block", fontSize: "0.55rem", color: "var(--slate)", textTransform: "uppercase", letterSpacing: "0.08em", marginBottom: "4px" }}>Context</label>
                    <input className="inp" value={eCtx} onChange={e => setECtx(e.target.value)} />
                  </div>
                </div>
                <div style={{ marginBottom: "10px" }}>
                  <label className="mono" style={{ display: "block", fontSize: "0.55rem", color: "var(--slate)", textTransform: "uppercase", letterSpacing: "0.08em", marginBottom: "4px" }}>Description</label>
                  <textarea className="inp" value={eDesc} onChange={e => setEDesc(e.target.value)} rows={2} style={{ resize: "vertical" }} />
                </div>
                <div style={{ display: "flex", gap: "1.25rem", marginBottom: "10px" }}>
                  {[["Public", ePublic, setEPublic], ["Common Use", eCommon, setECommon]].map(([label, val, setter]) => (
                    <label key={label as string} style={{ display: "flex", alignItems: "center", gap: "6px", cursor: "pointer" }}>
                      <input type="checkbox" checked={val as boolean} onChange={e => (setter as (v: boolean) => void)(e.target.checked)} />
                      <span className="mono" style={{ fontSize: "0.62rem", color: "var(--muted)" }}>{label as string}</span>
                    </label>
                  ))}
                </div>
                <div style={{ display: "flex", gap: "8px" }}>
                  <button className="btn btn-primary" style={{ fontSize: "0.65rem", padding: "0.4rem 0.8rem" }} onClick={() => handleUpdate(img.id)} disabled={loading}><Check size={10} /> Save</button>
                  <button className="btn btn-ghost" style={{ fontSize: "0.65rem", padding: "0.4rem 0.8rem" }} onClick={() => setEditId(null)}><X size={10} /> Cancel</button>
                </div>
              </div>
            ) : (
              <div className="tbl-row" style={{ gridTemplateColumns: "3fr 2fr 70px 70px 100px 80px" }}>
                <div style={{ minWidth: 0 }}>
                  <p style={{ fontSize: "0.82rem", color: "var(--paper)", overflow: "hidden", textOverflow: "ellipsis", whiteSpace: "nowrap", marginBottom: "3px" }}>
                    {img.image_description || <span style={{ color: "var(--slate)" }}>No description</span>}
                  </p>
                  {img.url && (
                    <a href={img.url} target="_blank" rel="noopener noreferrer" style={{ display: "inline-flex", alignItems: "center", gap: "4px" }}>
                      <span className="mono" style={{ fontSize: "0.6rem", color: "var(--slate)", overflow: "hidden", textOverflow: "ellipsis", whiteSpace: "nowrap", maxWidth: "240px" }}>{img.url}</span>
                      <ExternalLink size={9} color="var(--slate)" />
                    </a>
                  )}
                </div>
                <span className="mono" style={{ fontSize: "0.7rem", color: "var(--muted)", overflow: "hidden", textOverflow: "ellipsis", whiteSpace: "nowrap" }}>{img.additional_context || <span style={{ color: "var(--slate)" }}>—</span>}</span>
                <span>{img.is_public ? <span className="badge badge-green">Yes</span> : <span className="badge badge-gray">No</span>}</span>
                <span>{img.is_common_use ? <span className="badge badge-blue">Yes</span> : <span className="badge badge-gray">No</span>}</span>
                <span className="mono" style={{ fontSize: "0.65rem", color: "var(--slate)" }}>{img.created_datetime_utc ? new Date(img.created_datetime_utc).toLocaleDateString() : "—"}</span>
                <div style={{ display: "flex", gap: "4px" }}>
                  <button onClick={() => startEdit(img)} style={{ padding: "5px", background: "none", border: "none", cursor: "pointer", color: "var(--slate)", borderRadius: "3px", transition: "color 0.15s" }}
                    onMouseEnter={e => (e.currentTarget.style.color = "var(--acid)")} onMouseLeave={e => (e.currentTarget.style.color = "var(--slate)")}><Pencil size={13} /></button>
                  <button onClick={() => handleDelete(img.id)} style={{ padding: "5px", background: "none", border: "none", cursor: "pointer", color: "var(--slate)", borderRadius: "3px", transition: "color 0.15s" }}
                    onMouseEnter={e => (e.currentTarget.style.color = "var(--rust)")} onMouseLeave={e => (e.currentTarget.style.color = "var(--slate)")}><Trash2 size={13} /></button>
                </div>
              </div>
            )}
          </div>
        ))}
      </div>
    </div>
  );
}
EOF

# ============================================================
# app/captions/page.tsx
# ============================================================
cat > app/captions/page.tsx << 'EOF'
import { createClient } from "@/lib/supabase/server";
import Sidebar from "@/components/Sidebar";

export const dynamic = "force-dynamic";

export default async function CaptionsPage() {
  const sb = await createClient();
  const { data: captions, error } = await sb
    .from("captions")
    .select("id, content, is_public, is_featured, like_count, created_datetime_utc, humor_flavor_id, humor_flavors ( slug ), profiles ( first_name, last_name, email )")
    .order("created_datetime_utc", { ascending: false });

  const totalLikes = captions?.reduce((sum, c) => sum + (c.like_count ?? 0), 0) ?? 0;
  const featuredCount = captions?.filter(c => c.is_featured).length ?? 0;
  const publicCount = captions?.filter(c => c.is_public).length ?? 0;

  return (
    <div style={{ display: "flex", minHeight: "100vh" }}>
      <Sidebar />
      <main style={{ flex: 1, marginLeft: "220px", padding: "2.5rem 2rem" }}>
        <div className="fade-up" style={{ marginBottom: "2rem" }}>
          <div style={{ display: "flex", alignItems: "center", gap: "10px", marginBottom: "6px" }}>
            <div style={{ width: "28px", height: "1px", background: "var(--acid)" }} />
            <span className="mono" style={{ fontSize: "0.6rem", color: "var(--acid)", textTransform: "uppercase", letterSpacing: "0.12em" }}>Read-only</span>
          </div>
          <h1 className="font-display" style={{ fontSize: "4rem", color: "var(--paper)", letterSpacing: "0.04em", lineHeight: 1 }}>CAPTIONS</h1>
          <p style={{ color: "var(--slate)", fontSize: "0.85rem", marginTop: "6px" }}>{captions?.length ?? 0} total captions</p>
        </div>

        <div className="fade-up-1" style={{ display: "flex", gap: "12px", marginBottom: "2rem" }}>
          {[["Total Likes", totalLikes], ["Featured", featuredCount], ["Public", publicCount], ["Private", (captions?.length ?? 0) - publicCount]].map(([label, value]) => (
            <div key={label} className="card" style={{ padding: "0.875rem 1.25rem", flex: 1 }}>
              <p className="mono" style={{ fontSize: "0.58rem", color: "var(--slate)", textTransform: "uppercase", letterSpacing: "0.1em", marginBottom: "4px" }}>{label}</p>
              <p className="font-display" style={{ fontSize: "2rem", color: "var(--paper)" }}>{(value as number).toLocaleString()}</p>
            </div>
          ))}
        </div>

        {error && <div className="mono" style={{ marginBottom: "1rem", padding: "0.75rem 1rem", background: "rgba(240,79,35,0.08)", border: "1px solid rgba(240,79,35,0.25)", color: "var(--rust)", fontSize: "0.75rem", borderRadius: "4px" }}>Error: {error.message}</div>}

        <div className="card fade-up-2">
          <div className="tbl-head" style={{ gridTemplateColumns: "3fr 1.5fr 1.5fr 80px 80px 80px 100px" }}>
            <span>Caption</span><span>Author</span><span>Flavor</span><span>Likes</span><span>Featured</span><span>Public</span><span>Created</span>
          </div>
          {!captions || captions.length === 0 ? (
            <div style={{ padding: "2rem 1.25rem", color: "var(--slate)", fontSize: "0.85rem" }}>No captions yet.</div>
          ) : captions.map(cap => {
            const profile = cap.profiles as { first_name?: string; last_name?: string; email?: string } | null;
            const flavor = cap.humor_flavors as { slug: string } | null;
            const author = [profile?.first_name, profile?.last_name].filter(Boolean).join(" ") || profile?.email || "—";
            return (
              <div key={cap.id} className="tbl-row" style={{ gridTemplateColumns: "3fr 1.5fr 1.5fr 80px 80px 80px 100px" }}>
                <p style={{ fontSize: "0.82rem", color: "var(--paper)", overflow: "hidden", textOverflow: "ellipsis", whiteSpace: "nowrap" }}>&ldquo;{cap.content || "—"}&rdquo;</p>
                <span className="mono" style={{ fontSize: "0.68rem", color: "var(--muted)", overflow: "hidden", textOverflow: "ellipsis", whiteSpace: "nowrap" }}>{author}</span>
                <span>{flavor?.slug ? <span className="badge badge-purple">{flavor.slug}</span> : <span style={{ color: "var(--slate)", fontSize: "0.75rem" }}>—</span>}</span>
                <span className="mono" style={{ fontSize: "0.75rem", color: (cap.like_count ?? 0) > 0 ? "var(--acid)" : "var(--slate)" }}>{cap.like_count ?? 0}</span>
                <span>{cap.is_featured ? <span className="badge badge-gold">Yes</span> : <span className="badge badge-gray">No</span>}</span>
                <span>{cap.is_public ? <span className="badge badge-green">Yes</span> : <span className="badge badge-gray">No</span>}</span>
                <span className="mono" style={{ fontSize: "0.65rem", color: "var(--slate)" }}>{cap.created_datetime_utc ? new Date(cap.created_datetime_utc).toLocaleDateString() : "—"}</span>
              </div>
            );
          })}
        </div>
      </main>
    </div>
  );
}
EOF

echo ""
echo "✅ All files written!"
echo ""
echo "Next steps:"
echo "  1. Make sure your .env.local has NEXT_PUBLIC_SUPABASE_URL and NEXT_PUBLIC_SUPABASE_ANON_KEY"
echo "  2. Run: npm run dev"
echo "  3. Visit: http://localhost:3000"
