import 'package:flutter/material.dart';

import '../auth/auth_session.dart';
import '../services/auth_api_client.dart';
import '../theme/app_theme.dart';
import '../widgets/app_logo_icon.dart';
import '../widgets/responsive_page.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _client = const AuthApiClient();
  bool _loading = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.x8),
            child: ResponsivePage(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Column(
                      children: [
                        const AppLogoLockup(width: 190),
                        const SizedBox(height: AppSpacing.x2),
                        Text(
                          '자격증 준비를 한곳에서',
                          style: textTheme.bodyMedium?.copyWith(
                            color: AppColors.onSurfaceVariant,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.x8),
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.x6),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceLowest,
                      borderRadius: BorderRadius.circular(AppRadius.lg),
                      boxShadow: AppShadows.soft,
                    ),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '로그인',
                            style: textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.x5),
                          const _FieldLabel('이메일'),
                          const SizedBox(height: AppSpacing.x2),
                          TextFormField(
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            autofillHints: const [AutofillHints.email],
                            decoration: const InputDecoration(
                              hintText: 'email@example.com',
                              prefixIcon: Icon(Icons.mail_outline_rounded),
                            ),
                            validator: _validateEmail,
                          ),
                          const SizedBox(height: AppSpacing.x4),
                          const _FieldLabel('비밀번호'),
                          const SizedBox(height: AppSpacing.x2),
                          TextFormField(
                            controller: _passwordController,
                            obscureText: _obscurePassword,
                            autofillHints: const [AutofillHints.password],
                            decoration: InputDecoration(
                              hintText: '8자 이상 입력',
                              prefixIcon:
                                  const Icon(Icons.lock_outline_rounded),
                              suffixIcon: IconButton(
                                tooltip:
                                    _obscurePassword ? '비밀번호 보기' : '비밀번호 숨기기',
                                onPressed: () => setState(
                                  () => _obscurePassword = !_obscurePassword,
                                ),
                                icon: Icon(
                                  _obscurePassword
                                      ? Icons.visibility_off_rounded
                                      : Icons.visibility_rounded,
                                ),
                              ),
                            ),
                            validator: _validatePassword,
                            onFieldSubmitted: (_) => _submit(),
                          ),
                          const SizedBox(height: AppSpacing.x3),
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton(
                              onPressed: _loading ? null : _openPasswordReset,
                              child: const Text('비밀번호 찾기'),
                            ),
                          ),
                          const SizedBox(height: AppSpacing.x2),
                          FilledButton(
                            onPressed: _loading ? null : _submit,
                            child: _loading
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.4,
                                    ),
                                  )
                                : const Text('로그인'),
                          ),
                          const SizedBox(height: AppSpacing.x4),
                          Center(
                            child: TextButton(
                              onPressed: _loading ? null : _openRegister,
                              child: const Text('계정이 없나요? 회원가입'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    setState(() => _loading = true);
    try {
      final user = await _client.login(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );
      if (!mounted) {
        return;
      }
      AuthScope.of(context).signIn(user);
    } catch (error) {
      if (mounted) {
        _showMessage(error.toString().replaceFirst('Exception: ', ''));
      }
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _openRegister() async {
    final user = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const RegisterScreen(),
      ),
    );
    if (mounted && user != null) {
      AuthScope.of(context).signIn(user);
    }
  }

  void _openPasswordReset() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => const PasswordResetScreen(),
      ),
    );
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }
}

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _nameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _client = const AuthApiClient();
  bool _loading = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _nameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('회원가입')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.x6),
          child: ResponsivePage(
            child: Container(
              padding: const EdgeInsets.all(AppSpacing.x6),
              decoration: BoxDecoration(
                color: AppColors.surfaceLowest,
                borderRadius: BorderRadius.circular(AppRadius.lg),
                boxShadow: AppShadows.soft,
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '스펙모아.zip 시작하기',
                      style: textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.x5),
                    const _FieldLabel('닉네임'),
                    const SizedBox(height: AppSpacing.x2),
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        hintText: '예: 정처기마스터',
                        prefixIcon: Icon(Icons.person_outline_rounded),
                      ),
                      validator: (value) {
                        final text = value?.trim() ?? '';
                        if (text.length < 2) {
                          return '닉네임은 2자 이상 입력해주세요.';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: AppSpacing.x4),
                    const _FieldLabel('이메일'),
                    const SizedBox(height: AppSpacing.x2),
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(
                        hintText: 'email@example.com',
                        prefixIcon: Icon(Icons.mail_outline_rounded),
                      ),
                      validator: _validateEmail,
                    ),
                    const SizedBox(height: AppSpacing.x4),
                    const _FieldLabel('비밀번호'),
                    const SizedBox(height: AppSpacing.x2),
                    TextFormField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      decoration: InputDecoration(
                        hintText: '8자 이상 입력',
                        prefixIcon: const Icon(Icons.lock_outline_rounded),
                        suffixIcon: IconButton(
                          tooltip: _obscurePassword ? '비밀번호 보기' : '비밀번호 숨기기',
                          onPressed: () => setState(
                            () => _obscurePassword = !_obscurePassword,
                          ),
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility_off_rounded
                                : Icons.visibility_rounded,
                          ),
                        ),
                      ),
                      validator: _validatePassword,
                    ),
                    const SizedBox(height: AppSpacing.x6),
                    FilledButton(
                      onPressed: _loading ? null : _submit,
                      child: _loading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child:
                                  CircularProgressIndicator(strokeWidth: 2.4),
                            )
                          : const Text('회원가입'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    setState(() => _loading = true);
    try {
      final user = await _client.register(
        email: _emailController.text.trim(),
        displayName: _nameController.text.trim(),
        password: _passwordController.text,
      );
      if (mounted) {
        Navigator.of(context).pop(user);
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(error.toString().replaceFirst('Exception: ', ''))),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }
}

class PasswordResetScreen extends StatefulWidget {
  const PasswordResetScreen({super.key});

  @override
  State<PasswordResetScreen> createState() => _PasswordResetScreenState();
}

class _PasswordResetScreenState extends State<PasswordResetScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _client = const AuthApiClient();
  bool _loading = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('비밀번호 찾기')),
      body: SafeArea(
        child: ResponsivePage(
          child: Container(
            margin: const EdgeInsets.only(top: AppSpacing.x6),
            padding: const EdgeInsets.all(AppSpacing.x6),
            decoration: BoxDecoration(
              color: AppColors.surfaceLowest,
              borderRadius: BorderRadius.circular(AppRadius.lg),
              boxShadow: AppShadows.soft,
            ),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '가입한 이메일을 입력해주세요',
                    style: textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.x2),
                  Text(
                    '재설정 안내를 받을 수 있도록 요청을 접수합니다.',
                    style: textTheme.bodyMedium?.copyWith(
                      color: AppColors.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.x5),
                  const _FieldLabel('이메일'),
                  const SizedBox(height: AppSpacing.x2),
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      hintText: 'email@example.com',
                      prefixIcon: Icon(Icons.mail_outline_rounded),
                    ),
                    validator: _validateEmail,
                  ),
                  const SizedBox(height: AppSpacing.x6),
                  FilledButton(
                    onPressed: _loading ? null : _submit,
                    child: _loading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2.4),
                          )
                        : const Text('재설정 요청'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    setState(() => _loading = true);
    try {
      final message = await _client.requestPasswordReset(
        email: _emailController.text.trim(),
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message)),
        );
        Navigator.of(context).pop();
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(error.toString().replaceFirst('Exception: ', ''))),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: Theme.of(context).textTheme.labelMedium?.copyWith(
            color: AppColors.onSurfaceVariant,
            fontWeight: FontWeight.w800,
          ),
    );
  }
}

String? _validateEmail(String? value) {
  final text = value?.trim() ?? '';
  if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(text)) {
    return '올바른 이메일을 입력해주세요.';
  }
  return null;
}

String? _validatePassword(String? value) {
  if ((value ?? '').length < 8) {
    return '비밀번호는 8자 이상 입력해주세요.';
  }
  return null;
}
