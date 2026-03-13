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
