"use client";
import { useState } from "react";
import { createClient } from "@/lib/supabase/client";
import { Plus, Pencil, Trash2, X, Check } from "lucide-react";

export interface Field {
  key: string;
  label: string;
  type?: "text" | "textarea" | "boolean" | "number";
  readOnly?: boolean;
  width?: string;
}

interface Props {
  title: string;
  subtitle?: string;
  table: string;
  rows: Record<string, unknown>[];
  fields: Field[];
  idKey?: string;
  canCreate?: boolean;
  canEdit?: boolean;
  canDelete?: boolean;
  fetchError?: string;
}

function val(v: unknown): string {
  if (v === null || v === undefined) return "";
  return String(v);
}

export default function CrudTable({
  title, subtitle, table, rows: initialRows, fields,
  idKey = "id", canCreate = true, canEdit = true, canDelete = true, fetchError,
}: Props) {
  const [rows, setRows] = useState(initialRows);
  const [creating, setCreating] = useState(false);
  const [editId, setEditId] = useState<unknown>(null);
  const [loading, setLoading] = useState(false);
  const [toast, setToast] = useState<{ msg: string; ok: boolean } | null>(null);
  const [form, setForm] = useState<Record<string, string>>({});
  const [editForm, setEditForm] = useState<Record<string, string>>({});

  const sb = createClient();
  const editableFields = fields.filter(f => !f.readOnly);

  const pop = (msg: string, ok: boolean) => {
    setToast({ msg, ok });
    setTimeout(() => setToast(null), 3000);
  };

  const startCreate = () => {
    const init: Record<string, string> = {};
    editableFields.forEach(f => { init[f.key] = ""; });
    setForm(init);
    setCreating(true);
  };

  const handleCreate = async () => {
    setLoading(true);
    const payload: Record<string, unknown> = {};
    editableFields.forEach(f => {
      if (form[f.key] !== "") {
        payload[f.key] = f.type === "boolean" ? form[f.key] === "true"
          : f.type === "number" ? Number(form[f.key])
          : form[f.key];
      }
    });
    const { data, error } = await sb.from(table).insert(payload).select().single();
    if (error) pop(error.message, false);
    else { setRows([data, ...rows]); setCreating(false); pop("Created successfully", true); }
    setLoading(false);
  };

  const startEdit = (row: Record<string, unknown>) => {
    const init: Record<string, string> = {};
    editableFields.forEach(f => { init[f.key] = val(row[f.key]); });
    setEditForm(init);
    setEditId(row[idKey]);
  };

  const handleUpdate = async (id: unknown) => {
    setLoading(true);
    const payload: Record<string, unknown> = {};
    editableFields.forEach(f => {
      payload[f.key] = f.type === "boolean" ? editForm[f.key] === "true"
        : f.type === "number" ? (editForm[f.key] === "" ? null : Number(editForm[f.key]))
        : editForm[f.key] || null;
    });
    payload["modified_datetime_utc"] = new Date().toISOString();
    const { data, error } = await sb.from(table).update(payload).eq(idKey, id).select().single();
    if (error) {
      delete payload["modified_datetime_utc"];
      const { data: d2, error: e2 } = await sb.from(table).update(payload).eq(idKey, id).select().single();
      if (e2) { pop(e2.message, false); setLoading(false); return; }
      setRows(rows.map(r => r[idKey] === id ? d2 : r));
    } else {
      setRows(rows.map(r => r[idKey] === id ? data : r));
    }
    setEditId(null);
    pop("Updated successfully", true);
    setLoading(false);
  };

  const handleDelete = async (id: unknown) => {
    if (!confirm("Delete this record? This cannot be undone.")) return;
    setLoading(true);
    const { error } = await sb.from(table).delete().eq(idKey, id);
    if (error) pop(error.message, false);
    else { setRows(rows.filter(r => r[idKey] !== id)); pop("Deleted", true); }
    setLoading(false);
  };

  const gridCols = [...fields, ...(canEdit || canDelete ? [{ key: "_actions", label: "Actions", width: "80px" }] : [])];
  const templateColumns = gridCols.map(f => f.width || "1fr").join(" ");

  const FormField = ({ field, value, onChange }: { field: Field; value: string; onChange: (v: string) => void }) => {
    if (field.type === "boolean") return (
      <select className="inp" value={value} onChange={e => onChange(e.target.value)} style={{ fontSize: "0.8rem" }}>
        <option value="">—</option>
        <option value="true">True</option>
        <option value="false">False</option>
      </select>
    );
    if (field.type === "textarea") return (
      <textarea className="inp" value={value} onChange={e => onChange(e.target.value)} rows={2} style={{ resize: "vertical", fontSize: "0.8rem" }} />
    );
    return <input className="inp" value={value} onChange={e => onChange(e.target.value)} style={{ fontSize: "0.8rem" }} />;
  };

  return (
    <div>
      {toast && (
        <div className="mono" style={{
          position: "fixed", top: "1.5rem", right: "1.5rem", zIndex: 100,
          padding: "0.65rem 1rem", borderRadius: "4px", fontSize: "0.7rem",
          background: toast.ok ? "rgba(184,247,35,0.1)" : "rgba(240,79,35,0.1)",
          border: `1px solid ${toast.ok ? "rgba(184,247,35,0.4)" : "rgba(240,79,35,0.4)"}`,
          color: toast.ok ? "var(--acid)" : "var(--rust)",
        }}>{toast.msg}</div>
      )}
      <div className="fade-up" style={{ marginBottom: "2rem", display: "flex", alignItems: "flex-end", justifyContent: "space-between" }}>
        <div>
          <div style={{ display: "flex", alignItems: "center", gap: "10px", marginBottom: "6px" }}>
            <div style={{ width: "28px", height: "1px", background: "var(--acid)" }} />
            <span className="mono" style={{ fontSize: "0.6rem", color: "var(--acid)", textTransform: "uppercase", letterSpacing: "0.12em" }}>
              {canCreate || canEdit || canDelete ? "CRUD" : "Read-only"}
            </span>
          </div>
          <h1 className="font-display" style={{ fontSize: "3.5rem", color: "var(--paper)", letterSpacing: "0.04em", lineHeight: 1 }}>{title}</h1>
          {subtitle && <p style={{ color: "var(--slate)", fontSize: "0.85rem", marginTop: "6px" }}>{subtitle}</p>}
        </div>
        {canCreate && (
          <button className="btn btn-primary" onClick={startCreate}><Plus size={12} /> Add New</button>
        )}
      </div>

      {creating && (
        <div className="card" style={{ padding: "1.25rem", marginBottom: "1rem", borderColor: "var(--acid)" }}>
          <p className="mono" style={{ fontSize: "0.6rem", color: "var(--acid)", textTransform: "uppercase", letterSpacing: "0.1em", marginBottom: "1rem" }}>New Record</p>
          <div style={{ display: "grid", gridTemplateColumns: "repeat(auto-fill, minmax(200px, 1fr))", gap: "10px", marginBottom: "1rem" }}>
            {editableFields.map(f => (
              <div key={f.key}>
                <label className="mono" style={{ display: "block", fontSize: "0.55rem", color: "var(--slate)", textTransform: "uppercase", letterSpacing: "0.08em", marginBottom: "4px" }}>{f.label}</label>
                <FormField field={f} value={form[f.key] || ""} onChange={v => setForm({ ...form, [f.key]: v })} />
              </div>
            ))}
          </div>
          <div style={{ display: "flex", gap: "8px" }}>
            <button className="btn btn-primary" onClick={handleCreate} disabled={loading}><Check size={11} /> Create</button>
            <button className="btn btn-ghost" onClick={() => setCreating(false)}><X size={11} /> Cancel</button>
          </div>
        </div>
      )}

      {fetchError && (
        <div className="mono" style={{ marginBottom: "1rem", padding: "0.75rem 1rem", background: "rgba(240,79,35,0.08)", border: "1px solid rgba(240,79,35,0.25)", color: "var(--rust)", fontSize: "0.75rem", borderRadius: "4px" }}>
          {fetchError}
        </div>
      )}

      <div className="card fade-up-1">
        <div className="tbl-head" style={{ gridTemplateColumns: templateColumns }}>
          {gridCols.map(f => <span key={f.key}>{f.key === "_actions" ? "" : f.label}</span>)}
        </div>
        {rows.length === 0 && (
          <div style={{ padding: "2rem 1.25rem", color: "var(--slate)", fontSize: "0.85rem" }}>No records found.</div>
        )}
        {rows.map((row) => {
          const id = row[idKey];
          const isEditing = editId === id;
          return (
            <div key={String(id)}>
              {isEditing ? (
                <div style={{ padding: "1rem 1.25rem", borderBottom: "1px solid var(--border)", background: "rgba(184,247,35,0.02)" }}>
                  <div style={{ display: "grid", gridTemplateColumns: "repeat(auto-fill, minmax(200px, 1fr))", gap: "10px", marginBottom: "10px" }}>
                    {editableFields.map(f => (
                      <div key={f.key}>
                        <label className="mono" style={{ display: "block", fontSize: "0.55rem", color: "var(--slate)", textTransform: "uppercase", letterSpacing: "0.08em", marginBottom: "4px" }}>{f.label}</label>
                        <FormField field={f} value={editForm[f.key] || ""} onChange={v => setEditForm({ ...editForm, [f.key]: v })} />
                      </div>
                    ))}
                  </div>
                  <div style={{ display: "flex", gap: "8px" }}>
                    <button className="btn btn-primary" style={{ fontSize: "0.65rem", padding: "0.4rem 0.8rem" }} onClick={() => handleUpdate(id)} disabled={loading}><Check size={10} /> Save</button>
                    <button className="btn btn-ghost" style={{ fontSize: "0.65rem", padding: "0.4rem 0.8rem" }} onClick={() => setEditId(null)}><X size={10} /> Cancel</button>
                  </div>
                </div>
              ) : (
                <div className="tbl-row" style={{ gridTemplateColumns: templateColumns }}>
                  {fields.map(f => {
                    const v = row[f.key];
                    if (f.type === "boolean") return (
                      <span key={f.key}>
                        {v === true ? <span className="badge badge-green">True</span> : v === false ? <span className="badge badge-gray">False</span> : <span style={{ color: "var(--slate)" }}>—</span>}
                      </span>
                    );
                    return (
                      <span key={f.key} style={{ fontSize: f.readOnly ? "0.65rem" : "0.82rem", color: f.readOnly ? "var(--slate)" : "var(--paper)", overflow: "hidden", textOverflow: "ellipsis", whiteSpace: "nowrap", fontFamily: f.readOnly ? "'JetBrains Mono', monospace" : "inherit" } as React.CSSProperties}>
                        {val(v) || <span style={{ color: "var(--slate)" }}>—</span>}
                      </span>
                    );
                  })}
                  {(canEdit || canDelete) && (
                    <div style={{ display: "flex", gap: "4px" }}>
                      {canEdit && (
                        <button onClick={() => startEdit(row)} style={{ padding: "5px", background: "none", border: "none", cursor: "pointer", color: "var(--slate)", borderRadius: "3px", transition: "color 0.15s" }}
                          onMouseEnter={e => (e.currentTarget.style.color = "var(--acid)")}
                          onMouseLeave={e => (e.currentTarget.style.color = "var(--slate)")}><Pencil size={13} /></button>
                      )}
                      {canDelete && (
                        <button onClick={() => handleDelete(id)} style={{ padding: "5px", background: "none", border: "none", cursor: "pointer", color: "var(--slate)", borderRadius: "3px", transition: "color 0.15s" }}
                          onMouseEnter={e => (e.currentTarget.style.color = "var(--rust)")}
                          onMouseLeave={e => (e.currentTarget.style.color = "var(--slate)")}><Trash2 size={13} /></button>
                      )}
                    </div>
                  )}
                </div>
              )}
            </div>
          );
        })}
      </div>
    </div>
  );
}
