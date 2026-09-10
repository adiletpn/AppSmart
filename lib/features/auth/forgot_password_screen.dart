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
  bool _loading = false;
  bool _sent = false;

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    final app = context.read<AppState>();
    final l = context.lRead;
    final messenger = ScaffoldMessenger.of(context);
    try {
      await app.resetPassword(_email.text);
      setState(() => _sent = true);
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
    final muted =
        Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6);

    return Scaffold(
      appBar: AppBar(
        title: Text(l.t('Құпиясөзді қалпына келтіру', 'Восстановление пароля')),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  _sent
                      ? l.t(
                          'Поштаңа сілтеме жіберілді. Ашып, жаңа құпиясөз орнат.',
                          'Ссылка отправлена на почту. Открой её и задай новый пароль.',
                        )
                      : l.t(
                          'Email-іңді жаз — жаңа құпиясөз орнатуға сілтеме жібереміз.',
                          'Укажи email — пришлём ссылку для смены пароля.',
                        ),
                  style: TextStyle(fontSize: 14, height: 1.45, color: muted),
                ),
                const SizedBox(height: 26),
                if (!_sent) ...[
                  PrimaryField(
                    controller: _email,
                    label: 'Email',
                    hint: 'student@mail.com',
                    icon: Icons.mail_outline,
                    keyboardType: TextInputType.emailAddress,
                    validator: (value) {
                      if (value == null || !value.contains('@')) {
                        return l.t(
                            'Дұрыс email жаз', 'Введите корректный email');
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 28),
                  FilledButton(
                    onPressed: _loading ? null : _submit,
                    child: _loading
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.4,
                              color: Colors.white,
                            ),
                          )
                        : Text(l.t('Сілтеме жіберу', 'Отправить ссылку')),
                  ),
                ] else ...[
                  const SizedBox(height: 8),
                  FilledButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text(l.t('Кіру бетіне оралу', 'Вернуться ко входу')),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
