"use client"

import { useState, useEffect } from "react"
import { TrendingUp, Clock, Target, Brain, Sparkles, Eye } from "lucide-react"
import { analyzeKeywords } from "@/lib/keywordExtractor"
import { generateAIInsights } from "@/lib/aiAnalyzer"
import type { LogEntry, KeywordAnalysis, AIInsight } from "@/lib/types"

export default function AnalyticsView() {
  const [keywords, setKeywords] = useState<KeywordAnalysis[]>([])
  const [aiInsights, setAiInsights] = useState<AIInsight[]>([])
  const [activeTab, setActiveTab] = useState<"overview" | "keywords" | "ai" | "fortune">("overview")

  // 模拟日志数据
  const sampleLogs: LogEntry[] = [
    {
      id: "1",
      title: "项目进展顺利",
      content:
        "今天完成了项目的重要里程碑，团队协作很好，客户反馈积极。需要继续保持这种工作节奏，下周计划开始新的功能开发。",
      date: new Date(),
      mood: "😊",
      tags: ["项目", "团队"],
      authorId: "user1",
      visibility: "team",
      status: "approved",
    },
    {
      id: "2",
      title: "学习新技术",
      content: "花时间学习了React的新特性，对状态管理有了更深的理解。这些技能对项目开发很有帮助，计划继续深入学习。",
      date: new Date(Date.now() - 86400000),
      mood: "🔥",
      tags: ["学习", "技术"],
      authorId: "user1",
      visibility: "private",
      status: "approved",
    },
    {
      id: "3",
      title: "客户沟通",
      content: "与客户进行了深入沟通，了解了他们的真实需求。发现之前的理解有偏差，需要调整产品方向。沟通很重要。",
      date: new Date(Date.now() - 172800000),
      mood: "😐",
      tags: ["沟通", "客户"],
      authorId: "user1",
      visibility: "department",
      status: "approved",
    },
  ]

  useEffect(() => {
    const keywordAnalysis = analyzeKeywords(sampleLogs)
    const insights = generateAIInsights(keywordAnalysis, sampleLogs)
    setKeywords(keywordAnalysis)
    setAiInsights(insights)
  }, [])

  const stats = [
    { label: "关键词提取", value: keywords.length.toString(), icon: Target, color: "from-blue-400 to-blue-600" },
    { label: "AI洞察", value: aiInsights.length.toString(), icon: Brain, color: "from-purple-400 to-purple-600" },
    { label: "工作清单", value: "8", icon: Clock, color: "from-green-400 to-green-600" },
    { label: "建议采纳", value: "95%", icon: TrendingUp, color: "from-orange-400 to-orange-600" },
  ]

  const renderOverview = () => (
    <div className="space-y-6">
      {/* Stats Cards */}
      <div className="grid grid-cols-2 gap-4">
        {stats.map((stat, index) => (
          <div key={index} className="bg-white rounded-2xl p-4 shadow-md">
            <div
              className={`w-10 h-10 rounded-full bg-gradient-to-r ${stat.color} flex items-center justify-center mb-3`}
            >
              <stat.icon className="w-5 h-5 text-white" />
            </div>
            <div className="text-2xl font-bold text-gray-800 mb-1">{stat.value}</div>
            <div className="text-xs text-gray-600">{stat.label}</div>
          </div>
        ))}
      </div>

      {/* Quick Insights */}
      <div className="bg-white rounded-2xl p-4 shadow-md">
        <h3 className="font-bold text-gray-800 mb-4 flex items-center">
          <Sparkles className="w-5 h-5 mr-2 text-yellow-500" />
          今日洞察
        </h3>
        <div className="space-y-3">
          <div className="bg-gradient-to-r from-blue-50 to-indigo-50 rounded-xl p-3">
            <div className="text-blue-800 font-medium text-sm">工作效率指数：92分</div>
            <div className="text-blue-600 text-xs mt-1">比昨日提升8%，保持良好状态</div>
          </div>
          <div className="bg-gradient-to-r from-green-50 to-emerald-50 rounded-xl p-3">
            <div className="text-green-800 font-medium text-sm">关键词活跃度：项目(85%) 学习(72%)</div>
            <div className="text-green-600 text-xs mt-1">专业成长趋势明显</div>
          </div>
        </div>
      </div>
    </div>
  )

  const renderKeywords = () => (
    <div className="space-y-4">
      <div className="bg-white rounded-2xl p-4 shadow-md">
        <h3 className="font-bold text-gray-800 mb-4 flex items-center">
          <Target className="w-5 h-5 mr-2 text-blue-500" />
          关键词分析
        </h3>
        <div className="space-y-3">
          {keywords.slice(0, 10).map((keyword, index) => (
            <div key={index} className="flex items-center justify-between">
              <div className="flex items-center space-x-3">
                <div
                  className={`w-3 h-3 rounded-full ${
                    keyword.category === "work"
                      ? "bg-blue-400"
                      : keyword.category === "emotion"
                        ? "bg-red-400"
                        : keyword.category === "skill"
                          ? "bg-green-400"
                          : keyword.category === "goal"
                            ? "bg-purple-400"
                            : "bg-orange-400"
                  }`}
                ></div>
                <span className="font-medium text-gray-800">{keyword.keyword}</span>
              </div>
              <div className="flex items-center space-x-2">
                <div className="text-xs text-gray-500">频次: {keyword.frequency}</div>
                <div className="text-xs font-medium text-gray-700">{keyword.importance}%</div>
                <div
                  className={`text-xs ${
                    keyword.trend === "up"
                      ? "text-green-500"
                      : keyword.trend === "down"
                        ? "text-red-500"
                        : "text-gray-500"
                  }`}
                >
                  {keyword.trend === "up" ? "↗" : keyword.trend === "down" ? "↘" : "→"}
                </div>
              </div>
            </div>
          ))}
        </div>
      </div>

      {/* 工作清单生成 */}
      <div className="bg-white rounded-2xl p-4 shadow-md">
        <h3 className="font-bold text-gray-800 mb-4 flex items-center">
          <Clock className="w-5 h-5 mr-2 text-green-500" />
          AI生成工作清单
        </h3>
        <div className="space-y-2">
          {keywords
            .filter((k) => k.category === "work" || k.category === "goal")
            .slice(0, 5)
            .map((keyword, index) => (
              <div key={index} className="flex items-center space-x-3 p-2 bg-gray-50 rounded-lg">
                <input type="checkbox" className="rounded" />
                <span className="text-sm text-gray-700">继续推进{keyword.keyword}相关工作</span>
                <span className="text-xs text-gray-500 ml-auto">重要度: {keyword.importance}%</span>
              </div>
            ))}
        </div>
      </div>
    </div>
  )

  const renderAIAnalysis = () => (
    <div className="space-y-4">
      {aiInsights.map((insight, index) => (
        <div key={index} className="bg-white rounded-2xl p-4 shadow-md">
          <div className="flex items-start space-x-3">
            <div
              className={`w-10 h-10 rounded-full flex items-center justify-center ${
                insight.type === "personality"
                  ? "bg-purple-100 text-purple-600"
                  : insight.type === "work_style"
                    ? "bg-blue-100 text-blue-600"
                    : insight.type === "strength"
                      ? "bg-green-100 text-green-600"
                      : insight.type === "weakness"
                        ? "bg-red-100 text-red-600"
                        : "bg-orange-100 text-orange-600"
              }`}
            >
              {insight.type === "personality"
                ? "🧠"
                : insight.type === "work_style"
                  ? "💼"
                  : insight.type === "strength"
                    ? "💪"
                    : insight.type === "weakness"
                      ? "⚠️"
                      : "💡"}
            </div>
            <div className="flex-1">
              <div className="flex items-center justify-between mb-2">
                <h4 className="font-bold text-gray-800">{insight.title}</h4>
                <div className="flex items-center space-x-1">
                  {insight.mbtiTrait && (
                    <span className="text-xs bg-purple-100 text-purple-600 px-2 py-1 rounded-full">
                      MBTI-{insight.mbtiTrait}
                    </span>
                  )}
                  <span className="text-xs text-gray-500">{insight.confidence}%</span>
                </div>
              </div>
              <p className="text-sm text-gray-600 leading-relaxed">{insight.content}</p>
            </div>
          </div>
        </div>
      ))}
    </div>
  )

  const renderFortuneTelling = () => (
    <div className="space-y-4">
      {/* 算命风格的分析界面 */}
      <div className="bg-gradient-to-br from-purple-900 to-indigo-900 rounded-2xl p-6 text-white shadow-lg">
        <div className="text-center mb-6">
          <div className="text-4xl mb-2">🔮</div>
          <h3 className="text-xl font-bold">职场运势解析</h3>
          <p className="text-purple-200 text-sm">基于日志关键词的智能分析</p>
        </div>

        <div className="grid grid-cols-2 gap-4 mb-6">
          <div className="bg-white/10 rounded-xl p-3 text-center">
            <div className="text-2xl mb-1">⭐</div>
            <div className="text-sm font-medium">事业运</div>
            <div className="text-xs text-purple-200">旺盛</div>
          </div>
          <div className="bg-white/10 rounded-xl p-3 text-center">
            <div className="text-2xl mb-1">🌟</div>
            <div className="text-sm font-medium">学习运</div>
            <div className="text-xs text-purple-200">上升</div>
          </div>
          <div className="bg-white/10 rounded-xl p-3 text-center">
            <div className="text-2xl mb-1">💫</div>
            <div className="text-sm font-medium">人际运</div>
            <div className="text-xs text-purple-200">平稳</div>
          </div>
          <div className="bg-white/10 rounded-xl p-3 text-center">
            <div className="text-2xl mb-1">✨</div>
            <div className="text-sm font-medium">创新运</div>
            <div className="text-xs text-purple-200">待发</div>
          </div>
        </div>

        <div className="bg-white/10 rounded-xl p-4">
          <h4 className="font-bold mb-2 flex items-center">
            <span className="mr-2">🎯</span>
            本周运势指引
          </h4>
          <p className="text-sm text-purple-100 leading-relaxed">
            根据您的工作日志分析，本周您的事业运势呈上升趋势。"项目"和"学习"关键词频繁出现，
            表明您正处于快速成长期。建议把握机会，在技能提升方面加大投入，
            同时注意与团队成员的协作沟通。财运方面，适合进行长期投资规划。
          </p>
        </div>
      </div>

      {/* MBTI性格分析 */}
      <div className="bg-white rounded-2xl p-4 shadow-md">
        <h3 className="font-bold text-gray-800 mb-4 flex items-center">
          <Brain className="w-5 h-5 mr-2 text-purple-500" />
          MBTI职场性格分析
        </h3>

        <div className="grid grid-cols-4 gap-2 mb-4">
          {[
            { trait: "E", name: "外向", active: false },
            { trait: "I", name: "内向", active: true },
            { trait: "S", name: "感觉", active: false },
            { trait: "N", name: "直觉", active: true },
            { trait: "T", name: "思维", active: true },
            { trait: "F", name: "情感", active: false },
            { trait: "J", name: "判断", active: true },
            { trait: "P", name: "感知", active: false },
          ].map((item, index) => (
            <div
              key={index}
              className={`text-center p-2 rounded-lg text-xs ${
                item.active ? "bg-purple-100 text-purple-700 font-bold" : "bg-gray-100 text-gray-500"
              }`}
            >
              <div className="font-bold">{item.trait}</div>
              <div>{item.name}</div>
            </div>
          ))}
        </div>

        <div className="bg-purple-50 rounded-xl p-3">
          <div className="font-bold text-purple-800 mb-2">推测类型：INTJ (建筑师)</div>
          <p className="text-sm text-purple-700">
            您展现出典型的INTJ特质：善于独立思考、注重长远规划、追求专业精进。
            在工作中表现出强烈的目标导向和系统性思维，适合从事需要深度分析和创新的工作。
          </p>
        </div>
      </div>
    </div>
  )

  return (
    <div className="h-full bg-gradient-to-br from-yellow-50 to-orange-50">
      {/* Tab Navigation */}
      <div className="bg-white border-b border-gray-200 p-2">
        <div className="flex space-x-1">
          {[
            { key: "overview", label: "概览", icon: Eye },
            { key: "keywords", label: "关键词", icon: Target },
            { key: "ai", label: "AI分析", icon: Brain },
            { key: "fortune", label: "运势", icon: Sparkles },
          ].map((tab) => (
            <button
              key={tab.key}
              onClick={() => setActiveTab(tab.key as any)}
              className={`flex items-center space-x-1 px-3 py-2 rounded-lg text-sm font-medium transition-all ${
                activeTab === tab.key
                  ? "bg-gradient-to-r from-yellow-400 to-orange-400 text-white shadow-md"
                  : "text-gray-600 hover:text-gray-800 hover:bg-gray-100"
              }`}
            >
              <tab.icon className="w-4 h-4" />
              <span>{tab.label}</span>
            </button>
          ))}
        </div>
      </div>

      {/* Content */}
      <div className="flex-1 overflow-auto p-4">
        {activeTab === "overview" && renderOverview()}
        {activeTab === "keywords" && renderKeywords()}
        {activeTab === "ai" && renderAIAnalysis()}
        {activeTab === "fortune" && renderFortuneTelling()}
      </div>
    </div>
  )
}
