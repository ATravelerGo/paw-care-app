import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class AppBackButton extends StatelessWidget {
  const AppBackButton({
    required this.fallbackLocation,
    this.tooltip = '返回上一页',
    super.key,
  });

  final String fallbackLocation;
  final String tooltip;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      key: const Key('app_back_button'),
      tooltip: tooltip,
      onPressed: () {
        if (context.canPop()) {
          context.pop();
        } else {
          context.go(fallbackLocation);
        }
      },
      icon: const Icon(Icons.arrow_back_rounded),
    );
  }
}
