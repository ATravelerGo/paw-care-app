import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/route_paths.dart';
import '../../application/auth_providers.dart';
import '../../application/auth_session_controller.dart';
import '../auth_form_validators.dart';
import '../widgets/auth_form_card.dart';

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit(AuthSessionController authSession) async {
    if (authSession.isAuthenticating) return;

    FocusManager.instance.primaryFocus?.unfocus();
    if (!(_formKey.currentState?.validate() ?? false)) return;

    try {
      await authSession.login(
        email: _emailController.text.trim().toLowerCase(),
        password: _passwordController.text,
      );
    } on Object {
      // The controller exposes a user-facing error for this request.
    }
  }

  void _openRegister(AuthSessionController authSession) {
    authSession.clearAuthenticationError();
    context.go(AppRoutePaths.register);
  }

  @override
  Widget build(BuildContext context) {
    final authSession = ref.read(authSessionProvider);

    return Scaffold(
      body: SafeArea(
        child: AuthFormCard(
          title: '登录',
          subtitle: '欢迎回来，继续照顾你的毛孩子',
          child: ListenableBuilder(
            listenable: authSession,
            builder: (context, _) {
              final error =
                  authSession.authenticationError ?? authSession.restoreError;

              return AutofillGroup(
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (error != null) ...[
                        AuthErrorBanner(error: error),
                        const SizedBox(height: 16),
                      ],
                      TextFormField(
                        key: const Key('login_email_field'),
                        controller: _emailController,
                        enabled: !authSession.isAuthenticating,
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.next,
                        autofillHints: const [AutofillHints.email],
                        autocorrect: false,
                        validator: AuthFormValidators.email,
                        decoration: const InputDecoration(
                          labelText: '邮箱',
                          hintText: 'name@example.com',
                          prefixIcon: Icon(Icons.mail_outline_rounded),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        key: const Key('login_password_field'),
                        controller: _passwordController,
                        enabled: !authSession.isAuthenticating,
                        obscureText: _obscurePassword,
                        textInputAction: TextInputAction.done,
                        autofillHints: const [AutofillHints.password],
                        validator: AuthFormValidators.password,
                        onFieldSubmitted: (_) => _submit(authSession),
                        decoration: InputDecoration(
                          labelText: '密码',
                          prefixIcon: const Icon(Icons.lock_outline_rounded),
                          suffixIcon: IconButton(
                            tooltip: _obscurePassword ? '显示密码' : '隐藏密码',
                            onPressed: authSession.isAuthenticating
                                ? null
                                : () => setState(
                                    () => _obscurePassword = !_obscurePassword,
                                  ),
                            icon: Icon(
                              _obscurePassword
                                  ? Icons.visibility_outlined
                                  : Icons.visibility_off_outlined,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      FilledButton(
                        key: const Key('login_submit_button'),
                        onPressed: authSession.isAuthenticating
                            ? null
                            : () => _submit(authSession),
                        child: AuthSubmitButtonContent(
                          isLoading: authSession.isAuthenticating,
                          label: '登录',
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextButton(
                        key: const Key('open_register_button'),
                        onPressed: authSession.isAuthenticating
                            ? null
                            : () => _openRegister(authSession),
                        child: const Text('还没有账号？创建账号'),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
