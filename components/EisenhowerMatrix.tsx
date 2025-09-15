"use client"

import type React from "react"

import { Plus, Edit3, Eye, ChevronRight } from "lucide-react"
import { useState } from "react"

interface CompanyItem {
  id: string
  title: string
  description: string
  priority: "high" | "medium" | "low"
  status: "active" | "completed" | "pending"
}

interface PersonalItem {
  id: string
  title: string
  description: string
  dueDate?: Date
  completed: boolean
}

interface LogEntry {
  id: string
  title: string
  content: string
  date: Date
  mood: "😊" | "😐" | "😔" | "😴" | "🔥"
}

export default function EisenhowerMatrix() {
  const [personalNote, setPersonalNote] = useState("今天要专注完成重要任务，保持高效工作状态！")
  const [isEditingNote, setIsEditingNote] = useState(false)

  // 公司10大重要事项（只读）
  const [companyImportantItems] = useState<CompanyItem[]>([
    { id: "1", title: "Q4季度业绩目标达成", description: "确保完成年度业绩指标", priority: "high", status: "active" },
    { id: "2", title: "新产品发布准备", description: "准备新产品上市相关工作", priority: "high", status: "active" },
    { id: "3", title: "客户满意度提升项目", description: "改善客户服务质量", priority: "medium", status: "active" },
    { id: "4", title: "团队建设活动", description: "增强团队凝聚力", priority: "medium", status: "pending" },
    { id: "5", title: "技术架构升级", description: "系统性能优化", priority: "high", status: "active" },
  ])

  // 公司10大派发任务（只读）
  const [companyTasks] = useState<CompanyItem[]>([
    { id: "1", title: "完成Q4季度报告", description: "整理季度工作总结", priority: "high", status: "active" },
    { id: "2", title: "参与新员工培训", description: "协助新人入职培训", priority: "medium", status: "pending" },
    { id: "3", title: "客户服务流程优化", description: "改进服务流程", priority: "medium", status: "active" },
    { id: "4", title: "年度总结材料准备", description: "准备年终汇报材料", priority: "high", status: "active" },
    { id: "5", title: "市场推广活动支持", description: "配合市场部活动", priority: "low", status: "pending" },
  ])

  // 个人10大重要事项（可编辑）
  const [personalItems, setPersonalItems] = useState<PersonalItem[]>([
    { id: "1", title: "完成项目里程碑", description: "按时交付项目阶段成果", completed: false },
    { id: "2", title: "学习新技术栈", description: "提升专业技能", completed: false },
    { id: "3", title: "制定职业规划", description: "明确未来发展方向", completed: true },
    { id: "4", title: "改善工作流程", description: "提高工作效率", completed: false },
    { id: "5", title: "加强团队沟通", description: "增进同事关系", completed: false },
  ])

  // 个人日志（可编辑）
  const [personalLogs, setPersonalLogs] = useState<LogEntry[]>([
    {
      id: "1",
      title: "项目进展顺利",
      content: "今天完成了重要功能开发",
      date: new Date(),
      mood: "😊",
    },
    {
      id: "2",
      title: "学习新知识",
      content: "掌握了React新特性",
      date: new Date(Date.now() - 86400000),
      mood: "🔥",
    },
    {
      id: "3",
      title: "团队协作",
      content: "与同事讨论技术方案",
      date: new Date(Date.now() - 172800000),
      mood: "😐",
    },
  ])

  const handleSaveNote = () => {
    setIsEditingNote(false)
    // 这里可以添加保存到后端的逻辑
  }

  const togglePersonalItem = (id: string) => {
    setPersonalItems((prev) => prev.map((item) => (item.id === id ? { ...item, completed: !item.completed } : item)))
  }

  const getPriorityColor = (priority: "high" | "medium" | "low") => {
    switch (priority) {
      case "high":
        return "text-red-600 bg-red-50"
      case "medium":
        return "text-orange-600 bg-orange-50"
      case "low":
        return "text-green-600 bg-green-50"
    }
  }

  const getStatusColor = (status: "active" | "completed" | "pending") => {
    switch (status) {
      case "active":
        return "text-blue-600 bg-blue-50"
      case "completed":
        return "text-green-600 bg-green-50"
      case "pending":
        return "text-gray-600 bg-gray-50"
    }
  }

  const QuadrantCard = ({
    title,
    children,
    bgColor,
    isReadOnly = false,
    onEdit,
  }: {
    title: string
    children: React.ReactNode
    bgColor: string
    isReadOnly?: boolean
    onEdit?: () => void
  }) => (
    <div className={`${bgColor} rounded-3xl p-4 border-2 border-gray-200 shadow-lg relative overflow-hidden h-full`}>
      <div className="flex items-center justify-between mb-3">
        <h3 className="text-sm font-bold text-gray-700 cute-text">{title}</h3>
        <div className="flex items-center space-x-1">
          {isReadOnly ? (
            <Eye className="w-4 h-4 text-gray-500" />
          ) : (
            <button onClick={onEdit} className="p-1 rounded-full hover:bg-white/50 transition-colors">
              <Edit3 className="w-4 h-4 text-gray-600" />
            </button>
          )}
          <ChevronRight className="w-4 h-4 text-gray-500" />
        </div>
      </div>
      <div className="space-y-2 max-h-48 overflow-y-auto">{children}</div>
    </div>
  )

  return (
    <div className="p-4 h-full flex flex-col">
      {/* 上方个人备注区域 */}
      <div className="mb-4">
        <div className="bg-gradient-to-r from-yellow-100 to-orange-100 rounded-2xl p-4 border-2 border-orange-200">
          <div className="flex items-center justify-between mb-2">
            <h2 className="text-sm font-bold text-gray-700 flex items-center">
              <span className="mr-2">📝</span>
              个人备注
            </h2>
            <button
              onClick={() => setIsEditingNote(!isEditingNote)}
              className="p-1 rounded-full hover:bg-white/50 transition-colors"
            >
              <Edit3 className="w-4 h-4 text-gray-600" />
            </button>
          </div>
          {isEditingNote ? (
            <div className="space-y-2">
              <textarea
                value={personalNote}
                onChange={(e) => setPersonalNote(e.target.value)}
                className="w-full p-2 bg-white rounded-lg border border-orange-200 text-sm resize-none"
                rows={2}
                placeholder="添加个人备注..."
              />
              <div className="flex justify-end space-x-2">
                <button
                  onClick={() => setIsEditingNote(false)}
                  className="px-3 py-1 text-xs text-gray-600 hover:text-gray-800"
                >
                  取消
                </button>
                <button
                  onClick={handleSaveNote}
                  className="px-3 py-1 bg-orange-400 text-white rounded-lg text-xs hover:bg-orange-500"
                >
                  保存
                </button>
              </div>
            </div>
          ) : (
            <p className="text-sm text-gray-600 leading-relaxed">{personalNote}</p>
          )}
        </div>
      </div>

      {/* 四象限布局 */}
      <div className="grid grid-cols-2 gap-4 flex-1">
        {/* 左上：公司10大重要事项（只读） */}
        <QuadrantCard title="公司10大重要事项" bgColor="bg-gradient-to-br from-red-100 to-pink-100" isReadOnly={true}>
          {companyImportantItems.slice(0, 5).map((item) => (
            <div key={item.id} className="bg-white/70 rounded-xl p-2">
              <div className="flex items-center justify-between mb-1">
                <h4 className="text-xs font-medium text-gray-800 truncate">{item.title}</h4>
                <span className={`text-xs px-2 py-0.5 rounded-full ${getPriorityColor(item.priority)}`}>
                  {item.priority === "high" ? "高" : item.priority === "medium" ? "中" : "低"}
                </span>
              </div>
              <p className="text-xs text-gray-600 truncate">{item.description}</p>
              <span className={`text-xs px-2 py-0.5 rounded-full ${getStatusColor(item.status)} mt-1 inline-block`}>
                {item.status === "active" ? "进行中" : item.status === "completed" ? "已完成" : "待开始"}
              </span>
            </div>
          ))}
          <div className="text-center mt-2">
            <span className="text-xs text-gray-500">查看全部 {companyImportantItems.length} 项</span>
          </div>
        </QuadrantCard>

        {/* 右上：公司10大派发任务（只读） */}
        <QuadrantCard
          title="公司10大派发任务"
          bgColor="bg-gradient-to-br from-blue-100 to-indigo-100"
          isReadOnly={true}
        >
          {companyTasks.slice(0, 5).map((task) => (
            <div key={task.id} className="bg-white/70 rounded-xl p-2">
              <div className="flex items-center justify-between mb-1">
                <h4 className="text-xs font-medium text-gray-800 truncate">{task.title}</h4>
                <span className={`text-xs px-2 py-0.5 rounded-full ${getPriorityColor(task.priority)}`}>
                  {task.priority === "high" ? "高" : task.priority === "medium" ? "中" : "低"}
                </span>
              </div>
              <p className="text-xs text-gray-600 truncate">{task.description}</p>
              <span className={`text-xs px-2 py-0.5 rounded-full ${getStatusColor(task.status)} mt-1 inline-block`}>
                {task.status === "active" ? "进行中" : task.status === "completed" ? "已完成" : "待开始"}
              </span>
            </div>
          ))}
          <div className="text-center mt-2">
            <span className="text-xs text-gray-500">查看全部 {companyTasks.length} 项</span>
          </div>
        </QuadrantCard>

        {/* 左下：个人10大重要事项（可编辑） */}
        <QuadrantCard
          title="个人10大重要事项"
          bgColor="bg-gradient-to-br from-green-100 to-emerald-100"
          onEdit={() => {
            // 跳转到编辑页面或打开编辑模态框
            console.log("编辑个人重要事项")
          }}
        >
          {personalItems.slice(0, 5).map((item) => (
            <div key={item.id} className="bg-white/70 rounded-xl p-2">
              <div className="flex items-center space-x-2">
                <input
                  type="checkbox"
                  checked={item.completed}
                  onChange={() => togglePersonalItem(item.id)}
                  className="rounded text-green-500 focus:ring-green-400"
                />
                <div className="flex-1">
                  <h4
                    className={`text-xs font-medium ${item.completed ? "line-through text-gray-500" : "text-gray-800"} truncate`}
                  >
                    {item.title}
                  </h4>
                  <p className={`text-xs ${item.completed ? "line-through text-gray-400" : "text-gray-600"} truncate`}>
                    {item.description}
                  </p>
                </div>
              </div>
            </div>
          ))}
          <div className="text-center mt-2">
            <span className="text-xs text-gray-500">管理全部 {personalItems.length} 项</span>
          </div>
        </QuadrantCard>

        {/* 右下：个人日志（可编辑） */}
        <QuadrantCard
          title="个人日志"
          bgColor="bg-gradient-to-br from-yellow-100 to-orange-100"
          onEdit={() => {
            // 跳转到日志页面
            console.log("编辑个人日志")
          }}
        >
          {personalLogs.slice(0, 4).map((log) => (
            <div key={log.id} className="bg-white/70 rounded-xl p-2">
              <div className="flex items-center justify-between mb-1">
                <h4 className="text-xs font-medium text-gray-800 truncate">{log.title}</h4>
                <span className="text-lg">{log.mood}</span>
              </div>
              <p className="text-xs text-gray-600 truncate">{log.content}</p>
              <span className="text-xs text-gray-500">{log.date.toLocaleDateString()}</span>
            </div>
          ))}
          <div className="text-center mt-2">
            <span className="text-xs text-gray-500">查看全部日志</span>
          </div>
        </QuadrantCard>
      </div>

      {/* 浮动添加按钮 */}
      <button className="fixed bottom-20 right-6 w-14 h-14 bg-gradient-to-r from-orange-400 to-red-400 rounded-full shadow-lg flex items-center justify-center text-white hover:scale-110 transition-transform">
        <Plus className="w-6 h-6" />
      </button>
    </div>
  )
}
