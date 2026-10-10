# PawCare 认证接口契约

> 核对日期：2026-10-10  
> 依据：`paw-care-ai/apps/server` 当前代码  
> 状态：Phase 1 所需的最小认证契约已实现

## 一、基础地址

NestJS 服务默认端口为 `3000`，并配置全局前缀 `api`。

```text
开发环境 API Base URL：http://127.0.0.1:3000/api/
```

认证接口：

```text
POST /api/auth/register
POST /api/auth/login
GET  /api/auth/me
```

Flutter 的 `ApiClient` 已包含 `/api/`。业务代码使用相对路径
`auth/register`、`auth/login` 和 `auth/me`，不要再次拼接 `/api`。

## 二、统一用户与认证响应

注册和登录成功时返回相同结构：

```json
{
  "access_token": "jwt-token",
  "user": {
    "id": "uuid",
    "email": "user@example.com",
    "nickname": "小陈",
    "avatarUrl": null
  }
}
```

`nickname` 和 `avatarUrl` 均允许为 `null`。响应不包含 `passwordHash`、
`createdAt` 或 `updatedAt`。

Flutter 模型需要把服务端的 `access_token` 映射为客户端字段
`accessToken`。

## 三、注册接口

### 请求

```http
POST /api/auth/register
Content-Type: application/json
```

```json
{
  "email": "user@example.com",
  "password": "123456",
  "nickname": "小陈"
}
```

字段规则：

| 字段 | 类型 | 规则 |
|---|---|---|
| `email` | string | 必填，去除两端空格并转为小写，必须符合邮箱格式 |
| `password` | string | 必填，最少 6 个字符 |
| `nickname` | string | 必填，去除两端空格，不允许为空，最多 50 个字符 |

注册成功后直接签发 Token，Flutter 不需要再次调用登录接口。

重复邮箱返回：

```http
409 Conflict
```

```json
{
  "message": "该邮箱已注册",
  "error": "Conflict",
  "statusCode": 409
}
```

服务端同时处理注册前检查和数据库唯一约束冲突，避免并发注册产生 500。

## 四、登录接口

### 请求

```http
POST /api/auth/login
Content-Type: application/json
```

```json
{
  "email": "user@example.com",
  "password": "123456"
}
```

字段规则：

| 字段 | 类型 | 规则 |
|---|---|---|
| `email` | string | 必填，去除两端空格并转为小写，必须符合邮箱格式 |
| `password` | string | 必填，最少 6 个字符 |

邮箱不存在或密码错误均返回：

```http
401 Unauthorized
```

```json
{
  "message": "邮箱或密码错误",
  "error": "Unauthorized",
  "statusCode": 401
}
```

## 五、当前用户接口

```http
GET /api/auth/me
Authorization: Bearer <token>
```

成功响应：

```json
{
  "id": "uuid",
  "email": "user@example.com",
  "nickname": "小陈",
  "avatarUrl": null
}
```

Token 无效、过期，或 Token 对应的用户已不存在时返回 `401 Unauthorized`。
Flutter 冷启动时用该接口验证本地 Token，并恢复当前用户信息。

## 六、JWT 契约

JWT 使用 `Authorization: Bearer <token>` 传递。

Payload：

```json
{
  "sub": "user-uuid",
  "email": "user@example.com"
}
```

当前有效期为 7 天，并启用过期校验。MVP 暂不提供 Refresh Token 和服务端
退出接口；认证接口返回 401 时，Flutter 清理本地 Token 并返回登录页。

用户登录 JWT 使用 `JWT_SECRET`。服务间调用继续使用独立的
`AGENT_SERVICE_JWT_SECRET`，两类身份凭证不混用。

## 七、校验错误

全局 `ValidationPipe` 开启了 `whitelist` 和 `transform`。DTO 之外的字段会被
移除。校验失败响应为：

```http
400 Bad Request
```

```json
{
  "message": [
    "email must be an email",
    "password must be longer than or equal to 6 characters"
  ],
  "error": "Bad Request",
  "statusCode": 400
}
```

Flutter 网络层已支持把字符串数组 `message` 合并为可显示信息。

## 八、Phase 1 客户端接入顺序

1. 建立 `AuthUser` 和 `AuthResponse` 数据模型。
2. 实现注册、登录和当前用户读取的远程数据源。
3. 成功注册或登录后把 `access_token` 写入安全存储。
4. 冷启动读取 Token，并通过 `GET auth/me` 恢复会话。
5. 收到认证接口 `401` 时清理 Token，由路由守卫返回登录页。
