#!/bin/bash
# Run from root of humor-project-admin
# Usage: bash update.sh

echo "🚀 Updating admin panel with new pages..."

# Create new directories
mkdir -p app/caption-examples
mkdir -p app/caption-requests
mkdir -p app/humor-flavors
mkdir -p app/humor-flavor-steps
mkdir -p app/humor-flavor-mix
mkdir -p app/terms
mkdir -p app/llm-models
mkdir -p app/llm-providers
mkdir -p app/llm-prompt-chains
mkdir -p app/llm-responses
mkdir -p app/allowed-domains
mkdir -p app/whitelist-emails

# ============================================================
# components/CrudTable.tsx - reusable CRUD component
# ============================================================
cat > components/CrudTable.tsx << 'EOF'
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
EOF

# ============================================================
# Updated Sidebar with all nav items
# ============================================================
cat > components/Sidebar.tsx << 'EOF'
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
                    {item.children.map(({ href, label, icon: CIcon }) => {
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
EOF

# ============================================================
# All new pages
# ============================================================

cat > app/allowed-domains/page.tsx << 'EOF'
import { createClient } from "@/lib/supabase/server";
import Sidebar from "@/components/Sidebar";
import CrudTable from "@/components/CrudTable";
export const dynamic = "force-dynamic";
export default async function Page() {
  const sb = await createClient();
  const { data, error } = await sb.from("allowed_signup_domains").select("*").order("created_datetime_utc", { ascending: false });
  return (
    <div style={{ display: "flex", minHeight: "100vh" }}>
      <Sidebar />
      <main style={{ flex: 1, marginLeft: "220px", padding: "2.5rem 2rem" }}>
        <CrudTable title="ALLOWED DOMAINS" subtitle={`${data?.length ?? 0} domains`} table="allowed_signup_domains" rows={data || []} idKey="id"
          fields={[
            { key: "id", label: "ID", readOnly: true, width: "60px" },
            { key: "apex_domain", label: "Domain" },
            { key: "created_datetime_utc", label: "Created", readOnly: true, width: "140px" },
          ]} fetchError={error?.message} />
      </main>
    </div>
  );
}
EOF

cat > app/whitelist-emails/page.tsx << 'EOF'
import { createClient } from "@/lib/supabase/server";
import Sidebar from "@/components/Sidebar";
import CrudTable from "@/components/CrudTable";
export const dynamic = "force-dynamic";
export default async function Page() {
  const sb = await createClient();
  const { data, error } = await sb.from("whitelist_email_addresses").select("*").order("created_datetime_utc", { ascending: false });
  return (
    <div style={{ display: "flex", minHeight: "100vh" }}>
      <Sidebar />
      <main style={{ flex: 1, marginLeft: "220px", padding: "2.5rem 2rem" }}>
        <CrudTable title="WHITELIST EMAILS" subtitle={`${data?.length ?? 0} addresses`} table="whitelist_email_addresses" rows={data || []} idKey="id"
          fields={[
            { key: "id", label: "ID", readOnly: true, width: "60px" },
            { key: "email_address", label: "Email Address" },
            { key: "created_datetime_utc", label: "Created", readOnly: true, width: "140px" },
          ]} fetchError={error?.message} />
      </main>
    </div>
  );
}
EOF

cat > app/terms/page.tsx << 'EOF'
import { createClient } from "@/lib/supabase/server";
import Sidebar from "@/components/Sidebar";
import CrudTable from "@/components/CrudTable";
export const dynamic = "force-dynamic";
export default async function Page() {
  const sb = await createClient();
  const { data, error } = await sb.from("terms").select("*").order("priority", { ascending: true });
  return (
    <div style={{ display: "flex", minHeight: "100vh" }}>
      <Sidebar />
      <main style={{ flex: 1, marginLeft: "220px", padding: "2.5rem 2rem" }}>
        <CrudTable title="TERMS" subtitle={`${data?.length ?? 0} terms`} table="terms" rows={data || []} idKey="id"
          fields={[
            { key: "id", label: "ID", readOnly: true, width: "60px" },
            { key: "term", label: "Term" },
            { key: "definition", label: "Definition", type: "textarea" },
            { key: "example", label: "Example", type: "textarea" },
            { key: "priority", label: "Priority", type: "number", width: "80px" },
          ]} fetchError={error?.message} />
      </main>
    </div>
  );
}
EOF

cat > app/caption-examples/page.tsx << 'EOF'
import { createClient } from "@/lib/supabase/server";
import Sidebar from "@/components/Sidebar";
import CrudTable from "@/components/CrudTable";
export const dynamic = "force-dynamic";
export default async function Page() {
  const sb = await createClient();
  const { data, error } = await sb.from("caption_examples").select("*").order("priority", { ascending: true });
  return (
    <div style={{ display: "flex", minHeight: "100vh" }}>
      <Sidebar />
      <main style={{ flex: 1, marginLeft: "220px", padding: "2.5rem 2rem" }}>
        <CrudTable title="CAPTION EXAMPLES" subtitle={`${data?.length ?? 0} examples`} table="caption_examples" rows={data || []} idKey="id"
          fields={[
            { key: "id", label: "ID", readOnly: true, width: "60px" },
            { key: "image_description", label: "Image Desc", type: "textarea" },
            { key: "caption", label: "Caption", type: "textarea" },
            { key: "explanation", label: "Explanation", type: "textarea" },
            { key: "priority", label: "Priority", type: "number", width: "80px" },
          ]} fetchError={error?.message} />
      </main>
    </div>
  );
}
EOF

cat > app/llm-providers/page.tsx << 'EOF'
import { createClient } from "@/lib/supabase/server";
import Sidebar from "@/components/Sidebar";
import CrudTable from "@/components/CrudTable";
export const dynamic = "force-dynamic";
export default async function Page() {
  const sb = await createClient();
  const { data, error } = await sb.from("llm_providers").select("*").order("id");
  return (
    <div style={{ display: "flex", minHeight: "100vh" }}>
      <Sidebar />
      <main style={{ flex: 1, marginLeft: "220px", padding: "2.5rem 2rem" }}>
        <CrudTable title="LLM PROVIDERS" subtitle={`${data?.length ?? 0} providers`} table="llm_providers" rows={data || []} idKey="id"
          fields={[
            { key: "id", label: "ID", readOnly: true, width: "60px" },
            { key: "name", label: "Name" },
            { key: "created_datetime_utc", label: "Created", readOnly: true, width: "140px" },
          ]} fetchError={error?.message} />
      </main>
    </div>
  );
}
EOF

cat > app/llm-models/page.tsx << 'EOF'
import { createClient } from "@/lib/supabase/server";
import Sidebar from "@/components/Sidebar";
import CrudTable from "@/components/CrudTable";
export const dynamic = "force-dynamic";
export default async function Page() {
  const sb = await createClient();
  const { data, error } = await sb.from("llm_models").select("*").order("id");
  return (
    <div style={{ display: "flex", minHeight: "100vh" }}>
      <Sidebar />
      <main style={{ flex: 1, marginLeft: "220px", padding: "2.5rem 2rem" }}>
        <CrudTable title="LLM MODELS" subtitle={`${data?.length ?? 0} models`} table="llm_models" rows={data || []} idKey="id"
          fields={[
            { key: "id", label: "ID", readOnly: true, width: "60px" },
            { key: "name", label: "Name" },
            { key: "provider_model_id", label: "Provider Model ID" },
            { key: "llm_provider_id", label: "Provider ID", type: "number", width: "100px" },
            { key: "is_temperature_supported", label: "Temp Support", type: "boolean", width: "120px" },
          ]} fetchError={error?.message} />
      </main>
    </div>
  );
}
EOF

cat > app/llm-prompt-chains/page.tsx << 'EOF'
import { createClient } from "@/lib/supabase/server";
import Sidebar from "@/components/Sidebar";
import CrudTable from "@/components/CrudTable";
export const dynamic = "force-dynamic";
export default async function Page() {
  const sb = await createClient();
  const { data, error } = await sb.from("llm_prompt_chains").select("*").order("created_datetime_utc", { ascending: false }).limit(200);
  return (
    <div style={{ display: "flex", minHeight: "100vh" }}>
      <Sidebar />
      <main style={{ flex: 1, marginLeft: "220px", padding: "2.5rem 2rem" }}>
        <CrudTable title="PROMPT CHAINS" subtitle={`showing last ${data?.length ?? 0}`} table="llm_prompt_chains" rows={data || []} idKey="id" canCreate={false} canEdit={false} canDelete={false}
          fields={[
            { key: "id", label: "ID", readOnly: true, width: "80px" },
            { key: "caption_request_id", label: "Caption Request ID", readOnly: true },
            { key: "created_datetime_utc", label: "Created", readOnly: true, width: "140px" },
          ]} fetchError={error?.message} />
      </main>
    </div>
  );
}
EOF

cat > app/llm-responses/page.tsx << 'EOF'
import { createClient } from "@/lib/supabase/server";
import Sidebar from "@/components/Sidebar";
import CrudTable from "@/components/CrudTable";
export const dynamic = "force-dynamic";
export default async function Page() {
  const sb = await createClient();
  const { data, error } = await sb.from("llm_model_responses").select("id, created_datetime_utc, llm_model_id, processing_time_seconds, humor_flavor_id, caption_request_id").order("created_datetime_utc", { ascending: false }).limit(200);
  return (
    <div style={{ display: "flex", minHeight: "100vh" }}>
      <Sidebar />
      <main style={{ flex: 1, marginLeft: "220px", padding: "2.5rem 2rem" }}>
        <CrudTable title="LLM RESPONSES" subtitle={`showing last ${data?.length ?? 0}`} table="llm_model_responses" rows={data || []} idKey="id" canCreate={false} canEdit={false} canDelete={false}
          fields={[
            { key: "id", label: "ID", readOnly: true },
            { key: "llm_model_id", label: "Model", readOnly: true, width: "80px" },
            { key: "humor_flavor_id", label: "Flavor", readOnly: true, width: "80px" },
            { key: "processing_time_seconds", label: "Time(s)", readOnly: true, width: "80px" },
            { key: "caption_request_id", label: "Request ID", readOnly: true, width: "100px" },
            { key: "created_datetime_utc", label: "Created", readOnly: true, width: "140px" },
          ]} fetchError={error?.message} />
      </main>
    </div>
  );
}
EOF

cat > app/humor-flavors/page.tsx << 'EOF'
import { createClient } from "@/lib/supabase/server";
import Sidebar from "@/components/Sidebar";
import CrudTable from "@/components/CrudTable";
export const dynamic = "force-dynamic";
export default async function Page() {
  const sb = await createClient();
  const { data, error } = await sb.from("humor_flavors").select("*").order("id");
  return (
    <div style={{ display: "flex", minHeight: "100vh" }}>
      <Sidebar />
      <main style={{ flex: 1, marginLeft: "220px", padding: "2.5rem 2rem" }}>
        <CrudTable title="HUMOR FLAVORS" subtitle={`${data?.length ?? 0} flavors`} table="humor_flavors" rows={data || []} idKey="id" canCreate={false} canEdit={false} canDelete={false}
          fields={[
            { key: "id", label: "ID", readOnly: true, width: "60px" },
            { key: "slug", label: "Slug", readOnly: true },
            { key: "description", label: "Description", readOnly: true },
            { key: "created_datetime_utc", label: "Created", readOnly: true, width: "140px" },
          ]} fetchError={error?.message} />
      </main>
    </div>
  );
}
EOF

cat > app/humor-flavor-steps/page.tsx << 'EOF'
import { createClient } from "@/lib/supabase/server";
import Sidebar from "@/components/Sidebar";
import CrudTable from "@/components/CrudTable";
export const dynamic = "force-dynamic";
export default async function Page() {
  const sb = await createClient();
  const { data, error } = await sb.from("humor_flavor_steps").select("id, humor_flavor_id, description, llm_temperature, order_by, llm_model_id, created_datetime_utc").order("humor_flavor_id").order("order_by");
  return (
    <div style={{ display: "flex", minHeight: "100vh" }}>
      <Sidebar />
      <main style={{ flex: 1, marginLeft: "220px", padding: "2.5rem 2rem" }}>
        <CrudTable title="FLAVOR STEPS" subtitle={`${data?.length ?? 0} steps`} table="humor_flavor_steps" rows={data || []} idKey="id" canCreate={false} canEdit={false} canDelete={false}
          fields={[
            { key: "id", label: "ID", readOnly: true, width: "60px" },
            { key: "humor_flavor_id", label: "Flavor ID", readOnly: true, width: "80px" },
            { key: "order_by", label: "Order", readOnly: true, width: "70px" },
            { key: "description", label: "Description", readOnly: true },
            { key: "llm_temperature", label: "Temp", readOnly: true, width: "70px" },
            { key: "llm_model_id", label: "Model", readOnly: true, width: "70px" },
          ]} fetchError={error?.message} />
      </main>
    </div>
  );
}
EOF

cat > app/humor-flavor-mix/page.tsx << 'EOF'
import { createClient } from "@/lib/supabase/server";
import Sidebar from "@/components/Sidebar";
import CrudTable from "@/components/CrudTable";
export const dynamic = "force-dynamic";
export default async function Page() {
  const sb = await createClient();
  const { data, error } = await sb.from("humor_flavor_mix").select("*, humor_flavors(slug)").order("id");
  const rows = (data || []).map((r: Record<string, unknown>) => ({
    ...r,
    flavor_slug: (r.humor_flavors as { slug: string } | null)?.slug || "",
  }));
  return (
    <div style={{ display: "flex", minHeight: "100vh" }}>
      <Sidebar />
      <main style={{ flex: 1, marginLeft: "220px", padding: "2.5rem 2rem" }}>
        <CrudTable title="FLAVOR MIX" subtitle={`${data?.length ?? 0} entries`} table="humor_flavor_mix" rows={rows} idKey="id" canCreate={false} canDelete={false}
          fields={[
            { key: "id", label: "ID", readOnly: true, width: "60px" },
            { key: "flavor_slug", label: "Flavor", readOnly: true },
            { key: "caption_count", label: "Caption Count", type: "number", width: "130px" },
            { key: "created_datetime_utc", label: "Created", readOnly: true, width: "140px" },
          ]} fetchError={error?.message} />
      </main>
    </div>
  );
}
EOF

cat > app/caption-requests/page.tsx << 'EOF'
import { createClient } from "@/lib/supabase/server";
import Sidebar from "@/components/Sidebar";
import CrudTable from "@/components/CrudTable";
export const dynamic = "force-dynamic";
export default async function Page() {
  const sb = await createClient();
  const { data, error } = await sb.from("caption_requests").select("id, created_datetime_utc, profile_id, image_id").order("created_datetime_utc", { ascending: false }).limit(200);
  return (
    <div style={{ display: "flex", minHeight: "100vh" }}>
      <Sidebar />
      <main style={{ flex: 1, marginLeft: "220px", padding: "2.5rem 2rem" }}>
        <CrudTable title="CAPTION REQUESTS" subtitle={`showing last ${data?.length ?? 0}`} table="caption_requests" rows={data || []} idKey="id" canCreate={false} canEdit={false} canDelete={false}
          fields={[
            { key: "id", label: "ID", readOnly: true, width: "80px" },
            { key: "profile_id", label: "Profile ID", readOnly: true },
            { key: "image_id", label: "Image ID", readOnly: true },
            { key: "created_datetime_utc", label: "Created", readOnly: true, width: "140px" },
          ]} fetchError={error?.message} />
      </main>
    </div>
  );
}
EOF

echo ""
echo "✅ All files written!"
echo ""
echo "Now run:"
echo "  git add ."
echo "  git commit -m 'feat: expand admin with all new pages'"
echo "  git push origin main"
