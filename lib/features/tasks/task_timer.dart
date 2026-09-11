import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/app_colors.dart';
import '../../core/l10n.dart';
import '../../data/models/study_task.dart';
import '../../state/app_state.dart';
import '../../widgets/gradient_card.dart';

class TaskTimer extends StatefulWidget {
  const TaskTimer({super.key, required this.task});

  final StudyTask task;

  @override
  State<TaskTimer> createState() => _TaskTimerState();
}

class _TaskTimerState extends State<TaskTimer> {
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    _syncTicker();
  }

  @override
  void didUpdateWidget(TaskTimer oldWidget) {
    super.didUpdateWidget(oldWidget);
    _syncTicker();
  }

  void _syncTicker() {
    if (widget.task.isRunning && _ticker == null) {
      _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
        if (mounted) setState(() {});
      });
    } else if (!widget.task.isRunning) {
      _ticker?.cancel();
      _ticker = null;
    }
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  String _format(int seconds) {
    final hours = seconds ~/ 3600;
    final minutes = (seconds % 3600) ~/ 60;
    final secs = seconds % 60;
    final mm = minutes.toString().padLeft(2, '0');
    final ss = secs.toString().padLeft(2, '0');
    return hours > 0 ? '$hours:$mm:$ss' : '$mm:$ss';
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l;
    final app = context.read<AppState>();
    final task = widget.task;
    final elapsed = task.elapsedSeconds;
    final planned = task.durationMinutes * 60;
    final progress = planned == 0 ? 0.0 : (elapsed / planned).clamp(0.0, 1.0);
    final overtime = elapsed > planned;

    return SurfaceCard(
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l.t('Жұмсалған уақыт', 'Затрачено времени'),
                      style: TextStyle(
                        fontSize: 12.5,
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withValues(alpha: 0.55),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _format(elapsed),
                      style: TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.w800,
                        fontFeatures: const [FontFeature.tabularFigures()],
                        color: overtime ? AppColors.warning : null,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      l.t(
                        'Жоспар: ${l.duration(task.durationMinutes)}',
                        'План: ${l.duration(task.durationMinutes)}',
                      ),
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withValues(alpha: 0.5),
                      ),
                    ),
                  ],
                ),
              ),
              GestureDetector(
                onTap: () => task.isRunning
                    ? app.pauseTimer(task.id)
                    : app.startTimer(task.id),
                child: Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    gradient: task.isRunning ? null : AppColors.cardGradient,
                    color: task.isRunning
                        ? AppColors.warning.withValues(alpha: 0.16)
                        : null,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    task.isRunning ? Icons.pause : Icons.play_arrow,
                    size: 30,
                    color: task.isRunning ? AppColors.warning : Colors.white,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 7,
              backgroundColor: Theme.of(context)
                  .colorScheme
                  .onSurface
                  .withValues(alpha: 0.08),
              color: overtime ? AppColors.warning : AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }
}
