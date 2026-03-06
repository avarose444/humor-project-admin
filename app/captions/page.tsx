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
            const flavor = (Array.isArray(cap.humor_flavors) ? cap.humor_flavors[0] : cap.humor_flavors) as { slug: string } | null;
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
