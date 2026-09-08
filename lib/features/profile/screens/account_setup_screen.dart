import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_application_1/core/theme/theme_provider.dart';
import 'package:flutter_application_1/core/database/database_helper.dart';
import 'package:flutter_application_1/features/auth/models/user_model.dart';

// =========================================================================
// HALAMAN SETUP AKUN AWAL & EDIT PROFIL PETUALANG NARA
// Sinkronisasi Data Petualang, Proteksi Data Registrasi (Email & HP), & Dark/Light Earth Tone
// =========================================================================

class SetupAkunPage extends StatefulWidget {
  final UserModel? user;
  final int? userId;
  final bool isInitialSetup;

  const SetupAkunPage({
    super.key,
    this.user,
    this.userId,
    this.isInitialSetup = false,
  });

  @override
  State<SetupAkunPage> createState() => _SetupAkunPageState();
}

class _SetupAkunPageState extends State<SetupAkunPage> {
  final _formKey = GlobalKey<FormState>();

  UserModel? _activeUser;
  bool _isLoading = true;
  bool _isSaving = false;

  // Form Controllers
  late TextEditingController _namaCtrl;
  late TextEditingController _emailCtrl;
  late TextEditingController _noHpCtrl;
  late TextEditingController _asalKotaCtrl;
  late TextEditingController _bioCtrl;
  late TextEditingController _kontakDaruratNamaCtrl;
  late TextEditingController _kontakDaruratHpCtrl;
  late TextEditingController _organisasiCtrl;

  String _selectedRole = 'Senior Caver & Speleologi';
  String _selectedGolonganDarah = 'O+';
  String? _selectedPhotoPath;

  final List<String> _roleOptions = [
    'Senior Caver & Speleologi',
    'Lead Climber & Belayer',
    'SRT (Single Rope Technique) Specialist',
    'Outdoor Explorer & Hiker',
    'Mountain Guide & Rescue Team',
    'Penggiat Alam Terbuka',
  ];

  final List<String> _golonganDarahOptions = [
    'O+',
    'O-',
    'A+',
    'A-',
    'B+',
    'B-',
    'AB+',
    'AB-',
  ];

  @override
  void initState() {
    super.initState();
    _namaCtrl = TextEditingController();
    _emailCtrl = TextEditingController();
    _noHpCtrl = TextEditingController();
    _asalKotaCtrl = TextEditingController();
    _bioCtrl = TextEditingController();
    _kontakDaruratNamaCtrl = TextEditingController();
    _kontakDaruratHpCtrl = TextEditingController();
    _organisasiCtrl = TextEditingController();

    _loadUserData();
  }

  @override
  void dispose() {
    _namaCtrl.dispose();
    _emailCtrl.dispose();
    _noHpCtrl.dispose();
    _asalKotaCtrl.dispose();
    _bioCtrl.dispose();
    _kontakDaruratNamaCtrl.dispose();
    _kontakDaruratHpCtrl.dispose();
    _organisasiCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    setState(() => _isLoading = true);

    UserModel? loadedUser = widget.user;
    if (loadedUser == null && widget.userId != null) {
      loadedUser = await DatabaseHelper.instance.getUserById(widget.userId!);
    }
    loadedUser ??= await DatabaseHelper.instance.getLatestUser();

    if (loadedUser != null) {
      _activeUser = loadedUser;
      _namaCtrl.text = loadedUser.nama;
      _emailCtrl.text = loadedUser.email;
      _noHpCtrl.text = loadedUser.noHp;
      _asalKotaCtrl.text = loadedUser.asalKota;
      _bioCtrl.text = loadedUser.bio ?? 'Penjelajah goa vertikal karst & pemanjat tebing tegar.';
      _kontakDaruratNamaCtrl.text = loadedUser.kontakDaruratNama ?? 'Basecamp / Keluarga';
      _kontakDaruratHpCtrl.text = loadedUser.kontakDaruratHp ?? '+62 812-3456-7890';
      _organisasiCtrl.text = loadedUser.organisasi ?? 'NARA Speleo Club';

      if (loadedUser.rolePetualang != null && _roleOptions.contains(loadedUser.rolePetualang)) {
        _selectedRole = loadedUser.rolePetualang!;
      }
      if (loadedUser.golonganDarah != null && _golonganDarahOptions.contains(loadedUser.golonganDarah)) {
        _selectedGolonganDarah = loadedUser.golonganDarah!;
      }
      if (loadedUser.fotoProfil != null && loadedUser.fotoProfil!.isNotEmpty) {
        _selectedPhotoPath = loadedUser.fotoProfil;
      }
    }

    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  // Memilih Foto dari Galeri atau Kamera HP
  Future<void> _pickImage(ImageSource source) async {
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (picked != null) {
        setState(() {
          _selectedPhotoPath = picked.path;
        });
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Foto berhasil dipilih dari perangkat!'),
            backgroundColor: context.themePrimary,
            duration: const Duration(milliseconds: 1200),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal memilih foto: $e'),
          backgroundColor: AppTheme.errorRed,
        ),
      );
    }
  }

  void _showImagePickerSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      backgroundColor: context.themeCard,
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.camera_alt_outlined,
                      size: 20,
                      color: context.themePrimary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Pilih Sumber Foto Profil',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: context.themeText,
                      ),
                    ),
                  ],
                ),
                IconButton(
                  icon: Icon(Icons.close_rounded, color: context.themeTextSecondary),
                  onPressed: () => Navigator.pop(ctx),
                ),
              ],
            ),
            const SizedBox(height: 14),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: context.themePrimaryFixed,
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.photo_library_rounded, color: context.themePrimary),
              ),
              title: Text(
                'Pilih dari Galeri HP',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: context.themeText,
                ),
              ),
              subtitle: Text(
                'Buka album galeri foto di perangkat',
                style: TextStyle(fontSize: 11, color: context.themeTextSecondary),
              ),
              trailing: Icon(Icons.chevron_right_rounded, color: context.themeTextSecondary),
              onTap: () {
                Navigator.pop(ctx);
                _pickImage(ImageSource.gallery);
              },
            ),
            Divider(height: 1, color: context.themeBorder),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: context.themeSurface,
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.camera_alt_rounded, color: context.themePrimary),
              ),
              title: Text(
                'Ambil Foto Kamera',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: context.themeText,
                ),
              ),
              subtitle: Text(
                'Potret foto baru secara langsung',
                style: TextStyle(fontSize: 11, color: context.themeTextSecondary),
              ),
              trailing: Icon(Icons.chevron_right_rounded, color: context.themeTextSecondary),
              onTap: () {
                Navigator.pop(ctx);
                _pickImage(ImageSource.camera);
              },
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  // Builder Gambar Avatar
  Widget _buildAvatarWidget() {
    if (_selectedPhotoPath != null && _selectedPhotoPath!.isNotEmpty) {
      if (_selectedPhotoPath!.startsWith('http://') || _selectedPhotoPath!.startsWith('https://')) {
        return Image.network(
          _selectedPhotoPath!,
          key: ValueKey(_selectedPhotoPath),
          width: 104,
          height: 104,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => Container(
            width: 104,
            height: 104,
            color: context.themeSurface,
            child: Icon(Icons.person, size: 48, color: context.themePrimary),
          ),
        );
      } else {
        final file = File(_selectedPhotoPath!);
        if (file.existsSync()) {
          return Image.file(
            file,
            key: ValueKey(_selectedPhotoPath),
            width: 104,
            height: 104,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) => Container(
              width: 104,
              height: 104,
              color: context.themeSurface,
              child: Icon(Icons.person, size: 48, color: context.themePrimary),
            ),
          );
        }
      }
    }
    return Container(
      width: 104,
      height: 104,
      color: context.themeSurface,
      child: Icon(Icons.person, size: 48, color: context.themePrimary),
    );
  }

  Future<void> _saveProfileSetup() async {
    if (_formKey.currentState!.validate() && _activeUser != null) {
      setState(() => _isSaving = true);

      // Sinkronkan data petualang yang diubah tanpa menimpa data registrasi awal (email & noHp tetap konsisten)
      final updatedUser = _activeUser!.copyWith(
        nama: _namaCtrl.text.trim(),
        asalKota: _asalKotaCtrl.text.trim().isNotEmpty ? _asalKotaCtrl.text.trim() : _activeUser!.asalKota,
        bio: _bioCtrl.text.trim(),
        rolePetualang: _selectedRole,
        golonganDarah: _selectedGolonganDarah,
        kontakDaruratNama: _kontakDaruratNamaCtrl.text.trim(),
        kontakDaruratHp: _kontakDaruratHpCtrl.text.trim(),
        organisasi: _organisasiCtrl.text.trim(),
        fotoProfil: _selectedPhotoPath,
      );

      try {
        await DatabaseHelper.instance.updateUser(updatedUser);
        await DatabaseHelper.instance.syncUserStatsFromLogs(updatedUser.id);

        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.isInitialSetup
                  ? 'Setup Akun Selesai! Selamat datang di NARA Outdoor.'
                  : 'Profil Petualang Berhasil Disinkronkan!',
            ),
            backgroundColor: context.themePrimary,
          ),
        );

        Navigator.pop(context, updatedUser);
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal menyimpan profil: $e'),
            backgroundColor: AppTheme.errorRed,
          ),
        );
      } finally {
        if (mounted) setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = context.isDarkMode;

    return Scaffold(
      backgroundColor: context.themeBg,
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(color: context.themePrimary),
            )
          : CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                // 1. Top Glassmorphism AppBar
                SliverAppBar(
                  pinned: true,
                  backgroundColor: Colors.transparent,
                  elevation: 0,
                  scrolledUnderElevation: 0,
                  leading: IconButton(
                    icon: Icon(Icons.arrow_back, color: context.themePrimary),
                    onPressed: () => Navigator.pop(context),
                  ),
                  title: Text(
                    widget.isInitialSetup ? 'SETUP AKUN AWAL' : 'EDIT PROFIL PETUALANG',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.5,
                      color: context.themePrimary,
                    ),
                  ),
                  centerTitle: true,
                  actions: [
                    IconButton(
                      icon: Icon(
                        isDark ? Icons.light_mode_rounded : Icons.dark_mode_outlined,
                        color: isDark ? AppTheme.goldAccentDark : context.themePrimary,
                        size: 22,
                      ),
                      tooltip: isDark ? 'Beralih ke Mode Terang' : 'Beralih ke Mode Gelap',
                      onPressed: () => ThemeController.instance.toggleTheme(context),
                    ),
                    const SizedBox(width: 4),
                  ],
                  flexibleSpace: ClipRect(
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                      child: Container(color: context.themeBg.withValues(alpha: 0.85)),
                    ),
                  ),
                ),

                // 2. Form Konten
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      // Header Deskripsi
                      Text(
                        widget.isInitialSetup
                            ? 'Lengkapi Identitas Petualang Anda'
                            : 'Sinkronisasi Informasi Akun NARA',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: context.themeText,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Data ini digunakan untuk identitas profil, catatan ekspedisi, dan protokol keselamatan darurat di lapangan.',
                        style: TextStyle(fontSize: 12, color: context.themeTextSecondary, height: 1.35),
                      ),
                      const SizedBox(height: 18),

                      // Strip Ringkasan Statistik Ekspedisi Live
                      _buildLiveStatsBanner(),
                      const SizedBox(height: 18),

                      // Avatar Galeri Selector
                      _buildAvatarPickerSection(),
                      const SizedBox(height: 24),

                      // Form Input Detail Pengguna
                      Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // 1. Data Registrasi Akun (Terkunci / Read-Only)
                            _buildLockedAccountCard(),
                            const SizedBox(height: 20),

                            // 2. Nama Lengkap Petualang
                            _buildFieldLabel('Nama Lengkap', Icons.person_outline),
                            TextFormField(
                              controller: _namaCtrl,
                              style: TextStyle(fontSize: 13, color: context.themeText),
                              decoration: _inputDecoration('Nama Lengkap Anda'),
                              validator: (v) => v == null || v.trim().isEmpty ? 'Nama wajib diisi' : null,
                            ),
                            const SizedBox(height: 16),

                            // 3. Asal Kota
                            _buildFieldLabel('Asal Kota / Daerah', Icons.location_city_outlined),
                            TextFormField(
                              controller: _asalKotaCtrl,
                              style: TextStyle(fontSize: 13, color: context.themeText),
                              decoration: _inputDecoration('Contoh: Bandung Barat, Jawa Barat'),
                              validator: (v) => v == null || v.trim().isEmpty ? 'Asal kota wajib diisi' : null,
                            ),
                            const SizedBox(height: 16),

                            // 4. Role & Tingkat Pengalaman Petualang
                            _buildFieldLabel('Role & Tingkat Pengalaman', Icons.military_tech_outlined),
                            DropdownButtonFormField<String>(
                              initialValue: _selectedRole,
                              dropdownColor: context.themeCard,
                              style: TextStyle(fontSize: 13, color: context.themeText),
                              decoration: _inputDecoration('Pilih Peran Petualang'),
                              items: _roleOptions.map((role) {
                                return DropdownMenuItem(
                                  value: role,
                                  child: Text(
                                    role,
                                    style: TextStyle(fontSize: 13, color: context.themeText),
                                  ),
                                );
                              }).toList(),
                              onChanged: (val) {
                                if (val != null) setState(() => _selectedRole = val);
                              },
                            ),
                            const SizedBox(height: 16),

                            // 5. Bio Petualang
                            _buildFieldLabel('Bio & Spesialisasi Petualangan', Icons.edit_note_rounded),
                            TextFormField(
                              controller: _bioCtrl,
                              maxLines: 2,
                              style: TextStyle(fontSize: 13, color: context.themeText),
                              decoration: _inputDecoration('Contoh: Penjelajah goa vertikal & pemanjat tebing tegar.'),
                            ),
                            const SizedBox(height: 20),

                            // 6. Box Keselamatan & Medis (Goa & Tebing Safety)
                            _buildSafetyMedicalCard(),
                            const SizedBox(height: 16),

                            // 7. Organisasi / Komunitas
                            _buildFieldLabel('Klub / Organisasi Petualang', Icons.groups_outlined),
                            TextFormField(
                              controller: _organisasiCtrl,
                              style: TextStyle(fontSize: 13, color: context.themeText),
                              decoration: _inputDecoration('Contoh: NARA Speleology Club / FPTI'),
                            ),
                            const SizedBox(height: 28),

                            // Tombol Submit & Sinkronkan
                            SizedBox(
                              width: double.infinity,
                              height: 52,
                              child: ElevatedButton(
                                onPressed: _isSaving ? null : _saveProfileSetup,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: context.themePrimary,
                                  foregroundColor: isDark ? const Color(0xFF0F1713) : Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  elevation: 0,
                                ),
                                child: _isSaving
                                    ? SizedBox(
                                        height: 20,
                                        width: 20,
                                        child: CircularProgressIndicator(
                                          color: isDark ? const Color(0xFF0F1713) : Colors.white,
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : Text(
                                        widget.isInitialSetup
                                            ? 'SELESAIKAN SETUP PROFIL'
                                            : 'SIMPAN & SINKRONKAN PROFIL',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                              ),
                            ),
                            const SizedBox(height: 40),
                          ],
                        ),
                      ),
                    ]),
                  ),
                ),
              ],
            ),
    );
  }

  // =========================================================================
  // BANNER STATISTIK EKSPEDISI TERSINKRONISASI
  // =========================================================================

  Widget _buildLiveStatsBanner() {
    final int total = _activeUser?.totalEkspedisi ?? 0;
    final String jarak = _activeUser?.jarakJelajah ?? '0 km';
    final String jam = _activeUser?.jamTerbang ?? '0 Jam';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: context.themeSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.themeBorder),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: context.themePrimaryFixed,
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.sync_rounded, size: 18, color: context.themePrimary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Data Ekspedisi Terhubung',
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.bold,
                    color: context.themeText,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '$total Ekspedisi • $jarak Jelajah • $jam di Lapangan',
                  style: TextStyle(
                    fontSize: 11,
                    color: context.themeTextSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // =========================================================================
  // SEKSI FOTO PROFIL DARI GALERI / KAMERA HP
  // =========================================================================

  Widget _buildAvatarPickerSection() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: context.themeCard,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: context.themeBorder),
        boxShadow: [
          BoxShadow(
            color: context.isDarkMode
                ? Colors.black.withValues(alpha: 0.2)
                : Colors.black.withValues(alpha: 0.03),
            blurRadius: 18,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.photo_library_rounded, size: 18, color: context.themePrimary),
                  const SizedBox(width: 8),
                  Text(
                    'Foto Profil Petualang',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: context.themeText,
                    ),
                  ),
                ],
              ),
              GestureDetector(
                onTap: _showImagePickerSheet,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: context.themePrimaryFixed,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.add_photo_alternate_rounded, size: 14, color: context.themePrimary),
                      const SizedBox(width: 4),
                      Text(
                        'Pilih Galeri',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: context.themePrimary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Lingkaran Avatar Preview (Bisa di-tap untuk buka Galeri HP)
          GestureDetector(
            onTap: _showImagePickerSheet,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width: 112,
                  height: 112,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: context.themePrimary.withValues(alpha: 0.1),
                    border: Border.all(color: context.themeBorder, width: 2),
                  ),
                ),
                ClipOval(
                  child: _buildAvatarWidget(),
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: context.themePrimary,
                      shape: BoxShape.circle,
                      border: Border.all(color: context.themeCard, width: 2),
                    ),
                    child: Icon(
                      Icons.camera_alt_rounded,
                      size: 14,
                      color: context.isDarkMode ? const Color(0xFF0F1713) : Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Ketuk foto untuk mengambil dari Galeri atau Kamera HP',
            style: TextStyle(fontSize: 11, color: context.themeTextSecondary),
          ),
        ],
      ),
    );
  }

  // =========================================================================
  // DATA REGISTRASI AKUN (EMAIL & NO HP TERKUNCI / READ-ONLY)
  // =========================================================================

  Widget _buildLockedAccountCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.themeSurface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: context.themeBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.lock_outline_rounded, size: 16, color: context.themeGold),
              const SizedBox(width: 8),
              Text(
                'Data Registrasi Akun',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: context.themeText,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: context.themeGold.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Terkunci Otentikasi',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: context.themeGold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Alamat email dan nomor HP terikat permanen dengan akun registrasi awal dan tidak dapat diubah.',
            style: TextStyle(fontSize: 11, color: context.themeTextSecondary, height: 1.3),
          ),
          const SizedBox(height: 14),

          // 1. Email (Read-Only)
          _buildFieldLabel('Email Terdaftar (Read-Only)', Icons.email_outlined),
          TextFormField(
            controller: _emailCtrl,
            readOnly: true,
            enabled: false,
            style: TextStyle(fontSize: 13, color: context.themeTextSecondary),
            decoration: _lockedInputDecoration('Email Akun Registrasi'),
          ),
          const SizedBox(height: 12),

          // 2. Nomor HP (Read-Only)
          _buildFieldLabel('Nomor HP Terdaftar (Read-Only)', Icons.phone_android_outlined),
          TextFormField(
            controller: _noHpCtrl,
            readOnly: true,
            enabled: false,
            style: TextStyle(fontSize: 13, color: context.themeTextSecondary),
            decoration: _lockedInputDecoration('Nomor HP Akun Registrasi'),
          ),
        ],
      ),
    );
  }

  // =========================================================================
  // BOX KESELAMATAN & MEDIS (GOA & TEBING SAFETY)
  // =========================================================================

  Widget _buildSafetyMedicalCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.themeSurface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: context.themeBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.medical_services_outlined, size: 18, color: context.themeTerracotta),
              const SizedBox(width: 8),
              Text(
                'Data Medis & Keselamatan Lapangan',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: context.themeText,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Golongan Darah
          _buildFieldLabel('Golongan Darah', Icons.bloodtype_outlined),
          DropdownButtonFormField<String>(
            initialValue: _selectedGolonganDarah,
            dropdownColor: context.themeCard,
            style: TextStyle(fontSize: 13, color: context.themeText),
            decoration: _inputDecoration('Pilih Golongan Darah'),
            items: _golonganDarahOptions.map((goldar) {
              return DropdownMenuItem(
                value: goldar,
                child: Text(
                  'Golongan Darah $goldar',
                  style: TextStyle(fontSize: 13, color: context.themeText),
                ),
              );
            }).toList(),
            onChanged: (val) {
              if (val != null) setState(() => _selectedGolonganDarah = val);
            },
          ),
          const SizedBox(height: 12),

          // Nama Kontak Darurat
          _buildFieldLabel('Nama Kontak Darurat', Icons.contact_emergency_outlined),
          TextFormField(
            controller: _kontakDaruratNamaCtrl,
            style: TextStyle(fontSize: 13, color: context.themeText),
            decoration: _inputDecoration('Contoh: Rangga / Posko Evakuasi'),
          ),
          const SizedBox(height: 12),

          // No. HP Kontak Darurat
          _buildFieldLabel('Nomor HP Darurat', Icons.phone_callback_outlined),
          TextFormField(
            controller: _kontakDaruratHpCtrl,
            keyboardType: TextInputType.phone,
            style: TextStyle(fontSize: 13, color: context.themeText),
            decoration: _inputDecoration('Contoh: +62 812-9876-5432'),
          ),
        ],
      ),
    );
  }

  Widget _buildFieldLabel(String label, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6.0),
      child: Row(
        children: [
          Icon(icon, size: 14, color: context.themePrimary),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: context.themePrimary,
            ),
          ),
        ],
      ),
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(
        fontSize: 12,
        color: context.themeTextSecondary.withValues(alpha: 0.6),
      ),
      filled: true,
      fillColor: context.isDarkMode ? context.themeSurfaceHigh : Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: context.themeBorder),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: context.themeBorder),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: context.themePrimary, width: 1.5),
      ),
    );
  }

  InputDecoration _lockedInputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      prefixIcon: Icon(Icons.lock_rounded, size: 16, color: context.themeTextSecondary),
      hintStyle: TextStyle(
        fontSize: 12,
        color: context.themeTextSecondary.withValues(alpha: 0.5),
      ),
      filled: true,
      fillColor: context.isDarkMode
          ? Colors.black.withValues(alpha: 0.25)
          : const Color(0xFFE8E4DB).withValues(alpha: 0.7),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: context.themeBorder.withValues(alpha: 0.5)),
      ),
      disabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: context.themeBorder.withValues(alpha: 0.5)),
      ),
    );
  }
}
