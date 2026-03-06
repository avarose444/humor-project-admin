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
