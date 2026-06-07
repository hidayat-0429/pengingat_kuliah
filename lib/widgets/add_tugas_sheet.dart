import 'package:flutter/material.dart';
import '../models/tugas.dart';
import '../utils/constants.dart';
import 'gradient_button.dart';

class AddTugasSheet extends StatefulWidget {
  final Tugas? tugasToEdit;

  const AddTugasSheet({super.key, this.tugasToEdit});

  @override
  State<AddTugasSheet> createState() => _AddTugasSheetState();
}

class _AddTugasSheetState extends State<AddTugasSheet> {
  late final TextEditingController _matkulCtrl;
  late final TextEditingController _judulCtrl;
  DateTime? _tanggal;
  TimeOfDay? _jam;

  bool get _isEdit => widget.tugasToEdit != null;

  @override
  void initState() {
    super.initState();
    _matkulCtrl =
        TextEditingController(text: widget.tugasToEdit?.mataKuliah ?? '');
    _judulCtrl =
        TextEditingController(text: widget.tugasToEdit?.judulTugas ?? '');
    if (widget.tugasToEdit != null) {
      _tanggal = widget.tugasToEdit!.tenggat;
      _jam = TimeOfDay(
        hour: widget.tugasToEdit!.tenggat.hour,
        minute: widget.tugasToEdit!.tenggat.minute,
      );
    }
  }

  @override
  void dispose() {
    _matkulCtrl.dispose();
    _judulCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    if (_matkulCtrl.text.trim().isEmpty ||
        _judulCtrl.text.trim().isEmpty ||
        _tanggal == null ||
        _jam == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Semua bidang wajib diisi!'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppColors.danger,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      return;
    }
    final dt = DateTime(
      _tanggal!.year,
      _tanggal!.month,
      _tanggal!.day,
      _jam!.hour,
      _jam!.minute,
    );
    Navigator.pop(context, {
      'mataKuliah': _matkulCtrl.text.trim(),
      'judul': _judulCtrl.text.trim(),
      'tenggat': dt,
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF12122A),
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        border: Border(
          top: BorderSide(color: AppColors.glassBorder, width: 1),
          left: BorderSide(color: AppColors.glassBorder, width: 1),
          right: BorderSide(color: AppColors.glassBorder, width: 1),
        ),
      ),
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom +
              MediaQuery.of(context).padding.bottom +
              24,
          left: 24,
          right: 24,
          top: 16,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: AppColors.textMuted.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    ShaderMask(
                      shaderCallback: (bounds) =>
                          AppColors.primaryGradient.createShader(bounds),
                      child: Icon(
                        _isEdit ? Icons.edit_rounded : Icons.add_circle_outline,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      _isEdit ? 'Edit Tugas' : 'Tugas Baru',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: AppColors.textMuted),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 24),
            _buildField(_matkulCtrl, 'Mata Kuliah', Icons.book_outlined),
            const SizedBox(height: 14),
            _buildField(
                _judulCtrl, 'Judul Tugas', Icons.edit_note_outlined),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(child: _buildDatePicker()),
                const SizedBox(width: 10),
                Expanded(child: _buildTimePicker()),
              ],
            ),
            const SizedBox(height: 24),
            GradientButton(
              text: _isEdit ? 'Simpan Perubahan' : 'Simpan Tugas',
              icon: _isEdit ? Icons.check_rounded : Icons.add_rounded,
              onPressed: _submit,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildField(
      TextEditingController ctrl, String label, IconData icon) {
    return TextField(
      controller: ctrl,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: AppColors.textMuted),
        prefixIcon: Icon(icon, color: AppColors.textMuted),
        filled: true,
        fillColor: AppColors.bgTertiary,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.glassBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide:
              const BorderSide(color: AppColors.primary, width: 1.5),
        ),
      ),
    );
  }

  Widget _buildDatePicker() {
    return OutlinedButton.icon(
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 14),
        side: const BorderSide(color: AppColors.glassBorder),
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      icon: const Icon(Icons.calendar_month_outlined,
          size: 18, color: AppColors.primary),
      label: Text(
        _tanggal == null
            ? 'Tanggal'
            : '${_tanggal!.day}/${_tanggal!.month}/${_tanggal!.year}',
        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
      ),
      onPressed: () async {
        final res = await showDatePicker(
          context: context,
          initialDate: _tanggal ?? DateTime.now(),
          firstDate: DateTime.now().subtract(const Duration(days: 1)),
          lastDate: DateTime(2030),
          builder: (context, child) => Theme(
            data: ThemeData.dark().copyWith(
              colorScheme: const ColorScheme.dark(
                primary: AppColors.primary,
                surface: AppColors.bgTertiary,
              ),
            ),
            child: child!,
          ),
        );
        if (res != null) setState(() => _tanggal = res);
      },
    );
  }

  Widget _buildTimePicker() {
    return OutlinedButton.icon(
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 14),
        side: const BorderSide(color: AppColors.glassBorder),
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      icon: const Icon(Icons.access_time_outlined,
          size: 18, color: AppColors.primary),
      label: Text(
        _jam == null ? 'Jam' : _jam!.format(context),
        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
      ),
      onPressed: () async {
        final res = await showTimePicker(
          context: context,
          initialTime: _jam ?? TimeOfDay.now(),
          builder: (context, child) => Theme(
            data: ThemeData.dark().copyWith(
              colorScheme: const ColorScheme.dark(
                primary: AppColors.primary,
                surface: AppColors.bgTertiary,
              ),
            ),
            child: child!,
          ),
        );
        if (res != null) setState(() => _jam = res);
      },
    );
  }
}
