import type { KeywordAnalysis, AIInsight, LogEntry } from "./types"

export const generateAIInsights = (keywords: KeywordAnalysis[], logs: LogEntry[]): AIInsight[] => {
  const insights: AIInsight[] = []

  // 分析工作风格
  const workKeywords = keywords.filter((k) => k.category === "work")
  if (workKeywords.length > 0) {
    insights.push({
      type: "work_style",
      title: "工作风格分析",
      content: generateWorkStyleAnalysis(workKeywords),
      confidence: 85,
      mbtiTrait: "T", // 思维型
    })
  }

  // 分析性格特征
  const emotionKeywords = keywords.filter((k) => k.category === "emotion")
  insights.push({
    type: "personality",
    title: "性格特征洞察",
    content: generatePersonalityAnalysis(emotionKeywords, logs),
    confidence: 78,
    mbtiTrait: "F", // 情感型
  })

  // 分析优势
  const skillKeywords = keywords.filter((k) => k.category === "skill")
  insights.push({
    type: "strength",
    title: "核心优势识别",
    content: generateStrengthAnalysis(skillKeywords),
    confidence: 82,
  })

  // 分析改进建议
  const problemKeywords = keywords.filter((k) => k.category === "problem")
  insights.push({
    type: "suggestion",
    title: "发展建议",
    content: generateSuggestionAnalysis(problemKeywords, keywords),
    confidence: 90,
  })

  return insights
}

const generateWorkStyleAnalysis = (workKeywords: KeywordAnalysis[]): string => {
  const topKeywords = workKeywords.slice(0, 3).map((k) => k.keyword)

  if (topKeywords.includes("项目") && topKeywords.includes("计划")) {
    return "您展现出强烈的项目导向思维，善于制定计划和推进执行。这表明您具有优秀的组织能力和目标导向性，属于典型的执行者类型。建议继续发挥这一优势，同时注意平衡细节与全局视野。"
  } else if (topKeywords.includes("学习") && topKeywords.includes("技能")) {
    return "您对学习和技能提升表现出浓厚兴趣，这反映了您的成长型思维模式。您善于自我反思和持续改进，具备很强的适应能力。建议将学习成果更多地应用到实际工作中。"
  } else {
    return "从您的工作记录来看，您是一个注重实效的实干家。您专注于具体任务的完成，具有很强的执行力。建议在保持高效执行的同时，适当增加战略思考的时间。"
  }
}

const generatePersonalityAnalysis = (emotionKeywords: KeywordAnalysis[], logs: LogEntry[]): string => {
  const positiveEmotions = emotionKeywords.filter((k) => ["开心", "满意", "成功"].some((e) => k.keyword.includes(e)))
  const negativeEmotions = emotionKeywords.filter((k) => ["焦虑", "压力", "困难"].some((e) => k.keyword.includes(e)))

  const positiveRatio = positiveEmotions.length / (positiveEmotions.length + negativeEmotions.length || 1)

  if (positiveRatio > 0.6) {
    return "您是一个天生的乐观主义者，即使面对挑战也能保持积极的心态。这种正能量不仅有助于您自己的成长，也能感染周围的同事。您的情绪稳定性很高，适合承担更多的团队协调工作。"
  } else if (positiveRatio < 0.4) {
    return "您对工作要求很高，这体现了您的责任心和完美主义倾向。虽然这种特质有助于产出高质量的工作成果，但也要注意适度调节压力，保持工作与生活的平衡。"
  } else {
    return "您展现出很好的情绪平衡能力，既能客观面对挑战，也能享受工作中的成就感。这种理性与感性并重的特质，使您在团队中扮演着重要的稳定器角色。"
  }
}

const generateStrengthAnalysis = (skillKeywords: KeywordAnalysis[]): string => {
  const topSkills = skillKeywords.slice(0, 3)

  if (topSkills.some((k) => k.keyword.includes("沟通"))) {
    return "沟通协调是您的核心优势。您善于与不同背景的人建立良好关系，能够有效传达想法和协调资源。这项能力在现代职场中极其宝贵，建议您考虑向管理或客户关系方向发展。"
  } else if (topSkills.some((k) => k.keyword.includes("技术"))) {
    return "您在技术领域展现出强大的专业能力和持续学习的动力。这种深度专业化的优势，使您在团队中具有不可替代的价值。建议在保持技术深度的同时，适当拓展业务理解。"
  } else {
    return "您的优势在于综合能力的均衡发展。您不仅具备扎实的专业技能，还有良好的学习能力和适应性。这种全面发展的特质，为您的职业发展提供了更多可能性。"
  }
}

const generateSuggestionAnalysis = (problemKeywords: KeywordAnalysis[], allKeywords: KeywordAnalysis[]): string => {
  const suggestions = []

  if (problemKeywords.some((k) => k.keyword.includes("时间"))) {
    suggestions.push("时间管理优化：建议使用番茄工作法或时间块管理，提高工作效率")
  }

  if (problemKeywords.some((k) => k.keyword.includes("沟通"))) {
    suggestions.push("沟通技巧提升：可以参加相关培训或多观察优秀同事的沟通方式")
  }

  if (allKeywords.filter((k) => k.category === "skill").length < 3) {
    suggestions.push("技能拓展：建议制定学习计划，定期更新专业技能")
  }

  if (suggestions.length === 0) {
    suggestions.push("继续保持：您目前的工作状态很好，建议保持现有的工作节奏和方法")
  }

  return suggestions.join("；")
}
