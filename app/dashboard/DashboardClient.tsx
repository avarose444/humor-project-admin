"use client";
import { AreaChart, Area, BarChart, Bar, XAxis, YAxis, Tooltip, ResponsiveContainer, Cell } from "recharts";
import { Users, Image, MessageSquare, ThumbsUp, Heart, Bug, Star, Globe } from "lucide-react";

interface Stats {
  totalUsers: number; totalImages: number; totalCaptions: number;
  totalVotes: number; totalLikes: number; bugReports: number;
  studyUsers: number; publicCaptions: number; featuredCaptions: number;
  chartData: { day: string; count: number }[];
  topCaptions: { id: string; content: string | null; like_count: number | null; is_featured: boolean | null; is_public: boolean | null }[];
  recentBugs: { id: number; subject: string | null; created_datetime_utc: string | null }[];
  flavorData: { slug: string; count: number }[];
}

const COLORS = ["#b8f723", "#4f8ef0", "#9b6dff", "#f0b823", "#f04f23", "#4ade80"];

const Tip = ({ active, payload, label }: { active?: boolean; payload?: { value: number }[]; label?: string }) => {
  if (!active || !payload?.length) return null;
  return (
    <div style={{ background: "var(--card)", border: "1px solid var(--border2)", padding: "0.5rem 0.75rem", borderRadius: "4px" }}>
      <p className="mono" style={{ fontSize: "0.65rem", color: "var(--slate)", marginBottom: "2px" }}>{label}</p>
      <p className="mono" style={{ fontSize: "0.75rem", color: "var(--acid)" }}>{payload[0].value} captions</p>
    </div>
  );
};

const FlavorTip = ({ active, payload }: { active?: boolean; payload?: { value: number; payload: { slug: string } }[] }) => {
  if (!active || !payload?.length) return null;
  return (
    <div style={{ background: "var(--card)", border: "1px solid var(--border2)", padding: "0.5rem 0.75rem", borderRadius: "4px" }}>
      <p className="mono" style={{ fontSize: "0.65rem", color: "var(--slate)" }}>{payload[0].payload.slug}</p>
      <p className="mono" style={{ fontSize: "0.75rem", color: "var(--acid)" }}>{payload[0].value}</p>
    </div>
  );
};

function StatCard({ icon: Icon, label, value, sub, color, delay }: {
  icon: React.ElementType; label: string; value: string | number; sub?: string; color: string; delay: number;
}) {
  return (
    <div className={`card fade-up-${delay}`} style={{ padding: "1.25rem 1.5rem", position: "relative", overflow: "hidden" }}>
      <div style={{ position: "absolute", top: "-20px", right: "-20px", width: "80px", height: "80px", borderRadius: "50%", background: color, opacity: 0.06 }} />
      <div style={{ display: "flex", justifyContent: "space-between", alignItems: "flex-start", marginBottom: "1rem" }}>
        <div style={{ padding: "6px", borderRadius: "4px", background: `${color}18`, color }}><Icon size={14} /></div>
        <span className="mono" style={{ fontSize: "0.58rem", color: "var(--slate)", textTransform: "uppercase", letterSpacing: "0.1em" }}>{label}</span>
      </div>
      <div className="font-display" style={{ fontSize: "2.75rem", color: "var(--paper)", letterSpacing: "0.02em", lineHeight: 1 }}>
        {typeof value === "number" ? value.toLocaleString() : value}
      </div>
      {sub && <div className="mono" style={{ fontSize: "0.62rem", color: "var(--slate)", marginTop: "4px" }}>{sub}</div>}
    </div>
  );
}

export default function DashboardClient({ stats }: { stats: Stats }) {
  const { totalUsers, totalImages, totalCaptions, totalVotes, totalLikes, bugReports,
    studyUsers, publicCaptions, featuredCaptions, chartData, topCaptions, recentBugs, flavorData } = stats;

  const studyPct = totalUsers > 0 ? Math.round((studyUsers / totalUsers) * 100) : 0;
  const publicPct = totalCaptions > 0 ? Math.round((publicCaptions / totalCaptions) * 100) : 0;
  const avgVotes = totalCaptions > 0 ? (totalVotes / totalCaptions).toFixed(1) : "0";

  return (
    <div>
      <div className="fade-up" style={{ marginBottom: "2.5rem" }}>
        <div style={{ display: "flex", alignItems: "center", gap: "10px", marginBottom: "6px" }}>
          <div style={{ width: "28px", height: "1px", background: "var(--acid)" }} />
          <span className="mono" style={{ fontSize: "0.6rem", color: "var(--acid)", textTransform: "uppercase", letterSpacing: "0.12em" }}>Overview</span>
        </div>
        <h1 className="font-display" style={{ fontSize: "4rem", color: "var(--paper)", letterSpacing: "0.04em", lineHeight: 1 }}>DASHBOARD</h1>
        <p style={{ color: "var(--slate)", fontSize: "0.85rem", marginTop: "6px" }}>Platform health at a glance</p>
      </div>

      <div style={{ display: "grid", gridTemplateColumns: "repeat(4, 1fr)", gap: "12px", marginBottom: "12px" }}>
        <StatCard icon={Users} label="Total Users" value={totalUsers} sub={`${studyUsers} in study (${studyPct}%)`} color="var(--acid)" delay={1} />
        <StatCard icon={Image} label="Images" value={totalImages} sub="in library" color="var(--blue)" delay={2} />
        <StatCard icon={MessageSquare} label="Captions" value={totalCaptions} sub={`${publicPct}% public`} color="var(--purple)" delay={3} />
        <StatCard icon={ThumbsUp} label="Votes Cast" value={totalVotes} sub={`${avgVotes} avg per caption`} color="var(--gold)" delay={4} />
      </div>
      <div style={{ display: "grid", gridTemplateColumns: "repeat(4, 1fr)", gap: "12px", marginBottom: "2rem" }}>
        <StatCard icon={Heart} label="Caption Likes" value={totalLikes} sub="total engagements" color="var(--rust)" delay={1} />
        <StatCard icon={Star} label="Featured" value={featuredCaptions} sub="hand-picked captions" color="var(--gold)" delay={2} />
        <StatCard icon={Globe} label="Public Captions" value={publicCaptions} sub="visible to all" color="var(--blue)" delay={3} />
        <StatCard icon={Bug} label="Bug Reports" value={bugReports} sub="submitted reports" color="var(--rust)" delay={4} />
      </div>

      <div style={{ display: "grid", gridTemplateColumns: "2fr 1fr", gap: "16px", marginBottom: "16px" }}>
        <div className="card fade-up-5" style={{ padding: "1.5rem" }}>
          <p className="mono" style={{ fontSize: "0.58rem", color: "var(--slate)", textTransform: "uppercase", letterSpacing: "0.1em", marginBottom: "4px" }}>Activity</p>
          <h2 className="font-display" style={{ fontSize: "1.5rem", color: "var(--paper)", marginBottom: "1.25rem" }}>CAPTION VOLUME — 21 DAYS</h2>
          <ResponsiveContainer width="100%" height={200}>
            <AreaChart data={chartData} margin={{ top: 5, right: 5, left: -25, bottom: 0 }}>
              <defs>
                <linearGradient id="grad" x1="0" y1="0" x2="0" y2="1">
                  <stop offset="0%" stopColor="#b8f723" stopOpacity={0.25} />
                  <stop offset="100%" stopColor="#b8f723" stopOpacity={0} />
                </linearGradient>
              </defs>
              <XAxis dataKey="day" tick={{ fill: "var(--slate)", fontFamily: "'JetBrains Mono'", fontSize: 9 }} axisLine={false} tickLine={false} interval={3} />
              <YAxis tick={{ fill: "var(--slate)", fontFamily: "'JetBrains Mono'", fontSize: 9 }} axisLine={false} tickLine={false} allowDecimals={false} />
              <Tooltip content={<Tip />} />
              <Area type="monotone" dataKey="count" stroke="#b8f723" strokeWidth={1.5} fill="url(#grad)" dot={false} />
            </AreaChart>
          </ResponsiveContainer>
        </div>
        <div className="card fade-up-6" style={{ padding: "1.5rem" }}>
          <p className="mono" style={{ fontSize: "0.58rem", color: "var(--slate)", textTransform: "uppercase", letterSpacing: "0.1em", marginBottom: "4px" }}>Distribution</p>
          <h2 className="font-display" style={{ fontSize: "1.5rem", color: "var(--paper)", marginBottom: "1.25rem" }}>HUMOR FLAVORS</h2>
          {flavorData.length === 0 ? <p style={{ color: "var(--slate)", fontSize: "0.8rem" }}>No flavor data yet.</p> : (
            <ResponsiveContainer width="100%" height={200}>
              <BarChart data={flavorData} layout="vertical" margin={{ top: 0, right: 10, left: 0, bottom: 0 }}>
                <XAxis type="number" tick={{ fill: "var(--slate)", fontFamily: "'JetBrains Mono'", fontSize: 9 }} axisLine={false} tickLine={false} />
                <YAxis type="category" dataKey="slug" tick={{ fill: "var(--muted)", fontFamily: "'JetBrains Mono'", fontSize: 9 }} axisLine={false} tickLine={false} width={80} />
                <Tooltip content={<FlavorTip />} />
                <Bar dataKey="count" radius={[0, 3, 3, 0]}>
                  {flavorData.map((_, i) => <Cell key={i} fill={COLORS[i % COLORS.length]} />)}
                </Bar>
              </BarChart>
            </ResponsiveContainer>
          )}
        </div>
      </div>

      <div style={{ display: "grid", gridTemplateColumns: "1fr 1fr", gap: "16px" }}>
        <div className="card" style={{ padding: "1.5rem" }}>
          <p className="mono" style={{ fontSize: "0.58rem", color: "var(--slate)", textTransform: "uppercase", letterSpacing: "0.1em", marginBottom: "3px" }}>Leaderboard</p>
          <h2 className="font-display" style={{ fontSize: "1.25rem", color: "var(--paper)", marginBottom: "1rem" }}>TOP CAPTIONS</h2>
          {topCaptions.length === 0 ? <p style={{ color: "var(--slate)", fontSize: "0.8rem" }}>No captions yet.</p> : topCaptions.map((cap, i) => (
            <div key={cap.id} style={{ display: "flex", gap: "12px", alignItems: "flex-start", padding: "0.6rem 0", borderBottom: i < topCaptions.length - 1 ? "1px solid var(--border)" : "none" }}>
              <span className="font-display" style={{ fontSize: "1.5rem", color: "var(--border2)", minWidth: "24px", lineHeight: 1, marginTop: "2px" }}>{String(i + 1).padStart(2, "0")}</span>
              <div style={{ flex: 1, minWidth: 0 }}>
                <p style={{ fontSize: "0.82rem", color: "var(--paper)", overflow: "hidden", textOverflow: "ellipsis", whiteSpace: "nowrap", marginBottom: "4px" }}>&ldquo;{cap.content || "—"}&rdquo;</p>
                <div style={{ display: "flex", gap: "6px" }}>
                  <span className="badge badge-green">{cap.like_count ?? 0} likes</span>
                  {cap.is_featured && <span className="badge badge-gold">Featured</span>}
                  {cap.is_public ? <span className="badge badge-blue">Public</span> : <span className="badge badge-gray">Private</span>}
                </div>
              </div>
            </div>
          ))}
        </div>
        <div className="card" style={{ padding: "1.5rem" }}>
          <p className="mono" style={{ fontSize: "0.58rem", color: "var(--slate)", textTransform: "uppercase", letterSpacing: "0.1em", marginBottom: "3px" }}>Support</p>
          <h2 className="font-display" style={{ fontSize: "1.25rem", color: "var(--paper)", marginBottom: "1rem" }}>RECENT BUG REPORTS</h2>
          {recentBugs.length === 0 ? (
            <div style={{ display: "flex", flexDirection: "column", alignItems: "center", justifyContent: "center", height: "120px" }}>
              <p style={{ color: "var(--acid)", fontSize: "0.85rem" }}>✓ No bugs reported</p>
            </div>
          ) : recentBugs.map((bug, i) => (
            <div key={bug.id} style={{ padding: "0.6rem 0", borderBottom: i < recentBugs.length - 1 ? "1px solid var(--border)" : "none" }}>
              <div style={{ display: "flex", justifyContent: "space-between", marginBottom: "3px" }}>
                <p style={{ fontSize: "0.82rem", color: "var(--paper)", fontWeight: 500 }}>{bug.subject || "No subject"}</p>
                <span className="badge badge-red">Open</span>
              </div>
              <p className="mono" style={{ fontSize: "0.62rem", color: "var(--slate)" }}>
                {bug.created_datetime_utc ? new Date(bug.created_datetime_utc).toLocaleDateString() : "—"}
              </p>
            </div>
          ))}
        </div>
      </div>
    </div>
  );
}
