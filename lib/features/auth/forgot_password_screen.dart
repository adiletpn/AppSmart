import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/l10n.dart';
import '../../data/repositories/auth_repository.dart';
import '../../state/app_state.dart';
import '../../widgets/primary_field.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    final app = context.read<AppState>();
    final l = context.lRead;
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    try {
      await app.resetPassword(_email.text, _password.text);
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            l.t('Құпиясөз жаңартылды', 'Пароль обновлён'),
          ),
        ),
      );
      navigator.pop();
    } on AuthException catch (error) {
      messenger.showSnackBar(
        SnackBar(content: Text(l.t(error.messageKz, error.messageRu))),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l;
    return Scaffold(
      appBar: AppBar(title: Text(l.t('Құпиясөзді қалпына келтіру', 'Сброс пароля'))),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  l.t(
                    'Email-іңді жазып, жаңа құпиясөз орнат.',
                    'Укажи email и задай новый пароль.',
                  ),
                  style: TextStyle(
                    fontSize: 14,
                    height: 1.4,
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withValues(alpha: 0.6),
                  ),
                ),
                const SizedBox(height: 26),
                PrimaryField(
                  controller: _email,
                  label: 'Email',
                  hint: 'student@mail.com',
                  icon: Icons.mail_outline,
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    if (value == null || !value.contains('@')) {
                      return l.t('Дұрыс email жаз', 'Введите корректный email');
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                PrimaryField(
                  controller: _password,
                  label: l.t('Жаңа құпиясөз', 'Новый пароль'),
                  hint: '••••••',
                  icon: Icons.lock_outline,
                  obscure: true,
                  validator: (value) {
                    if (value == null || value.length < 6) {
                      return l.t('Кемінде 6 таңба', 'Минимум 6 символов');
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 28),
                FilledButton(
                  onPressed: _loading ? null : _submit,
                  child: Text(l.t('Сақтау', 'Сохранить')),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
