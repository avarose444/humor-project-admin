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
