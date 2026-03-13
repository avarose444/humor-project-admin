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
