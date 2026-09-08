import 'package:flutter/material.dart';

// =========================================================================
// MODEL & KNOWLEDGE BASE PERAWATAN ALAT GOA & TEBING (NARA OUTDOOR)
// =========================================================================

class RetirementCriterion {
  final IconData icon;
  final String title;
  final String description;

  const RetirementCriterion({
    required this.icon,
    required this.title,
    this.description = '',
  });
}

class CareGuideModel {
  final String heroTitle;
  final String heroSubtitle;
  final String heroImageUrl;
  final String cleaningTitle;
  final String cleaningDesc;
  final String dryingTitle;
  final String dryingDesc;
  final String storageTitle;
  final String storageDesc;
  final List<String> storageRules;
  final String storageImageUrl;
  final String safetyDesc;
  final List<RetirementCriterion> retirementCriteria;

  const CareGuideModel({
    required this.heroTitle,
    required this.heroSubtitle,
    required this.heroImageUrl,
    required this.cleaningTitle,
    required this.cleaningDesc,
    required this.dryingTitle,
    required this.dryingDesc,
    required this.storageTitle,
    required this.storageDesc,
    required this.storageRules,
    required this.storageImageUrl,
    required this.safetyDesc,
    required this.retirementCriteria,
  });
}

class GearItem {
  final String id;
  final String categoryId;
  final String title;
  String subtitle;
  final IconData icon;
  bool isReady;
  DateTime? lastMaintenanceDate;
  String? lastMaintenanceNote;
  final CareGuideModel? customCareGuide;

  GearItem({
    required this.id,
    required this.categoryId,
    required this.title,
    required this.subtitle,
    required this.icon,
    this.isReady = false,
    this.lastMaintenanceDate,
    this.lastMaintenanceNote,
    this.customCareGuide,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'categoryId': categoryId,
      'title': title,
      'subtitle': subtitle,
      'icon': icon,
      'isReady': isReady,
      'lastMaintenanceDate': lastMaintenanceDate,
      'lastMaintenanceNote': lastMaintenanceNote,
    };
  }
}

class GearCategory {
  final String id;
  final String title;
  final IconData icon;
  final String description;
  final List<GearItem> items;

  GearCategory({
    required this.id,
    required this.title,
    required this.icon,
    required this.description,
    required this.items,
  });
}

// =========================================================================
// CENTRAL GEAR MANAGER & SYNC SERVICE (SINGLETON + VALUE NOTIFIER)
// =========================================================================

class GearManager extends ChangeNotifier {
  static final GearManager _instance = GearManager._internal();
  factory GearManager() => _instance;

  GearManager._internal() {
    _initDefaultData();
  }

  static GearManager get instance => _instance;

  // Master Categories & Items
  final List<GearCategory> _categories = [];
  List<GearCategory> get categories => List.unmodifiable(_categories);

  // Fallback static accessor for backward compatibility
  static List<Map<String, dynamic>> get staticCategoriesCompat {
    return _instance._categories.map((cat) {
      return {
        'id': cat.id,
        'icon': cat.icon,
        'title': cat.title,
        'items': cat.items.map((item) => item.toMap()).toList(),
      };
    }).toList();
  }

  static int get totalCount => _instance._calculateTotalCount();
  static int get readyCount => _instance._calculateReadyCount();
  static bool get isAllReady => _instance._calculateIsAllReady();

  int _calculateTotalCount() {
    int count = 0;
    for (var cat in _categories) {
      count += cat.items.length;
    }
    return count;
  }

  int _calculateReadyCount() {
    int count = 0;
    for (var cat in _categories) {
      count += cat.items.where((i) => i.isReady).length;
    }
    return count;
  }

  bool _calculateIsAllReady() {
    final total = _calculateTotalCount();
    return total > 0 && _calculateReadyCount() == total;
  }

  int get totalGearCount => _calculateTotalCount();
  int get readyGearCount => _calculateReadyCount();
  bool get isAllGearReady => _calculateIsAllReady();

  // Mencari GearItem berdasarkan ID
  GearItem? findItemById(String itemId) {
    for (var cat in _categories) {
      for (var item in cat.items) {
        if (item.id == itemId) return item;
      }
    }
    return null;
  }

  // Toggle status kesiapan alat
  void toggleItemStatus(String itemId) {
    final item = findItemById(itemId);
    if (item != null) {
      item.isReady = !item.isReady;
      if (item.isReady) {
        item.subtitle = 'Kondisi Baik & Siap Digunakan';
      } else {
        item.subtitle = 'Belum diverifikasi kelayakannya';
      }
      notifyListeners();
    }
  }

  // Log perawatan baru & tandai alat siap
  void recordMaintenance(String itemId, {String note = 'Pembersihan & inspeksi berkala selesai dilakukan.'}) {
    final item = findItemById(itemId);
    if (item != null) {
      item.isReady = true;
      item.lastMaintenanceDate = DateTime.now();
      item.lastMaintenanceNote = note;
      item.subtitle = 'Selesai dirawat (${_formatDate(DateTime.now())})';
      notifyListeners();
    }
  }

  // Menambah Alat Baru
  void addNewGear({
    required String categoryId,
    required String title,
    required String subtitle,
    required bool isReady,
  }) {
    final catIndex = _categories.indexWhere((c) => c.id == categoryId || c.title == categoryId);
    if (catIndex != -1) {
      final targetCat = _categories[catIndex];
      IconData itemIcon = _resolveIconForNewGear(targetCat.id, title);

      final newItem = GearItem(
        id: 'gear_${DateTime.now().millisecondsSinceEpoch}',
        categoryId: targetCat.id,
        title: title,
        subtitle: subtitle.trim().isEmpty
            ? (isReady ? 'Kondisi Baik & Siap' : 'Belum diverifikasi kelayakannya')
            : subtitle.trim(),
        icon: itemIcon,
        isReady: isReady,
        lastMaintenanceDate: isReady ? DateTime.now() : null,
        lastMaintenanceNote: isReady ? 'Inisialisasi alat baru siap pakai.' : null,
      );

      targetCat.items.add(newItem);
      notifyListeners();
    }
  }

  IconData _resolveIconForNewGear(String categoryId, String title) {
    final lowerTitle = title.toLowerCase();
    if (lowerTitle.contains('tali') || lowerTitle.contains('rope') || lowerTitle.contains('sling') || lowerTitle.contains('webbing') || lowerTitle.contains('cowstail')) {
      return Icons.link_rounded;
    }
    if (lowerTitle.contains('harness') || lowerTitle.contains('seat') || lowerTitle.contains('chest')) {
      return Icons.accessibility_new_rounded;
    }
    if (lowerTitle.contains('helm') || lowerTitle.contains('helmet')) {
      return Icons.sports_motorsports_rounded;
    }
    if (lowerTitle.contains('karabiner') || lowerTitle.contains('carabiner') || lowerTitle.contains('quickdraw')) {
      return Icons.lock_outline_rounded;
    }
    if (lowerTitle.contains('lampu') || lowerTitle.contains('headlamp') || lowerTitle.contains('senter')) {
      return Icons.flashlight_on_rounded;
    }
    if (lowerTitle.contains('descender') || lowerTitle.contains('ascender') || lowerTitle.contains('jumar') || lowerTitle.contains('stop')) {
      return Icons.anchor_rounded;
    }
    if (lowerTitle.contains('baju') || lowerTitle.contains('wearpack') || lowerTitle.contains('coverall')) {
      return Icons.dry_cleaning_rounded;
    }
    if (lowerTitle.contains('sepatu') || lowerTitle.contains('boots')) {
      return Icons.hiking_rounded;
    }

    if (categoryId == 'tali_keamanan') return Icons.shield_outlined;
    if (categoryId == 'hardware') return Icons.handyman_rounded;
    if (categoryId == 'penerangan') return Icons.flashlight_on_rounded;
    if (categoryId == 'kebutuhan_goa') return Icons.explore_rounded;
    return Icons.construction_rounded;
  }

  // =========================================================================
  // BASIS PENGETAHUAN PANDUAN PERAWATAN ALAT (AUTO-SYNC ENGINE)
  // =========================================================================

  CareGuideModel getCareGuideForItem(GearItem item) {
    if (item.customCareGuide != null) {
      return item.customCareGuide!;
    }

    final lowerTitle = item.title.toLowerCase();
    final catId = item.categoryId.toLowerCase();

    // 1. Tali Dinamis / Tali Statis / Webbing
    if (lowerTitle.contains('tali') || lowerTitle.contains('rope') || lowerTitle.contains('sling') || lowerTitle.contains('cowstail')) {
      final isDynamic = lowerTitle.contains('dinamis') || lowerTitle.contains('dynamic');
      return CareGuideModel(
        heroTitle: isDynamic ? 'Merawat Tali Dinamis Keselamatan' : 'Merawat Tali Statis Speleologi',
        heroSubtitle: 'Panduan standar pemeliharaan, pencucian tanpa merusak inti kernmantle, dan inspeksi taktil berkala.',
        heroImageUrl: 'https://lh3.googleusercontent.com/aida-public/AB6AXuD_dxMrFHdVRzjwjDrqp8lZkxNOWMuqK-gIezGXHzOkSddQo6C1Wb8BVZwVKfAHwZxQKwd3rpPN013aHaPsqDwFCQRfuSAvy7Fqce2MTetr5thX4rD6yEvwukgvF3Rmq9VHtnhuKq-w27pGCV_A088z61VCOOLQgrPATZruqhq1NE07TKHNAmxQKTp69qhsh-aY35BSzvTmMrNhHIZ9_7IN6Q9np-rr7ogdfn-k3mPyL6c_aqrFpMgw',
        cleaningTitle: 'Pembersihan Ringan',
        cleaningDesc: 'Gunakan air dingin (<30°C) dan sabun khusus tali berbahan lembut (non-deterjen). Sikat perlahan dengan sikat spiral/sikat nylon halus untuk merontokkan lumpur goa dan partikel kristal kuarsa yang bisa mengikis serat inti.',
        dryingTitle: 'Proses Pengeringan',
        dryingDesc: 'Keringkan dengan cara diangin-anginkan di tempat teduh dan sirkulasi lancar. DILARANG keras menjemur di bawah terik matahari langsung atau memakai hair dryer/pemanas yang dapat merusak elastisitas poliamida.',
        storageTitle: 'Penyimpanan Ideal',
        storageDesc: 'Penyimpanan yang tepat menjaga umur tali tetap prima hingga 5-10 tahun. Pastikan tali 100% kering sebelum masuk ke dalam rope bag.',
        storageRules: [
          'Teknik Kumparan Kupu-kupu (Butterfly Coil) atau susun rapi dalam Rope Bag berpori.',
          'Suhu & Kelembapan: Simpan di ruangan sejuk (15-20°C), kering, dan bebas dari tikus.',
          'Bebas Bahan Kimia: Jauhkan dari asam baterai aki/headlamp, cairan pemutih, pelarut minyak, atau bensin.',
        ],
        storageImageUrl: 'https://lh3.googleusercontent.com/aida-public/AB6AXuAtSA_5Oc7vpbHgtd-2XyVhlyM9BSx01eQXNFAau_z1cmuKM9tSjjSOU_cfoCEDZrQKzxswVoawYM16pZlrvDQ8PjBC2M0_kAWJ9zILw7GR0MLquoR9RbvY5kof8LS9B2YGV47MjL8xfYqvBKRnKrRMl4emkoC-vcr-eLMCi34xyTzwhQSthNPNaCkurUg219CpvcPUod2S4r1YHCXoc1CCkwtKIzsLFKiTI9Ofgcse8vCtki4TnWRI',
        safetyDesc: 'Lakukan inspeksi taktil (meraba seluruh panjang tali) dan visual sebelum dan sesudah ekspedisi. Tali wajib segera dipensiunkan jika ditemukan:',
        retirementCriteria: const [
          RetirementCriterion(icon: Icons.content_cut_rounded, title: 'Kerusakan Selubung (Sheath) Parah'),
          RetirementCriterion(icon: Icons.visibility_rounded, title: 'Inti Putih (Core) Terlihat Keluar'),
          RetirementCriterion(icon: Icons.line_weight_rounded, title: 'Perubahan Diameter / Terjepit Drastis'),
          RetirementCriterion(icon: Icons.do_not_touch_rounded, title: 'Terasa Keras, Hangus, atau Kaku Ekstrem'),
        ],
      );
    }

    // 2. Harness & Pelindung Tubuh
    if (lowerTitle.contains('harness') || lowerTitle.contains('sabuk') || lowerTitle.contains('chest')) {
      return CareGuideModel(
        heroTitle: 'Merawat Harness & Sabuk Tubuh',
        heroSubtitle: 'Menjaga kekuatan jahitan webbing penahan beban tubuh dan ketahanan gesekan lumpur goa.',
        heroImageUrl: 'https://images.unsplash.com/photo-1522163182402-834f871fd851?auto=format&fit=crop&w=1000&q=80',
        cleaningTitle: 'Pembersihan Webbing & Pad',
        cleaningDesc: 'Bilas dengan air bersih suam-suam kuku setelah terkena lumpur goa atau keringat garam. Gunakan sikat berbulu lembut pada webbing dan buckle logam. Jangan gunakan pelarut korosif.',
        dryingTitle: 'Pengeringan Alami',
        dryingDesc: 'Gantung harness di tempat teduh dengan sirkulasi udara baik. Hindari paparan sinar UV matahari berlebihan yang dapat mendegradasi poliester.',
        storageTitle: 'Penyimpanan Harness',
        storageDesc: 'Simpan harness dalam kantong jaring berventilasi agar busa bantalan tidak lembap dan buckle tidak berkarat.',
        storageRules: [
          'Gantung bebas atau simpan dalam mesh pouch bawaan tanpa tertindih alat berat.',
          'Pastikan buckle logam dilapisi lapisan tipis silikon food-grade jika disimpan lama.',
          'Hindari kontak langsung dengan asam, minyak gemuk kotor, atau zat pembersih keras.',
        ],
        storageImageUrl: 'https://images.unsplash.com/photo-1583863788434-e58a36330cf0?auto=format&fit=crop&w=1000&q=80',
        safetyDesc: 'Lakukan inspeksi visual jahitan pengaman (bar-tack) dan ring logam sebelum digunakan. Segera pensiunkan jika:',
        retirementCriteria: const [
          RetirementCriterion(icon: Icons.content_cut_rounded, title: 'Benang Jahitan Bar-tack Terputus/Aus'),
          RetirementCriterion(icon: Icons.shield_outlined, title: 'Belay Loop Terkikis Gesekan >10%'),
          RetirementCriterion(icon: Icons.warning_amber_rounded, title: 'Buckle Logam Retak atau Bengkok'),
          RetirementCriterion(icon: Icons.history_rounded, title: 'Masa Pakai Melebihi 7-10 Tahun'),
        ],
      );
    }

    // 3. Hardware (Carabiner, Quickdraw, Belay Device, Descender, Ascender/Jumar)
    if (catId == 'hardware' || lowerTitle.contains('carabiner') || lowerTitle.contains('karabiner') || lowerTitle.contains('quickdraw') || lowerTitle.contains('belay') || lowerTitle.contains('descender') || lowerTitle.contains('ascender') || lowerTitle.contains('jumar') || lowerTitle.contains('stop')) {
      return CareGuideModel(
        heroTitle: 'Merawat Logam & Perangkat SRT/Belay',
        heroSubtitle: 'Mencegah korosi, keausan alur gesekan tali, dan macetnya pegas gerbang autolock/cam jumar.',
        heroImageUrl: 'https://images.unsplash.com/photo-1544441893-675973e31985?auto=format&fit=crop&w=1000&q=80',
        cleaningTitle: 'Pencucian Lumpur & Kerikil',
        cleaningDesc: 'Rendam perangkat dalam air hangat untuk melarutkan lumpur goa yang menyumbat pegas cam jumar atau ulir karabiner. Sikat celah bergerak dengan sikat gigi bekas.',
        dryingTitle: 'Pengeringan & Lubrikasi',
        dryingDesc: 'Keringkan dengan kain microfiber sampai tuntas. Berikan setetes pelumas berbasis PTFE kering (dry silicone) pada poros pegas/cam, lalu seka sisa cairan.',
        storageTitle: 'Penyimpanan Hardware',
        storageDesc: 'Simpan perangkat logam di tempat kering dengan kantong silica gel untuk mencegah oksidasi dan korosi galvanik.',
        storageRules: [
          'Pisahkan komponen aluminium dan baja saat penyimpanan jangka panjang.',
          'Pastikan gerbang karabiner dan cam jumar dapat bergerak membal secara spontan.',
          'Jauhkan dari uap asam aki atau udara lembap bersulfur tinggi.',
        ],
        storageImageUrl: 'https://images.unsplash.com/photo-1516592673884-4a382d1124c2?auto=format&fit=crop&w=1000&q=80',
        safetyDesc: 'Periksa keausan alur tali (groove wear) dan kelurusan struktur logam. Pensiunkan segera jika:',
        retirementCriteria: const [
          RetirementCriterion(icon: Icons.broken_image_rounded, title: 'Ditemukan Retak Rambut (Hairline Crack)'),
          RetirementCriterion(icon: Icons.compress_rounded, title: 'Keausan Gesekan Tali >1mm / Alur Dalam'),
          RetirementCriterion(icon: Icons.lock_clock_rounded, title: 'Gerbang / Cam Macet dan Tidak Membal'),
          RetirementCriterion(icon: Icons.gpp_bad_rounded, title: 'Jatuh Bebas dari Ketinggian >5 Meter ke Batu'),
        ],
      );
    }

    // 4. Penerangan & Elektronik (Headlamp, Baterai, GPS)
    if (catId == 'penerangan' || lowerTitle.contains('headlamp') || lowerTitle.contains('lampu') || lowerTitle.contains('baterai') || lowerTitle.contains('senter')) {
      return CareGuideModel(
        heroTitle: 'Merawat Headlamp & Sistem Penerangan',
        heroSubtitle: 'Mempertahankan integritas segel tahan air (O-ring IPX8) dan daya tahan baterai lithium.',
        heroImageUrl: 'https://images.unsplash.com/photo-1510312305653-8ed496efae75?auto=format&fit=crop&w=1000&q=80',
        cleaningTitle: 'Pembersihan Kaca Lensa & Body',
        cleaningDesc: 'Lap body headlamp dengan kain lembap bersih. Bersihkan lumpur di celah tombol dan lensa dengan cotton bud. Jangan gunakan alkohol pada karet seal.',
        dryingTitle: 'Pengecekan Kompartemen',
        dryingDesc: 'Buka slot baterai setelah pemakaian di lingkungan goa berair/lembab tinggi untuk memastikan tidak ada kondensasi di dalam kompartemen.',
        storageTitle: 'Penyimpanan Elektronik',
        storageDesc: 'Simpan headlamp di dalam dry box atau hard case khusus outdoor bersama silica gel.',
        storageRules: [
          'Lepaskan baterai jika alat tidak akan digunakan dalam kurun waktu lebih dari 2 minggu.',
          'Lumasi O-ring karet secara berkala dengan petroleum jelly / silikon grease.',
          'Isi daya baterai lithium minimal 50-70% sebelum disimpan dalam waktu lama.',
        ],
        storageImageUrl: 'https://images.unsplash.com/photo-1508873696983-2df5293cb32b?auto=format&fit=crop&w=1000&q=80',
        safetyDesc: 'Pastikan keandalan optik dan kelistrikan sebelum memasuki medan gelap goa. Ganti jika:',
        retirementCriteria: const [
          RetirementCriterion(icon: Icons.battery_alert_rounded, title: 'Baterai Menggelembung atau Korosi Terminal'),
          RetirementCriterion(icon: Icons.water_damage_rounded, title: 'Segel Karet O-ring Robek / Bocor Air'),
          RetirementCriterion(icon: Icons.lightbulb_outline_rounded, title: 'Lensa Retak Mengurangi Jarak Sorot'),
          RetirementCriterion(icon: Icons.electric_bolt_rounded, title: 'Sistem Elektronik Mati Mendadak / Overheat'),
        ],
      );
    }

    // 5. Kebutuhan Khusus Goa (Wearpack Caving, Boots, Kneepad, Helm Caving)
    if (catId == 'kebutuhan_goa' || lowerTitle.contains('wearpack') || lowerTitle.contains('coverall') || lowerTitle.contains('helm') || lowerTitle.contains('kneepad') || lowerTitle.contains('boots') || lowerTitle.contains('sepatu')) {
      return CareGuideModel(
        heroTitle: 'Merawat Perlengkapan Speleologi / Goa',
        heroSubtitle: 'Melindungi coverall PVC dan pelindung tubuh dari abrasi tajam stalaktit dan lumpur asam.',
        heroImageUrl: 'https://images.unsplash.com/photo-1506744038136-46273834b3fb?auto=format&fit=crop&w=1000&q=80',
        cleaningTitle: 'Pencucian Lumpur Berat',
        cleaningDesc: 'Semprot wearpack dan boots dengan selang air bertekanan sedang segera setelah keluar goa. Jangan biarkan lumpur mengering dan mengeras pada ritsleting atau jahitan sintetis.',
        dryingTitle: 'Pengeringan Sempurna',
        dryingDesc: 'Balik coverall dan gantung di tempat teduh berangin. Pastikan bagian dalam benar-benar kering sebelum disimpan untuk mencegah timbulnya jamur bau.',
        storageTitle: 'Penyimpanan Perlengkapan Goa',
        storageDesc: 'Simpan di lemari berventilasi baik jauh dari paparan cahaya matahari langsung dan panas atap.',
        storageRules: [
          'Gantung wearpack lurus tanpa lipatan tajam yang dapat memicu retak lapisan PVC.',
          'Beri pelumas lilin lebah (beeswax) pada ritsleting logam/plastik tahan karat.',
          'Pastikan bagian busa helm dan bantalan lutut telah steril dan kering.',
        ],
        storageImageUrl: 'https://images.unsplash.com/photo-1464822759023-fed622ff2c3b?auto=format&fit=crop&w=1000&q=80',
        safetyDesc: 'Pemeriksaan integritas pelindung benturan dan jahitan penutup tubuh:',
        retirementCriteria: const [
          RetirementCriterion(icon: Icons.sports_motorsports_rounded, title: 'Cangkang Helm Retak / Busa EPS Rusak'),
          RetirementCriterion(icon: Icons.content_cut_rounded, title: 'Robekan Besar pada Bagian Kunci Wearpack'),
          RetirementCriterion(icon: Icons.do_not_step_rounded, title: 'Outsole Boots Licin / Tapak Gundul'),
          RetirementCriterion(icon: Icons.shield_moon_rounded, title: 'Bantalan Kneepad Pecah atau Pipih Total'),
        ],
      );
    }

    // Default Fallback Guide untuk Custom Tools
    return CareGuideModel(
      heroTitle: 'Panduan Perawatan ${item.title}',
      heroSubtitle: 'Menjaga performa, kebersihan, dan keselamatan penggunaan peralatan ekspedisi outdoor.',
      heroImageUrl: 'https://lh3.googleusercontent.com/aida-public/AB6AXuD_dxMrFHdVRzjwjDrqp8lZkxNOWMuqK-gIezGXHzOkSddQo6C1Wb8BVZwVKfAHwZxQKwd3rpPN013aHaPsqDwFCQRfuSAvy7Fqce2MTetr5thX4rD6yEvwukgvF3Rmq9VHtnhuKq-w27pGCV_A088z61VCOOLQgrPATZruqhq1NE07TKHNAmxQKTp69qhsh-aY35BSzvTmMrNhHIZ9_7IN6Q9np-rr7ogdfn-k3mPyL6c_aqrFpMgw',
      cleaningTitle: 'Pembersihan Standar',
      cleaningDesc: 'Bersihkan kotoran, debu, dan partikel tanah menggunakan kain basah dan sabun lembut berbahan netral. Hindari penggunaan deterjen keras atau sikat kawat.',
      dryingTitle: 'Pengeringan Alami',
      dryingDesc: 'Angin-anginkan di tempat terlindung dari terik matahari langsung hingga kering sempurna sebelum disimpan.',
      storageTitle: 'Penyimpanan Rapi & Kering',
      storageDesc: 'Simpan di ruangan yang memiliki ventilasi memadai, kering, dan bebas dari kelembapan tinggi.',
      storageRules: [
        'Simpan pada kotak atau rak penyimpanan khusus alat ekspedisi.',
        'Jauhkan dari kontak langsung dengan zat kimia agresif atau suhu ekstrem.',
        'Lakukan pengecekan berkala setiap 3-6 bulan meski alat jarang digunakan.',
      ],
      storageImageUrl: 'https://lh3.googleusercontent.com/aida-public/AB6AXuAtSA_5Oc7vpbHgtd-2XyVhlyM9BSx01eQXNFAau_z1cmuKM9tSjjSOU_cfoCEDZrQKzxswVoawYM16pZlrvDQ8PjBC2M0_kAWJ9zILw7GR0MLquoR9RbvY5kof8LS9B2YGV47MjL8xfYqvBKRnKrRMl4emkoC-vcr-eLMCi34xyTzwhQSthNPNaCkurUg219CpvcPUod2S4r1YHCXoc1CCkwtKIzsLFKiTI9Ofgcse8vCtki4TnWRI',
      safetyDesc: 'Lakukan pemeriksaan visual menyeluruh sebelum digunakan ke medan lapangan:',
      retirementCriteria: const [
        RetirementCriterion(icon: Icons.warning_amber_rounded, title: 'Terjadi Deformasi Fisik atau Bengkok'),
        RetirementCriterion(icon: Icons.broken_image_rounded, title: 'Keretakan atau Kerusakan Komponen Kritis'),
        RetirementCriterion(icon: Icons.do_not_touch_rounded, title: 'Fungsi Mekanikal Macet atau Tidak Presisi'),
        RetirementCriterion(icon: Icons.history_rounded, title: 'Melewati Batas Usia Rekomendasi Pabrik'),
      ],
    );
  }

  String _formatDate(DateTime dt) {
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
      'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'
    ];
    return '${dt.day} ${months[dt.month - 1]} ${dt.year}';
  }

  // =========================================================================
  // INISIALISASI DATA MASTER ALAT KEBUTUHAN GOA & TEBING
  // =========================================================================

  void _initDefaultData() {
    _categories.clear();

    // 1. Kategori: Tali & Keamanan
    _categories.add(
      GearCategory(
        id: 'tali_keamanan',
        title: 'Tali & Keamanan',
        icon: Icons.shield_outlined,
        description: 'Tali dinamis, harness panjat & caving, cowstail, dan pelindung kepala.',
        items: [
          GearItem(
            id: 'tk_1',
            categoryId: 'tali_keamanan',
            icon: Icons.link_rounded,
            title: 'Dynamic Rope 9.8mm 60m',
            subtitle: 'Kondisi Baik & Siap Digunakan',
            isReady: true,
            lastMaintenanceDate: DateTime.now().subtract(const Duration(days: 4)),
            lastMaintenanceNote: 'Dicuci air dingin & lolos inspeksi taktil.',
          ),
          GearItem(
            id: 'tk_2',
            categoryId: 'tali_keamanan',
            icon: Icons.link_rounded,
            title: 'Static Rope Caving 10mm 100m',
            subtitle: 'Kondisi Baik & Siap Digunakan',
            isReady: true,
            lastMaintenanceDate: DateTime.now().subtract(const Duration(days: 6)),
            lastMaintenanceNote: 'Inspeksi selubung lolos uji kelayakan.',
          ),
          GearItem(
            id: 'tk_3',
            categoryId: 'tali_keamanan',
            icon: Icons.accessibility_new_rounded,
            title: 'Harness Petzl Fractio Caving',
            subtitle: 'Kondisi Baik & Siap Digunakan',
            isReady: true,
            lastMaintenanceDate: DateTime.now().subtract(const Duration(days: 7)),
            lastMaintenanceNote: 'Jahitan bar-tack utuh.',
          ),
          GearItem(
            id: 'tk_4',
            categoryId: 'tali_keamanan',
            icon: Icons.sports_motorsports_rounded,
            title: 'Helm Panjat & Caving Petzl Boreo',
            subtitle: 'Belum diverifikasi kelayakannya',
            isReady: false,
          ),
        ],
      ),
    );

    // 2. Kategori: Hardware & Rigging
    _categories.add(
      GearCategory(
        id: 'hardware',
        title: 'Hardware',
        icon: Icons.handyman_outlined,
        description: 'Karabiner, Quickdraw, Descender Petzl Stop, Belay Device, & Ascender Jumar.',
        items: [
          GearItem(
            id: 'hw_1',
            categoryId: 'hardware',
            icon: Icons.lock_outline_rounded,
            title: 'Quickdraw Set x12 Petzl Djinn',
            subtitle: 'Belum diverifikasi kelayakannya',
            isReady: false,
          ),
          GearItem(
            id: 'hw_2',
            categoryId: 'hardware',
            icon: Icons.anchor_rounded,
            title: 'Descender Petzl Stop (Goa/SRT)',
            subtitle: 'Kondisi Baik & Siap Digunakan',
            isReady: true,
            lastMaintenanceDate: DateTime.now().subtract(const Duration(days: 3)),
            lastMaintenanceNote: 'Poros cam dilumasi dry silicone.',
          ),
          GearItem(
            id: 'hw_3',
            categoryId: 'hardware',
            icon: Icons.vertical_align_top_rounded,
            title: 'Ascender Jumar + Chest Croll',
            subtitle: 'Kondisi Baik & Siap Digunakan',
            isReady: true,
            lastMaintenanceDate: DateTime.now().subtract(const Duration(days: 3)),
            lastMaintenanceNote: 'Gigi cam bersih dari tanah goa.',
          ),
          GearItem(
            id: 'hw_4',
            categoryId: 'hardware',
            icon: Icons.anchor_rounded,
            title: 'Belay Device GriGri / ATC',
            subtitle: 'Lancar & Siap Pakai',
            isReady: true,
          ),
        ],
      ),
    );

    // 3. Kategori: Penerangan & Elektronik
    _categories.add(
      GearCategory(
        id: 'penerangan',
        title: 'Penerangan',
        icon: Icons.flashlight_on_outlined,
        description: 'Headlamp waterproof goa, baterai cadangan, dan lampu darurat.',
        items: [
          GearItem(
            id: 'pen_1',
            categoryId: 'penerangan',
            icon: Icons.flashlight_on_rounded,
            title: 'Headlamp Petzl Duo S (IP67)',
            subtitle: 'Baterai perlu diisi ulang',
            isReady: false,
          ),
          GearItem(
            id: 'pen_2',
            categoryId: 'penerangan',
            icon: Icons.battery_charging_full_rounded,
            title: 'Baterai Cadangan & Dry Bag',
            subtitle: 'Kondisi Baik & Terisi Penuh',
            isReady: true,
          ),
        ],
      ),
    );

    // 4. Kategori: Kebutuhan Khusus Goa (Caving Essentials)
    _categories.add(
      GearCategory(
        id: 'kebutuhan_goa',
        title: 'Kebutuhan Goa',
        icon: Icons.explore_outlined,
        description: 'Wearpack PVC Caving, Boots anti slip, Footloop, & Kneepad protektor.',
        items: [
          GearItem(
            id: 'goa_1',
            categoryId: 'kebutuhan_goa',
            icon: Icons.dry_cleaning_rounded,
            title: 'Wearpack Caving PVC Aventure',
            subtitle: 'Kondisi Baik & Siap Digunakan',
            isReady: true,
            lastMaintenanceDate: DateTime.now().subtract(const Duration(days: 5)),
            lastMaintenanceNote: 'Dibersihkan dari lumpur goa dan ritsleting dilumasi.',
          ),
          GearItem(
            id: 'goa_2',
            categoryId: 'kebutuhan_goa',
            icon: Icons.hiking_rounded,
            title: 'Boots Karet Anti-Slip Caving',
            subtitle: 'Kondisi Baik & Siap Digunakan',
            isReady: true,
          ),
          GearItem(
            id: 'goa_3',
            categoryId: 'kebutuhan_goa',
            icon: Icons.airline_stops_rounded,
            title: 'Footloop SRT Caving Webbing',
            subtitle: 'Belum diverifikasi kelayakannya',
            isReady: false,
          ),
        ],
      ),
    );
  }
}
