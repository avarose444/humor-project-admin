import { createClient } from "@/lib/supabase/server";
import Sidebar from "@/components/Sidebar";
import RatingsClient from "./RatingsClient";

export const dynamic = "force-dynamic";

export default async function RatingsPage() {
  const sb = await createClient();

  const [
    { data: voteDistribution },
    { data: topLiked },
    { data: mostVoted },
    { data: topDownvoted },
    { data: votesOverTime },
    { count: totalVotes },
    { data: avgData },
  ] = await Promise.all([
    // vote value breakdown
    sb.from("caption_votes").select("vote_value"),

    // top liked captions
    sb.from("captions")
      .select("id, content, like_count, humor_flavor_id, humor_flavors(slug)")
      .order("like_count", { ascending: false })
      .gt("like_count", 0)
      .limit(10),

    // most voted captions (by total vote count)
    sb.from("caption_votes")
      .select("caption_id")
      .limit(5000),

    // most downvoted
    sb.from("caption_votes")
      .select("caption_id, vote_value")
      .eq("vote_value", -1)
      .limit(5000),

    // votes over last 30 days
    sb.from("caption_votes")
      .select("created_datetime_utc, vote_value")
      .gte("created_datetime_utc", new Date(Date.now() - 30 * 86400000).toISOString())
      .order("created_datetime_utc", { ascending: true }),

    // total votes
    sb.from("caption_votes").select("*", { count: "exact", head: true }),

    // for avg calculation
    sb.from("caption_votes").select("vote_value").in("vote_value", [-1, 0, 1]),
  ]);

  // Vote distribution chart
  const distMap: Record<string, number> = {};
  (voteDistribution || []).forEach(v => {
    const key = String(v.vote_value);
    distMap[key] = (distMap[key] || 0) + 1;
  });
  const distData = Object.entries(distMap)
    .sort((a, b) => Number(a[0]) - Number(b[0]))
    .map(([value, count]) => ({ value: value === "-1" ? "Downvote" : value === "0" ? "Neutral" : value === "1" ? "Upvote" : `+${value}`, raw: Number(value), count }));

  // Most voted captions
  const voteCounts: Record<string, number> = {};
  (mostVoted || []).forEach(v => {
    voteCounts[v.caption_id] = (voteCounts[v.caption_id] || 0) + 1;
  });
  const topVotedIds = Object.entries(voteCounts)
    .sort((a, b) => b[1] - a[1])
    .slice(0, 8)
    .map(([id, count]) => ({ id, count }));

  // Most downvoted
  const downvoteCounts: Record<string, number> = {};
  (topDownvoted || []).forEach(v => {
    downvoteCounts[v.caption_id] = (downvoteCounts[v.caption_id] || 0) + 1;
  });
  const topDownvotedIds = Object.entries(downvoteCounts)
    .sort((a, b) => b[1] - a[1])
    .slice(0, 5)
    .map(([id, count]) => ({ id, count }));

  // Votes over time (daily buckets)
  const days = Array.from({ length: 30 }, (_, i) => {
    const d = new Date();
    d.setDate(d.getDate() - (29 - i));
    return d.toISOString().split("T")[0];
  });
  const upByDay: Record<string, number> = {};
  const downByDay: Record<string, number> = {};
  (votesOverTime || []).forEach(v => {
    const day = v.created_datetime_utc?.split("T")[0];
    if (!day) return;
    if (v.vote_value === 1) upByDay[day] = (upByDay[day] || 0) + 1;
    if (v.vote_value === -1) downByDay[day] = (downByDay[day] || 0) + 1;
  });
  const timeData = days.map(d => ({
    day: d.slice(5),
    up: upByDay[d] || 0,
    down: downByDay[d] || 0,
  }));

  // Avg vote value
  const validVotes = avgData || [];
  const avg = validVotes.length > 0
    ? (validVotes.reduce((sum, v) => sum + (v.vote_value || 0), 0) / validVotes.length).toFixed(3)
    : "0";

  const upvotes = distMap["1"] || 0;
  const downvotes = distMap["-1"] || 0;
  const totalUD = upvotes + downvotes;
  const upvotePct = totalUD > 0 ? Math.round((upvotes / totalUD) * 100) : 0;

  return (
    <div style={{ display: "flex", minHeight: "100vh" }}>
      <Sidebar />
      <main style={{ flex: 1, marginLeft: "220px", padding: "2.5rem 2rem" }}>
        <RatingsClient
          stats={{
            totalVotes: totalVotes || 0,
            upvotes,
            downvotes,
            upvotePct,
            avg,
            distData,
            timeData,
            topLiked: (topLiked || []).map(c => ({
              id: c.id,
              content: c.content,
              like_count: c.like_count,
              flavor: (c.humor_flavors as { slug: string } | null)?.slug || null,
            })),
            topVotedIds,
            topDownvotedIds,
          }}
        />
      </main>
    </div>
  );
}
