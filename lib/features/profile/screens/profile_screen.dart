import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_application_1/core/theme/theme_provider.dart';
import 'package:flutter_application_1/features/gear/screens/gear_screen.dart';
import 'package:flutter_application_1/features/gear/screens/maintenance_guide_screen.dart';
import 'package:flutter_application_1/features/safety/screens/safety_screen.dart';
import 'package:flutter_application_1/features/profile/screens/expedition_history_screen.dart';
import 'package:flutter_application_1/features/profile/screens/account_setup_screen.dart';
import 'package:flutter_application_1/features/auth/screens/login_screen.dart';
import 'package:flutter_application_1/features/map/screens/bookmark_list_screen.dart';
import 'package:flutter_application_1/core/database/database_helper.dart';
import 'package:flutter_application_1/features/auth/models/user_model.dart';
import 'package:flutter_application_1/features/profile/screens/privacy_policy_screen.dart';

// =========================================================================
// HALAMAN PROFIL PENGGUNA NARA (1:1 DENGAN DESAIN GOOGLE STITCH)
// Layar: Profil Pengguna (ID) - node 0019335eb9304a6cabea492e1ec08293
// Data tersinkronisasi dengan Database SQLite & Import Foto Galeri HP
// =========================================================================

class ProfilePage extends StatefulWidget {
  final VoidCallback? onBack;
  final bool showBackButton;

  const ProfilePage({
    super.key,
    this.onBack,
    this.showBackButton = false,
  });

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  // Palet Aksen Earth Tone NARA Profil
  static const Color darkGreen = Color(0xFF1E382B); // Deep Forest Moss
  static const Color terracottaSoft = Color(0xFFE28C72); // Warm Desert Terracotta
  static const Color roseAccent = Color(0xFFB8786B); // Dusty Clay Rose
  static const Color secondaryGold = Color(0xFFDDA15E); // Warm Desert Ochre Gold

  UserModel? _currentUser;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  // Mengambil data user yang terdaftar di device dari SQLite & Sinkronisasi Ekspedisi Riil
  Future<void> _loadUserData() async {
    setState(() => _isLoading = true);
    try {
      var user = await DatabaseHelper.instance.getLatestUser();
      if (user == null) {
        // Inisialisasi default user profil jika database belum memiliki user
        final defaultUser = UserModel(
          nama: 'Farhiyah Petualang',
          email: 'farhiyah.outdoor@nara.id',
          password: 'password123',
          asalKota: 'Bandung Barat',
          noHp: '+62 812-3456-7890',
          rolePetualang: 'Senior Caver & Speleologi',
          bio: 'Penjelajah goa vertikal karst Citatah & pemanjat tebing tegar.',
          golonganDarah: 'O+',
          kontakDaruratNama: 'Basecamp Citatah',
          kontakDaruratHp: '+62 812-9876-5432',
          organisasi: 'NARA Speleo Club',
          fotoProfil: 'https://images.unsplash.com/photo-1522163182402-834f871fd851?auto=format&fit=crop&w=400&q=80',
          totalEkspedisi: 0,
          jarakJelajah: '0 km',
          jamTerbang: '0 Jam',
        );
        final newId = await DatabaseHelper.instance.registerUser(defaultUser);
        user = defaultUser.copyWith(id: newId);
      }

      // Pastikan log ekspedisi terinisialisasi dan sinkronkan statistik riil dari database
      final syncedUser = await DatabaseHelper.instance.syncUserStatsFromLogs(user.id);
      if (syncedUser != null) {
        user = syncedUser;
      }

      if (mounted) {
        setState(() {
          _currentUser = user;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _openSetupAkunPage() async {
    final result = await Navigator.push<UserModel?>(
      context,
      MaterialPageRoute(
        builder: (context) => SetupAkunPage(
          user: _currentUser,
          isInitialSetup: false,
        ),
      ),
    );

    if (result != null) {
      setState(() {
        _currentUser = result;
      });
      _loadUserData();
    } else {
      _loadUserData();
    }
  }

  // Memilih Foto Profil dari Galeri Perangkat atau Kamera & Auto-Sync SQLite
  Future<void> _pickImage(ImageSource source) async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        final UserModel targetUser = _currentUser ??
            UserModel(
              nama: 'Petualang NARA',
              email: 'petualang@nara.id',
              password: 'password123',
              asalKota: 'Indonesia',
              noHp: '+62 812-0000-0000',
              rolePetualang: 'Petualang NARA',
              bio: 'Penjelajah alam bebas bersama NARA.',
              golonganDarah: '-',
              kontakDaruratNama: '-',
              kontakDaruratHp: '-',
              organisasi: 'NARA Outdoor Club',
              fotoProfil: pickedFile.path,
              totalEkspedisi: 0,
              jarakJelajah: '0 km',
              jamTerbang: '0 Jam',
            );

        final updated = targetUser.copyWith(fotoProfil: pickedFile.path);
        await DatabaseHelper.instance.updateUser(updated);
        final freshUser = await DatabaseHelper.instance.getLatestUser();

        if (mounted) {
          setState(() {
            _currentUser = freshUser ?? updated;
          });

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Foto Profil berhasil diperbarui dan tersinkronisasi!'),
              backgroundColor: Color(0xFF2E7D32),
              duration: Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal mengambil foto dari perangkat: $e'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  void _showImageSourcePicker() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      backgroundColor: context.themeCard,
      builder: (ctx) {
        return Padding(
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
                        Icons.photo_camera_back_rounded,
                        color: context.isDarkMode ? AppTheme.darkPrimary : darkGreen,
                        size: 22,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Pilih Foto Profil',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: context.isDarkMode ? AppTheme.darkPrimary : darkGreen,
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: Icon(Icons.close, color: context.themeTextSecondary),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                'Import foto petualang Anda langsung dari perangkat:',
                style: TextStyle(fontSize: 12, color: context.themeTextSecondary),
              ),
              const SizedBox(height: 16),
              ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: context.themePrimaryFixed,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.photo_library_rounded,
                    color: context.isDarkMode ? AppTheme.darkPrimary : darkGreen,
                  ),
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
                  'Ambil foto dari album penyimpanan perangkat',
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
                contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: context.themeSurface,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.camera_alt_rounded,
                    color: context.isDarkMode ? AppTheme.darkPrimary : darkGreen,
                  ),
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
        );
      },
    );
  }

  // Builder Gambar Avatar (Mendukung File Lokal & Network URL)
  Widget _buildAvatarImageWidget(String? avatarPath) {
    if (avatarPath != null && avatarPath.isNotEmpty) {
      if (avatarPath.startsWith('http://') || avatarPath.startsWith('https://')) {
        return Image.network(
          avatarPath,
          key: ValueKey(avatarPath),
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => Container(
            color: context.themeSurface,
            child: Icon(
              Icons.person,
              size: 54,
              color: context.isDarkMode ? AppTheme.darkPrimary : darkGreen,
            ),
          ),
        );
      } else {
        final file = File(avatarPath);
        if (file.existsSync()) {
          return Image.file(
            file,
            key: ValueKey(avatarPath),
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) => Container(
              color: context.themeSurface,
              child: Icon(
                Icons.person,
                size: 54,
                color: context.isDarkMode ? AppTheme.darkPrimary : darkGreen,
              ),
            ),
          );
        }
      }
    }
    return Container(
      color: context.themeSurface,
      child: Icon(
        Icons.person,
        size: 54,
        color: context.isDarkMode ? AppTheme.darkPrimary : darkGreen,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Data Sinkronisasi dari SQLite
    final String displayName = _currentUser?.nama.isNotEmpty == true ? _currentUser!.nama : 'Petualang NARA';
    final String displayEmail = _currentUser?.email.isNotEmpty == true ? _currentUser!.email : 'petualang@nara.id';
    final String displayKota = _currentUser?.asalKota.isNotEmpty == true ? _currentUser!.asalKota : 'Indonesia';
    final String displayHp = _currentUser?.noHp.isNotEmpty == true ? _currentUser!.noHp : '-';
    final String displayRole = _currentUser?.rolePetualang?.isNotEmpty == true ? _currentUser!.rolePetualang! : 'Petualang NARA';
    final String displayBio = _currentUser?.bio?.isNotEmpty == true ? _currentUser!.bio! : 'Penjelajah alam bebas bersama NARA.';
    final String displayGoldar = _currentUser?.golonganDarah?.isNotEmpty == true ? _currentUser!.golonganDarah! : '-';
    final String displayKontakDarurat = _currentUser?.kontakDaruratNama?.isNotEmpty == true ? '${_currentUser!.kontakDaruratNama} (${_currentUser!.kontakDaruratHp ?? "-"})' : '-';
    final String displayOrganisasi = _currentUser?.organisasi?.isNotEmpty == true ? _currentUser!.organisasi! : '-';
    final String displayAvatar = _currentUser?.fotoProfil ?? '';

    final String displayTotalEkspedisi = _currentUser?.totalEkspedisi?.toString() ?? '0';
    final String displayJarak = _currentUser?.jarakJelajah ?? '0 km';
    final String displayJamTerbang = _currentUser?.jamTerbang ?? '0 Jam';

    return Scaffold(
      backgroundColor: context.themeBg,
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(
                color: context.isDarkMode ? AppTheme.darkPrimary : darkGreen,
              ),
            )
          : RefreshIndicator(
              onRefresh: _loadUserData,
              color: context.isDarkMode ? AppTheme.darkPrimary : darkGreen,
              child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                slivers: [
                  // 1. TOP APP BAR DENGAN GLASSMORPHISM
                  SliverAppBar(
                    pinned: true,
                    backgroundColor: Colors.transparent,
                    elevation: 0,
                    scrolledUnderElevation: 0,
                    automaticallyImplyLeading: false,
                    leading: widget.showBackButton
                        ? IconButton(
                            icon: Icon(
                              Icons.arrow_back,
                              color: context.isDarkMode ? AppTheme.darkPrimary : darkGreen,
                            ),
                            onPressed: () {
                              if (widget.onBack != null) {
                                widget.onBack!();
                              } else {
                                Navigator.pop(context);
                              }
                            },
                          )
                        : null,
                    title: Text(
                      'NARA',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        color: context.isDarkMode ? AppTheme.darkPrimary : darkGreen,
                      ),
                    ),
                    centerTitle: true,
                    actions: [
                      // Quick Theme Mode Toggle Button
                      IconButton(
                        icon: Icon(
                          ThemeController.instance.isDarkMode(context)
                              ? Icons.light_mode_rounded
                              : Icons.dark_mode_outlined,
                          color: context.isDarkMode ? AppTheme.goldAccent : darkGreen,
                          size: 24,
                        ),
                        tooltip: ThemeController.instance.isDarkMode(context)
                            ? 'Beralih ke Mode Terang'
                            : 'Beralih ke Mode Gelap',
                        onPressed: () => ThemeController.instance.toggleTheme(context),
                      ),
                      IconButton(
                        icon: Icon(
                          Icons.edit_note_rounded,
                          color: context.isDarkMode ? AppTheme.darkPrimary : darkGreen,
                          size: 26,
                        ),
                        tooltip: 'Edit Setup Profil',
                        onPressed: _openSetupAkunPage,
                      ),
                      const SizedBox(width: 4),
                    ],
                    flexibleSpace: ClipRect(
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                        child: Container(
                          color: context.themeBg.withValues(alpha: 0.85),
                        ),
                      ),
                    ),
                  ),

                  // 2. KONTEN UTAMA PROFIL
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    sliver: SliverList(
                      delegate: SliverChildListDelegate([
                        // Profil Header Avatar & Info (Galeri HP + Dynamic User)
                        _buildProfileHeader(
                          avatarPath: displayAvatar,
                          name: displayName,
                          email: displayEmail,
                          kota: displayKota,
                          role: displayRole,
                          bio: displayBio,
                        ),
                        const SizedBox(height: 20),

                        // Stats Grid Bento (Ekspedisi, Jarak, Jam Terbang)
                        _buildStatsGridBento(
                          totalEkspedisi: displayTotalEkspedisi,
                          jarak: displayJarak,
                          jamTerbang: displayJamTerbang,
                        ),
                        const SizedBox(height: 20),

                        // Dedicated Dark Mode & Tampilan Settings Bento Card
                        _buildThemeSettingsCard(),
                        const SizedBox(height: 20),

                        // Data Medis & Keselamatan Lapangan
                        _buildSafetyMedicalCard(
                          goldar: displayGoldar,
                          kontakDarurat: displayKontakDarurat,
                          organisasi: displayOrganisasi,
                        ),
                        const SizedBox(height: 20),

                        // Pencapaian (Badges)
                        _buildAchievementsSection(),
                        const SizedBox(height: 20),

                        // Menu List Bento
                        _buildMenuListSection(
                          name: displayName,
                          email: displayEmail,
                          kota: displayKota,
                          hp: displayHp,
                          role: displayRole,
                          goldar: displayGoldar,
                          kontakDarurat: displayKontakDarurat,
                          organisasi: displayOrganisasi,
                        ),
                        const SizedBox(height: 24),

                        // Tombol Keluar (Logout)
                        _buildLogoutButton(),
                        const SizedBox(height: 110), // Padding navbar bawah
                      ]),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
  // ==========================================
  // 1. WIDGET PROFIL HEADER (AVATAR & BADGE)
  // ==========================================
  Widget _buildProfileHeader({
    required String avatarPath,
    required String name,
    required String email,
    required String kota,
    required String role,
    required String bio,
  }) {
    return Column(
      children: [
        // Avatar dengan Glow Ambient & Verified Badge (Dapat di-tap untuk buka Galeri)
        GestureDetector(
          onTap: _showImageSourcePicker,
          child: Stack(
            alignment: Alignment.center,
            clipBehavior: Clip.none,
            children: [
              // Ambient Blur Glow
              Container(
                width: 124,
                height: 124,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: (context.isDarkMode ? AppTheme.darkPrimary : darkGreen).withValues(alpha: 0.12),
                  boxShadow: [
                    BoxShadow(
                      color: (context.isDarkMode ? AppTheme.darkPrimary : darkGreen).withValues(alpha: 0.18),
                      blurRadius: 28,
                      spreadRadius: 4,
                    ),
                  ],
                ),
              ),

              // Foto Profil dari Galeri Perangkat / Kamera
              Container(
                width: 116,
                height: 116,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: context.themeCard, width: 4),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ClipOval(
                  child: _buildAvatarImageWidget(avatarPath),
                ),
              ),

              // Tombol Edit Kamera/Galeri Badge Kanan Bawah
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: context.isDarkMode ? AppTheme.darkPrimary : darkGreen,
                    shape: BoxShape.circle,
                    border: Border.all(color: context.themeCard, width: 2.5),
                  ),
                  child: Icon(
                    Icons.photo_camera_rounded,
                    color: context.isDarkMode ? const Color(0xFF0F1713) : Colors.white,
                    size: 14,
                  ),
                ),
              ),

              // Verified Gold Badge Kiri Bawah
              Positioned(
                bottom: 0,
                left: 0,
                child: Container(
                  padding: const EdgeInsets.all(5),
                  decoration: BoxDecoration(
                    color: secondaryGold,
                    shape: BoxShape.circle,
                    border: Border.all(color: context.themeCard, width: 2.5),
                  ),
                  child: const Icon(
                    Icons.verified_rounded,
                    color: Color(0xFF776005),
                    size: 14,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // Nama Pengguna
        Text(
          name,
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: context.themeText,
            letterSpacing: -0.5,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 4),

        // Badge Status Role & Asal Kota
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
          decoration: BoxDecoration(
            color: context.themeSurfaceHigh,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.military_tech_rounded,
                color: context.isDarkMode ? AppTheme.darkPrimary : darkGreen,
                size: 15,
              ),
              const SizedBox(width: 5),
              Text(
                '$role • $kota',
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.bold,
                  color: context.isDarkMode ? AppTheme.darkPrimary : darkGreen,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),

        // Bio Petualang
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Text(
            bio,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              color: context.themeTextSecondary,
              height: 1.35,
            ),
          ),
        ),
      ],
    );
  }

  // ==========================================
  // 2. STATS GRID BENTO (3 KARTU)
  // ==========================================
  Widget _buildStatsGridBento({
    required String totalEkspedisi,
    required String jarak,
    required String jamTerbang,
  }) {
    return Row(
      children: [
        // Kartu 1: Ekspedisi
        Expanded(
          child: GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => RiwayatLogPage(userId: _currentUser?.id),
                ),
              ).then((_) => _loadUserData());
            },
            child: _buildBentoStatCard(
              title: totalEkspedisi,
              subtitle: 'EKSPEDISI',
              isDark: false,
            ),
          ),
        ),
        const SizedBox(width: 10),

        // Kartu 2: Jarak Jelajah
        Expanded(
          child: GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => RiwayatLogPage(userId: _currentUser?.id),
                ),
              ).then((_) => _loadUserData());
            },
            child: _buildBentoStatCard(
              title: jarak,
              subtitle: 'JELAJAH',
              isDark: false,
            ),
          ),
        ),
        const SizedBox(width: 10),

        // Kartu 3: Jam Terbang
        Expanded(
          child: GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => RiwayatLogPage(userId: _currentUser?.id),
                ),
              ).then((_) => _loadUserData());
            },
            child: _buildBentoStatCard(
              title: jamTerbang,
              subtitle: 'DI LAPANGAN',
              isDark: true,
              icon: Icons.timer_outlined,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBentoStatCard({
    required String title,
    required String subtitle,
    required bool isDark,
    IconData? icon,
  }) {
    final bool isDarkTheme = context.isDarkMode;
    return Container(
      height: 96,
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: isDark
            ? (isDarkTheme ? const Color(0xFF273B32) : darkGreen)
            : context.themeCard,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark ? Colors.transparent : context.themeBorder,
          width: 0.8,
        ),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? (isDarkTheme ? Colors.black.withValues(alpha: 0.3) : darkGreen.withValues(alpha: 0.22))
                : Colors.black.withValues(alpha: 0.04),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (icon != null) ...[
            Icon(icon, color: secondaryGold, size: 18),
            const SizedBox(height: 2),
          ],
          Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isDark
                  ? Colors.white
                  : (isDarkTheme ? AppTheme.darkPrimary : darkGreen),
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.bold,
              color: isDark ? const Color(0xFFAACFB7) : context.themeTextSecondary,
              letterSpacing: 0.6,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // ==========================================
  // 3. PENGATURAN TEMA & MODE GELAP (BENTO CARD)
  // ==========================================
  Widget _buildThemeSettingsCard() {
    final bool isDark = context.isDarkMode;
    final ThemeMode currentMode = ThemeController.instance.themeMode;

    String modeLabel = 'Ikuti Pengaturan Sistem Perangkat';
    if (currentMode == ThemeMode.light) modeLabel = 'Mode Terang (Light) Aktif';
    if (currentMode == ThemeMode.dark) modeLabel = 'Mode Gelap (Dark) Aktif';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.themeCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: context.themeBorder, width: 0.8),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withValues(alpha: 0.25)
                : darkGreen.withValues(alpha: 0.04),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xFF1E3D2E)
                          : const Color(0xFFE8F5E9),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      isDark ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
                      color: isDark ? AppTheme.darkPrimary : darkGreen,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Mode Gelap (Dark Mode)',
                        style: TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.bold,
                          color: context.themeText,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        modeLabel,
                        style: TextStyle(
                          fontSize: 11,
                          color: context.themeTextSecondary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              Switch.adaptive(
                value: isDark,
                activeThumbColor: AppTheme.darkPrimary,
                activeTrackColor: const Color(0xFF1E3D2E),
                onChanged: (val) {
                  ThemeController.instance.setThemeMode(
                    val ? ThemeMode.dark : ThemeMode.light,
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 12),
          Divider(height: 1, color: context.themeBorder),
          const SizedBox(height: 12),
          // Segmented selector for theme mode (Terang, Gelap, Sistem)
          Row(
            children: [
              Expanded(
                child: _buildThemeModeChoiceChip(
                  icon: Icons.wb_sunny_rounded,
                  label: 'Terang',
                  isSelected: currentMode == ThemeMode.light,
                  onTap: () => ThemeController.instance.setThemeMode(ThemeMode.light),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildThemeModeChoiceChip(
                  icon: Icons.nightlight_round,
                  label: 'Gelap',
                  isSelected: currentMode == ThemeMode.dark,
                  onTap: () => ThemeController.instance.setThemeMode(ThemeMode.dark),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildThemeModeChoiceChip(
                  icon: Icons.settings_brightness_rounded,
                  label: 'Sistem',
                  isSelected: currentMode == ThemeMode.system,
                  onTap: () => ThemeController.instance.setThemeMode(ThemeMode.system),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildThemeModeChoiceChip({
    required IconData icon,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final bool isDark = context.isDarkMode;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        decoration: BoxDecoration(
          color: isSelected
              ? (isDark ? AppTheme.darkPrimary : darkGreen)
              : context.themeSurface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? (isDark ? AppTheme.darkPrimary : darkGreen)
                : context.themeBorder,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 14,
              color: isSelected
                  ? (isDark ? const Color(0xFF0F1713) : Colors.white)
                  : context.themeTextSecondary,
            ),
            const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected
                    ? (isDark ? const Color(0xFF0F1713) : Colors.white)
                    : context.themeText,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================
  // 4. DATA MEDIS & KESELAMATAN LAPANGAN
  // ==========================================
  Widget _buildSafetyMedicalCard({
    required String goldar,
    required String kontakDarurat,
    required String organisasi,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.themeCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: context.themeBorder, width: 0.8),
        boxShadow: [
          BoxShadow(
            color: (context.isDarkMode ? AppTheme.darkPrimary : darkGreen).withValues(alpha: 0.04),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.shield_rounded,
                    size: 18,
                    color: context.isDarkMode ? AppTheme.darkPrimary : darkGreen,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Identitas Keselamatan & Medis',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: context.themeText,
                    ),
                  ),
                ],
              ),
              GestureDetector(
                onTap: _openSetupAkunPage,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: context.themePrimaryFixed,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.edit,
                        size: 12,
                        color: context.isDarkMode ? AppTheme.darkPrimary : darkGreen,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Edit',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: context.isDarkMode ? AppTheme.darkPrimary : darkGreen,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  color: context.isDarkMode ? const Color(0xFF3B1D1D) : const Color(0xFFFFEBEE),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.bloodtype_rounded, size: 16, color: Color(0xFFBA1A1A)),
                    const SizedBox(width: 4),
                    Text(
                      'Goldar: $goldar',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFBA1A1A),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  decoration: BoxDecoration(
                    color: context.themeSurface,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.groups_rounded,
                        size: 16,
                        color: context.isDarkMode ? AppTheme.darkPrimary : darkGreen,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          organisasi,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: context.themeText,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: context.themeSurface,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.phone_callback_rounded,
                  size: 15,
                  color: context.isDarkMode ? AppTheme.darkPrimary : darkGreen,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Darurat: $kontakDarurat',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: context.themeText,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // 5. PENCAPAIAN (ACHIEVEMENTS BADGES)
  // ==========================================
  Widget _buildAchievementsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Pencapaian & Sertifikasi',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: context.themeText,
          ),
        ),
        const SizedBox(height: 12),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          child: Row(
            children: [
              _buildAchievementItem(
                icon: Icons.landscape_rounded,
                iconColor: terracottaSoft,
                title: 'Penjelajah\nGoa',
                isUnlocked: true,
              ),
              const SizedBox(width: 12),
              _buildAchievementItem(
                icon: Icons.hiking_rounded,
                iconColor: context.isDarkMode ? AppTheme.darkPrimary : darkGreen,
                title: 'Pendaki\nTebing',
                isUnlocked: true,
              ),
              const SizedBox(width: 12),
              _buildAchievementItem(
                icon: Icons.anchor_rounded,
                iconColor: roseAccent,
                title: 'SRT\nSpecialist',
                isUnlocked: true,
              ),
              const SizedBox(width: 12),
              _buildAchievementItem(
                icon: Icons.lock_outline_rounded,
                iconColor: context.themeTextSecondary,
                title: 'Rescue\nMaster',
                isUnlocked: false,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAchievementItem({
    required IconData icon,
    required Color iconColor,
    required String title,
    required bool isUnlocked,
  }) {
    return Column(
      children: [
        Container(
          width: 62,
          height: 62,
          decoration: BoxDecoration(
            color: isUnlocked ? context.themeCard : context.themeSurfaceHigh,
            shape: BoxShape.circle,
            border: Border.all(color: context.themeBorder),
            boxShadow: isUnlocked
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : [],
          ),
          child: Icon(
            icon,
            color: isUnlocked ? iconColor : context.themeTextSecondary.withValues(alpha: 0.6),
            size: 26,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          title,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 10.5,
            fontWeight: FontWeight.w600,
            color: isUnlocked ? context.themeText : context.themeTextSecondary,
            height: 1.2,
          ),
        ),
      ],
    );
  }

  // ==========================================
  // 6. MENU LIST SECTION
  // ==========================================
  Widget _buildMenuListSection({
    required String name,
    required String email,
    required String kota,
    required String hp,
    required String role,
    required String goldar,
    required String kontakDarurat,
    required String organisasi,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: context.themeCard,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: context.themeBorder, width: 0.8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // 0. Riwayat Log Ekspedisi
          _buildMenuItem(
            icon: Icons.explore_rounded,
            title: 'Log Ekspedisi Saya',
            subtitle: 'Riwayat penjelajahan tebing, goa, dan catatan rute',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => RiwayatLogPage(userId: _currentUser?.id),
                ),
              ).then((_) => _loadUserData());
            },
          ),
          Divider(height: 1, indent: 64, color: context.themeBorder),

          // 0.5. Spot Favorit & Bookmark
          _buildMenuItem(
            icon: Icons.bookmarks_rounded,
            title: 'Spot Favorit & Bookmark Saya',
            subtitle: 'Daftar tebing dan goa favorit yang Anda simpan',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      DaftarBookmarkPage(userId: _currentUser?.id),
                ),
              );
            },
          ),
          Divider(height: 1, indent: 64, color: context.themeBorder),

          // 1. Edit Profil & Setup Akun
          _buildMenuItem(
            icon: Icons.tune_rounded,
            title: 'Edit Profil & Setup Akun',
            subtitle: 'Ubah role, bio, golongan darah, dan kontak darurat',
            onTap: _openSetupAkunPage,
          ),
          Divider(height: 1, indent: 64, color: context.themeBorder),

          // 2. Ganti Foto dari Galeri HP
          _buildMenuItem(
            icon: Icons.photo_library_rounded,
            title: 'Ganti Foto Profil (Galeri HP)',
            subtitle: 'Pilih foto petualang langsung dari album galeri HP',
            onTap: _showImageSourcePicker,
          ),
          Divider(height: 1, indent: 64, color: context.themeBorder),

          // 3. Panduan Perawatan Alat
          _buildMenuItem(
            icon: Icons.menu_book_rounded,
            title: 'Panduan Perawatan Alat',
            subtitle: 'SOP perawatan tali, descender, & gear caving',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const PanduanPerawatanPage(),
                ),
              );
            },
          ),
          Divider(height: 1, indent: 64, color: context.themeBorder),

          // 4. Pemeriksaan Gear
          _buildMenuItem(
            icon: Icons.handyman_rounded,
            title: 'Pemeriksaan Gear & Alat',
            subtitle: 'Verifikasi kesiapan perlengkapan ekspedisi',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const PeriksaGearPage(),
                ),
              );
            },
          ),
          Divider(height: 1, indent: 64, color: context.themeBorder),

          // 5. Pusat Keamanan
          _buildMenuItem(
            icon: Icons.gpp_good_rounded,
            title: 'Pusat Keamanan & SOS',
            subtitle: 'Pelacak teman luring & tombol sinyal darurat',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const KeamananPage(),
                ),
              );
            },
          ),
          Divider(height: 1, indent: 64, color: context.themeBorder),

          // 6. Rincian Data Akun
          _buildMenuItem(
            icon: Icons.manage_accounts_rounded,
            title: 'Rincian Akun Terdaftar',
            subtitle: 'Lihat data identitas yang tersimpan di SQLite',
            onTap: () => _showAkunDetailDialog(
              name: name,
              email: email,
              kota: kota,
              hp: hp,
              role: role,
              goldar: goldar,
              kontakDarurat: kontakDarurat,
              organisasi: organisasi,
            ),
          ),
          Divider(height: 1, indent: 64, color: context.themeBorder),

          // 7. Kebijakan Privasi & Privasi Data
          _buildMenuItem(
            icon: Icons.shield_outlined,
            title: 'Kebijakan Privasi & Data',
            subtitle: 'Informasi keamanan data GPS, medis, & izin perangkat',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const PrivacyPolicyPage(),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    String? subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(22),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: (context.isDarkMode ? AppTheme.darkPrimary : darkGreen).withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: context.isDarkMode ? AppTheme.darkPrimary : darkGreen,
                size: 19,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: context.themeText,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(fontSize: 10.5, color: context.themeTextSecondary),
                    ),
                  ],
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: context.themeTextSecondary,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================
  // 7. TOMBOL LOGOUT (KELUAR)
  // ==========================================
  Widget _buildLogoutButton() {
    return Center(
      child: TextButton.icon(
        onPressed: _showLogoutConfirmDialog,
        icon: const Icon(
          Icons.logout_rounded,
          color: Color(0xFFBA1A1A),
          size: 18,
        ),
        label: const Text(
          'Keluar dari Akun',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: Color(0xFFBA1A1A),
          ),
        ),
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
        ),
      ),
    );
  }

  void _showLogoutConfirmDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: context.themeCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.logout_rounded, color: Color(0xFFBA1A1A)),
            SizedBox(width: 10),
            Text('Keluar Akun', style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        content: Text(
          'Apakah Anda yakin ingin keluar dari akun ini? Data tersimpan aman di database perangkat Anda.',
          style: TextStyle(color: context.themeText),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Batal', style: TextStyle(color: context.themeTextSecondary)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(
                  builder: (context) => const Tugas12LoginPage(),
                ),
                (route) => false,
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFBA1A1A),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Keluar'),
          ),
        ],
      ),
    );
  }

  // Dialog Detail & Rincian Akun
  void _showAkunDetailDialog({
    required String name,
    required String email,
    required String kota,
    required String hp,
    required String role,
    required String goldar,
    required String kontakDarurat,
    required String organisasi,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      backgroundColor: context.themeCard,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          left: 24,
          right: 24,
          top: 24,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Data Akun Petualang',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: context.isDarkMode ? AppTheme.darkPrimary : darkGreen,
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.close, color: context.themeTextSecondary),
                  onPressed: () => Navigator.pop(ctx),
                ),
              ],
            ),
            const SizedBox(height: 14),
            _buildAkunInfoTile(Icons.person_outline, 'Nama Lengkap', name),
            _buildAkunInfoTile(Icons.military_tech_outlined, 'Role Petualang', role),
            _buildAkunInfoTile(Icons.email_outlined, 'Email Akun', email),
            _buildAkunInfoTile(Icons.location_city_outlined, 'Asal Kota', kota),
            _buildAkunInfoTile(Icons.phone_outlined, 'Nomor HP', hp),
            _buildAkunInfoTile(Icons.bloodtype_outlined, 'Golongan Darah', goldar),
            _buildAkunInfoTile(Icons.contact_emergency_outlined, 'Kontak Darurat', kontakDarurat),
            _buildAkunInfoTile(Icons.groups_outlined, 'Organisasi', organisasi),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: context.themeSurfaceHigh,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.storage_rounded,
                    color: context.isDarkMode ? AppTheme.darkPrimary : darkGreen,
                    size: 18,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Tersinkronisasi dengan SQLite Database Perangkat',
                      style: TextStyle(
                        fontSize: 11,
                        color: context.themeTextSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAkunInfoTile(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(
            icon,
            color: context.isDarkMode ? AppTheme.darkPrimary : darkGreen,
            size: 18,
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(fontSize: 10.5, color: context.themeTextSecondary),
              ),
              Text(
                value,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: context.themeText,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
