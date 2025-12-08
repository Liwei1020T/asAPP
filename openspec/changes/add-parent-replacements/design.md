## Context
家长在孩子缺席原定课时时，需要选择可用班次补课。必须先由家长手动标记缺勤，再提交补课申请；需兼顾容量、时间冲突、审批规则、通知，以及保持班次与出勤数据一致。

## Goals / Non-Goals
- Goals: 提供家长端补课申请与可报名班次列表；校验容量与时间冲突；支持自动确认或待审核；在日程/出勤中体现补课结果；在确认/拒绝/撤销时推送通知。
- Non-Goals: 支付/费用结算、跨校区调课策略、复杂规则引擎。

## Decisions
- Data: 新增 `replacement_requests`（id, studentId, sourceSessionId, targetSessionId, status[pending|confirmed|rejected|cancelled], reason/notes, requestedAt, handledBy, decidedAt）。
- Auto-confirm: 满足容量>0、无时间冲突、同级别/匹配条件时直接确认并占用名额；否则 `pending` 供管理员/教练审核。
- Integration: 只有当源课次存在家长手动缺勤记录时可发起；确认后将学生关联到目标 session（报名列表/出勤默认缺席待打卡），原课次保持缺勤标记。
- Notifications: 在确认/拒绝/撤销时向家长推送站内通知（可复用现有通知或新增轻量消息通道）。
- UI: 家长端新增补课列表/筛选视图与申请对话框；在“我的补课”里展示状态与撤销；拒绝需显示理由。

## Risks / Trade-offs
- 容量写冲突：需在提交时做原子校验/更新，避免超额；必要时增加重试或失败提示。
- 规则升级：未来若有更复杂政策，可能需要抽象可配置规则；当前保持简化以快速落地。
- 通知一致性：若通知通道失败需回退为状态视图可见并允许重发。

## Open Questions
- 自动确认的具体匹配条件（目前假设级别/场馆匹配，无教练/时间窗口限制）。
- 通知渠道是否仅站内，是否需要推送至教练/管理员。
