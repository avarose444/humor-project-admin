import type { Metadata } from "next";
import "./globals.css";

export const metadata: Metadata = {
  title: "Humor Study — Admin",
  description: "Superadmin control panel",
};

export default function RootLayout({ children }: { children: React.ReactNode }) {
  return (
    <html lang="en">
      <body>{children}</body>
    </html>
  );
}
