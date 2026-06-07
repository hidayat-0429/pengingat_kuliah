class Tugas {
  final int id;
  final String mataKuliah;
  final String judulTugas;
  final DateTime tenggat;
  final bool selesai;
  final String userId;

  const Tugas({
    required this.id,
    required this.mataKuliah,
    required this.judulTugas,
    required this.tenggat,
    this.selesai = false,
    required this.userId,
  });

  factory Tugas.fromJson(Map<String, dynamic> json) {
    return Tugas(
      id: json['id'] as int,
      mataKuliah: (json['mata_kuliah'] as String?) ?? '',
      judulTugas: (json['judul'] as String?) ?? '',
      tenggat: DateTime.parse(json['tenggat'] as String),
      selesai: (json['selesai'] as bool?) ?? false,
      userId: (json['user_id'] as String?) ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'mata_kuliah': mataKuliah,
      'judul': judulTugas,
      'tenggat': tenggat.toIso8601String(),
      'selesai': selesai,
      'user_id': userId,
    };
  }

  Tugas copyWith({
    int? id,
    String? mataKuliah,
    String? judulTugas,
    DateTime? tenggat,
    bool? selesai,
    String? userId,
  }) {
    return Tugas(
      id: id ?? this.id,
      mataKuliah: mataKuliah ?? this.mataKuliah,
      judulTugas: judulTugas ?? this.judulTugas,
      tenggat: tenggat ?? this.tenggat,
      selesai: selesai ?? this.selesai,
      userId: userId ?? this.userId,
    );
  }

  /// Apakah tugas ini sudah melewati deadline?
  bool get terlambat => !selesai && tenggat.isBefore(DateTime.now());

  /// Apakah deadline tinggal <= 24 jam?
  bool get mendekati {
    if (selesai) return false;
    final sisa = tenggat.difference(DateTime.now()).inHours;
    return sisa >= 0 && sisa <= 24;
  }
}
