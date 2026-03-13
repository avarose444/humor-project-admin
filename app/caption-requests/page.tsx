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
