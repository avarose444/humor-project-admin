#!/bin/bash
# Run from root of humor-project-admin
# Usage: bash ratings.sh

echo "📊 Adding ratings statistics page..."

mkdir -p app/ratings

cat > app/ratings/page.tsx << 'EOF'
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
EOF

cat > app/ratings/RatingsClient.tsx << 'EOF'
"use client";
import {
  AreaChart, Area, BarChart, Bar, XAxis, YAxis, Tooltip,
  ResponsiveContainer, Cell, PieChart, Pie, Legend,
} from "recharts";
import { ThumbsUp, ThumbsDown, Activity, TrendingUp } from "lucide-react";

interface Stats {
  totalVotes: number;
  upvotes: number;
  downvotes: number;
  upvotePct: number;
  avg: string;
  distData: { value: string; raw: number; count: number }[];
  timeData: { day: string; up: number; down: number }[];
  topLiked: { id: string; content: string | null; like_count: number | null; flavor: string | null }[];
  topVotedIds: { id: string; count: number }[];
  topDownvotedIds: { id: string; count: number }[];
}

const DIST_COLORS: Record<string, string> = {
  "Downvote": "#f04f23",
  "Neutral": "#6b7280",
  "Upvote": "#b8f723",
};

const Tip = ({ active, payload, label }: { active?: boolean; payload?: { name: string; value: number; color: string }[]; label?: string }) => {
  if (!active || !payload?.length) return null;
  return (
    <div style={{ background: "var(--card)", border: "1px solid var(--border2)", padding: "0.5rem 0.75rem", borderRadius: "4px" }}>
      <p className="mono" style={{ fontSize: "0.65rem", color: "var(--slate)", marginBottom: "4px" }}>{label}</p>
      {payload.map(p => (
        <p key={p.name} className="mono" style={{ fontSize: "0.7rem", color: p.color }}>{p.name}: {p.value}</p>
      ))}
    </div>
  );
};

function StatCard({ icon: Icon, label, value, sub, color }: {
  icon: React.ElementType; label: string; value: string | number; sub?: string; color: string;
}) {
  return (
    <div className="card" style={{ padding: "1.25rem 1.5rem", position: "relative", overflow: "hidden" }}>
      <div style={{ position: "absolute", top: "-20px", right: "-20px", width: "80px", height: "80px", borderRadius: "50%", background: color, opacity: 0.06 }} />
      <div style={{ display: "flex", justifyContent: "space-between", alignItems: "flex-start", marginBottom: "0.875rem" }}>
        <div style={{ padding: "6px", borderRadius: "4px", background: `${color}18`, color }}><Icon size={14} /></div>
        <span className="mono" style={{ fontSize: "0.58rem", color: "var(--slate)", textTransform: "uppercase", letterSpacing: "0.1em" }}>{label}</span>
      </div>
      <div className="font-display" style={{ fontSize: "2.5rem", color: "var(--paper)", letterSpacing: "0.02em", lineHeight: 1 }}>
        {typeof value === "number" ? value.toLocaleString() : value}
      </div>
      {sub && <div className="mono" style={{ fontSize: "0.62rem", color: "var(--slate)", marginTop: "4px" }}>{sub}</div>}
    </div>
  );
}

export default function RatingsClient({ stats }: { stats: Stats }) {
  const { totalVotes, upvotes, downvotes, upvotePct, avg, distData, timeData, topLiked, topVotedIds, topDownvotedIds } = stats;

  return (
    <div>
      {/* Header */}
      <div className="fade-up" style={{ marginBottom: "2rem" }}>
        <div style={{ display: "flex", alignItems: "center", gap: "10px", marginBottom: "6px" }}>
          <div style={{ width: "28px", height: "1px", background: "var(--acid)" }} />
          <span className="mono" style={{ fontSize: "0.6rem", color: "var(--acid)", textTransform: "uppercase", letterSpacing: "0.12em" }}>Analytics</span>
        </div>
        <h1 className="font-display" style={{ fontSize: "4rem", color: "var(--paper)", letterSpacing: "0.04em", lineHeight: 1 }}>RATINGS</h1>
        <p style={{ color: "var(--slate)", fontSize: "0.85rem", marginTop: "6px" }}>How users are voting on captions</p>
      </div>

      {/* Stat cards */}
      <div style={{ display: "grid", gridTemplateColumns: "repeat(4, 1fr)", gap: "12px", marginBottom: "1.5rem" }}>
        <StatCard icon={Activity} label="Total Votes" value={totalVotes} sub="all time" color="var(--acid)" />
        <StatCard icon={ThumbsUp} label="Upvotes" value={upvotes} sub={`${upvotePct}% of up/down`} color="var(--acid)" />
        <StatCard icon={ThumbsDown} label="Downvotes" value={downvotes} sub={`${100 - upvotePct}% of up/down`} color="var(--rust)" />
        <StatCard icon={TrendingUp} label="Avg Vote" value={avg} sub="-1 to +1 scale" color="var(--blue)" />
      </div>

      {/* Upvote ratio bar */}
      <div className="card fade-up-1" style={{ padding: "1.25rem 1.5rem", marginBottom: "1.5rem" }}>
        <div style={{ display: "flex", justifyContent: "space-between", alignItems: "center", marginBottom: "0.75rem" }}>
          <p className="mono" style={{ fontSize: "0.6rem", color: "var(--slate)", textTransform: "uppercase", letterSpacing: "0.1em" }}>Upvote Ratio</p>
          <div style={{ display: "flex", gap: "1rem" }}>
            <span className="mono" style={{ fontSize: "0.7rem", color: "var(--acid)" }}>👍 {upvotePct}%</span>
            <span className="mono" style={{ fontSize: "0.7rem", color: "var(--rust)" }}>👎 {100 - upvotePct}%</span>
          </div>
        </div>
        <div style={{ height: "12px", background: "var(--border)", borderRadius: "6px", overflow: "hidden" }}>
          <div style={{ height: "100%", width: `${upvotePct}%`, background: "linear-gradient(90deg, var(--acid), #8bc34a)", borderRadius: "6px", transition: "width 1s ease" }} />
        </div>
      </div>

      {/* Charts row */}
      <div style={{ display: "grid", gridTemplateColumns: "2fr 1fr", gap: "16px", marginBottom: "16px" }}>

        {/* Votes over time */}
        <div className="card fade-up-2" style={{ padding: "1.5rem" }}>
          <p className="mono" style={{ fontSize: "0.58rem", color: "var(--slate)", textTransform: "uppercase", letterSpacing: "0.1em", marginBottom: "4px" }}>Trend</p>
          <h2 className="font-display" style={{ fontSize: "1.4rem", color: "var(--paper)", marginBottom: "1.25rem" }}>VOTES OVER 30 DAYS</h2>
          <ResponsiveContainer width="100%" height={200}>
            <AreaChart data={timeData} margin={{ top: 5, right: 5, left: -25, bottom: 0 }}>
              <defs>
                <linearGradient id="gradUp" x1="0" y1="0" x2="0" y2="1">
                  <stop offset="0%" stopColor="#b8f723" stopOpacity={0.3} />
                  <stop offset="100%" stopColor="#b8f723" stopOpacity={0} />
                </linearGradient>
                <linearGradient id="gradDown" x1="0" y1="0" x2="0" y2="1">
                  <stop offset="0%" stopColor="#f04f23" stopOpacity={0.3} />
                  <stop offset="100%" stopColor="#f04f23" stopOpacity={0} />
                </linearGradient>
              </defs>
              <XAxis dataKey="day" tick={{ fill: "var(--slate)", fontFamily: "'JetBrains Mono'", fontSize: 9 }} axisLine={false} tickLine={false} interval={5} />
              <YAxis tick={{ fill: "var(--slate)", fontFamily: "'JetBrains Mono'", fontSize: 9 }} axisLine={false} tickLine={false} allowDecimals={false} />
              <Tooltip content={<Tip />} />
              <Area type="monotone" dataKey="up" name="Upvotes" stroke="#b8f723" strokeWidth={1.5} fill="url(#gradUp)" dot={false} />
              <Area type="monotone" dataKey="down" name="Downvotes" stroke="#f04f23" strokeWidth={1.5} fill="url(#gradDown)" dot={false} />
            </AreaChart>
          </ResponsiveContainer>
        </div>

        {/* Vote distribution */}
        <div className="card fade-up-3" style={{ padding: "1.5rem" }}>
          <p className="mono" style={{ fontSize: "0.58rem", color: "var(--slate)", textTransform: "uppercase", letterSpacing: "0.1em", marginBottom: "4px" }}>Distribution</p>
          <h2 className="font-display" style={{ fontSize: "1.4rem", color: "var(--paper)", marginBottom: "1.25rem" }}>VOTE VALUES</h2>
          <ResponsiveContainer width="100%" height={200}>
            <BarChart data={distData} margin={{ top: 0, right: 5, left: -25, bottom: 0 }}>
              <XAxis dataKey="value" tick={{ fill: "var(--slate)", fontFamily: "'JetBrains Mono'", fontSize: 9 }} axisLine={false} tickLine={false} />
              <YAxis tick={{ fill: "var(--slate)", fontFamily: "'JetBrains Mono'", fontSize: 9 }} axisLine={false} tickLine={false} allowDecimals={false} />
              <Tooltip content={<Tip />} />
              <Bar dataKey="count" name="Votes" radius={[3, 3, 0, 0]}>
                {distData.map((entry, i) => (
                  <Cell key={i} fill={DIST_COLORS[entry.value] || "#9b6dff"} />
                ))}
              </Bar>
            </BarChart>
          </ResponsiveContainer>
        </div>
      </div>

      {/* Bottom row */}
      <div style={{ display: "grid", gridTemplateColumns: "1fr 1fr", gap: "16px" }}>

        {/* Top liked captions */}
        <div className="card" style={{ padding: "1.5rem" }}>
          <p className="mono" style={{ fontSize: "0.58rem", color: "var(--slate)", textTransform: "uppercase", letterSpacing: "0.1em", marginBottom: "3px" }}>Leaderboard</p>
          <h2 className="font-display" style={{ fontSize: "1.25rem", color: "var(--paper)", marginBottom: "1rem" }}>MOST LIKED</h2>
          {topLiked.length === 0 ? (
            <p style={{ color: "var(--slate)", fontSize: "0.8rem" }}>No data yet.</p>
          ) : topLiked.map((cap, i) => (
            <div key={cap.id} style={{ display: "flex", gap: "10px", alignItems: "flex-start", padding: "0.5rem 0", borderBottom: i < topLiked.length - 1 ? "1px solid var(--border)" : "none" }}>
              <span className="font-display" style={{ fontSize: "1.25rem", color: "var(--border2)", minWidth: "24px", lineHeight: 1, marginTop: "2px" }}>
                {String(i + 1).padStart(2, "0")}
              </span>
              <div style={{ flex: 1, minWidth: 0 }}>
                <p style={{ fontSize: "0.8rem", color: "var(--paper)", overflow: "hidden", textOverflow: "ellipsis", whiteSpace: "nowrap", marginBottom: "3px" }}>
                  &ldquo;{cap.content || "—"}&rdquo;
                </p>
                <div style={{ display: "flex", gap: "6px" }}>
                  <span className="badge badge-green">❤️ {cap.like_count ?? 0}</span>
                  {cap.flavor && <span className="badge badge-purple">{cap.flavor}</span>}
                </div>
              </div>
            </div>
          ))}
        </div>

        {/* Most voted (by volume) */}
        <div className="card" style={{ padding: "1.5rem" }}>
          <p className="mono" style={{ fontSize: "0.58rem", color: "var(--slate)", textTransform: "uppercase", letterSpacing: "0.1em", marginBottom: "3px" }}>By Volume</p>
          <h2 className="font-display" style={{ fontSize: "1.25rem", color: "var(--paper)", marginBottom: "1rem" }}>MOST VOTED ON</h2>
          {topVotedIds.length === 0 ? (
            <p style={{ color: "var(--slate)", fontSize: "0.8rem" }}>No data yet.</p>
          ) : topVotedIds.map((item, i) => (
            <div key={item.id} style={{ display: "flex", justifyContent: "space-between", alignItems: "center", padding: "0.5rem 0", borderBottom: i < topVotedIds.length - 1 ? "1px solid var(--border)" : "none" }}>
              <div style={{ display: "flex", gap: "10px", alignItems: "center", minWidth: 0, flex: 1 }}>
                <span className="font-display" style={{ fontSize: "1.1rem", color: "var(--border2)", minWidth: "20px" }}>
                  {String(i + 1).padStart(2, "0")}
                </span>
                <span className="mono" style={{ fontSize: "0.65rem", color: "var(--slate)", overflow: "hidden", textOverflow: "ellipsis", whiteSpace: "nowrap" }}>
                  {item.id.slice(0, 20)}...
                </span>
              </div>
              <span className="badge badge-gold">{item.count} votes</span>
            </div>
          ))}
          <div style={{ marginTop: "1rem", paddingTop: "1rem", borderTop: "1px solid var(--border)" }}>
            <p className="mono" style={{ fontSize: "0.58rem", color: "var(--slate)", textTransform: "uppercase", letterSpacing: "0.08em", marginBottom: "0.5rem" }}>Most Downvoted</p>
            {topDownvotedIds.slice(0, 3).map((item, i) => (
              <div key={item.id} style={{ display: "flex", justifyContent: "space-between", alignItems: "center", padding: "0.35rem 0" }}>
                <span className="mono" style={{ fontSize: "0.65rem", color: "var(--slate)" }}>{item.id.slice(0, 22)}...</span>
                <span className="badge badge-red">👎 {item.count}</span>
              </div>
            ))}
          </div>
        </div>
      </div>
    </div>
  );
}
EOF

echo ""
echo "✅ Ratings page written!"
echo ""
echo "Now run:"
echo "  git add ."
echo "  git commit -m 'feat: ratings analytics page'"
echo "  git push origin main"
