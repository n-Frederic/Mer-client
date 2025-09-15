import type { UserRole, Permission } from "./types"

export const getRolePermissions = (role: UserRole): Permission => {
  switch (role) {
    case "founder":
      return {
        canCreate: true,
        canEdit: true,
        canDelete: true,
        canView: true,
        canApprove: true,
        canViewSubordinates: true,
        canRequestApproval: false,
      }
    case "admin":
      return {
        canCreate: true,
        canEdit: true,
        canDelete: true,
        canView: true,
        canApprove: true,
        canViewSubordinates: true,
        canRequestApproval: true,
      }
    case "department_head":
      return {
        canCreate: true,
        canEdit: true,
        canDelete: false,
        canView: true,
        canApprove: true,
        canViewSubordinates: true,
        canRequestApproval: true,
      }
    case "team_leader":
      return {
        canCreate: true,
        canEdit: true,
        canDelete: false,
        canView: true,
        canApprove: false,
        canViewSubordinates: true,
        canRequestApproval: true,
      }
    case "employee":
      return {
        canCreate: true,
        canEdit: false,
        canDelete: false,
        canView: false,
        canApprove: false,
        canViewSubordinates: false,
        canRequestApproval: true,
      }
    default:
      return {
        canCreate: false,
        canEdit: false,
        canDelete: false,
        canView: false,
        canApprove: false,
        canViewSubordinates: false,
        canRequestApproval: false,
      }
  }
}

export const getRoleDisplayName = (role: UserRole): string => {
  switch (role) {
    case "founder":
      return "创始人"
    case "admin":
      return "管理员"
    case "department_head":
      return "部门主管"
    case "team_leader":
      return "团队长"
    case "employee":
      return "员工"
    default:
      return "未知"
  }
}
