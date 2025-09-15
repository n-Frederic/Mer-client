"use client"

import { useState } from "react"
import {
  Plus,
  Search,
  Send,
  Eye,
  CheckCircle,
  XCircle,
  ArrowUp,
  ArrowDown,
  Users,
  Lock,
  UserCheck,
  Building,
  Globe,
} from "lucide-react"
import { getRolePermissions, getRoleDisplayName } from "@/lib/rolePermissions"
import type { LogEntry, User } from "@/lib/types"

export default function LogView() {
  // 当前用户信息
  const [currentUser] = useState<User>({
    id: "user1",
    name: "张小兔",
    role: "team_leader",
    department: "技术部",
    avatar: "🐰",
    superiorId: "admin1",
    subordinates: ["emp1", "emp2", "emp3"],
  })

  // 模拟团队成员数据
  const [teamMembers] = useState<User[]>([
    { id: "emp1", name: "小王", role: "employee", department: "技术部", avatar: "🐱" },
    { id: "emp2", name: "小李", role: "employee", department: "技术部", avatar: "🐶" },
    { id: "emp3", name: "小张", role: "employee", department: "技术部", avatar: "🐼" },
  ])

  const [logs, setLogs] = useState<LogEntry[]>([
    {
      id: "1",
      title: "项目进展汇报",
      content: "本周完成了用户界面优化，团队协作效率提升明显。下周计划开始后端接口对接工作。",
      date: new Date(),
      mood: "😊",
      tags: ["项目", "团队"],
      authorId: "user1",
      visibility: "department",
      status: "approved",
    },
    {
      id: "2",
      title: "技能学习记录",
      content: "深入学习了React Hooks的使用，对状态管理有了新的理解。计划将新知识应用到当前项目中。",
      date: new Date(Date.now() - 86400000),
      mood: "🔥",
      tags: ["学习", "技术"],
      authorId: "emp1",
      visibility: "private",
      status: "draft",
    },
    {
      id: "3",
      title: "客户反馈处理",
      content: "今天处理了客户的反馈意见，优化了产品功能。客户表示满意。",
      date: new Date(Date.now() - 172800000),
      mood: "😊",
      tags: ["客户", "反馈"],
      authorId: "emp2",
      visibility: "team",
      status: "submitted",
    },
    {
      id: "4",
      title: "跨部门协作",
      content: "与市场部门协作完成了产品推广方案，效果不错。",
      date: new Date(Date.now() - 259200000),
      mood: "😐",
      tags: ["协作", "市场"],
      authorId: "emp3",
      visibility: "company",
      status: "approved",
    },
  ])

  const [searchTerm, setSearchTerm] = useState("")
  const [viewScope, setViewScope] = useState<"personal" | "company" | "external">("personal")
  const [viewMode, setViewMode] = useState<"my" | "team" | "member" | "approval">("my")
  const [selectedMember, setSelectedMember] = useState<string | null>(null)
  const [selectedLog, setSelectedLog] = useState<LogEntry | null>(null)
  const [permissionRequests, setPermissionRequests] = useState<string[]>([])

  const permissions = getRolePermissions(currentUser.role)

  const getFilteredLogs = () => {
    const filteredLogs = logs.filter((log) => {
      const matchesSearch =
        log.title.toLowerCase().includes(searchTerm.toLowerCase()) ||
        log.content.toLowerCase().includes(searchTerm.toLowerCase())

      if (!matchesSearch) return false

      // 根据查看范围过滤
      switch (viewScope) {
        case "personal":
          // 个人板块：只看个人和团队相关
          return log.visibility === "private" || log.visibility === "team" || log.authorId === currentUser.id
        case "company":
          // 公司板块：公司内部信息
          return log.visibility === "department" || log.visibility === "company"
        case "external":
          // 其他公司板块：外部协作信息
          return log.visibility === "public" || log.tags.includes("外部")
        default:
          return true
      }
    })

    // 根据查看模式进一步过滤
    switch (viewMode) {
      case "my":
        return filteredLogs.filter((log) => log.authorId === currentUser.id)
      case "team":
        return filteredLogs.filter(
          (log) =>
            permissions.canViewSubordinates &&
            (currentUser.subordinates?.includes(log.authorId) || log.visibility !== "private"),
        )
      case "member":
        return selectedMember ? filteredLogs.filter((log) => log.authorId === selectedMember) : []
      case "approval":
        return filteredLogs.filter((log) => permissions.canApprove && log.status === "submitted")
      default:
        return filteredLogs
    }
  }

  const formatDate = (date: Date) => {
    const now = new Date()
    const diffTime = Math.abs(now.getTime() - date.getTime())
    const diffDays = Math.ceil(diffTime / (1000 * 60 * 60 * 24))

    if (diffDays === 1) return "今天"
    if (diffDays === 2) return "昨天"
    if (diffDays <= 7) return `${diffDays - 1}天前`

    return `${date.getMonth() + 1}月${date.getDate()}日`
  }

  const handleApproval = (logId: string, approved: boolean) => {
    setLogs((prev) =>
      prev.map((log) => (log.id === logId ? { ...log, status: approved ? "approved" : "rejected" } : log)),
    )
  }

  const handlePermissionRequest = (logId: string) => {
    setPermissionRequests((prev) => [...prev, logId])
    // 这里可以发送权限申请到后端
    alert("权限申请已发送，等待审批...")
  }

  const canViewLog = (log: LogEntry) => {
    // 检查是否有权限查看该日志
    if (log.authorId === currentUser.id) return true
    if (log.visibility === "public") return true
    if (log.visibility === "company" && permissions.canView) return true
    if (log.visibility === "department" && permissions.canView) return true
    if (log.visibility === "team" && permissions.canViewSubordinates) return true
    return false
  }

  const getStatusColor = (status: LogEntry["status"]) => {
    switch (status) {
      case "draft":
        return "bg-gray-100 text-gray-600"
      case "submitted":
        return "bg-yellow-100 text-yellow-700"
      case "approved":
        return "bg-green-100 text-green-700"
      case "rejected":
        return "bg-red-100 text-red-700"
      default:
        return "bg-gray-100 text-gray-600"
    }
  }

  const getStatusText = (status: LogEntry["status"]) => {
    switch (status) {
      case "draft":
        return "草稿"
      case "submitted":
        return "待审批"
      case "approved":
        return "已通过"
      case "rejected":
        return "已拒绝"
      default:
        return "未知"
    }
  }

  const getScopeIcon = (scope: "personal" | "company" | "external") => {
    switch (scope) {
      case "personal":
        return <Users className="w-4 h-4" />
      case "company":
        return <Building className="w-4 h-4" />
      case "external":
        return <Globe className="w-4 h-4" />
    }
  }

  const getScopeColor = (scope: "personal" | "company" | "external") => {
    switch (scope) {
      case "personal":
        return "from-blue-400 to-blue-600"
      case "company":
        return "from-green-400 to-green-600"
      case "external":
        return "from-purple-400 to-purple-600"
    }
  }

  return (
    <div className="h-full bg-gradient-to-br from-yellow-50 to-orange-50">
      {/* Header */}
      <div className="bg-white border-b border-gray-200 p-4">
        {/* User Role Info */}
        <div className="flex items-center justify-between mb-4">
          <div className="flex items-center space-x-3">
            <span className="text-3xl">{currentUser.avatar}</span>
            <div>
              <div className="font-bold text-gray-800 cute-text">{currentUser.name}</div>
              <div className="text-sm text-gray-500">
                {getRoleDisplayName(currentUser.role)} · {currentUser.department}
              </div>
            </div>
          </div>
          <div className="flex space-x-2">
            {permissions.canViewSubordinates && (
              <div className="flex items-center space-x-1 bg-green-100 px-2 py-1 rounded-full">
                <ArrowDown className="w-3 h-3 text-green-600" />
                <span className="text-xs text-green-600">可查看下级</span>
              </div>
            )}
            {permissions.canRequestApproval && (
              <div className="flex items-center space-x-1 bg-blue-100 px-2 py-1 rounded-full">
                <ArrowUp className="w-3 h-3 text-blue-600" />
                <span className="text-xs text-blue-600">可申请审批</span>
              </div>
            )}
          </div>
        </div>

        {/* Scope Tabs */}
        <div className="flex space-x-2 mb-4">
          {(["personal", "company", "external"] as const).map((scope) => (
            <button
              key={scope}
              onClick={() => setViewScope(scope)}
              className={`flex items-center space-x-2 px-4 py-2 rounded-full text-sm font-medium transition-all ${
                viewScope === scope
                  ? `bg-gradient-to-r ${getScopeColor(scope)} text-white shadow-md`
                  : "text-gray-600 hover:text-gray-800 hover:bg-gray-100"
              }`}
            >
              {getScopeIcon(scope)}
              <span>{scope === "personal" ? "个人板块" : scope === "company" ? "公司板块" : "其他公司"}</span>
            </button>
          ))}
        </div>

        {/* View Mode Tabs */}
        <div className="flex space-x-1 mb-4">
          <button
            onClick={() => setViewMode("my")}
            className={`px-3 py-2 rounded-full text-sm font-medium transition-all ${
              viewMode === "my"
                ? "bg-gradient-to-r from-yellow-400 to-orange-400 text-white"
                : "text-gray-600 hover:text-gray-800"
            }`}
          >
            我的日志
          </button>
          {permissions.canViewSubordinates && (
            <>
              <button
                onClick={() => setViewMode("team")}
                className={`px-3 py-2 rounded-full text-sm font-medium transition-all ${
                  viewMode === "team"
                    ? "bg-gradient-to-r from-yellow-400 to-orange-400 text-white"
                    : "text-gray-600 hover:text-gray-800"
                }`}
              >
                团队日志
              </button>
              <button
                onClick={() => setViewMode("member")}
                className={`px-3 py-2 rounded-full text-sm font-medium transition-all ${
                  viewMode === "member"
                    ? "bg-gradient-to-r from-yellow-400 to-orange-400 text-white"
                    : "text-gray-600 hover:text-gray-800"
                }`}
              >
                成员日志
              </button>
            </>
          )}
          {permissions.canApprove && (
            <button
              onClick={() => setViewMode("approval")}
              className={`px-3 py-2 rounded-full text-sm font-medium transition-all ${
                viewMode === "approval"
                  ? "bg-gradient-to-r from-yellow-400 to-orange-400 text-white"
                  : "text-gray-600 hover:text-gray-800"
              }`}
            >
              待审批
            </button>
          )}
        </div>

        {/* Member Selection (when in member view mode) */}
        {viewMode === "member" && permissions.canViewSubordinates && (
          <div className="flex space-x-2 mb-4">
            {teamMembers.map((member) => (
              <button
                key={member.id}
                onClick={() => setSelectedMember(member.id)}
                className={`flex items-center space-x-2 px-3 py-2 rounded-full text-sm transition-all ${
                  selectedMember === member.id
                    ? "bg-orange-200 text-orange-700"
                    : "bg-gray-100 text-gray-600 hover:bg-gray-200"
                }`}
              >
                <span className="text-lg">{member.avatar}</span>
                <span>{member.name}</span>
              </button>
            ))}
          </div>
        )}

        {/* Search */}
        <div className="relative">
          <Search className="absolute left-3 top-1/2 transform -translate-y-1/2 text-gray-400 w-4 h-4" />
          <input
            type="text"
            placeholder="搜索日志..."
            value={searchTerm}
            onChange={(e) => setSearchTerm(e.target.value)}
            className="w-full pl-10 pr-4 py-3 bg-gray-100 rounded-2xl text-sm focus:outline-none focus:ring-2 focus:ring-yellow-400 cute-text"
          />
        </div>
      </div>

      {/* Logs List */}
      <div className="flex-1 overflow-auto p-4 space-y-4">
        {getFilteredLogs().map((log) => {
          const hasPermission = canViewLog(log)
          const author =
            teamMembers.find((m) => m.id === log.authorId) || (log.authorId === currentUser.id ? currentUser : null)

          return (
            <div key={log.id} className="bg-white rounded-3xl p-5 shadow-md border border-gray-100">
              <div className="flex items-start justify-between mb-3">
                <div className="flex items-center space-x-3">
                  {author && <span className="text-2xl">{author.avatar}</span>}
                  <div>
                    <h3 className="font-bold text-gray-800 cute-text">{log.title}</h3>
                    {author && <p className="text-xs text-gray-500">{author.name}</p>}
                  </div>
                </div>
                <div className="flex items-center space-x-2">
                  <span className="text-2xl">{log.mood}</span>
                  <span className={`text-xs px-3 py-1 rounded-full ${getStatusColor(log.status)}`}>
                    {getStatusText(log.status)}
                  </span>
                  <span className="text-xs text-gray-500">{formatDate(log.date)}</span>
                </div>
              </div>

              {hasPermission ? (
                <>
                  <p className="text-gray-600 text-sm mb-4 leading-relaxed cute-text">{log.content}</p>
                  <div className="flex items-center justify-between">
                    <div className="flex flex-wrap gap-2">
                      {log.tags.map((tag) => (
                        <span
                          key={tag}
                          className="px-3 py-1 bg-gradient-to-r from-yellow-100 to-orange-100 text-orange-600 rounded-full text-xs font-medium cute-text"
                        >
                          {tag}
                        </span>
                      ))}
                    </div>

                    <div className="flex items-center space-x-2">
                      <button
                        onClick={() => setSelectedLog(log)}
                        className="p-2 text-gray-400 hover:text-gray-600 rounded-full hover:bg-gray-100"
                      >
                        <Eye className="w-4 h-4" />
                      </button>

                      {viewMode === "approval" && permissions.canApprove && log.status === "submitted" && (
                        <div className="flex space-x-1">
                          <button
                            onClick={() => handleApproval(log.id, true)}
                            className="p-2 text-green-500 hover:text-green-700 rounded-full hover:bg-green-50"
                          >
                            <CheckCircle className="w-4 h-4" />
                          </button>
                          <button
                            onClick={() => handleApproval(log.id, false)}
                            className="p-2 text-red-500 hover:text-red-700 rounded-full hover:bg-red-50"
                          >
                            <XCircle className="w-4 h-4" />
                          </button>
                        </div>
                      )}
                    </div>
                  </div>
                </>
              ) : (
                <div className="flex items-center justify-between p-4 bg-gray-50 rounded-2xl">
                  <div className="flex items-center space-x-3">
                    <Lock className="w-5 h-5 text-gray-400" />
                    <div>
                      <p className="text-sm text-gray-600 cute-text">您暂无权限查看此日志</p>
                      <p className="text-xs text-gray-500">需要相应权限才能查看内容</p>
                    </div>
                  </div>
                  <button
                    onClick={() => handlePermissionRequest(log.id)}
                    disabled={permissionRequests.includes(log.id)}
                    className={`px-4 py-2 rounded-full text-sm font-medium transition-all ${
                      permissionRequests.includes(log.id)
                        ? "bg-gray-200 text-gray-500 cursor-not-allowed"
                        : "bg-gradient-to-r from-blue-400 to-blue-600 text-white hover:shadow-lg"
                    }`}
                  >
                    {permissionRequests.includes(log.id) ? (
                      <>
                        <UserCheck className="w-4 h-4 inline mr-1" />
                        已申请
                      </>
                    ) : (
                      <>
                        <Send className="w-4 h-4 inline mr-1" />
                        申请权限
                      </>
                    )}
                  </button>
                </div>
              )}
            </div>
          )
        })}

        {getFilteredLogs().length === 0 && (
          <div className="text-center py-16">
            <div className="text-8xl mb-4">📝</div>
            <p className="text-gray-500 text-lg cute-text">
              {viewMode === "my"
                ? "暂无个人日志"
                : viewMode === "team"
                  ? "暂无团队日志"
                  : viewMode === "member"
                    ? "请选择团队成员"
                    : "暂无待审批日志"}
            </p>
            <p className="text-gray-400 text-sm mt-2">
              {viewScope === "personal" ? "个人板块" : viewScope === "company" ? "公司板块" : "其他公司板块"}
            </p>
          </div>
        )}
      </div>

      {/* Floating Add Button */}
      {permissions.canCreate && (
        <button className="fixed bottom-20 right-6 w-16 h-16 bg-gradient-to-r from-yellow-400 to-orange-400 rounded-full shadow-xl flex items-center justify-center text-white hover:scale-110 transition-transform">
          <Plus className="w-7 h-7" />
        </button>
      )}

      {/* Log Detail Modal */}
      {selectedLog && (
        <div className="fixed inset-0 bg-black/50 flex items-center justify-center p-4 z-50">
          <div className="bg-white rounded-3xl p-6 max-w-md w-full max-h-[80vh] overflow-auto">
            <div className="flex items-center justify-between mb-4">
              <h3 className="text-xl font-bold text-gray-800 cute-text">{selectedLog.title}</h3>
              <button
                onClick={() => setSelectedLog(null)}
                className="text-gray-400 hover:text-gray-600 p-2 rounded-full hover:bg-gray-100"
              >
                ✕
              </button>
            </div>

            <div className="space-y-4">
              <div className="flex items-center space-x-3">
                <span className="text-3xl">{selectedLog.mood}</span>
                <span className={`text-sm px-3 py-1 rounded-full ${getStatusColor(selectedLog.status)}`}>
                  {getStatusText(selectedLog.status)}
                </span>
                <span className="text-sm text-gray-500">{formatDate(selectedLog.date)}</span>
              </div>

              <p className="text-gray-600 leading-relaxed cute-text">{selectedLog.content}</p>

              <div className="flex flex-wrap gap-2">
                {selectedLog.tags.map((tag) => (
                  <span
                    key={tag}
                    className="px-3 py-2 bg-gradient-to-r from-yellow-100 to-orange-100 text-orange-600 rounded-full text-sm font-medium cute-text"
                  >
                    {tag}
                  </span>
                ))}
              </div>
            </div>
          </div>
        </div>
      )}
    </div>
  )
}
