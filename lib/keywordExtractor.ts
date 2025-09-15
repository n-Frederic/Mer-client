import type { LogEntry, KeywordAnalysis } from "./types"

// 模拟关键词提取算法
export const extractKeywords = (content: string): string[] => {
  // 简化的关键词提取逻辑
  const stopWords = [
    "的",
    "了",
    "在",
    "是",
    "我",
    "有",
    "和",
    "就",
    "不",
    "人",
    "都",
    "一",
    "个",
    "上",
    "也",
    "很",
    "到",
    "说",
    "要",
    "去",
    "你",
    "会",
    "着",
    "没有",
    "看",
    "好",
    "自己",
    "这",
  ]

  const words = content
    .replace(/[^\u4e00-\u9fa5a-zA-Z0-9]/g, " ")
    .split(/\s+/)
    .filter((word) => word.length >= 2 && !stopWords.includes(word))

  // 统计词频
  const wordCount: Record<string, number> = {}
  words.forEach((word) => {
    wordCount[word] = (wordCount[word] || 0) + 1
  })

  // 返回频率最高的关键词
  return Object.entries(wordCount)
    .sort(([, a], [, b]) => b - a)
    .slice(0, 10)
    .map(([word]) => word)
}

export const analyzeKeywords = (logs: LogEntry[]): KeywordAnalysis[] => {
  const allKeywords: Record<string, { count: number; contexts: string[] }> = {}

  logs.forEach((log) => {
    const keywords = extractKeywords(log.content)
    keywords.forEach((keyword) => {
      if (!allKeywords[keyword]) {
        allKeywords[keyword] = { count: 0, contexts: [] }
      }
      allKeywords[keyword].count++
      allKeywords[keyword].contexts.push(log.content)
    })
  })

  return Object.entries(allKeywords)
    .map(([keyword, data]) => ({
      keyword,
      frequency: data.count,
      importance: Math.min(data.count * 10, 100),
      trend: Math.random() > 0.5 ? "up" : Math.random() > 0.5 ? "down" : "stable",
      category: categorizeKeyword(keyword),
    }))
    .sort((a, b) => b.importance - a.importance)
    .slice(0, 20)
}

const categorizeKeyword = (keyword: string): "work" | "emotion" | "skill" | "goal" | "problem" => {
  const workKeywords = ["项目", "任务", "会议", "客户", "报告", "开发", "设计", "测试"]
  const emotionKeywords = ["开心", "焦虑", "压力", "满意", "困难", "挑战", "成功", "失败"]
  const skillKeywords = ["学习", "技能", "培训", "经验", "知识", "能力", "提升", "改进"]
  const goalKeywords = ["目标", "计划", "完成", "达成", "实现", "期望", "希望", "想要"]
  const problemKeywords = ["问题", "困难", "障碍", "错误", "bug", "故障", "延迟", "风险"]

  if (workKeywords.some((w) => keyword.includes(w))) return "work"
  if (emotionKeywords.some((w) => keyword.includes(w))) return "emotion"
  if (skillKeywords.some((w) => keyword.includes(w))) return "skill"
  if (goalKeywords.some((w) => keyword.includes(w))) return "goal"
  if (problemKeywords.some((w) => keyword.includes(w))) return "problem"

  return "work"
}
