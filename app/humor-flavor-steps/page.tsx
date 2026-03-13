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
