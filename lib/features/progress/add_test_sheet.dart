import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/l10n.dart';
import '../../data/ai/topic_catalog.dart';
import '../../state/app_state.dart';
import '../../widgets/primary_field.dart';
import '../../widgets/section_header.dart';

class AddTestSheet extends StatefulWidget {
  const AddTestSheet({super.key});

  @override
  State<AddTestSheet> createState() => _AddTestSheetState();
}

class _AddTestSheetState extends State<AddTestSheet> {
  final _score = TextEditingController();
  final _total = TextEditingController(text: '10');
  String? _topic;

  @override
  void dispose() {
    _score.dispose();
    _total.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final score = int.tryParse(_score.text) ?? 0;
    final total = int.tryParse(_total.text) ?? 0;
    if (_topic == null || total <= 0) return;
    await context.read<AppState>().addTestResult(_topic!, score, total);
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l;
    final topics = TopicCatalog.all.map((t) => t.name(l.isKz)).toList();

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SectionHeader(
              title: l.t('Тест нәтижесі', 'Результат теста'),
              subtitle: l.t('AI әлсіз тақырыпты осыдан анықтайды',
                  'По ним AI определяет слабые темы'),
            ),
            DropdownButtonFormField<String>(
              initialValue: _topic,
              isExpanded: true,
              decoration: InputDecoration(
                hintText: l.t('Тақырып', 'Тема'),
                prefixIcon: const Icon(Icons.topic_outlined, size: 20),
              ),
              items: topics
                  .map((topic) =>
                      DropdownMenuItem(value: topic, child: Text(topic)))
                  .toList(),
              onChanged: (value) => setState(() => _topic = value),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: PrimaryField(
                    controller: _score,
                    hint: l.t('Дұрыс жауап', 'Верных'),
                    icon: Icons.check_circle_outline,
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: PrimaryField(
                    controller: _total,
                    hint: l.t('Барлығы', 'Всего'),
                    icon: Icons.list_alt,
                    keyboardType: TextInputType.number,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 22),
            FilledButton(
              onPressed: _save,
              child: Text(l.t('Сақтау', 'Сохранить')),
            ),
          ],
        ),
      ),
    );
  }
}
