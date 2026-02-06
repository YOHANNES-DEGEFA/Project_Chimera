# Project Chimera: Frontend Specification
*User Interface Design, Component Hierarchy & User Flows | Version 1.0*

## 1. Purpose & Scope

This specification defines the complete user-facing layer for Project Chimera's Super-Orchestrator dashboard. The frontend enables humans to monitor, approve, and govern autonomous agent swarms at scale (1 human → 1,000+ agents).

**Target Audience**: Super-Orchestrators (campaign managers, content strategists)
**Platform**: Web application (React/Next.js), responsive design (desktop-first, mobile-adaptive)

## 2. Screen Inventory

### 2.1 Core Screens

| Screen ID | Name | Purpose | Primary User Action |
|-----------|------|---------|---------------------|
| `SCREEN_001` | Campaign Dashboard | Overview of all campaigns, status, budget consumption | Create new campaign, filter by status |
| `SCREEN_002` | Campaign Detail | Deep dive into single campaign: DAG visualization, task progress | Approve/reject HITL items, view generated content |
| `SCREEN_003` | HITL Review Queue | Centralized queue of content requiring human approval | Batch approve/reject, add review notes |
| `SCREEN_004` | Agent Monitoring | Real-time status of all agents (Planner/Worker/Judge) | View agent health, reputation scores, current tasks |
| `SCREEN_005` | Analytics & Insights | Engagement metrics, budget analytics, content performance | Filter by date range, export reports |
| `SCREEN_006` | Settings & Configuration | Character references, budget limits, notification preferences | Upload character images, set daily spend limits |

### 2.2 Secondary Screens

| Screen ID | Name | Purpose |
|-----------|------|---------|
| `SCREEN_007` | Login/Authentication | OAuth 2.0 PKCE flow with Google Workspace |
| `SCREEN_008` | Content Preview Modal | Full-screen preview of generated video/image before approval |
| `SCREEN_009` | DAG Execution Timeline | Visual timeline of task execution with state transitions |

## 3. Component Hierarchy

### 3.1 Layout Components

```
App (Root)
├── AuthGuard (Route protection)
├── Layout
│   ├── Header
│   │   ├── Logo
│   │   ├── Navigation (Campaigns, HITL Queue, Agents, Analytics)
│   │   └── UserMenu (Profile, Settings, Logout)
│   ├── Sidebar (Collapsible)
│   │   ├── CampaignFilter
│   │   └── QuickStats (Total campaigns, Pending HITL count)
│   └── MainContent (Router outlet)
│       ├── CampaignDashboard (SCREEN_001)
│       ├── CampaignDetail (SCREEN_002)
│       ├── HITLReviewQueue (SCREEN_003)
│       ├── AgentMonitoring (SCREEN_004)
│       ├── AnalyticsInsights (SCREEN_005)
│       └── SettingsConfig (SCREEN_006)
└── GlobalModals
    ├── ContentPreviewModal (SCREEN_008)
    ├── CreateCampaignModal
    └── ConfirmationDialog
```

### 3.2 Core Feature Components

**CampaignDashboard (SCREEN_001)**
```
CampaignDashboard
├── CampaignList
│   ├── CampaignCard (repeated)
│   │   ├── CampaignHeader (title, status badge, budget bar)
│   │   ├── ProgressIndicator (tasks completed/total)
│   │   ├── QuickActions (View Detail, Pause, Delete)
│   │   └── HITLPendingBadge (count if >0)
│   └── EmptyState (if no campaigns)
├── CampaignFilters
│   ├── StatusFilter (pending|executing|completed|failed)
│   ├── DateRangeFilter
│   └── SearchInput
└── CreateCampaignButton (opens modal)
```

**CampaignDetail (SCREEN_002)**
```
CampaignDetail
├── CampaignHeader
│   ├── Title & Status
│   ├── BudgetConsumption (current/total, percentage)
│   └── ActionButtons (Pause, Resume, Delete)
├── DAGVisualization
│   ├── TaskNode (repeated, color-coded by status)
│   │   ├── TaskTypeIcon
│   │   ├── TaskStatusBadge
│   │   └── TaskDetailsTooltip (on hover)
│   └── DependencyEdges (arrows between nodes)
├── TaskList (Tabbed: All | Pending | Completed | Failed)
│   ├── TaskRow (repeated)
│   │   ├── TaskMetadata (type, worker_did, timestamp)
│   │   ├── ConfidenceScore (color-coded: green >0.9, amber 0.7-0.9, red <0.7)
│   │   └── TaskArtifactPreview (thumbnail, click opens ContentPreviewModal)
│   └── Pagination
└── HITLReviewSection (if pending reviews exist)
    └── HITLReviewCard (repeated, links to SCREEN_003)
```

**HITLReviewQueue (SCREEN_003)**
```
HITLReviewQueue
├── ReviewFilters
│   ├── CampaignFilter (dropdown)
│   ├── ConfidenceRangeFilter (slider: 0.7-0.9)
│   ├── SensitiveTopicFilter (checkbox: politics|health|finance|legal)
│   └── SortBy (Newest First | Oldest First | Highest Confidence)
├── ReviewList
│   ├── ReviewCard (repeated)
│   │   ├── ContentPreview (video/image thumbnail, play button)
│   │   ├── ReviewMetadata
│   │   │   ├── CampaignName (link to SCREEN_002)
│   │   │   ├── AgentDID (who generated)
│   │   │   ├── ConfidenceScore (badge)
│   │   │   ├── SensitiveTopicTags (if detected)
│   │   │   └── TimeInQueue (relative: "2 hours ago")
│   │   ├── ReviewActions
│   │   │   ├── ApproveButton (primary, green)
│   │   │   ├── RejectButton (secondary, red)
│   │   │   ├── RequestChangesButton (secondary, amber)
│   │   │   └── NotesTextarea (optional, max 500 chars)
│   │   └── BatchSelectionCheckbox (for bulk actions)
│   └── EmptyState (if no pending reviews)
└── BulkActionsBar (appears when items selected)
    ├── BulkApproveButton
    ├── BulkRejectButton
    └── SelectedCount
```

**AgentMonitoring (SCREEN_004)**
```
AgentMonitoring
├── AgentTypeTabs (Planner | Worker | Judge)
├── AgentGrid
│   ├── AgentCard (repeated)
│   │   ├── AgentDID (truncated, copy button)
│   │   ├── StatusIndicator (available|busy|maintenance, color-coded)
│   │   ├── CurrentTask (if busy, link to task in CampaignDetail)
│   │   ├── ReputationScore (0.0-1.0, visual gauge)
│   │   ├── Metrics
│   │   │   ├── TasksCompleted (count)
│   │   │   ├── AverageConfidence (decimal)
│   │   │   └── BudgetConsumed (USD)
│   │   └── LastHeartbeat (relative time)
│   └── EmptyState (if no agents of type)
└── AgentFilters
    ├── StatusFilter
    └── ReputationFilter (slider: min reputation score)
```

**AnalyticsInsights (SCREEN_005)**
```
AnalyticsInsights
├── DateRangePicker (default: last 30 days)
├── MetricsGrid
│   ├── MetricCard (Total Campaigns, Total Content Generated, Avg Engagement Rate)
│   ├── MetricCard (Budget Spent, Budget Remaining, ROI)
│   └── MetricCard (HITL Approval Rate, Auto-Approval Rate)
├── ChartsSection
│   ├── EngagementRateChart (line chart: engagement over time)
│   ├── PlatformDistributionChart (pie chart: TikTok vs Instagram vs YouTube)
│   ├── BudgetConsumptionChart (bar chart: spend per campaign)
│   └── AgentPerformanceChart (scatter: reputation vs tasks completed)
└── ExportButton (CSV/JSON download)
```

## 4. User Interaction Flows

### 4.1 Flow: Create Campaign → Monitor → Approve Content

```
1. User lands on SCREEN_001 (Campaign Dashboard)
2. User clicks "Create Campaign" button
   → Opens CreateCampaignModal
3. User fills form:
   - Goal (text, min 10 chars, validated)
   - Budget USD (number, validated >0)
   - Target Platforms (multi-select: TikTok, Instagram, YouTube)
   - Character Reference (optional, file upload)
4. User submits form
   → POST /api/v1/campaigns
   → Response: campaign_id, status: "pending"
5. Modal closes, user sees new CampaignCard in list
6. User clicks CampaignCard
   → Navigates to SCREEN_002 (Campaign Detail)
7. User sees DAG visualization updating in real-time (WebSocket)
8. User sees HITLReviewSection appear when content requires approval
9. User clicks "Review" button on HITL item
   → Navigates to SCREEN_003 (HITL Review Queue), filtered to this campaign
10. User previews content (video plays in ContentPreviewModal)
11. User clicks "Approve" button
    → POST /api/v1/hitl/reviews/{review_id}/approve
    → Response: approval_token
    → Content automatically distributed via MCP post_content tool
12. User returns to SCREEN_002, sees task status updated to "completed"
```

### 4.2 Flow: Batch Approve HITL Reviews

```
1. User navigates to SCREEN_003 (HITL Review Queue)
2. User applies filters (e.g., confidence 0.8-0.9, no sensitive topics)
3. User selects multiple ReviewCards via checkboxes
4. User clicks "Bulk Approve" button in BulkActionsBar
   → ConfirmationDialog appears: "Approve 5 items?"
5. User confirms
   → POST /api/v1/hitl/reviews/bulk-approve
   → Request: { review_ids: ["uuid1", "uuid2", ...] }
   → Response: { approved_count: 5, failed_count: 0 }
6. UI updates: Selected cards removed from queue, success toast shown
```

### 4.3 Flow: Monitor Agent Health

```
1. User navigates to SCREEN_004 (Agent Monitoring)
2. User selects "Worker" tab
3. User sees grid of Worker AgentCards
4. User notices one AgentCard shows StatusIndicator = "maintenance"
5. User clicks AgentCard
   → Expands to show detailed metrics:
     - Last successful task: 2 hours ago
     - Error rate: 15% (above threshold)
     - Reputation score: 0.65 (below 0.7 threshold)
6. User clicks "View Tasks" link
   → Navigates to SCREEN_002 filtered to show this agent's tasks
7. User identifies failed tasks, reviews error logs
```

## 5. API Integration Mapping

### 5.1 Backend Endpoints → Frontend Components

| Frontend Component | Backend Endpoint | Method | Request Schema | Response Schema |
|-------------------|------------------|--------|----------------|-----------------|
| `CreateCampaignModal` | `/api/v1/campaigns` | POST | See §3.2.1 | See §3.2.1 |
| `CampaignList` | `/api/v1/campaigns` | GET | `?status=pending&limit=20&offset=0` | Array of campaign objects |
| `CampaignDetail` | `/api/v1/campaigns/{id}/status` | GET | Path param: `id` | See §3.2.2 |
| `CampaignDetail` | `/api/v1/campaigns/{id}/dag` | GET | Path param: `id` | DAG JSON with task nodes |
| `HITLReviewQueue` | `/api/v1/hitl/reviews` | GET | `?status=pending&campaign_id={id}` | Array of review objects |
| `HITLReviewCard` | `/api/v1/hitl/reviews/{id}/approve` | POST | See §3.2.3 | See §3.2.3 |
| `AgentMonitoring` | `/api/v1/agents` | GET | `?type=worker&status=available` | Array of agent status objects |
| `AnalyticsInsights` | `/api/v1/analytics/metrics` | GET | `?start_date=...&end_date=...` | Aggregated metrics object |

### 5.2 Real-Time Updates (WebSocket)

**Connection**: `wss://api.chimera.io/v1/ws?token={jwt}`

**Message Types:**
- `campaign_status_update`: Campaign status changed (pending → executing)
- `task_completed`: Task in DAG completed, update progress bar
- `hitl_review_created`: New review added to queue, show notification badge
- `agent_heartbeat`: Agent status changed, update AgentCard

**Frontend Handling:**
```typescript
// Pseudo-code
websocket.on('campaign_status_update', (data) => {
  updateCampaignCard(data.campaign_id, { status: data.status });
});

websocket.on('hitl_review_created', (data) => {
  if (currentScreen === SCREEN_003) {
    prependReviewCard(data.review);
  }
  incrementHITLBadgeCount();
});
```

## 6. Design System & Accessibility

### 6.1 Color Palette
- **Primary**: #0066CC (Chimera blue, for primary actions)
- **Success**: #00AA44 (green, for approved/auto-approved content)
- **Warning**: #FF8800 (amber, for HITL pending, confidence 0.7-0.9)
- **Error**: #CC0000 (red, for rejected content, confidence <0.7)
- **Neutral**: #666666 (gray, for disabled states)

### 6.2 Typography
- **Headings**: Inter, 24px/32px (h1), 20px/28px (h2), 16px/24px (h3)
- **Body**: Inter, 14px/20px
- **Monospace**: JetBrains Mono, 12px/18px (for agent DIDs, hashes)

### 6.3 Accessibility Requirements
- **WCAG 2.1 AA compliance**: All interactive elements keyboard-navigable
- **Screen reader support**: ARIA labels on all icons, status badges announce state changes
- **Color contrast**: Minimum 4.5:1 for text, 3:1 for UI components
- **Focus indicators**: Visible focus rings on all interactive elements

## 7. Responsive Design Breakpoints

- **Desktop**: ≥1024px (default, full feature set)
- **Tablet**: 768px-1023px (sidebar collapses, simplified charts)
- **Mobile**: <768px (single-column layout, bottom navigation bar)

## 8. Performance Requirements

- **Initial Load**: <2 seconds (First Contentful Paint)
- **Time to Interactive**: <3 seconds
- **API Response Time**: <500ms (p95)
- **WebSocket Reconnection**: <1 second on network interruption

## 9. Error Handling & Edge Cases

### 9.1 API Error Scenarios
- **401 Unauthorized**: Redirect to login screen, show toast "Session expired"
- **403 Forbidden**: Show error message "You don't have permission to access this campaign"
- **500 Server Error**: Show retry button, log error to Sentry
- **Network Timeout**: Show offline indicator, queue actions for retry

### 9.2 Empty States
- **No campaigns**: Show illustration + "Create your first campaign" CTA
- **No pending HITL reviews**: Show "All caught up! 🎉" message
- **No agents available**: Show "No agents of this type are currently active"

## 10. Component Specifications (Detailed)

### 10.1 ContentPreviewModal Component

**Props:**
```typescript
interface ContentPreviewModalProps {
  contentHash: string;
  contentType: 'video' | 'image';
  platform: 'tiktok' | 'instagram_reels' | 'youtube_shorts';
  onApprove: (reviewId: string) => void;
  onReject: (reviewId: string, reason: string) => void;
  onClose: () => void;
}
```

**API Integration:**
- `GET /api/v1/content/{content_hash}/preview` → Returns signed S3 URL for video/image
- Video player: HTML5 `<video>` with controls, autoplay on open
- Image viewer: Full-screen with zoom/pan gestures

### 10.2 DAGVisualization Component

**Library**: React Flow or D3.js (decision: React Flow for React integration)

**Data Source:** `GET /api/v1/campaigns/{id}/dag` → Returns DAG JSON

**Visualization Rules:**
- Nodes: Rounded rectangles, color-coded by task status (green=completed, amber=pending, red=failed)
- Edges: Arrows showing dependencies, animated when task completes
- Layout: Hierarchical (top-to-bottom), auto-layout algorithm
- Interaction: Click node → Show TaskDetailsTooltip with metadata

## 11. Compliance Verification Checklist

- [ ] All screens mapped to backend API contracts (see §5.1)
- [ ] All user flows include error handling and edge cases
- [ ] Component hierarchy supports responsive design breakpoints
- [ ] Accessibility requirements (WCAG 2.1 AA) specified
- [ ] Real-time updates via WebSocket documented
- [ ] Performance requirements defined with measurable thresholds
- [ ] Empty states and loading states specified for all data-dependent components
