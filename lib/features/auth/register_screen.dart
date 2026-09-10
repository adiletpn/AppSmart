import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/l10n.dart';
import '../../data/repositories/auth_repository.dart';
import '../../state/app_state.dart';
import '../../widgets/lang_switch.dart';
import '../../widgets/primary_field.dart';
import '../profile_setup/profile_setup_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  bool _obscure = true;
  bool _loading = false;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    final app = context.read<AppState>();
    final l = context.lRead;
    try {
      await app.register(_name.text, _email.text, _password.text);
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const ProfileSetupScreen()),
        (route) => false,
      );
    } on AuthException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
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
      appBar: AppBar(
        title: Text(l.t('Тіркелу', 'Регистрация')),
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 16),
            child: Center(child: LangSwitch(compact: true)),
          ),
        ],
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
                  l.t(
                    'Аккаунт ашып, жеке дайындықты баста',
                    'Создай аккаунт и начни личную подготовку',
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
                  controller: _name,
                  label: l.t('Аты-жөні', 'Имя и фамилия'),
                  hint: l.t('Мұхтар Сұлтан', 'Мухтар Султан'),
                  icon: Icons.person_outline,
                  validator: (value) {
                    if (value == null || value.trim().length < 2) {
                      return l.t('Атыңды жаз', 'Укажи имя');
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
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
                  label: l.t('Құпиясөз', 'Пароль'),
                  hint: '••••••',
                  icon: Icons.lock_outline,
                  obscure: _obscure,
                  suffix: IconButton(
                    onPressed: () => setState(() => _obscure = !_obscure),
                    icon: Icon(
                      _obscure ? Icons.visibility_off : Icons.visibility,
                      size: 20,
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.length < 6) {
                      return l.t('Кемінде 6 таңба', 'Минимум 6 символов');
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                PrimaryField(
                  controller: _confirm,
                  label: l.t('Құпиясөзді қайтала', 'Повтори пароль'),
                  hint: '••••••',
                  icon: Icons.lock_reset,
                  obscure: _obscure,
                  validator: (value) {
                    if (value != _password.text) {
                      return l.t('Құпиясөздер сәйкес емес', 'Пароли не совпадают');
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
                      : Text(l.t('Тіркелу', 'Зарегистрироваться')),
                ),
                const SizedBox(height: 14),
                OutlinedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(l.t('Кіру бетіне оралу', 'Вернуться ко входу')),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
