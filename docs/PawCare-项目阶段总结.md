# PawCare 项目阶段总结

> 整理日期：2026-10-10  
> 文档性质：阶段性总结  
> 口径说明：本文基于当前会话中已经梳理的工作整理。“已完成”表示对应设计或链路在既有开发过程中已经实现或验证；“规划中”表示方向已确定，但尚未全部落地。文末百分比仅用于帮助理解阶段，不是严格的项目统计。

## 一、项目概览

PawCare 当前已经从一个基础宠物管理后端，逐步发展为包含业务 API、AI Agent、健康数据、长期与短期记忆、RAG 知识检索，以及 Flutter 客户端规划的完整宠物健康产品原型。

当前整体架构可概括为：

```text
Flutter App（规划/待开发）
        ↓ HTTP / JWT
NestJS Server
        ├── 用户、宠物、健康记录、会话等业务能力
        ├── PostgreSQL / TypeORM
        └── Agent Service JWT 内部接口
                    ↓
Supervisor Agent
        ├── Health Agent
        └── Knowledge Agent
                    ↓
        LangGraph / PostgresStore / Qdrant / RAG
```

后端与 AI 工程当前位于 `paw-care-ai`，Flutter 客户端计划独立放在 `paw-care-app`。

---

## 二、后端基础

### 2.1 技术栈

当前后端技术选型已经确定：

- NestJS
- TypeORM
- PostgreSQL
- JWT
- pnpm monorepo

项目主体结构为：

```text
paw-care-ai/
├── apps/server
├── packages/agent
├── packages/rag
└── infra
```

ORM 在早期探索 Prisma 后，最终切换并稳定在 TypeORM。

### 2.2 已完成的基础能力

- 用户注册与登录
- 用户 JWT 鉴权
- `@CurrentUser()` 当前用户注入
- User Entity
- Pet Entity
- HealthRecord Entity
- Conversation Entity
- Message Entity

这些基础实体与鉴权能力已经为宠物管理、健康记录和 AI 会话提供统一的业务底座。

---

## 三、宠物档案 CRUD

宠物档案接口已经完整建立：

```http
POST   /pets
GET    /pets
GET    /pets/:id
PATCH  /pets/:id
DELETE /pets/:id
```

所有宠物资源都受到当前用户边界约束：

```text
用户 JWT
   ↓
当前 userId
   ↓
只允许访问属于该用户的 Pet
```

该模块不仅服务于普通业务页面，也为 Agent 获取宠物档案和后续 Flutter 的“当前宠物”上下文提供数据来源。

---

## 四、HealthRecord 健康记录

### 4.1 数据模型

已经建立 `health_records`，核心字段包括：

```text
petId
recordType
title
description
recordDate
metadata
```

目前主要支持以下记录类型：

```text
symptom
vaccine
medicine
checkup
weight
diet
```

### 4.2 CRUD 与历史查询

健康记录已经支持创建、列表、详情、更新和删除，并增强了历史查询能力：

- 按 `recordType` 筛选
- 按 `startDate`、`endDate` 查询时间范围
- 使用 `limit` 控制返回数量
- 默认按 `recordDate DESC` 排序

健康趋势分析工具暂未继续开发，目前保留为后续能力。

---

## 五、Conversation 会话体系

PawCare 已经明确区分两类不同的数据：

```text
用户可见的业务会话
→ ai_conversations / ai_messages

Agent 内部运行状态
→ LangGraph checkpoint / thread_id
```

前端调用 AI 时只需要提交：

```json
{
  "conversationId": "...",
  "message": "..."
}
```

前端不负责传递 `petId` 和 `threadId`。服务端根据用户 JWT 中的 `userId` 和 `conversationId`，安全地解析实际的 `petId` 与 `threadId`，避免客户端篡改上下文。

已经完成的会话能力包括：

- 创建会话
- 查询会话列表
- 查询会话详情
- 删除会话
- 删除对应 LangGraph checkpoint
- 保存用户消息
- 保存 AI 最终消息
- 自动生成会话标题

---

## 六、Agent 架构

当前采用 Supervisor 协调多个专业 Agent：

```text
Supervisor
├── health_agent
└── knowledge_agent
```

### 6.1 Supervisor

Supervisor 负责：

- 判断请求应该交给哪个子 Agent
- 融合子 Agent 结果
- 读取和写入长期记忆
- 生成面向用户的最终回答

### 6.2 Health Agent

Health Agent 负责处理：

- 宠物档案
- 宠物健康历史
- 用户明确提供的健康事件

当前工具包括：

```text
get_pet_profile
get_health_history
create_health_record
```

安全边界已经明确：`petId` 和 `userId` 不由模型自由生成，而是从 `PawCareRuntimeContext` 注入。这能够防止模型跨用户或跨宠物访问数据。

### 6.3 职责边界

```text
个人宠物事实、健康历史 → Health Agent
疾病、症状、护理等通用知识 → Knowledge Agent
路由、整合与最终回答       → Supervisor
```

---

## 七、Service JWT

### 7.1 问题背景

Agent 调用 NestJS 内部接口时不能依赖普通用户 JWT，因此项目区分了两类身份：

```text
用户 JWT          → 表示用户身份
Agent Service JWT → 表示内部服务身份
```

### 7.2 已完成的设计

项目使用独立的：

```env
AGENT_SERVICE_JWT_SECRET
```

并实现 `AgentServiceAuthGuard`，校验的关键声明包括：

```text
issuer   = pawcare-agent
audience = pawcare-server
type     = service
sub      = pawcare-agent
```

### 7.3 已验证结果

```text
无 token          → 401
随机 token        → 401
普通用户 JWT      → 401
合法 Service JWT → 200
```

Agent 使用 Service JWT 调用 HealthRecord 写入接口的链路也已经跑通。

---

## 八、健康记录自动写入

Health Agent 已经能够把用户明确表达的健康事实写入 PostgreSQL。

例如用户说：

```text
咪咪今天吐了两次。
```

Agent 可以识别为：

```text
recordType = symptom
```

并通过 `create_health_record` 创建 HealthRecord。

写入边界遵循一条严格原则：

> 只记录用户明确提供的事实，不保存模型推测、诊断、风险判断或猜测病因。

`metadata` 也只允许保存用户明确给出的结构化信息，例如：

```text
vomitCount
temperature
weight
medicineName
dose
```

当用户只是在提出问题，而没有陈述真实发生的健康事件时，不应创建记录。这条端到端链路已经验证成功。

---

## 九、长期与短期记忆

### 9.1 长期记忆

长期记忆采用以下组合：

```text
PostgresStore     → 保存长期记忆正文和结构化数据
Qdrant            → 保存长期记忆的语义索引
DoubaoEmbeddings  → 生成 2048 维向量
```

命名空间为：

```text
users/{userId}/pets/{petId}/memories
```

新旧记忆之间会区分：

```text
same
update
conflict
unrelated
```

例如：

```text
旧记忆：咪咪吃鸡肉会腹泻。
新事实：咪咪现在吃鸡肉已经不会腹泻了。
```

系统能够将其识别为 `update`，并同步更新语义索引。

### 9.2 短期记忆

LangGraph 通过 `thread_id` 维护单个 Conversation 的短期对话上下文，并加入 `summarizationMiddleware`，避免会话历史无限增长。

### 9.3 数据优先级

目前确立的数据优先级为：

```text
业务数据库
   > Agent 长期记忆
   > 当前短期会话
```

最终形成三层数据结构：

```text
业务事实             → PostgreSQL
当前会话上下文       → LangGraph checkpoint
长期用户与宠物信息   → PostgresStore + Qdrant
```

---

## 十、稳定性与可观测性

### 10.1 降级警告

项目已经实现 requestId 级别的 `WarningCollector`，可收集：

```text
MEMORY_UNAVAILABLE
HEALTH_DATA_UNAVAILABLE
KNOWLEDGE_UNAVAILABLE
TOOL_UNAVAILABLE
PARTIAL_RESULT
```

API 可以返回：

```json
{
  "warnings": [],
  "meta": {
    "degraded": false
  }
}
```

这使得某个工具或外部能力暂时失败时，系统可以返回部分结果，而不是直接让整个 AI 请求变成 500。

### 10.2 运行保护与追踪

已经讨论或加入：

- model retry
- tool call limit
- model call limit
- recursionLimit
- LangSmith 运行追踪

此前出现的 `GraphRecursionError` 已经借助 LangSmith 定位并处理。

### 10.3 Doubao 兼容问题

曾经有工具返回如下对象：

```json
{
  "type": "symptom"
}
```

OpenAI-compatible / Doubao 接口会将其中的 `type` 误认为消息 content block 类型，从而触发 schema 错误。当前已经统一改用 `recordType`，同时将工具输出序列化为 JSON string，问题已经解决。

---

## 十一、Knowledge Agent

Knowledge Agent 已经建立，负责疾病、症状、护理、营养、风险与就医提示，以及其他通用宠物医学知识。

目前使用的核心工具为：

```text
search_pet_knowledge
```

Knowledge Agent 不读取当前宠物档案，避免把通用知识检索与个人宠物事实混在一起。

---

## 十二、RAG 链路

当前基础检索链路为：

```text
知识文本
   ↓
DoubaoEmbeddings
   ↓
Qdrant pet_knowledge
   ↓
similaritySearchWithScore
   ↓
Knowledge Agent
   ↓
Supervisor
```

`searchKnowledge()` 已改为使用 `similaritySearchWithScore()`，返回结构为：

```ts
{
  content,
  score,
  metadata
}
```

使用“猫瘟有哪些特征呢”进行测试时，能够从 Qdrant 召回相应知识。这说明以下基础环节已连通：

```text
Embedding       ✅
Qdrant          ✅
Search          ✅
Knowledge Agent ✅
Supervisor      ✅
```

---

## 十三、猫知识库

第一批猫知识库至少覆盖以下 9 个主题：

```text
cat/
├── vomiting
├── diarrhea
├── appetite-loss
├── urinary-obstruction
├── chronic-kidney-disease
├── feline-leukemia
├── feline-panleukopenia
├── upper-respiratory-infection
└── nutrition-obesity
```

内容主要参考 Cornell Feline Health Center、Merck Veterinary Manual、WSAVA 和 AAHA。知识内容不是直接复制网页，而是重新整理成更适合中文问答和 RAG 检索的结构化 Markdown 文本。

当前知识文件格式确定为纯 Markdown：

```md
# 猫食欲下降与厌食

## 定义
...

## 常见原因
...

## 危险信号
...
```

元数据来源规则为：

```text
目录        → species
文件名      → topic
# 一级标题  → title
## 二级标题 → section
manifest    → category / source / language
```

---

## 十四、RAG 已发现的问题

### 14.1 行为规则干扰检索

早期检索中，“PawCare 知识使用边界”等行为规则曾因为文字与用户问题过于相似而成为 Top 1。

已经明确 Agent 行为规则和 DISCLAIMER 不应参与 embedding，相关无效内容已经从向量检索范围中排除。

### 14.2 固定字数切块破坏语义

原有按约 400 字直接切分的方式会导致 chunk 从半句话开始、标题与正文被切开、多个 `##` section 混入同一个 chunk，甚至文末只剩孤立的 `#`。

当前确定的改造方向是：

```text
Markdown 文档
   ↓
解析 H1 标题
   ↓
按 H2 Section 切分
   ↓
一个 Section 作为基础语义块
   ↓
仅对过长 Section 进行二次 chunk
```

固定长度与 overlap 只作为 Section 内的第二层兜底，不再作为第一层切割方式。

---

## 十五、企业级 Ingestion 规划

### 15.1 目标流程

```text
Load → Parse → Clean → Section Parse → Chunk → Validate
     → Embedding → Qdrant Upsert → Ingestion Report
```

### 15.2 已确定的关键能力

- `documentId`、`contentHash` 和稳定 Point ID
- 文档级 replace 与失效旧 chunk 清理
- 避免重复导入
- 标准 metadata
- `source`、`section`、`topic`、`category`、`species`
- batch embedding 与 batch upsert
- retry 与指数退避
- dry-run 与 rebuild
- ingestion report

### 15.3 文档更新策略

在当前知识规模下，优先采用文档级替换，而不是复杂的 chunk 级 diff：

```text
按 documentId 删除旧 points
   ↓
重新解析与切块
   ↓
重新 embedding
   ↓
写入当前完整文档
```

这种方式简单、可靠且容易保证幂等。待知识库规模显著增大后，再考虑 chunk 级增量更新。

### 15.4 V1 落地范围

企业级 ingestion 尚未全部完成，当前建议先落地 8 项必需能力：

1. 标准 metadata 解析。
2. 清除 PawCare rules 与 disclaimer。
3. 按 Markdown `##` Section 切分。
4. 只对过长 Section 做二次 chunk。
5. 在 `pageContent` 注入 Title 与 Section。
6. 补齐 `documentId`、`title`、`topic`、`category`、`species`、`section`、`chunkIndex`。
7. 实现文档级 delete + replace，确保重复导入不产生重复数据。
8. 输出 ingestion report。

完成以上能力后，入库链路可以从 Demo ingestion 升级为 production-oriented ingestion pipeline。后续再补充 `contentHash`、稳定 Point ID、batch、retry、dry-run、版本控制和增量更新。

---

## 十六、Flutter 开发计划

Flutter 当前处于规划阶段，尚未正式开始完整编码。建议按以下顺序推进：

| 阶段 | 主要目标 |
|---|---|
| Phase 0 | 项目初始化、环境配置、网络层、Token 存储、路由、主题和基础目录 |
| Phase 1 | 登录、注册、自动登录、退出和 Token 失效处理 |
| Phase 2 | 宠物列表、创建、详情、编辑、删除与 `currentPetId` |
| Phase 3 | 首页、当前宠物卡片、健康概览、快捷入口和最近记录 |
| Phase 4 | AI 会话列表、新建会话、聊天、历史消息与流式体验 |
| Phase 5 | 健康记录列表、筛选、创建和详情 |
| Phase 6 | 体重趋势与图表 |
| Phase 7 | 宠物相册 |
| Phase 8 | “我的”页面与设置 |
| Phase 9 | 空状态、加载状态、错误恢复和整体体验完善 |
| Phase 10 | 构建、测试、隐私与上线准备 |

底部导航计划为：

```text
首页 / 健康 / AI / 相册 / 我的
```

视觉风格继续采用 PawCare 的暖色与清新配色：

```text
暖橙：#FF9E64 / #FF9F70
薄荷绿：#64D2AA
```

---

## 十七、Flutter 仓库策略

建议将 Flutter 客户端与后端/Agent monorepo 分开：

```text
PawCare/
├── paw-care-ai/       # 后端 + Agent + RAG
│   ├── apps/server
│   ├── packages/agent
│   └── packages/rag
│
└── paw-care-app/      # Flutter 客户端
    ├── lib
    ├── android
    ├── ios
    └── pubspec.yaml
```

原因是两者的技术栈、依赖管理、构建链、CI 和发布流程不同。保持独立仓库可以让边界更清晰。

具体选择原则：

- 如果已经有独立 Flutter PawCare 项目，并包含 onboarding、登录、创建宠物等代码，则继续使用原仓库。
- 如果目前只有 `paw-care-ai`，则新建 `paw-care-app`。
- 不建议把 Flutter 直接放进 `paw-care-ai/apps/mobile`。

---

## 十八、当前阶段评估

以下比例是帮助理解成熟度的阶段估算，不是严格统计：

| 模块 | 阶段估算 | 当前判断 |
|---|---:|---|
| 后端业务基础 | 85% | 核心实体、鉴权和主要业务接口已具备 |
| Agent 架构 | 80% | Supervisor 与两个专业 Agent 的边界已形成 |
| 长期/短期记忆 | 80% | 三层数据结构与主要读写链路已建立 |
| 健康数据能力 | 80% | CRUD、历史查询和 Agent 写入已完成 |
| RAG 查询链路 | 70% | 基础召回链路已跑通，仍需提升切块和检索质量 |
| 知识库内容 | 50% | 已有首批猫知识主题，覆盖面仍需扩大 |
| 企业级 Ingestion | 30% | 方案已明确，工程化能力尚未完整落地 |
| Flutter App | 10% | 已完成路线规划，产品端尚待正式开发 |

PawCare 当前已经不再只是“后端 Demo”，而是具备业务数据库、Agent 编排、健康数据写入、记忆、知识检索和客户端路线的产品型原型。现阶段的主要短板不在基础架构，而在于产品端闭环和 RAG 工程化程度。

---

## 十九、后续建议

### 19.1 当前优先级：先做 Flutter 最小闭环

建议优先完成：

```text
登录 → 宠物档案 → 首页 → AI 聊天 → 健康记录
```

原因是后端已经具备足够能力。先让用户真正走通产品主链路，能够更快暴露接口、交互和 Agent 回答中的真实问题，也能为后续 RAG 优化提供明确需求。

### 19.2 RAG 保留一条并行但收敛的工程线

RAG 侧建议先完成 ingestion V1 的 8 项必需能力，不要立即扩展过多高级能力。优先解决：

1. Section-first chunking。
2. 标题和章节语义注入。
3. 文档级幂等替换。
4. 标准元数据与导入报告。
5. 建立固定测试问题与召回结果，用于回归验证。

### 19.3 下一阶段里程碑

- Flutter 能完成注册/登录并保持登录状态。
- 用户能创建和切换宠物。
- 用户能创建 AI 会话、发送消息并查看历史。
- 用户陈述明确健康事实后，能够看到对应 HealthRecord。
- Knowledge Agent 回答能够引用结构清晰、来源可追踪的知识片段。
- 任何子能力降级时，API 能返回可解释的 warning，而不是无差别 500。

达到这些标准后，PawCare 就具备第一版可演示、可测试的端到端产品闭环。

---

## 二十、结论

当前项目已经完成了后端、健康数据、Agent、记忆和基础 RAG 的核心骨架，并验证了从用户会话到 Health Agent 写入健康记录、从知识问题到 Knowledge Agent 检索回答的关键链路。

下一步最有价值的工作，不是继续无限扩展底层架构，而是用独立的 `paw-care-app` 把现有能力串成真实用户流程；与此同时，以明确的 V1 范围完成 RAG ingestion 工程化。这样可以同时推进“产品可用性”和“知识质量”，避免项目长期停留在基础设施建设阶段。
