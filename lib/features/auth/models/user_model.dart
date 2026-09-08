class UserModel {
  final int? id;
  final String nama;
  final String email;
  final String noHp;
  final String password;
  final String asalKota;
  final String? fotoProfil;
  final String? rolePetualang;
  final String? bio;
  final String? golonganDarah;
  final String? kontakDaruratNama;
  final String? kontakDaruratHp;
  final String? organisasi;
  final int? totalEkspedisi;
  final String? jarakJelajah;
  final String? jamTerbang;

  UserModel({
    this.id,
    required this.nama,
    required this.email,
    required this.noHp,
    required this.password,
    required this.asalKota,
    this.fotoProfil,
    this.rolePetualang,
    this.bio,
    this.golonganDarah,
    this.kontakDaruratNama,
    this.kontakDaruratHp,
    this.organisasi,
    this.totalEkspedisi,
    this.jarakJelajah,
    this.jamTerbang,
  });

  // Konversi Objek ke Map (untuk disimpan ke SQFLite)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nama': nama,
      'email': email,
      'noHp': noHp,
      'password': password,
      'asalKota': asalKota,
      'fotoProfil': fotoProfil,
      'rolePetualang': rolePetualang,
      'bio': bio,
      'golonganDarah': golonganDarah,
      'kontakDaruratNama': kontakDaruratNama,
      'kontakDaruratHp': kontakDaruratHp,
      'organisasi': organisasi,
      'totalEkspedisi': totalEkspedisi,
      'jarakJelajah': jarakJelajah,
      'jamTerbang': jamTerbang,
    };
  }

  // Konversi Map database ke Objek UserModel
  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      id: map['id'] as int?,
      nama: map['nama'] ?? '',
      email: map['email'] ?? '',
      noHp: map['noHp'] ?? '',
      password: map['password'] ?? '',
      asalKota: map['asalKota'] ?? '',
      fotoProfil: map['fotoProfil'] as String?,
      rolePetualang: map['rolePetualang'] as String?,
      bio: map['bio'] as String?,
      golonganDarah: map['golonganDarah'] as String?,
      kontakDaruratNama: map['kontakDaruratNama'] as String?,
      kontakDaruratHp: map['kontakDaruratHp'] as String?,
      organisasi: map['organisasi'] as String?,
      totalEkspedisi: map['totalEkspedisi'] as int? ?? 0,
      jarakJelajah: map['jarakJelajah'] as String? ?? '0 km',
      jamTerbang: map['jamTerbang'] as String? ?? '0 Jam',
    );
  }

  UserModel copyWith({
    int? id,
    String? nama,
    String? email,
    String? noHp,
    String? password,
    String? asalKota,
    String? fotoProfil,
    String? rolePetualang,
    String? bio,
    String? golonganDarah,
    String? kontakDaruratNama,
    String? kontakDaruratHp,
    String? organisasi,
    int? totalEkspedisi,
    String? jarakJelajah,
    String? jamTerbang,
  }) {
    return UserModel(
      id: id ?? this.id,
      nama: nama ?? this.nama,
      email: email ?? this.email,
      noHp: noHp ?? this.noHp,
      password: password ?? this.password,
      asalKota: asalKota ?? this.asalKota,
      fotoProfil: fotoProfil ?? this.fotoProfil,
      rolePetualang: rolePetualang ?? this.rolePetualang,
      bio: bio ?? this.bio,
      golonganDarah: golonganDarah ?? this.golonganDarah,
      kontakDaruratNama: kontakDaruratNama ?? this.kontakDaruratNama,
      kontakDaruratHp: kontakDaruratHp ?? this.kontakDaruratHp,
      organisasi: organisasi ?? this.organisasi,
      totalEkspedisi: totalEkspedisi ?? this.totalEkspedisi,
      jarakJelajah: jarakJelajah ?? this.jarakJelajah,
      jamTerbang: jamTerbang ?? this.jamTerbang,
    );
  }
}
