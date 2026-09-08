class AreaModel {
  final String id;
  final String nama;
  final String lokasi;
  final String ukuran;
  final String coordinates;
  final String type;
  bool isDownloaded;
  double progress;

  AreaModel({
    required this.id,
    required this.nama,
    required this.lokasi,
    required this.ukuran,
    this.coordinates = '',
    this.type = 'Tebing',
    this.isDownloaded = false,
    this.progress = 0.0,
  });
}

class MapRepository {
  // Database Simulasi Peta Offline Tebing & Goa
  static final List<AreaModel> _allMaps = [
    AreaModel(
      id: '1',
      nama: 'Tebing Citatah 125',
      lokasi: 'Padalarang, Bandung Barat',
      ukuran: '450 MB',
      coordinates: '6°50\'25.8"S 107°27\'06.5"E',
      type: 'Tebing Panjat',
      isDownloaded: true,
      progress: 1.0,
    ),
    AreaModel(
      id: '2',
      nama: 'Gunung Parang',
      lokasi: 'Purwakarta, Jawa Barat',
      ukuran: '180 MB',
      coordinates: '6°35\'28.3"S 107°21\'04.3"E',
      type: 'Tebing Panjat',
      isDownloaded: true,
      progress: 1.0,
    ),
    AreaModel(
      id: '3',
      nama: 'Tebing Siung',
      lokasi: 'Gunungkidul, D.I. Yogyakarta',
      ukuran: '320 MB',
      coordinates: '8°10\'54.8"S 110°41\'00.0"E',
      type: 'Tebing Panjat',
      isDownloaded: true,
      progress: 1.0,
    ),
    AreaModel(
      id: '4',
      nama: 'Goa Jomblang',
      lokasi: 'Gunungkidul, D.I. Yogyakarta',
      ukuran: '250 MB',
      coordinates: '8°01\'43.3"S 110°38\'18.2"E',
      type: 'Goa Karst',
      isDownloaded: true,
      progress: 1.0,
    ),
    AreaModel(
      id: '5',
      nama: 'Goa Pindul',
      lokasi: 'Gunungkidul, D.I. Yogyakarta',
      ukuran: '150 MB',
      coordinates: '7°56\'04.9"S 110°38\'56.0"E',
      type: 'Goa Karst',
      isDownloaded: true,
      progress: 1.0,
    ),
    AreaModel(
      id: '6',
      nama: 'Tebing Lembah Harau',
      lokasi: 'Lima Puluh Kota, Sumatera Barat',
      ukuran: '500 MB',
      coordinates: '0°05\'55.3"S 100°39\'55.1"E',
      type: 'Tebing Panjat',
    ),
    AreaModel(
      id: '7',
      nama: 'Tebing Hawu',
      lokasi: 'Padalarang, Bandung Barat',
      ukuran: '210 MB',
      coordinates: '6°49\'55.2"S 107°26\'49.2"E',
      type: 'Tebing Panjat',
    ),
    AreaModel(
      id: '8',
      nama: 'Karst Maros-Pangkep',
      lokasi: 'Maros, Sulawesi Selatan',
      ukuran: '800 MB',
      coordinates: '4°59\'46.0"S 119°41\'00.0"E',
      type: 'Goa Karst',
    ),
    AreaModel(
      id: '9',
      nama: 'Goa Gong',
      lokasi: 'Pacitan, Jawa Timur',
      ukuran: '310 MB',
      coordinates: '8°09\'47.9"S 110°58\'50.2"E',
      type: 'Goa Karst',
    ),
    AreaModel(
      id: '10',
      nama: 'Goa Cerme',
      lokasi: 'Bantul, D.I. Yogyakarta',
      ukuran: '190 MB',
      coordinates: '7°56\'21.1"S 110°23\'44.2"E',
      type: 'Goa Karst',
    ),
  ];

  // Ambil semua peta yang belum di-download
  static List<AreaModel> getAvailableMaps() {
    return _allMaps.where((map) => !map.isDownloaded).toList();
  }

  // Ambil semua peta yang sudah di-download
  static List<AreaModel> getDownloadedMaps() {
    return _allMaps.where((map) => map.isDownloaded).toList();
  }

  // Tandai peta selesai download
  static void markAsDownloaded(String id) {
    final index = _allMaps.indexWhere((m) => m.id == id);
    if (index != -1) {
      _allMaps[index].isDownloaded = true;
      _allMaps[index].progress = 1.0;
    }
  }
}
