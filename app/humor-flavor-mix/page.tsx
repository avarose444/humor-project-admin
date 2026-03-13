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
