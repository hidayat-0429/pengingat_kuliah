import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import '../models/tugas.dart';
import '../utils/constants.dart';
import '../utils/date_formatter.dart';

class TugasCard extends StatelessWidget {
  final Tugas tugas;
  final int index;
  final VoidCallback onToggle;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const TugasCard({
    super.key,
    required this.tugas,
    required this.index,
    required this.onToggle,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final badge = DateFormatter.badgeText(tugas.tenggat, tugas.selesai);
    final isUrgent = tugas.mendekati || tugas.terlambat;

    return TweenAnimationBuilder<double>(
      duration: Duration(milliseconds: 350 + (index.clamp(0, 10) * 60)),
      tween: Tween(begin: 0.0, end: 1.0),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 20 * (1 - value)),
            child: child,
          ),
        );
      },
      child: Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          child: Slidable(
            key: ValueKey(tugas.id),
            endActionPane: ActionPane(
              motion: const StretchMotion(),
              children: [
                SlidableAction(
                  onPressed: (_) => onEdit(),
                  backgroundColor: AppColors.primaryDark,
                  foregroundColor: Colors.white,
                  icon: Icons.edit_rounded,
                  label: 'Edit',
                ),
                SlidableAction(
                  onPressed: (_) => onDelete(),
                  backgroundColor: AppColors.danger,
                  foregroundColor: Colors.white,
                  icon: Icons.delete_outline_rounded,
                  label: 'Hapus',
                ),
              ],
            ),
            child: Container(
              decoration: BoxDecoration(
                gradient: tugas.selesai ? null : AppColors.cardGradient,
                color: tugas.selesai ? const Color(0xFF0D0D1A) : null,
                border: Border.all(
                  color: tugas.terlambat
                      ? AppColors.danger.withOpacity(0.35)
                      : tugas.mendekati
                          ? AppColors.warning.withOpacity(0.25)
                          : AppColors.glassBorder,
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.15),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                  if (isUrgent && !tugas.selesai)
                    BoxShadow(
                      color: (tugas.terlambat
                              ? AppColors.danger
                              : AppColors.warning)
                          .withOpacity(0.08),
                      blurRadius: 20,
                      spreadRadius: -2,
                    ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildCheckbox(),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Title + Badge
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  tugas.judulTugas,
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    color: tugas.selesai
                                        ? AppColors.textMuted
                                        : Colors.white,
                                    decoration: tugas.selesai
                                        ? TextDecoration.lineThrough
                                        : null,
                                    decorationColor: AppColors.textMuted,
                                    letterSpacing: -0.3,
                                  ),
                                ),
                              ),
                              if (badge.isNotEmpty) ...[
                                const SizedBox(width: 8),
                                _buildBadge(badge),
                              ],
                            ],
                          ),
                          const SizedBox(height: 10),
                          // Mata Kuliah
                          Row(
                            children: [
                              Icon(
                                Icons.book_outlined,
                                size: 14,
                                color: AppColors.primary.withOpacity(0.6),
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  tugas.mataKuliah,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: AppColors.textSecondary,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          // Deadline
                          Row(
                            children: [
                              Icon(
                                Icons.schedule_rounded,
                                size: 14,
                                color: _deadlineColor,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                DateFormatter.format(tugas.tenggat),
                                style: TextStyle(
                                  fontSize: 12,
                                  color: _deadlineColor,
                                  fontWeight:
                                      isUrgent ? FontWeight.w600 : null,
                                ),
                              ),
                              if (!tugas.selesai) ...[
                                Text(
                                  '  ·  ',
                                  style: TextStyle(color: AppColors.textMuted),
                                ),
                                Text(
                                  DateFormatter.relative(tugas.tenggat),
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: _deadlineColor,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
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

  Color get _deadlineColor {
    if (tugas.selesai) return AppColors.textMuted;
    if (tugas.terlambat) return AppColors.danger;
    if (tugas.mendekati) return AppColors.warning;
    return AppColors.textMuted;
  }

  Widget _buildCheckbox() {
    return GestureDetector(
      onTap: onToggle,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 26,
        height: 26,
        margin: const EdgeInsets.only(top: 2),
        decoration: BoxDecoration(
          gradient: tugas.selesai ? AppColors.primaryGradient : null,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: tugas.selesai ? Colors.transparent : AppColors.textMuted,
            width: 2,
          ),
        ),
        child: tugas.selesai
            ? const Icon(Icons.check_rounded, color: Colors.white, size: 18)
            : null,
      ),
    );
  }

  Widget _buildBadge(String text) {
    final isTerlambat = text == 'Terlambat';
    final color = isTerlambat ? AppColors.danger : AppColors.warning;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.25), width: 1),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
}
