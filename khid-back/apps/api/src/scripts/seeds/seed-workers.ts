// ══════════════════════════════════════════════════════════════════════════════
// KHIDMETI — Script de seed : travailleurs de test sur les 58 wilayas
//
// USAGE via Makefile (recommandé) :
//   make scripts-seed-workers              ← seed / re-seed (upsert)
//   make scripts-seed-workers ARGS=--clear ← efface tout puis re-seed
//
// PROPRIÉTÉS :
//   • ~750 workers répartis sur les 58 wilayas (villes majeures densifiées),
//     en 2 anneaux : 1/3 près du centre (±9 km), 2/3 sur toute la wilaya
//     (±39 km) — un client loin du chef-lieu voit toujours des workers.
//   • Chaque wilaya couvre les 11 métiers (cycle i % 11 — vérifié par assert).
//   • Déterministe (RNG mulberry32 à graine fixe) : re-run = mêmes données.
//   • UPSERT (replaceOne) et non create-skip : re-lancer le script RÉPARE les
//     docs seedés obsolètes (ex: créés avant l'ajout de subscriptionActive,
//     qui restaient invisibles à cause du paywall de visibilité).
//   • UIDs fictifs (seed-worker-<wilaya>-<n>) : pas de Firebase Auth possible.
//   • phoneNumber en clair (pas de bidx) : décrypté « pass-through » à la
//     lecture par field-crypto — OK pour des workers de test.
// ══════════════════════════════════════════════════════════════════════════════

import mongoose from 'mongoose';

// ── Config ────────────────────────────────────────────────────────────────────
const MONGODB_URI =
  process.env['MONGODB_URI'] ??
  'mongodb://khidmeti:khidmeti123@localhost:27017/khidmeti?authSource=admin';

// ── 58 wilayas — coords copiées de khid-app/lib/services/wilaya_manager.dart ──
const WILAYAS: { code: number; name: string; lat: number; lng: number }[] = [
  { code:  1, name: 'Adrar',               lat: 27.8667, lng: -0.2833 },
  { code:  2, name: 'Chlef',               lat: 36.1667, lng:  1.3333 },
  { code:  3, name: 'Laghouat',            lat: 33.8000, lng:  2.8667 },
  { code:  4, name: 'Oum El Bouaghi',      lat: 35.8667, lng:  7.1167 },
  { code:  5, name: 'Batna',               lat: 35.5667, lng:  6.1667 },
  { code:  6, name: 'Béjaïa',              lat: 36.7500, lng:  5.0833 },
  { code:  7, name: 'Biskra',              lat: 34.8500, lng:  5.7333 },
  { code:  8, name: 'Béchar',              lat: 31.6167, lng: -2.2167 },
  { code:  9, name: 'Blida',               lat: 36.4833, lng:  2.8333 },
  { code: 10, name: 'Bouira',              lat: 36.3833, lng:  3.9000 },
  { code: 11, name: 'Tamanrasset',         lat: 22.7833, lng:  5.5167 },
  { code: 12, name: 'Tébessa',             lat: 35.4000, lng:  8.1167 },
  { code: 13, name: 'Tlemcen',             lat: 34.8833, lng: -1.3167 },
  { code: 14, name: 'Tiaret',              lat: 35.3708, lng:  1.3228 },
  { code: 15, name: 'Tizi Ouzou',          lat: 36.7000, lng:  4.0500 },
  { code: 16, name: 'Alger',               lat: 36.7539, lng:  3.0588 },
  { code: 17, name: 'Djelfa',              lat: 34.6667, lng:  3.2500 },
  { code: 18, name: 'Jijel',               lat: 36.8167, lng:  5.7667 },
  { code: 19, name: 'Sétif',               lat: 36.1833, lng:  5.4000 },
  { code: 20, name: 'Saïda',               lat: 34.8333, lng:  0.1500 },
  { code: 21, name: 'Skikda',              lat: 36.8667, lng:  6.9000 },
  { code: 22, name: 'Sidi Bel Abbès',      lat: 35.2000, lng: -0.6333 },
  { code: 23, name: 'Annaba',              lat: 36.9000, lng:  7.7667 },
  { code: 24, name: 'Guelma',              lat: 36.4667, lng:  7.4333 },
  { code: 25, name: 'Constantine',         lat: 36.3650, lng:  6.6147 },
  { code: 26, name: 'Médéa',               lat: 36.2667, lng:  2.7500 },
  { code: 27, name: 'Mostaganem',          lat: 35.9333, lng:  0.0833 },
  { code: 28, name: "M'Sila",              lat: 35.7000, lng:  4.5333 },
  { code: 29, name: 'Mascara',             lat: 35.3960, lng:  0.1400 },
  { code: 30, name: 'Ouargla',             lat: 31.9500, lng:  5.3333 },
  { code: 31, name: 'Oran',                lat: 35.6969, lng: -0.6331 },
  { code: 32, name: 'El Bayadh',           lat: 33.6833, lng:  1.0167 },
  { code: 33, name: 'Illizi',              lat: 26.5000, lng:  8.4667 },
  { code: 34, name: 'Bordj Bou Arréridj',  lat: 36.0667, lng:  4.7667 },
  { code: 35, name: 'Boumerdès',           lat: 36.7667, lng:  3.4833 },
  { code: 36, name: 'El Tarf',             lat: 36.7667, lng:  8.3167 },
  { code: 37, name: 'Tindouf',             lat: 27.6750, lng: -8.1333 },
  { code: 38, name: 'Tissemsilt',          lat: 35.6000, lng:  1.8167 },
  { code: 39, name: 'El Oued',             lat: 33.3667, lng:  6.8667 },
  { code: 40, name: 'Khenchela',           lat: 35.4333, lng:  7.1500 },
  { code: 41, name: 'Souk Ahras',          lat: 36.2833, lng:  7.9500 },
  { code: 42, name: 'Tipaza',              lat: 36.5931, lng:  2.4458 },
  { code: 43, name: 'Mila',                lat: 36.4500, lng:  6.2667 },
  { code: 44, name: 'Aïn Defla',           lat: 36.2667, lng:  1.9667 },
  { code: 45, name: 'Naâma',               lat: 33.2667, lng: -0.3167 },
  { code: 46, name: 'Aïn Témouchent',      lat: 35.2986, lng: -1.1392 },
  { code: 47, name: 'Ghardaïa',            lat: 32.4833, lng:  3.6667 },
  { code: 48, name: 'Relizane',            lat: 35.7372, lng:  0.5536 },
  { code: 49, name: 'Timimoun',            lat: 29.2500, lng:  0.2333 },
  { code: 50, name: 'Bordj Badji Mokhtar', lat: 21.3333, lng:  0.9500 },
  { code: 51, name: 'Ouled Djellal',       lat: 34.4167, lng:  5.0333 },
  { code: 52, name: 'Béni Abbès',          lat: 30.1333, lng: -2.1667 },
  { code: 53, name: 'In Salah',            lat: 27.2000, lng:  2.4667 },
  { code: 54, name: 'In Guezzam',          lat: 19.5667, lng:  5.7667 },
  { code: 55, name: 'Touggourt',           lat: 33.1167, lng:  6.0667 },
  { code: 56, name: 'Djanet',              lat: 24.5500, lng:  9.4833 },
  { code: 57, name: "El M'Ghair",          lat: 33.9500, lng:  5.9333 },
  { code: 58, name: 'El Meniaa',           lat: 30.5833, lng:  2.8833 },
];

// ── Métiers — clés identiques à professions.seeder.ts ─────────────────────────
const PROFESSIONS = [
  'plumber', 'electrician', 'ac_repair', 'mason', 'painter', 'carpenter',
  'cleaner', 'appliance_repair', 'gardener', 'mover', 'mechanic',
];

const FIRST_NAMES = [
  'Karim', 'Farid', 'Mohamed', 'Youcef', 'Amine', 'Rachid', 'Bilal', 'Nabil',
  'Samir', 'Hichem', 'Omar', 'Khaled', 'Sofiane', 'Riad', 'Adel', 'Mourad',
  'Hamza', 'Zaki', 'Ilyes', 'Walid', 'Djamel', 'Fouad', 'Lotfi', 'Nassim',
];
const LAST_NAMES = [
  'Benali', 'Boumediene', 'Tlemcani', 'Hadjadj', 'Zerrouk', 'Kaci',
  'Messaoudi', 'Brahimi', 'Bouali', 'Djebari', 'Laid', 'Mansouri',
  'Cherif', 'Belkacem', 'Hamidi', 'Saadi', 'Meziane', 'Bouzid',
  'Ferhat', 'Ghali', 'Toumi', 'Slimani', 'Rahmani', 'Ziani',
];

// Densité : 12 workers/wilaya (≥ 11 ⇒ tous les métiers couverts),
// villes majeures densifiées.
const PER_DEFAULT = 12;
const PER_OVERRIDE: Record<number, number> = {
  16: 24, 31: 24, 25: 18, 23: 18, 19: 18, 9: 16, 6: 16,
};

// ── RNG déterministe (mulberry32) — re-run ⇒ mêmes données ⇒ upserts stables ──
function mulberry32(seed: number): () => number {
  let t = seed >>> 0;
  return () => {
    t += 0x6d2b79f5;
    let r = Math.imul(t ^ (t >>> 15), t | 1);
    r ^= r + Math.imul(r ^ (r >>> 7), r | 61);
    return ((r ^ (r >>> 14)) >>> 0) / 4294967296;
  };
}

// ── Mongoose Schemas (minimaux — identiques à user.schema.ts / geo-cell) ──────
const UserSchema = new mongoose.Schema(
  {
    _id:            { type: String, required: true },
    name:           { type: String, required: true },
    email:          { type: String, default: '' },
    phoneNumber:    { type: String, default: '' },
    role:           { type: String, default: 'worker' },
    latitude:       { type: Number, default: null },
    longitude:      { type: Number, default: null },
    wilayaCode:     { type: Number, default: null },
    cellId:         { type: String, default: null },
    geoHash:        { type: String, default: null },
    lastUpdated:    { type: Date,   required: true },
    lastCellUpdate: { type: Date,   default: null },
    profileImageUrl:{ type: String, default: null },
    fcmToken:       { type: String, default: null },
    profession:     { type: String, default: null },
    isOnline:       { type: Boolean, default: false },
    averageRating:  { type: Number, default: 0 },
    ratingCount:    { type: Number, default: 0 },
    ratingSum:      { type: Number, default: 0 },
    jobsCompleted:  { type: Number, default: 0 },
    responseRate:   { type: Number, default: 0.7 },
    lastActiveAt:   { type: Date,   default: null },
    // Paywall de visibilité — findWorkers() filtre subscribedOnly:true.
    subscriptionActive: { type: Boolean, default: false },
    subscriptionUntil:  { type: Date,   default: null },
    subscriptionTier:   { type: String, default: null },
    subscriptionPrice:  { type: Number, default: null },
    dailyQuotaSeconds:  { type: Number, default: null },
    monthlyBidQuota:    { type: Number, default: null },
    searchPriority:     { type: Boolean, default: false },
    // Tier Expert — vue Business (b2bOnly). B2B requiert des docs vérifiés.
    b2bAccess:          { type: Boolean, default: false },
    isVerified:         { type: Boolean, default: false },
  },
  { collection: 'users', versionKey: false },
);

const GeoCellSchema = new mongoose.Schema(
  {
    _id:            { type: String, required: true },
    wilayaCode:     { type: Number, required: true },
    centerLat:      { type: Number, required: true },
    centerLng:      { type: Number, required: true },
    radius:         { type: Number, default: 5.0 },
    adjacentCellIds:{ type: [String], default: [] },
  },
  { collection: 'geographic_cells', versionKey: false },
);

// ── Helpers géo (identiques à LocationService) ────────────────────────────────
const CELL_PRECISION = 2;

function buildCellId(lat: number, lng: number, wilayaCode: number): string {
  const rLat = +lat.toFixed(CELL_PRECISION);
  const rLng = +lng.toFixed(CELL_PRECISION);
  return `${wilayaCode}_${rLat.toFixed(CELL_PRECISION)}_${rLng.toFixed(CELL_PRECISION)}`;
}

function getAdjacentCellIds(cellId: string): string[] {
  const parts = cellId.split('_');
  if (parts.length !== 3) return [];
  const [wilayaStr, latStr, lngStr] = parts;
  const wilayaCode = parseInt(wilayaStr, 10);
  const lat  = parseFloat(latStr);
  const lng  = parseFloat(lngStr);
  const step = Math.pow(10, -CELL_PRECISION);

  const ids: string[] = [];
  for (let dLat = -1; dLat <= 1; dLat++) {
    for (let dLng = -1; dLng <= 1; dLng++) {
      if (dLat === 0 && dLng === 0) continue;
      const adjLat = +(lat + dLat * step).toFixed(CELL_PRECISION);
      const adjLng = +(lng + dLng * step).toFixed(CELL_PRECISION);
      ids.push(`${wilayaCode}_${adjLat.toFixed(CELL_PRECISION)}_${adjLng.toFixed(CELL_PRECISION)}`);
    }
  }
  return ids;
}

function encodeGeoHash(lat: number, lng: number, precision = 6): string {
  const BASE32 = '0123456789bcdefghjkmnpqrstuvwxyz';
  let hash = '', isEven = true, bit = 0, ch = 0;
  let latMin = -90, latMax = 90, lngMin = -180, lngMax = 180;
  while (hash.length < precision) {
    let mid: number;
    if (isEven) {
      mid = (lngMin + lngMax) / 2;
      if (lng >= mid) { ch |= (1 << (4 - bit)); lngMin = mid; } else { lngMax = mid; }
    } else {
      mid = (latMin + latMax) / 2;
      if (lat >= mid) { ch |= (1 << (4 - bit)); latMin = mid; } else { latMax = mid; }
    }
    isEven = !isEven;
    if (bit < 4) { bit++; } else { hash += BASE32[ch]; bit = 0; ch = 0; }
  }
  return hash;
}

// ── Génération des workers ────────────────────────────────────────────────────
interface SeedWorker {
  uid: string; name: string; phone: string; profession: string;
  rating: number; jobs: number; isOnline: boolean; b2bAccess: boolean;
  lat: number; lng: number; wilayaCode: number; wilayaName: string;
}

function generateWorkers(): SeedWorker[] {
  const out: SeedWorker[] = [];
  for (const w of WILAYAS) {
    const n    = PER_OVERRIDE[w.code] ?? PER_DEFAULT;
    const rand = mulberry32(w.code * 7919); // graine fixe par wilaya
    for (let i = 0; i < n; i++) {
      // Cycle sur les métiers ⇒ couverture garantie de chaque métier.
      const profession = PROFESSIONS[i % PROFESSIONS.length];
      out.push({
        uid:        `seed-worker-${w.code}-${String(i + 1).padStart(3, '0')}`,
        name:       `${FIRST_NAMES[Math.floor(rand() * FIRST_NAMES.length)]} ` +
                    `${LAST_NAMES[Math.floor(rand() * LAST_NAMES.length)]}`,
        // +213 5 5CCC CIII — unique, format mobile algérien valide.
        phone:      `+2135${50000000 + w.code * 10000 + i}`,
        profession,
        rating:     +(3.2 + rand() * 1.8).toFixed(1),          // 3.2 → 5.0
        jobs:       3 + Math.floor(rand() * 77),               // 3 → 79
        isOnline:   rand() < 0.85,                             // ~15% hors ligne
        b2bAccess:  rand() < 0.2,                              // ~20% tier Expert
        // Dispersion en 2 anneaux : 1 worker sur 3 reste près du centre
        // (±9 km), les autres couvrent toute la wilaya (±0.35° ≈ ±39 km).
        // Un utilisateur situé loin du chef-lieu a ainsi toujours des
        // workers dans son rayon de 50 km.
        lat:        +(w.lat + (rand() - 0.5) * (i % 3 === 0 ? 0.16 : 0.70)).toFixed(6),
        lng:        +(w.lng + (rand() - 0.5) * (i % 3 === 0 ? 0.16 : 0.70)).toFixed(6),
        wilayaCode: w.code,
        wilayaName: w.name,
      });
    }
  }
  return out;
}

// ── Main ──────────────────────────────────────────────────────────────────────
async function main() {
  const shouldClear = process.argv.includes('--clear');
  const workers     = generateWorkers();

  // Self-check : chaque wilaya couvre les 11 métiers ET les 2 anneaux
  // de dispersion (au moins un worker à > 0.1° ≈ 11 km du centre).
  for (const w of WILAYAS) {
    const ws      = workers.filter((x) => x.wilayaCode === w.code);
    const covered = new Set(ws.map((x) => x.profession));
    if (covered.size !== PROFESSIONS.length) {
      throw new Error(`Couverture métiers incomplète — wilaya ${w.code} (${covered.size}/${PROFESSIONS.length})`);
    }
    if (!ws.some((x) => Math.abs(x.lat - w.lat) > 0.1 || Math.abs(x.lng - w.lng) > 0.1)) {
      throw new Error(`Dispersion large absente — wilaya ${w.code} (tous les workers < 11 km du centre)`);
    }
  }

  console.log('\n══════════════════════════════════════════════');
  console.log('  Khidmeti — Seed : workers (58 wilayas)');
  console.log('══════════════════════════════════════════════\n');

  await mongoose.connect(MONGODB_URI);
  console.log(`✅ Connecté à MongoDB (${workers.length} workers à seeder)\n`);

  const UserModel    = mongoose.model('User',           UserSchema);
  const GeoCellModel = mongoose.model('GeographicCell', GeoCellSchema);

  const allCellIds = [...new Set(
    workers.map((w) => buildCellId(w.lat, w.lng, w.wilayaCode)),
  )];

  if (shouldClear) {
    const delWorkers = await UserModel.deleteMany({ _id: /^seed-worker-/ });
    const delCells   = await GeoCellModel.deleteMany({ _id: { $in: allCellIds } });
    console.log(`🗑️  ${delWorkers.deletedCount} worker(s) seed supprimés`);
    console.log(`🗑️  ${delCells.deletedCount} cellule(s) seed supprimées\n`);
  }

  // ── Workers : UPSERT (replaceOne) — répare aussi les docs seedés obsolètes ──
  const now = new Date();
  const userOps = workers.map((w) => {
    const cellId  = buildCellId(w.lat, w.lng, w.wilayaCode);
    const geoHash = encodeGeoHash(w.lat, w.lng, 6);

    // Moyenne bayésienne — identique à UsersService.applyRating().
    const ratingSum   = w.rating * w.jobs;
    const C = 3.5, m = 10;
    const bayesianAvg = (m * C + ratingSum) / (m + w.jobs);

    return {
      replaceOne: {
        filter: { _id: w.uid },
        replacement: {
          _id:             w.uid,
          name:            w.name,
          email:           '',
          phoneNumber:     w.phone,
          role:            'worker',
          latitude:        w.lat,
          longitude:       w.lng,
          wilayaCode:      w.wilayaCode,
          cellId,
          geoHash,
          lastUpdated:     now,
          lastCellUpdate:  now,
          // Photo déterministe par uid (pravatar) — l'app retombe sur l'icône
          // métier via errorBuilder si le CDN est inaccessible hors ligne.
          profileImageUrl: `https://i.pravatar.cc/150?u=${w.uid}`,
          fcmToken:        null,
          profession:      w.profession,
          isOnline:        w.isOnline,
          averageRating:   bayesianAvg,
          ratingCount:     w.jobs,
          ratingSum,
          jobsCompleted:   w.jobs,
          responseRate:    0.85,
          lastActiveAt:    now,
          // Abonnement visibilité 1 an — requis par le paywall findWorkers.
          // Entitlements = pack business/expert (illimité, priorité).
          subscriptionActive: true,
          subscriptionUntil:  new Date(Date.now() + 365 * 24 * 60 * 60 * 1000),
          subscriptionTier:   w.b2bAccess ? 'expert' : 'business',
          subscriptionPrice:  w.b2bAccess ? 2500 : 1500,
          dailyQuotaSeconds:  null,
          monthlyBidQuota:    null,
          searchPriority:     true,
          b2bAccess:          w.b2bAccess,
          // Le gate B2B exige des docs vérifiés — cohérent pour les seeds Expert.
          isVerified:         w.b2bAccess,
        },
        upsert: true,
      },
    };
  });
  const ur = await UserModel.bulkWrite(userOps, { ordered: false });

  // ── Cellules : upsert $setOnInsert (no-op si déjà présentes) ────────────────
  const cellOps = allCellIds.map((cellId) => {
    const [wilayaStr, latStr, lngStr] = cellId.split('_');
    return {
      updateOne: {
        filter: { _id: cellId },
        update: {
          $setOnInsert: {
            wilayaCode:      parseInt(wilayaStr, 10),
            centerLat:       parseFloat(latStr),
            centerLng:       parseFloat(lngStr),
            radius:          5.0,
            adjacentCellIds: getAdjacentCellIds(cellId),
          },
        },
        upsert: true,
      },
    };
  });
  const cr = await GeoCellModel.bulkWrite(cellOps, { ordered: false });

  // ── Résumé par wilaya ──────────────────────────────────────────────────────
  console.log('  Répartition :');
  for (const w of WILAYAS) {
    const ws     = workers.filter((x) => x.wilayaCode === w.code);
    const online = ws.filter((x) => x.isOnline).length;
    console.log(
      `  ${String(w.code).padStart(2)} ${w.name.padEnd(20)} ` +
      `${String(ws.length).padStart(3)} workers | 🟢 ${online} en ligne`,
    );
  }

  console.log('\n══════════════════════════════════════════════');
  console.log(`  Workers  : ✅ ${ur.upsertedCount} créés | ♻️  ${ur.modifiedCount} mis à jour`);
  console.log(`  Cellules : ✅ ${cr.upsertedCount} créées | ⏭️  ${allCellIds.length - cr.upsertedCount} existantes`);
  console.log('══════════════════════════════════════════════');
  console.log('\n  Tests rapides :');
  console.log('  curl "http://localhost:3000/workers?wilayaCode=31&isOnline=true"');
  console.log('  curl "http://localhost:3000/workers?wilayaCode=16&profession=plumber"\n');

  await mongoose.disconnect();
}

main().catch((err) => {
  console.error('\n❌ Erreur :', err.message);
  process.exit(1);
});
