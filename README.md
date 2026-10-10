# PawCare App

PawCare 的 Flutter 客户端。

## 应用标识

```text
Android applicationId: com.zhangchen.pawcare
iOS Bundle ID:         com.zhangchen.pawcare
```

## 本地运行

默认使用开发环境，并连接本机的 `http://127.0.0.1:3000/api`：

```bash
flutter run
```

覆盖本地 API 地址：

```bash
flutter run \
  --dart-define=APP_ENV=dev \
  --dart-define=API_BASE_URL=http://127.0.0.1:3000/api
```

Android 模拟器访问宿主机时，通常需要使用 `http://10.0.2.2:3000/api`：

```bash
flutter run \
  --dart-define=APP_ENV=dev \
  --dart-define=API_BASE_URL=http://10.0.2.2:3000/api
```

测试环境与生产环境必须显式提供 API 地址：

```bash
flutter run \
  --dart-define=APP_ENV=staging \
  --dart-define=API_BASE_URL=https://staging-api.example.com
```

支持的 `APP_ENV` 值为 `dev`、`staging` 和 `prod`。环境配置通过编译参数注入，不要把密钥写入 `--dart-define` 或提交到仓库。

## 开发检查

```bash
dart format lib test
flutter analyze
flutter test
```
