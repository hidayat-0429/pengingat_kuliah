import 'package:flutter/material.dart';
import '../models/tugas.dart';
import '../services/auth_service.dart';
import '../services/notification_service.dart';
import '../services/tugas_service.dart';
import '../utils/constants.dart';
import '../widgets/add_tugas_sheet.dart';
import '../widgets/empty_state.dart';
import '../widgets/tugas_card.dart';
import 'profile_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Tugas> _daftarTugas = [];
  bool _isLoading = true;
  String _namaUser = '';
  String _filter = 'Semua';

  @override
  void initState() {
    super.initState();
    _initData();
  }

  Future<void> _initData() async {
    setState(() => _isLoading = true);
    try {
      final name = await AuthService.getNamaUser();
      if (mounted) setState(() => _namaUser = name);

      await _fetchTugas();
      await NotificationService.initFCM();
    } catch (e) {
      _showError('Gagal memuat data');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _fetchTugas() async {
    try {
      final data = await TugasService.fetchAll();
      if (mounted) {
        setState(() {
          _daftarTugas = data;
        });
      }
    } catch (e) {
      throw Exception('Gagal mengambil tugas');
    }
  }

  List<Tugas> get _filteredTugas {
    if (_filter == 'Aktif') return _daftarTugas.where((t) => !t.selesai && !t.terlambat).toList();
    if (_filter == 'Selesai') return _daftarTugas.where((t) => t.selesai).toList();
    if (_filter == 'Terlambat') return _daftarTugas.where((t) => t.terlambat).toList();
    return _daftarTugas; // 'Semua'
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.danger,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showAddSheet([Tugas? tugas]) async {
    final result = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AddTugasSheet(tugasToEdit: tugas),
    );

    if (result != null) {
      setState(() => _isLoading = true);
      try {
        if (tugas == null) {
          await TugasService.add(
            mataKuliah: result['mataKuliah'],
            judul: result['judul'],
            tenggat: result['tenggat'],
          );
        } else {
          await TugasService.update(
            tugas.id,
            mataKuliah: result['mataKuliah'],
            judul: result['judul'],
            tenggat: result['tenggat'],
          );
        }
        await _fetchTugas();
        // Jadwalkan notif untuk data baru
        if (tugas == null) {
          final newTugas = _daftarTugas.firstWhere((t) =>
              t.judulTugas == result['judul'] &&
              t.mataKuliah == result['mataKuliah']);
          await NotificationService.scheduleForTugas(newTugas);
        }
      } catch (e) {
        _showError('Gagal menyimpan tugas');
      } finally {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _deleteTugas(Tugas tugas) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.bgSecondary,
        title: const Text('Hapus Tugas?', style: TextStyle(color: Colors.white)),
        content: const Text('Tugas yang dihapus tidak dapat dikembalikan.',
            style: TextStyle(color: AppColors.textSecondary)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal', style: TextStyle(color: AppColors.textSecondary)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Hapus', style: TextStyle(color: AppColors.danger)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      setState(() => _isLoading = true);
      try {
        await TugasService.delete(tugas.id);
        await _fetchTugas();
      } catch (e) {
        _showError('Gagal menghapus tugas');
      } finally {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _toggleTugas(Tugas tugas) async {
    final oldState = tugas.selesai;
    try {
      setState(() {
        final index = _daftarTugas.indexWhere((t) => t.id == tugas.id);
        if (index != -1) {
          _daftarTugas[index] = _daftarTugas[index].copyWith(selesai: !oldState);
        }
      });
      await TugasService.toggleSelesai(tugas.id, !oldState);
      
      if (!oldState) {
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Tugas ditandai selesai!'),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
            action: SnackBarAction(
              label: 'BATAL',
              textColor: Colors.white,
              onPressed: () async {
                setState(() {
                  final index = _daftarTugas.indexWhere((t) => t.id == tugas.id);
                  if (index != -1) {
                    _daftarTugas[index] = _daftarTugas[index].copyWith(selesai: oldState);
                  }
                });
                await TugasService.toggleSelesai(tugas.id, oldState);
              },
            ),
          ),
        );
      }
    } catch (e) {
      _showError('Gagal mengubah status tugas');
      await _fetchTugas(); // Revert
    }
  }

  @override
  Widget build(BuildContext context) {
    final aktifCount = _daftarTugas.where((t) => !t.selesai && !t.terlambat).length;
    final selesaiCount = _daftarTugas.where((t) => t.selesai).length;
    final telatCount = _daftarTugas.where((t) => t.terlambat).length;

    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppColors.backgroundGradient,
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Halo, ${_namaUser.isEmpty ? 'Memuat...' : _namaUser} 👋',
                          style: const TextStyle(
                            fontSize: 14,
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Pengingat Tugas',
                          style: TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            letterSpacing: -0.6,
                          ),
                        ),
                      ],
                    ),
                    GestureDetector(
                      onTap: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const ProfileScreen()),
                        );
                        _initData(); // Refresh nama user & tugas jika berubah
                      },
                      child: Hero(
                        tag: 'profile_avatar',
                        child: Container(
                          padding: const EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: AppColors.primaryGradient,
                          ),
                          child: CircleAvatar(
                            radius: 22,
                            backgroundColor: AppColors.bgSecondary,
                            child: const Icon(
                              Icons.person_rounded,
                              color: Colors.white,
                              size: 24,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Stats
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                child: Row(
                  children: [
                    _buildStatItem('Aktif', aktifCount, AppColors.primary),
                    const SizedBox(width: 12),
                    _buildStatItem('Selesai', selesaiCount, AppColors.success),
                    const SizedBox(width: 12),
                    _buildStatItem('Terlambat', telatCount, AppColors.danger),
                  ],
                ),
              ),

              // Filter Chips
              SizedBox(
                height: 40,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  children: ['Semua', 'Aktif', 'Selesai', 'Terlambat']
                      .map((f) => Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            child: ChoiceChip(
                              label: Text(f),
                              selected: _filter == f,
                              onSelected: (val) {
                                if (val) setState(() => _filter = f);
                              },
                              backgroundColor: AppColors.bgSecondary,
                              selectedColor: AppColors.primary.withOpacity(0.2),
                              labelStyle: TextStyle(
                                color: _filter == f
                                    ? AppColors.primary
                                    : AppColors.textSecondary,
                                fontWeight: _filter == f
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                              ),
                              side: BorderSide(
                                color: _filter == f
                                    ? AppColors.primary
                                    : AppColors.glassBorder,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                            ),
                          ))
                      .toList(),
                ),
              ),
              const SizedBox(height: 10),

              // List
              Expanded(
                child: _isLoading
                    ? const Center(
                        child: CircularProgressIndicator(color: AppColors.primary))
                    : RefreshIndicator(
                        onRefresh: _fetchTugas,
                        color: AppColors.primary,
                        backgroundColor: AppColors.bgSecondary,
                        child: _filteredTugas.isEmpty
                            ? ListView(
                                children: [
                                  SizedBox(
                                    height: MediaQuery.of(context).size.height * 0.5,
                                    child: EmptyState(
                                        filterLabel:
                                            _filter == 'Semua' ? null : _filter),
                                  ),
                                ],
                              )
                            : ListView.builder(
                                padding: const EdgeInsets.fromLTRB(20, 10, 20, 80),
                                itemCount: _filteredTugas.length,
                                itemBuilder: (context, index) {
                                  final item = _filteredTugas[index];
                                  return TugasCard(
                                    tugas: item,
                                    index: index,
                                    onToggle: () => _toggleTugas(item),
                                    onEdit: () => _showAddSheet(item),
                                    onDelete: () => _deleteTugas(item),
                                  );
                                },
                              ),
                      ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withOpacity(0.3),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: FloatingActionButton.extended(
          backgroundColor: AppColors.primaryDark,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          icon: const Icon(Icons.add_rounded, size: 24),
          label: const Text(
            'Tugas Baru',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          onPressed: () => _showAddSheet(),
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, int count, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.2), width: 1),
        ),
        child: Column(
          children: [
            Text(
              count.toString(),
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: color.withOpacity(0.8),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
