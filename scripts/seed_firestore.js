const https = require('https');

const PROJECT_ID = 'nara-524a9';
const BASE_HOST = 'firestore.googleapis.com';
const BASE_PATH = `/v1/projects/${PROJECT_ID}/databases/(default)/documents`;

function toFirestoreValue(val) {
  if (val === null || val === undefined) {
    return { nullValue: null };
  }
  if (typeof val === 'boolean') {
    return { booleanValue: val };
  }
  if (typeof val === 'number') {
    if (Number.isInteger(val)) {
      return { integerValue: val.toString() };
    }
    return { doubleValue: val };
  }
  if (typeof val === 'string') {
    return { stringValue: val };
  }
  if (Array.isArray(val)) {
    return {
      arrayValue: {
        values: val.map(toFirestoreValue)
      }
    };
  }
  if (typeof val === 'object') {
    const fields = {};
    for (const [k, v] of Object.entries(val)) {
      fields[k] = toFirestoreValue(v);
    }
    return {
      mapValue: { fields }
    };
  }
  return { stringValue: String(val) };
}

function objectToFirestoreFields(obj) {
  const fields = {};
  for (const [key, val] of Object.entries(obj)) {
    fields[key] = toFirestoreValue(val);
  }
  return { fields };
}

function setFirestoreDocument(docPath, data) {
  return new Promise((resolve, reject) => {
    const payload = JSON.stringify(objectToFirestoreFields(data));
    const path = `${BASE_PATH}/${docPath}`;

    const options = {
      hostname: BASE_HOST,
      port: 443,
      path: path,
      method: 'PATCH',
      headers: {
        'Content-Type': 'application/json',
        'Content-Length': Buffer.byteLength(payload)
      }
    };

    const req = https.request(options, (res) => {
      let body = '';
      res.on('data', chunk => body += chunk);
      res.on('end', () => {
        if (res.statusCode >= 200 && res.statusCode < 300) {
          console.log(`[SUCCESS] Firestore document created/updated: ${docPath}`);
          resolve(JSON.parse(body));
        } else {
          console.error(`[ERROR ${res.statusCode}] Failed to write ${docPath}: ${body}`);
          resolve(null);
        }
      });
    });

    req.on('error', (e) => {
      console.error(`[NETWORK ERROR] ${docPath}:`, e.message);
      reject(e);
    });

    req.write(payload);
    req.end();
  });
}

async function seedAll() {
  console.log('==================================================');
  console.log(`Memulai seeding Cloud Firestore (${PROJECT_ID})...`);
  console.log('==================================================');

  // 1. Profil Pengguna
  await setFirestoreDocument('nara_user_profiles/farhiyah_outdoor@nara_id', {
    id: 1,
    nama: 'Farhiyah Petualang',
    email: 'farhiyah.outdoor@nara.id',
    noHp: '+62 812-3456-7890',
    asalKota: 'Bandung Barat',
    rolePetualang: 'Senior Caver & Speleologi',
    bio: 'Penjelajah goa vertikal karst Citatah & pemanjat tebing tegar bersama NARA Outdoor.',
    golonganDarah: 'O+',
    kontakDaruratNama: 'Basecamp Citatah',
    kontakDaruratHp: '+62 812-9876-5432',
    organisasi: 'NARA Speleo Club',
    fotoProfil: 'https://images.unsplash.com/photo-1522163182402-834f871fd851?auto=format&fit=crop&w=400&q=80',
    totalEkspedisi: 14,
    jarakJelajah: '84 km',
    jamTerbang: '120 Jam',
    updatedAt: new Date().toISOString()
  });

  // 2. Berita & Kabar Komunitas
  await setFirestoreDocument('nara_community_news/citatah_ekspedisi_1', {
    id: 'citatah_ekspedisi_1',
    title: '4 Pemuda-Pemudi Taklukkan Tebing Citatah: Sinergi Tim di Ketinggian',
    location: 'Padalarang, Bandung Barat',
    coordinates: '6°50\'25.8"S 107°27\'06.5"E',
    category: 'EKSPEDISI',
    categories: '["Tebing", "Jalur Baru"]',
    timeAgo: '1 jam yang lalu',
    date: '2026-02-24T07:00:00.000Z',
    formattedDate: '24/02/2026',
    description: 'Ekspedisi pemanjatan tebing Citatah 125, Padalarang, Jawa Barat telah sukses dilaksanakan oleh tim beranggotakan 4 orang. Cuaca cerah dan mendukung sepanjang kegiatan berlangsung, memungkinkan tim untuk fokus pada aspek teknis pemanjatan.',
    photos: '["assets/images/fotober4.jpeg", "assets/images/fotocitatah1.jpeg", "assets/images/fotocitatah2.jpeg"]',
    headerImage: 'assets/images/fotober4.jpeg',
    rockType: 'Andesit Karst',
    grade: 'Grade 5.9',
    rating: '5.0',
    author: 'Farhiyah Petualang',
    duration: '2 Hari 1 Malam',
    team: '4 Orang',
    elevation: '125 mdpl',
    technique: 'Single Rope Technique (SRT), Lead Climbing',
    mainRope: 'Dynamic Rope 10mm (60m)',
    isDraft: 0,
    status: 'VALID',
    verifiedCount: 18,
    hoaxCount: 0,
    createdAt: new Date().toISOString(),
    updatedAt: new Date().toISOString()
  });

  await setFirestoreDocument('nara_community_news/citatah_jalur_2', {
    id: 'citatah_jalur_2',
    title: 'Tebing Citatah 125: Jalur Utama dan Sektor Pemanjatan Dibuka Kembali',
    location: 'Padalarang, Bandung Barat',
    coordinates: '6°50\'25.8"S 107°27\'06.5"E',
    category: 'KONDISI JALUR',
    categories: '["Tebing"]',
    timeAgo: '3 jam yang lalu',
    date: '2026-02-23T09:00:00.000Z',
    formattedDate: '23/02/2026',
    description: 'Pengelola kawasan dan tim SAR gabungan memastikan seluruh anchor dan hanger pada jalur pemanjatan Tebing Citatah 125 aman untuk digunakan kembali.',
    photos: '["assets/images/citatah.jpg", "assets/images/fotocitatah1.jpeg"]',
    headerImage: 'assets/images/citatah.jpg',
    rockType: 'Andesit & Limestone',
    grade: 'Grade 5.9 - 5.11',
    rating: '4.8',
    author: 'Pengelola Citatah',
    duration: '1 Hari',
    team: 'Tim SAR & Pengelola',
    elevation: '125 mdpl',
    isDraft: 0,
    status: 'VALID',
    verifiedCount: 24,
    hoaxCount: 0,
    createdAt: new Date().toISOString(),
    updatedAt: new Date().toISOString()
  });

  // 3. Ulasan & Rating Spot
  await setFirestoreDocument('nara_spot_reviews/rev_tebing_citatah_125_1', {
    id: 'rev_tebing_citatah_125_1',
    spotId: 'tebing_citatah_125',
    destinationName: 'Tebing Citatah 125',
    userName: 'Farhiyah Petualang',
    userRole: 'Senior Caver & Speleologi',
    userAvatar: 'https://images.unsplash.com/photo-1522163182402-834f871fd851?w=200',
    rating: 5.0,
    comment: 'Jalurnya sangat menantang dan view dari atas luar biasa! Pastikan bawa kapur yang cukup dan cek anchor sebelum lead climbing.',
    photos: ['assets/images/fotocitatah1.jpeg'],
    likes: 8,
    createdAt: new Date().toISOString(),
    updatedAt: new Date().toISOString()
  });

  await setFirestoreDocument('nara_spot_reviews/rev_tebing_citatah_125_2', {
    id: 'rev_tebing_citatah_125_2',
    spotId: 'tebing_citatah_125',
    destinationName: 'Tebing Citatah 125',
    userName: 'Alex Rivers',
    userRole: 'Mountain Guide',
    userAvatar: 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=200',
    rating: 4.8,
    comment: 'Basecamp sangat ramah dan informasinya akurat. Cocok untuk latihan teknik SRT dan pemanjatan akhir pekan.',
    photos: ['assets/images/fotober4.jpeg'],
    likes: 5,
    createdAt: new Date().toISOString(),
    updatedAt: new Date().toISOString()
  });

  // 4. Live Mesh Safety Trackers
  await setFirestoreDocument('nara_safety_trackers/peer_budi_01', {
    userId: 'peer_budi_01',
    userName: 'Budi Santoso',
    latitude: -6.8378,
    longitude: 107.4502,
    altitude: '480 m ASL',
    status: 'normal',
    battery: 88,
    updatedAt: new Date().toISOString()
  });

  await setFirestoreDocument('nara_safety_trackers/peer_ayu_02', {
    userId: 'peer_ayu_02',
    userName: 'Ayu Lestari',
    latitude: -6.8412,
    longitude: 107.4545,
    altitude: '435 m ASL',
    status: 'normal',
    battery: 74,
    updatedAt: new Date().toISOString()
  });

  // 5. Inventaris Alat
  await setFirestoreDocument('nara_gear_inventories/default_nara_explorer', {
    userId: 'default_nara_explorer',
    updatedAt: new Date().toISOString(),
    categories: [
      {
        id: 'cat_rope',
        title: 'Tali & Webbing',
        description: 'Dynamic & Static Climbing Ropes',
        iconCodePoint: 58732,
        items: [
          {
            id: 'gear_rope_01',
            name: 'Beal Joker 9.1mm Golden Dry (60m)',
            brand: 'Beal',
            status: 'Layak Pakai',
            usageCount: 8,
            maxUsage: 50
          }
        ]
      }
    ]
  });

  // 6. Log Ekspedisi
  await setFirestoreDocument('nara_expedition_logs/default_nara_explorer_log_1', {
    id: 1,
    spotId: 'tebing_citatah_125',
    spotName: 'Tebing Citatah 125',
    location: 'Padalarang, Bandung Barat',
    date: '2026-02-24T08:00:00.000Z',
    durationMinutes: 180,
    distanceKm: 3.5,
    elevationGainM: 125,
    activityType: 'Climbing',
    notes: 'Pemanjatan rute jalur andesit sisi barat.',
    createdAt: new Date().toISOString(),
    updatedAt: new Date().toISOString()
  });

  // 7. Bookmarks
  await setFirestoreDocument('nara_user_bookmarks/default_nara_explorer_bm_1', {
    id: 1,
    spotId: 'tebing_citatah_125',
    title: 'Tebing Citatah 125',
    location: 'Padalarang, Bandung Barat',
    type: 'Tebing Karst',
    imageUrl: 'assets/images/citatah.jpg',
    rating: '4.8',
    elevation: '125 mdpl',
    coordinates: '-6.84050, 107.45180',
    createdAt: new Date().toISOString(),
    updatedAt: new Date().toISOString()
  });

  console.log('==================================================');
  console.log('Semua koleksi dan dokumen berhasil dibuat di Cloud Firestore!');
  console.log('==================================================');
}

seedAll().catch(console.error);
