# PawCare Flutter MVP 验收清单

> 更新日期：2026-10-13

## 已验证

- 用户可以登录并恢复登录状态。
- 用户可以创建、编辑、删除宠物，并恢复当前宠物。
- 首页、健康、AI、相册、我的五栏导航可用。
- 用户可以创建、查看和删除 AI 会话，并完成普通 AI 问答。
- 用户可以新增、查看、编辑和删除手动健康记录。
- 健康记录支持类型筛选和日期范围筛选。
- 切换宠物后，健康记录按当前宠物重新加载。
- 重新进入健康页时会刷新服务端数据。
- Agent 创建的 symptom 记录可以在健康页显示。
- iPhone 18 Pro 模拟器 Xcode debug 构建成功。
- `flutter analyze` 无问题。
- Flutter 单元与组件测试共 55 项通过。

## 自动化验收入口

```text
integration_test/pet_flow_test.dart
integration_test/ai_flow_test.dart
integration_test/health_flow_test.dart
integration_test/mvp_flow_test.dart
```

健康记录手动流程覆盖：

```text
登录
→ 创建临时宠物
→ 新增 symptom 记录
→ 类型筛选
→ 查看详情
→ 编辑记录
→ 删除记录
→ 删除临时宠物
```

MVP 联调流程覆盖：

```text
登录
→ 创建临时宠物
→ 创建 AI 会话
→ 陈述明确健康事实
→ Agent 写入 symptom 记录
→ 进入健康页刷新并看到记录
→ 清理临时数据
```

## 当前阻塞项

### Agent 最终回复

用户陈述健康事实后，Health Agent 能创建记录，但 Supervisor 没有返回并持久化最终助手消息，请求最终超时。需要在后端 Agent 链路继续定位 `supervisorAgent.invoke()` 的工具调用后续阶段。

### 相对日期

测试时间为 2026-10-13，Agent 将“今天”写成了 `2024-05-20`。当前 Health Agent 提示词没有注入运行时当前日期，需要由后端提供可靠的日期上下文。

### Android 构建

本机未配置 Android SDK，`flutter build apk --debug` 无法执行。配置 `ANDROID_HOME` 和 Android SDK 后重新验证。

## 复验标准

- AI 健康事实请求在客户端超时前返回最终回答。
- 会话详情中同时存在用户消息和助手消息。
- “今天”写入的 `recordDate` 与当前本地日期一致。
- 健康页显示 Agent 新建的记录。
- Android debug APK 构建成功。
