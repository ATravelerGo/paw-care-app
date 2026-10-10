import 'package:flutter/material.dart';

import '../shared/widgets/app_state_view.dart';

class StartupPage extends StatelessWidget {
  const StartupPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: SafeArea(child: AppLoadingView(message: '正在准备 PawCare…')),
    );
  }
}
