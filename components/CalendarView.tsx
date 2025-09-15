"use client"

import { useState } from "react"
import { ChevronLeft, ChevronRight } from "lucide-react"

type ViewMode = "day" | "month" | "year"

export default function CalendarView() {
  const [viewMode, setViewMode] = useState<ViewMode>("month")
  const [currentDate, setCurrentDate] = useState(new Date())

  const monthNames = [
    "一月",
    "二月",
    "三月",
    "四月",
    "五月",
    "六月",
    "七月",
    "八月",
    "九月",
    "十月",
    "十一月",
    "十二月",
  ]

  const weekDays = ["日", "一", "二", "三", "四", "五", "六"]

  const getDaysInMonth = (date: Date) => {
    const year = date.getFullYear()
    const month = date.getMonth()
    const firstDay = new Date(year, month, 1)
    const lastDay = new Date(year, month + 1, 0)
    const daysInMonth = lastDay.getDate()
    const startingDayOfWeek = firstDay.getDay()

    const days = []

    // Add empty cells for days before the first day of the month
    for (let i = 0; i < startingDayOfWeek; i++) {
      days.push(null)
    }

    // Add days of the month
    for (let day = 1; day <= daysInMonth; day++) {
      days.push(day)
    }

    return days
  }

  const navigateMonth = (direction: "prev" | "next") => {
    setCurrentDate((prev) => {
      const newDate = new Date(prev)
      if (direction === "prev") {
        newDate.setMonth(prev.getMonth() - 1)
      } else {
        newDate.setMonth(prev.getMonth() + 1)
      }
      return newDate
    })
  }

  const sampleEvents = [
    { date: 5, title: "项目会议", color: "bg-blue-200" },
    { date: 12, title: "客户拜访", color: "bg-green-200" },
    { date: 18, title: "培训课程", color: "bg-yellow-200" },
    { date: 25, title: "月度总结", color: "bg-purple-200" },
  ]

  const getEventsForDate = (date: number) => {
    return sampleEvents.filter((event) => event.date === date)
  }

  const renderMonthView = () => {
    const days = getDaysInMonth(currentDate)

    return (
      <div className="p-4">
        {/* Header */}
        <div className="flex items-center justify-between mb-4">
          <button onClick={() => navigateMonth("prev")} className="p-2 rounded-full hover:bg-yellow-100">
            <ChevronLeft className="w-5 h-5" />
          </button>
          <h2 className="text-lg font-bold text-gray-700">
            {currentDate.getFullYear()}年 {monthNames[currentDate.getMonth()]}
          </h2>
          <button onClick={() => navigateMonth("next")} className="p-2 rounded-full hover:bg-yellow-100">
            <ChevronRight className="w-5 h-5" />
          </button>
        </div>

        {/* Week days header */}
        <div className="grid grid-cols-7 gap-1 mb-2">
          {weekDays.map((day) => (
            <div key={day} className="text-center text-xs font-medium text-gray-500 p-2">
              {day}
            </div>
          ))}
        </div>

        {/* Calendar grid */}
        <div className="grid grid-cols-7 gap-1">
          {days.map((day, index) => (
            <div key={index} className="aspect-square">
              {day && (
                <div className="h-full bg-white rounded-lg border border-gray-200 p-1 relative">
                  <div className="text-xs font-medium text-gray-700">{day}</div>
                  <div className="mt-1 space-y-1">
                    {getEventsForDate(day).map((event, eventIndex) => (
                      <div key={eventIndex} className={`${event.color} rounded px-1 py-0.5 text-xs truncate`}>
                        {event.title}
                      </div>
                    ))}
                  </div>
                </div>
              )}
            </div>
          ))}
        </div>
      </div>
    )
  }

  const renderDayView = () => {
    const today = new Date()
    const hours = Array.from({ length: 24 }, (_, i) => i)

    return (
      <div className="p-4">
        <div className="text-center mb-4">
          <h2 className="text-lg font-bold text-gray-700">
            {today.getFullYear()}年{today.getMonth() + 1}月{today.getDate()}日
          </h2>
        </div>

        <div className="space-y-2 max-h-96 overflow-y-auto">
          {hours.map((hour) => (
            <div key={hour} className="flex items-center space-x-3">
              <div className="w-12 text-xs text-gray-500 text-right">{hour.toString().padStart(2, "0")}:00</div>
              <div className="flex-1 h-12 bg-white rounded-lg border border-gray-200 p-2">
                {hour === 9 && <div className="bg-blue-200 rounded px-2 py-1 text-xs">团队会议</div>}
                {hour === 14 && <div className="bg-green-200 rounded px-2 py-1 text-xs">客户电话</div>}
              </div>
            </div>
          ))}
        </div>
      </div>
    )
  }

  const renderYearView = () => {
    const months = Array.from({ length: 12 }, (_, i) => i)

    return (
      <div className="p-4">
        <div className="text-center mb-4">
          <h2 className="text-lg font-bold text-gray-700">{currentDate.getFullYear()}年</h2>
        </div>

        <div className="grid grid-cols-3 gap-4">
          {months.map((month) => (
            <div key={month} className="bg-white rounded-lg border border-gray-200 p-3">
              <div className="text-center text-sm font-medium text-gray-700 mb-2">{monthNames[month]}</div>
              <div className="grid grid-cols-7 gap-1">
                {Array.from({ length: 31 }, (_, day) => (
                  <div key={day} className="w-2 h-2 bg-gray-100 rounded-full"></div>
                ))}
              </div>
            </div>
          ))}
        </div>
      </div>
    )
  }

  return (
    <div className="h-full bg-gradient-to-br from-yellow-50 to-orange-50">
      {/* View Mode Selector */}
      <div className="flex justify-center p-4 bg-white border-b border-gray-200">
        <div className="flex bg-gray-100 rounded-full p-1">
          {(["day", "month", "year"] as ViewMode[]).map((mode) => (
            <button
              key={mode}
              onClick={() => setViewMode(mode)}
              className={`px-4 py-2 rounded-full text-sm font-medium transition-all ${
                viewMode === mode
                  ? "bg-gradient-to-r from-yellow-400 to-orange-400 text-white shadow-md"
                  : "text-gray-600 hover:text-gray-800"
              }`}
            >
              {mode === "day" ? "日" : mode === "month" ? "月" : "年"}
            </button>
          ))}
        </div>
      </div>

      {/* Content */}
      <div className="flex-1 overflow-auto">
        {viewMode === "day" && renderDayView()}
        {viewMode === "month" && renderMonthView()}
        {viewMode === "year" && renderYearView()}
      </div>
    </div>
  )
}
