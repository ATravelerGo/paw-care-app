import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/route_paths.dart';
import '../../application/auth_providers.dart';
import '../../application/auth_session_controller.dart';
import '../auth_form_validators.dart';
import '../widgets/auth_form_card.dart';

class RegisterPage extends ConsumerStatefulWidget {
  const RegisterPage({super.key});

  @override
  ConsumerState<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends ConsumerState<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _nicknameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirmation = true;

  @override
  void dispose() {
    _nicknameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _submit(AuthSessionController authSession) async {
    if (authSession.isAuthenticating) return;

    FocusManager.instance.primaryFocus?.unfocus();
    if (!(_formKey.currentState?.validate() ?? false)) return;

    try {
      await authSession.register(
        email: _emailController.text.trim().toLowerCase(),
        password: _passwordController.text,
        nickname: _nicknameController.text.trim(),
      );
    } on Object {
      // The controller exposes a user-facing error for this request.
    }
  }

  void _openLogin(AuthSessionController authSession) {
    authSession.clearAuthenticationError();
    context.go(AppRoutePaths.login);
  }

  @override
  Widget build(BuildContext context) {
    final authSession = ref.read(authSessionProvider);

    return ListenableBuilder(
      listenable: authSession,
      builder: (context, _) {
        final error = authSession.authenticationError;

        return Scaffold(
          appBar: AppBar(
            leading: IconButton(
              tooltip: '返回登录',
              onPressed: authSession.isAuthenticating
                  ? null
                  : () => _openLogin(authSession),
              icon: const Icon(Icons.arrow_back_rounded),
            ),
          ),
          body: SafeArea(
            child: AuthFormCard(
              title: '创建账号',
              subtitle: '从今天开始记录宠物的健康生活',
              child: AutofillGroup(
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
                        key: const Key('register_nickname_field'),
                        controller: _nicknameController,
                        enabled: !authSession.isAuthenticating,
                        textInputAction: TextInputAction.next,
                        autofillHints: const [AutofillHints.nickname],
                        validator: AuthFormValidators.nickname,
                        decoration: const InputDecoration(
                          labelText: '昵称',
                          prefixIcon: Icon(Icons.person_outline_rounded),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        key: const Key('register_email_field'),
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
                        key: const Key('register_password_field'),
                        controller: _passwordController,
                        enabled: !authSession.isAuthenticating,
                        obscureText: _obscurePassword,
                        textInputAction: TextInputAction.next,
                        autofillHints: const [AutofillHints.newPassword],
                        validator: AuthFormValidators.password,
                        decoration: InputDecoration(
                          labelText: '密码',
                          helperText: '至少 6 个字符',
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
                      const SizedBox(height: 16),
                      TextFormField(
                        key: const Key('register_confirm_password_field'),
                        controller: _confirmPasswordController,
                        enabled: !authSession.isAuthenticating,
                        obscureText: _obscureConfirmation,
                        textInputAction: TextInputAction.done,
                        autofillHints: const [AutofillHints.newPassword],
                        validator: (value) =>
                            AuthFormValidators.confirmPassword(
                              value,
                              _passwordController.text,
                            ),
                        onFieldSubmitted: (_) => _submit(authSession),
                        decoration: InputDecoration(
                          labelText: '确认密码',
                          prefixIcon: const Icon(Icons.lock_reset_rounded),
                          suffixIcon: IconButton(
                            tooltip: _obscureConfirmation ? '显示密码' : '隐藏密码',
                            onPressed: authSession.isAuthenticating
                                ? null
                                : () => setState(
                                    () => _obscureConfirmation =
                                        !_obscureConfirmation,
                                  ),
                            icon: Icon(
                              _obscureConfirmation
                                  ? Icons.visibility_outlined
                                  : Icons.visibility_off_outlined,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      FilledButton(
                        key: const Key('register_submit_button'),
                        onPressed: authSession.isAuthenticating
                            ? null
                            : () => _submit(authSession),
                        child: AuthSubmitButtonContent(
                          isLoading: authSession.isAuthenticating,
                          label: '创建账号',
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextButton(
                        key: const Key('open_login_button'),
                        onPressed: authSession.isAuthenticating
                            ? null
                            : () => _openLogin(authSession),
                        child: const Text('已有账号？返回登录'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
