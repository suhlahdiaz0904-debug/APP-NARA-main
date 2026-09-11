import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_application_1/core/database/database_helper.dart';
import 'package:flutter_application_1/features/auth/models/user_model.dart';

/// =========================================================================
/// AUTH & USER PROFILE CLOUD FIRESTORE SERVICE
/// =========================================================================
/// Service singleton untuk mengelola autentikasi Firebase (Google & Email/Password),
/// reset kata sandi, serta sinkronisasi dua arah profil pengguna antara SQLite
/// lokal dan Cloud Firestore (`nara_user_profiles`).
class AuthService {
  static final AuthService instance = AuthService._internal();

  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static const String _collectionProfiles = 'nara_user_profiles';

  AuthService._internal();

  /// Mendapatkan instance pengguna Firebase saat ini.
  User? get currentFirebaseUser => _firebaseAuth.currentUser;

  /// Stream perubahan state autentikasi Firebase.
  Stream<User?> get authStateChanges => _firebaseAuth.authStateChanges();

  // =========================================================================
  // 1. DAFTAR AKUN BARU (REGISTER DENGAN EMAIL & PASSWORD)
  // =========================================================================

  /// Mendaftarkan pengguna baru ke Firebase Authentication,
  /// menyimpan profil lengkap ke Cloud Firestore (`nara_user_profiles`),
  /// dan menyinkronkannya ke database SQLite lokal NARA.
  Future<UserCredential> registerWithEmailPassword({
    required String nama,
    required String email,
    required String password,
    required String noHp,
    String? asalKota,
  }) async {
    try {
      // 1. Buat user di Firebase Authentication
      final UserCredential userCredential = await _firebaseAuth
          .createUserWithEmailAndPassword(
            email: email.trim(),
            password: password,
          );

      final User? firebaseUser = userCredential.user;
      if (firebaseUser != null) {
        // Update display name di Firebase Auth
        await firebaseUser.updateDisplayName(nama.trim());
      }

      // 2. Siapkan model user lengkap
      final newUser = UserModel(
        nama: nama.trim(),
        email: email.trim(),
        password: password,
        noHp: noHp.trim(),
        asalKota: asalKota?.trim() ?? 'Indonesia',
        rolePetualang: 'Petualang NARA',
        bio: 'Penjelajah alam bebas bersama NARA.',
        golonganDarah: '-',
        kontakDaruratNama: '-',
        kontakDaruratHp: '-',
        organisasi: 'NARA Outdoor Club',
        totalEkspedisi: 0,
        jarakJelajah: '0 km',
        jamTerbang: '0 Jam',
      );

      // 3. Simpan / sinkronkan ke database SQLite lokal
      final existingLocal = await DatabaseHelper.instance.getUserByEmail(email.trim());
      int localUserId;
      if (existingLocal != null && existingLocal.id != null) {
        localUserId = existingLocal.id!;
        await DatabaseHelper.instance.updateUser(newUser.copyWith(id: localUserId));
      } else {
        localUserId = await DatabaseHelper.instance.registerUser(newUser);
      }
      await DatabaseHelper.instance.setActiveUserId(localUserId);

      // 4. Simpan / sinkronkan ke Cloud Firestore
      await syncUserProfileToFirestore(newUser.copyWith(id: localUserId));

      return userCredential;
    } catch (e) {
      debugPrint('[AuthService] Gagal registerWithEmailPassword: $e');
      rethrow;
    }
  }

  // =========================================================================
  // 2. MASUK DENGAN EMAIL & PASSWORD (LOGIN EMAIL / PASSWORD)
  // =========================================================================

  /// Masuk menggunakan Email & Password melalui Firebase Authentication,
  /// lalu menarik data profil dari Firestore untuk sinkronisasi dengan SQLite lokal.
  Future<UserCredential> signInWithEmailPassword({
    required String email,
    required String password,
  }) async {
    try {
      // 1. Autentikasi dengan Firebase Auth
      final UserCredential userCredential = await _firebaseAuth
          .signInWithEmailAndPassword(
            email: email.trim(),
            password: password,
          );

      final User? firebaseUser = userCredential.user;
      final userEmail = firebaseUser?.email ?? email.trim();

      // 2. Ambil profil dari Firestore jika ada
      final cloudProfile = await fetchUserProfileFromFirestore(userEmail);

      // 3. Sinkronkan dengan SQLite lokal
      final existingLocal = await DatabaseHelper.instance.getUserByEmail(userEmail);

      if (cloudProfile != null) {
        if (existingLocal != null && existingLocal.id != null) {
          final merged = cloudProfile.copyWith(id: existingLocal.id, password: password);
          await DatabaseHelper.instance.updateUser(merged);
          await DatabaseHelper.instance.setActiveUserId(existingLocal.id!);
        } else {
          final newId = await DatabaseHelper.instance.registerUser(cloudProfile.copyWith(password: password));
          await DatabaseHelper.instance.setActiveUserId(newId);
        }
      } else if (existingLocal != null && existingLocal.id != null) {
        await DatabaseHelper.instance.setActiveUserId(existingLocal.id!);
        // Cadangkan data lokal ke Cloud Firestore
        await syncUserProfileToFirestore(existingLocal);
      }

      return userCredential;
    } catch (e) {
      debugPrint('[AuthService] Gagal signInWithEmailPassword: $e');
      rethrow;
    }
  }

  // =========================================================================
  // 3. GOOGLE SIGN-IN & OAUTH INTEGRATION
  // =========================================================================

  /// Melakukan Sign-In menggunakan akun Google dan menghubungkannya dengan Firebase Authentication.
  /// Secara otomatis menyinkronkan data pengguna ke database SQLite lokal NARA dan Cloud Firestore.
  Future<UserCredential?> signInWithGoogle() async {
    try {
      // 1. Memulai alur autentikasi Google
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        return null;
      }

      // 2. Mengambil detail token autentikasi dari permintaan Google
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      // 3. Membuat kredensial baru untuk Firebase
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // 4. Masuk ke Firebase menggunakan kredensial Google
      final UserCredential userCredential =
          await _firebaseAuth.signInWithCredential(credential);
      final User? firebaseUser = userCredential.user;

      if (firebaseUser != null) {
        final String email = firebaseUser.email ?? googleUser.email;
        final String displayName =
            firebaseUser.displayName ?? googleUser.displayName ?? 'Petualang NARA';
        final String? photoUrl = firebaseUser.photoURL ?? googleUser.photoUrl;

        // 5. Cek data di Cloud Firestore & SQLite lokal NARA
        final cloudProfile = await fetchUserProfileFromFirestore(email);
        final existingUser = await DatabaseHelper.instance.getUserByEmail(email);

        UserModel userToSave;
        if (cloudProfile != null) {
          userToSave = cloudProfile.copyWith(
            nama: cloudProfile.nama.isNotEmpty ? cloudProfile.nama : displayName,
            fotoProfil: cloudProfile.fotoProfil ?? photoUrl,
          );
        } else if (existingUser != null) {
          userToSave = existingUser.copyWith(
            nama: existingUser.nama.isNotEmpty ? existingUser.nama : displayName,
            fotoProfil: existingUser.fotoProfil ?? photoUrl,
          );
        } else {
          userToSave = UserModel(
            nama: displayName,
            email: email,
            password: 'oauth_google_user',
            noHp: firebaseUser.phoneNumber ?? '-',
            asalKota: 'Indonesia',
            fotoProfil: photoUrl,
            rolePetualang: 'Petualang NARA',
            bio: 'Penjelajah alam bebas bersama NARA.',
            golonganDarah: '-',
            kontakDaruratNama: '-',
            kontakDaruratHp: '-',
            organisasi: 'NARA Outdoor Club',
            totalEkspedisi: 0,
            jarakJelajah: '0 km',
            jamTerbang: '0 Jam',
          );
        }

        if (existingUser != null && existingUser.id != null) {
          userToSave = userToSave.copyWith(id: existingUser.id);
          await DatabaseHelper.instance.updateUser(userToSave);
          await DatabaseHelper.instance.setActiveUserId(existingUser.id!);
        } else {
          final newId = await DatabaseHelper.instance.registerUser(userToSave);
          userToSave = userToSave.copyWith(id: newId);
          await DatabaseHelper.instance.setActiveUserId(newId);
        }

        // Sinkronkan ke Cloud Firestore
        await syncUserProfileToFirestore(userToSave);
      }

      return userCredential;
    } catch (e) {
      debugPrint('[AuthService] Gagal signInWithGoogle: $e');
      rethrow;
    }
  }

  // =========================================================================
  // 4. RESET KATA SANDI (FORGOT PASSWORD VIA FIREBASE)
  // =========================================================================

  /// Mengirimkan email instruksi pemulihan kata sandi resmi dari Firebase Authentication
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _firebaseAuth.sendPasswordResetEmail(email: email.trim());
      debugPrint('[AuthService] Email reset password berhasil dikirim ke $email');
    } catch (e) {
      debugPrint('[AuthService] Gagal mengirim email reset password: $e');
      rethrow;
    }
  }

  // =========================================================================
  // 5. CLOUD FIRESTORE USER PROFILE SYNC (nara_user_profiles)
  // =========================================================================

  /// Menyimpan atau memperbarui profil pengguna ke Cloud Firestore
  Future<void> syncUserProfileToFirestore(UserModel user) async {
    try {
      final docId = user.email.trim().toLowerCase().replaceAll('.', '_');
      final Map<String, dynamic> data = user.toMap();
      data['firebaseUid'] = _firebaseAuth.currentUser?.uid;
      data['updatedAt'] = FieldValue.serverTimestamp();

      await _firestore
          .collection(_collectionProfiles)
          .doc(docId)
          .set(data, SetOptions(merge: true));

      debugPrint(
        '[AuthService] Profil "${user.nama}" ($docId) berhasil disinkronkan ke Firestore.',
      );
    } catch (e) {
      debugPrint('[AuthService] Gagal sinkronisasi profil ke Firestore: $e');
    }
  }

  /// Mengambil data profil pengguna dari Cloud Firestore berdasarkan email
  Future<UserModel?> fetchUserProfileFromFirestore(String email) async {
    try {
      final docId = email.trim().toLowerCase().replaceAll('.', '_');
      final doc = await _firestore.collection(_collectionProfiles).doc(docId).get();
      if (doc.exists && doc.data() != null) {
        return UserModel.fromMap(doc.data()!);
      }
    } catch (e) {
      debugPrint('[AuthService] Gagal mengambil profil dari Firestore: $e');
    }
    return null;
  }

  // =========================================================================
  // 6. SIGN OUT
  // =========================================================================

  /// Melakukan Sign Out dari Firebase & Google Sign In.
  Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
      await _firebaseAuth.signOut();
    } catch (_) {}
  }
}
