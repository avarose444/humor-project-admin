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
