import { createClient } from "@/lib/supabase/server";
import Sidebar from "@/components/Sidebar";
import DashboardClient from "./DashboardClient";

export const dynamic = "force-dynamic";

const TWENTY_ONE_DAYS_AGO = new Date(Date.now() - 21 * 86400000).toISOString();

export default async function DashboardPage() {
  const sb = await createClient();

  const [
    { count: totalUsers },
    { count: totalImages },
    { count: totalCaptions },
    { count: totalVotes },
    { count: totalLikes },
    { count: bugReports },
    { count: studyUsers },
    { count: publicCaptions },
    { count: featuredCaptions },
    { data: captionsByDay },
    { data: topCaptions },
    { data: recentBugs },
    { data: flavorBreakdown },
  ] = await Promise.all([
    sb.from("profiles").select("*", { count: "exact", head: true }),
    sb.from("images").select("*", { count: "exact", head: true }),
    sb.from("captions").select("*", { count: "exact", head: true }),
    sb.from("caption_votes").select("*", { count: "exact", head: true }),
    sb.from("caption_likes").select("*", { count: "exact", head: true }),
    sb.from("bug_reports").select("*", { count: "exact", head: true }),
    sb.from("profiles").select("*", { count: "exact", head: true }).eq("is_in_study", true),
    sb.from("captions").select("*", { count: "exact", head: true }).eq("is_public", true),
    sb.from("captions").select("*", { count: "exact", head: true }).eq("is_featured", true),
    sb.from("captions").select("created_datetime_utc")
      .gte("created_datetime_utc", TWENTY_ONE_DAYS_AGO)
      .order("created_datetime_utc", { ascending: true }),
    sb.from("captions").select("id, content, like_count, is_featured, is_public")
      .order("like_count", { ascending: false }).limit(5),
    sb.from("bug_reports").select("id, subject, created_datetime_utc")
      .order("created_datetime_utc", { ascending: false }).limit(4),
    sb.from("captions").select("humor_flavor_id, humor_flavors(slug)")
      .not("humor_flavor_id", "is", null).limit(500),
  ]);

  const days = Array.from({ length: 21 }, (_, i) => {
    const d = new Date();
    d.setDate(d.getDate() - (20 - i));
    return d.toISOString().split("T")[0];
  });

  const dayMap: Record<string, number> = {};
  (captionsByDay || []).forEach(c => {
    const day = c.created_datetime_utc?.split("T")[0];
    if (day) dayMap[day] = (dayMap[day] || 0) + 1;
  });
  const chartData = days.map(d => ({ day: d.slice(5), count: dayMap[d] || 0 }));

  const flavorMap: Record<string, number> = {};
  (flavorBreakdown || []).forEach((c: { humor_flavor_id: number | null; humor_flavors: unknown }) => {
    const flavors = c.humor_flavors as { slug: string } | { slug: string }[] | null;
    const slug = Array.isArray(flavors) ? flavors[0]?.slug : flavors?.slug || `flavor_${c.humor_flavor_id}`;
    if (slug) flavorMap[slug] = (flavorMap[slug] || 0) + 1;
  });

  const flavorData = Object.entries(flavorMap)
    .sort((a, b) => b[1] - a[1])
    .slice(0, 6)
    .map(([slug, count]) => ({ slug, count }));

  return (
    <div style={{ display: "flex", minHeight: "100vh" }}>
      <Sidebar />
      <main style={{ flex: 1, marginLeft: "220px", padding: "2.5rem 2rem" }}>
        <DashboardClient stats={{
          totalUsers: totalUsers || 0,
          totalImages: totalImages || 0,
          totalCaptions: totalCaptions || 0,
          totalVotes: totalVotes || 0,
          totalLikes: totalLikes || 0,
          bugReports: bugReports || 0,
          studyUsers: studyUsers || 0,
          publicCaptions: publicCaptions || 0,
          featuredCaptions: featuredCaptions || 0,
          chartData,
          topCaptions: topCaptions || [],
          recentBugs: recentBugs || [],
          flavorData,
        }} />
      </main>
    </div>
  );
}