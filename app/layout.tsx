import type React from "react"
import type { Metadata } from "next"
import { Nunito, Dancing_Script } from "next/font/google"
import "./globals.css"

const nunito = Nunito({
  subsets: ["latin"],
  weight: ["300", "400", "500", "600", "700", "800"],
  display: "swap",
  variable: "--font-nunito",
})

const dancingScript = Dancing_Script({
  subsets: ["latin"],
  weight: ["400", "500", "600", "700"],
  display: "swap",
  variable: "--font-dancing-script",
})

export const metadata: Metadata = {
  title: "Pandora - 任务管理",
  description: "简约风格的任务管理应用",
    generator: 'v0.app'
}

export default function RootLayout({
  children,
}: {
  children: React.ReactNode
}) {
  return (
    <html lang="zh-CN">
      <body className={`${nunito.variable} ${dancingScript.variable} ${nunito.className}`}>
        <div className="min-h-screen bg-yellow-50">{children}</div>
      </body>
    </html>
  )
}
