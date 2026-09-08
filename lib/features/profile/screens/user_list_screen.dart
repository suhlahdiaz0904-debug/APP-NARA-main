import 'package:flutter/material.dart';
import 'package:flutter_application_1/core/theme/theme_provider.dart';
import 'package:flutter_application_1/features/auth/screens/login_screen.dart';
import 'package:flutter_application_1/core/database/database_helper.dart';
import 'package:flutter_application_1/features/auth/models/user_model.dart';

class UserListPage extends StatefulWidget {
  final UserModel? currentUser;

  const UserListPage({super.key, this.currentUser});

  @override
  State<UserListPage> createState() => _UserListPageState();
}

class _UserListPageState extends State<UserListPage> {
  late Future<List<UserModel>> _userListFuture;

  @override
  void initState() {
    super.initState();
    _refreshUsers();
  }

  void _refreshUsers() {
    setState(() {
      _userListFuture = DatabaseHelper.instance.getAllUsers();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.themeBg,
      appBar: _buildAppBar(context),
      body: _buildBody(),
    );
  }

  // --- Helper Widgets ---

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    final bool isDark = context.isDarkMode;

    return AppBar(
      backgroundColor: context.themeBg,
      elevation: 0,
      leading: IconButton(
        icon: Icon(Icons.arrow_back, color: context.themePrimary),
        onPressed: () {
          if (Navigator.canPop(context)) {
            Navigator.pop(context);
          }
        },
      ),
      title: Text(
        'DATA USER TERDAFTAR',
        style: TextStyle(
          color: context.themePrimary,
          fontWeight: FontWeight.w900,
          fontSize: 16,
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
        IconButton(
          icon: Icon(Icons.logout_rounded, color: Colors.red.shade700),
          tooltip: 'Logout',
          onPressed: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => const Tugas12LoginPage(),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildBody() {
    return FutureBuilder<List<UserModel>>(
      future: _userListFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text('Belum ada data user di SQLite'));
        }

        final users = snapshot.data!;

        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: users.length,
          separatorBuilder: (_, _) => const SizedBox(height: 10),
          itemBuilder: (context, index) {
            final item = users[index];
            final isCurrent =
                widget.currentUser != null && item.email == widget.currentUser!.email;

            return _buildUserCard(item, isCurrent);
          },
        );
      },
    );
  }

  Widget _buildUserCard(UserModel item, bool isCurrent) {
    return Card(
      color: context.themeCard,
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: isCurrent
            ? BorderSide(color: context.themePrimary, width: 1.5)
            : BorderSide(color: context.themeBorder),
      ),
      child: ListTile(
        leading: _buildUserAvatar(item, isCurrent),
        title: _buildUserTitle(item, isCurrent),
        subtitle: _buildUserSubtitle(item),
        isThreeLine: true,
        trailing: Icon(
          Icons.chevron_right_rounded,
          color: context.themePrimary,
          size: 24,
        ),
        onTap: () => _showUserDetailSheet(context, item),
      ),
    );
  }

  Widget _buildUserAvatar(UserModel item, bool isCurrent) {
    final bool isDark = context.isDarkMode;
    return CircleAvatar(
      backgroundColor: isCurrent
          ? context.themePrimary
          : context.themeSurface,
      child: Text(
        item.nama.isNotEmpty ? item.nama[0].toUpperCase() : 'U',
        style: TextStyle(
          color: isCurrent
              ? (isDark ? const Color(0xFF0F1713) : Colors.white)
              : context.themeText,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildUserTitle(UserModel item, bool isCurrent) {
    return Text(
      item.nama + (isCurrent ? ' (Saya)' : ''),
      style: TextStyle(
        fontWeight: FontWeight.bold,
        color: context.themeText,
      ),
    );
  }

  Widget _buildUserSubtitle(UserModel item) {
    return Text(
      '${item.email}\n${item.noHp} • ${item.asalKota}\nPassword: ${item.password}',
      style: TextStyle(color: context.themeTextSecondary),
    );
  }

  void _showUserDetailSheet(BuildContext context, UserModel user) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      backgroundColor: context.themeCard,
      builder: (ctx) {
        final bool isDark = ctx.isDarkMode;
        final Color darkGreen = const Color(0xFF1E382B);
        return Padding(
          padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 24,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Rincian Data Pengguna',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: isDark ? AppTheme.goldAccentDark : darkGreen,
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.close, color: context.themeTextSecondary),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                _buildInfoRow(Icons.person_outline, 'Nama Lengkap', user.nama),
                _buildInfoRow(Icons.email_outlined, 'Email', user.email),
                _buildInfoRow(Icons.lock_outline, 'Password', user.password, isPassword: true),
                _buildInfoRow(Icons.phone_outlined, 'Nomor HP', user.noHp),
                _buildInfoRow(Icons.location_city_outlined, 'Asal Kota', user.asalKota),
                _buildInfoRow(Icons.military_tech_outlined, 'Role Petualang', user.rolePetualang ?? '-'),
                _buildInfoRow(Icons.notes_outlined, 'Bio', user.bio ?? '-'),
                _buildInfoRow(Icons.bloodtype_outlined, 'Golongan Darah', user.golonganDarah ?? '-'),
                _buildInfoRow(Icons.contact_emergency_outlined, 'Nama Kontak Darurat', user.kontakDaruratNama ?? '-'),
                _buildInfoRow(Icons.phone_callback_outlined, 'HP Kontak Darurat', user.kontakDaruratHp ?? '-'),
                _buildInfoRow(Icons.groups_outlined, 'Organisasi', user.organisasi ?? '-'),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value, {bool isPassword = false}) {
    bool obscure = isPassword;
    return StatefulBuilder(builder: (context, setLocalState) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: Row(
          children: [
            Icon(icon, color: context.themePrimary, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(fontSize: 11, color: context.themeTextSecondary),
                  ),
                  Text(
                    obscure ? '••••••••' : value,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: context.themeText,
                    ),
                  ),
                ],
              ),
            ),
            if (isPassword)
              IconButton(
                icon: Icon(
                  obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                  color: context.themeTextSecondary,
                  size: 20,
                ),
                onPressed: () {
                  setLocalState(() {
                    obscure = !obscure;
                  });
                },
              ),
          ],
        ),
      );
    });
  }
}
