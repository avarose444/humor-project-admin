import { createClient } from "@/lib/supabase/server";
import Sidebar from "@/components/Sidebar";
import ImagesClient from "./ImagesClient";

export const dynamic = "force-dynamic";

export default async function ImagesPage() {
  const sb = await createClient();
  const { data: images, error } = await sb
    .from("images")
    .select("id, url, image_description, additional_context, is_public, is_common_use, created_datetime_utc")
    .order("created_datetime_utc", { ascending: false });

  return (
    <div style={{ display: "flex", minHeight: "100vh" }}>
      <Sidebar />
      <main style={{ flex: 1, marginLeft: "220px", padding: "2.5rem 2rem" }}>
        <ImagesClient initialImages={images || []} fetchError={error?.message} />
      </main>
    </div>
  );
}
