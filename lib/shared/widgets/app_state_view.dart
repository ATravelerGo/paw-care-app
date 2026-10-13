import 'package:flutter/material.dart';

class AppLoadingView extends StatelessWidget {
  const AppLoadingView({
    this.message = '正在加载…',
    this.animate = true,
    super.key,
  });

  final String? message;
  final bool animate;

  @override
  Widget build(BuildContext context) {
    return _AppStateLayout(
      indicator: SizedBox.square(
        dimension: 32,
        child: CircularProgressIndicator(
          value: animate ? null : 0.5,
          strokeWidth: 3,
        ),
      ),
      message: message,
    );
  }
}

class AppEmptyView extends StatelessWidget {
  const AppEmptyView({
    required this.title,
    this.message,
    this.icon = Icons.inbox_outlined,
    this.actionLabel,
    this.onAction,
    super.key,
  }) : assert(
         (actionLabel == null) == (onAction == null),
         'actionLabel and onAction must be provided together.',
       );

  final String title;
  final String? message;
  final IconData icon;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return _AppStateLayout(
      indicator: Icon(
        icon,
        size: 56,
        color: Theme.of(context).colorScheme.outline,
      ),
      title: title,
      message: message,
      action: actionLabel == null
          ? null
          : FilledButton(onPressed: onAction, child: Text(actionLabel!)),
    );
  }
}

class AppErrorView extends StatelessWidget {
  const AppErrorView({
    this.title = '加载失败',
    this.message = '暂时无法获取数据，请稍后重试。',
    this.retryLabel = '重新加载',
    this.onRetry,
    super.key,
  });

  final String title;
  final String? message;
  final String retryLabel;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return _AppStateLayout(
      indicator: Icon(
        Icons.error_outline_rounded,
        size: 56,
        color: Theme.of(context).colorScheme.error,
      ),
      title: title,
      message: message,
      action: onRetry == null
          ? null
          : OutlinedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: Text(retryLabel),
            ),
    );
  }
}

class _AppStateLayout extends StatelessWidget {
  const _AppStateLayout({
    required this.indicator,
    this.title,
    this.message,
    this.action,
  });

  final Widget indicator;
  final String? title;
  final String? message;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      liveRegion: true,
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 360),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                indicator,
                if (title != null) ...[
                  const SizedBox(height: 20),
                  Text(
                    title!,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ],
                if (message != null) ...[
                  const SizedBox(height: 10),
                  Text(
                    message!,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
                if (action != null) ...[const SizedBox(height: 24), action!],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
