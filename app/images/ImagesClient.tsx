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
