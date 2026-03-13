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
