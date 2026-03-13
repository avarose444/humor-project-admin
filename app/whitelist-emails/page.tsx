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
