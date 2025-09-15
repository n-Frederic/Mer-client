"use client"

import { Settings, Bell, Palette, HelpCircle, LogOut, User } from "lucide-react"

export default function ProfileView() {
  const menuItems = [
    { icon: User, label: "个人信息", color: "text-blue-500" },
    { icon: Bell, label: "通知设置", color: "text-green-500" },
    { icon: Palette, label: "主题设置", color: "text-purple-500" },
    { icon: Settings, label: "应用设置", color: "text-gray-500" },
    { icon: HelpCircle, label: "帮助中心", color: "text-orange-500" },
  ]

  return (
    <div className="h-full bg-gradient-to-br from-yellow-50 to-orange-50">
      {/* Profile Header */}
      <div className="bg-gradient-to-r from-yellow-400 to-orange-400 p-6 text-white">
        <div className="flex items-center space-x-4">
          <div className="w-16 h-16 bg-white rounded-full flex items-center justify-center shadow-lg">
            <span className="text-3xl">🐰</span>
          </div>
          <div>
            <h2 className="text-xl font-bold">小兔子</h2>
            <p className="text-yellow-100 text-sm">高效工作者</p>
          </div>
        </div>

        {/* Stats */}
        <div className="flex justify-around mt-6 pt-4 border-t border-yellow-300">
          <div className="text-center">
            <div className="text-2xl font-bold">156</div>
            <div className="text-xs text-yellow-100">完成任务</div>
          </div>
          <div className="text-center">
            <div className="text-2xl font-bold">89</div>
            <div className="text-xs text-yellow-100">日志记录</div>
          </div>
          <div className="text-center">
            <div className="text-2xl font-bold">245</div>
            <div className="text-xs text-yellow-100">工作天数</div>
          </div>
        </div>
      </div>

      {/* Menu Items */}
      <div className="p-4 space-y-3">
        {menuItems.map((item, index) => (
          <div
            key={index}
            className="bg-white rounded-2xl p-4 shadow-md flex items-center space-x-4 hover:shadow-lg transition-shadow"
          >
            <div className={`w-10 h-10 rounded-full bg-gray-100 flex items-center justify-center ${item.color}`}>
              <item.icon className="w-5 h-5" />
            </div>
            <div className="flex-1">
              <div className="font-medium text-gray-800">{item.label}</div>
            </div>
            <div className="text-gray-400">
              <svg className="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M9 5l7 7-7 7" />
              </svg>
            </div>
          </div>
        ))}
      </div>

      {/* Achievement Section */}
      <div className="p-4">
        <div className="bg-white rounded-2xl p-4 shadow-md">
          <h3 className="font-bold text-gray-800 mb-3 flex items-center">
            <span className="text-yellow-500 mr-2">🏆</span>
            最近成就
          </h3>

          <div className="space-y-3">
            <div className="flex items-center space-x-3">
              <div className="text-2xl">🎯</div>
              <div>
                <div className="font-medium text-sm text-gray-800">任务达人</div>
                <div className="text-xs text-gray-600">连续7天完成所有任务</div>
              </div>
            </div>

            <div className="flex items-center space-x-3">
              <div className="text-2xl">📝</div>
              <div>
                <div className="font-medium text-sm text-gray-800">记录专家</div>
                <div className="text-xs text-gray-600">本月记录了50条日志</div>
              </div>
            </div>

            <div className="flex items-center space-x-3">
              <div className="text-2xl">⚡</div>
              <div>
                <div className="font-medium text-sm text-gray-800">效率之星</div>
                <div className="text-xs text-gray-600">工作效率提升20%</div>
              </div>
            </div>
          </div>
        </div>
      </div>

      {/* Logout Button */}
      <div className="p-4">
        <button className="w-full bg-red-100 text-red-600 rounded-2xl p-4 flex items-center justify-center space-x-2 hover:bg-red-200 transition-colors">
          <LogOut className="w-5 h-5" />
          <span className="font-medium">退出登录</span>
        </button>
      </div>
    </div>
  )
}
