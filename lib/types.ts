export type UserRole = "founder" | "admin" | "department_head" | "team_leader" | "employee"

export interface User {
  id: string
  name: string
  role: UserRole
  department: string
  avatar: string
  superiorId?: string
  subordinates?: string[]
}

export interface LogEntry {
  id: string
  title: string
  content: string
  date: Date
  mood: "😊" | "😐" | "😔" | "😴" | "🔥"
  tags: string[]
  authorId: string
  visibility: "private" | "team" | "department" | "public"
  status: "draft" | "submitted" | "approved" | "rejected"
  keywords?: string[]
  keywordWeights?: Record<string, number>
}

export interface Permission {
  canCreate: boolean
  canEdit: boolean
  canDelete: boolean
  canView: boolean
  canApprove: boolean
  canViewSubordinates: boolean
  canRequestApproval: boolean
}

export interface KeywordAnalysis {
  keyword: string
  frequency: number
  importance: number
  trend: "up" | "down" | "stable"
  category: "work" | "emotion" | "skill" | "goal" | "problem"
}

export interface AIInsight {
  type: "personality" | "work_style" | "strength" | "weakness" | "suggestion"
  title: string
  content: string
  confidence: number
  mbtiTrait?: string
}
