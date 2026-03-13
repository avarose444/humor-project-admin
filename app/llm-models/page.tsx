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
