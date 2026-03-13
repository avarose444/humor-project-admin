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
