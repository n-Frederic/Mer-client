"use client"

import { useState } from "react"
import { Calendar, BarChart3, Clock, User } from "lucide-react"
import EisenhowerMatrix from "@/components/EisenhowerMatrix"
import CalendarView from "@/components/CalendarView"
import LogView from "@/components/LogView"
import AnalyticsView from "@/components/AnalyticsView"
import ProfileView from "@/components/ProfileView"

type ViewType = "matrix" | "calendar" | "log" | "analytics" | "profile"

export default function Home() {
  const [currentView, setCurrentView] = useState<ViewType>("matrix")

  const renderCurrentView = () => {
    switch (currentView) {
      case "matrix":
        return <EisenhowerMatrix />
      case "calendar":
        return <CalendarView />
      case "log":
        return <LogView />
      case "analytics":
        return <AnalyticsView />
      case "profile":
        return <ProfileView />
      default:
        return <EisenhowerMatrix />
    }
  }

  return (
    <div className="flex flex-col h-screen max-w-md mx-auto bg-white shadow-2xl">
      {/* Header */}
      <div className="bg-gradient-to-r from-yellow-400 to-orange-400 p-4 text-white">
        <h1 className="text-3xl font-bold text-center script-text">Pandora</h1>
      </div>

      {/* Main Content */}
      <div className="flex-1 overflow-hidden">{renderCurrentView()}</div>

      {/* Bottom Navigation */}
      <div className="bg-yellow-50 border-t-2 border-yellow-200 p-2">
        <div className="flex justify-around items-center">
          <button
            onClick={() => setCurrentView("matrix")}
            className={`nav-item ${currentView === "matrix" ? "active" : ""}`}
          >
            <div className="w-8 h-8 mb-1 flex items-center justify-center">
              <div className="grid grid-cols-2 gap-0.5 w-5 h-5">
                <div className="bg-current rounded-sm opacity-70"></div>
                <div className="bg-current rounded-sm opacity-70"></div>
                <div className="bg-current rounded-sm opacity-70"></div>
                <div className="bg-current rounded-sm opacity-70"></div>
              </div>
            </div>
            <span className="text-xs">导图</span>
          </button>

          <button
            onClick={() => setCurrentView("calendar")}
            className={`nav-item ${currentView === "calendar" ? "active" : ""}`}
          >
            <Calendar className="w-6 h-6 mb-1" />
            <span className="text-xs">视图</span>
          </button>

          <button onClick={() => setCurrentView("log")} className={`nav-item ${currentView === "log" ? "active" : ""}`}>
            <Clock className="w-6 h-6 mb-1" />
            <span className="text-xs">日志</span>
          </button>

          <button
            onClick={() => setCurrentView("analytics")}
            className={`nav-item ${currentView === "analytics" ? "active" : ""}`}
          >
            <BarChart3 className="w-6 h-6 mb-1" />
            <span className="text-xs">AI地图</span>
          </button>

          <button
            onClick={() => setCurrentView("profile")}
            className={`nav-item ${currentView === "profile" ? "active" : ""}`}
          >
            <User className="w-6 h-6 mb-1" />
            <span className="text-xs">我的</span>
          </button>
        </div>
      </div>
    </div>
  )
}
