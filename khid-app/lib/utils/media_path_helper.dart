// lib/utils/media_path_helper.dart
//
// MIGRATION v15 — MinIO (proxy NestJS) → Cloudinary (CDN public)
//
// AVANT (MinIO) :
//   On stockait un "storedPath" ("bucket/userId/file.ext") car l'URL complète
//   dépendait du domaine du tunnel Cloudflare, qui changeait régulièrement.
//   toUrl() reconstruisait dynamiquement l'URL à chaque affichage.
//
// APRÈS (Cloudinary) :
//   Le backend retourne déjà une URL CDN complète et permanente
//   (https://res.cloudinary.com/...) — elle ne dépend d'AUCUN domaine de
//   notre infra. Plus besoin de reconstruction : on l'affiche telle quelle.
//
// COMPATIBILITÉ :
//   Toutes les signatures publiques sont conservées à l'identique pour que
//   les call sites existants (Image.network(MediaPathHelper.toUrl(...)))
//   continuent de fonctionner sans aucune modification ailleurs dans l'app.
//   Seule l'implémentation interne change — elle devient une pass-through.
//
// BASE DE DONNÉES : vide au moment de cette migration (app pas encore
// lancée) → aucune valeur héritée à gérer, aucun cas legacy à couvrir.

class MediaPathHelper {
  MediaPathHelper._();

  /// Retourne l'URL d'affichage directement utilisable.
  ///
  /// Avec Cloudinary, [storedPathOrUrl] EST déjà l'URL complète à afficher
  /// (persistée telle quelle en base par les écrans d'upload). Cette méthode
  /// la retourne sans transformation.
  ///
  /// [apiBaseUrl] est conservé uniquement pour compatibilité de signature
  /// avec les anciens call sites — il n'est plus utilisé.
  static String toUrl(
    String? storedPathOrUrl, {
    String? apiBaseUrl,
  }) {
    return storedPathOrUrl ?? '';
  }

  /// Emoji avatars are persisted in the same `profileImageUrl` field with an
  /// `emoji:` sentinel (no image is uploaded). Returns the emoji character when
  /// the stored value is an emoji avatar, or null when it is a real image URL.
  /// Display widgets branch on this before calling [toUrl].
  static String? emoji(String? storedPathOrUrl) =>
      (storedPathOrUrl != null && storedPathOrUrl.startsWith('emoji:'))
          ? storedPathOrUrl.substring(6)
          : null;

  /// @deprecated Sans objet avec Cloudinary — l'URL persistée est déjà
  /// l'URL finale. Conservé pour compatibilité de signature uniquement.
  static String toStoredPath(String urlOrPath) => urlOrPath;

  /// @deprecated Le concept de "storedPath" séparé de l'URL n'existe plus
  /// avec Cloudinary. Retourne toujours false. Conservé pour compatibilité.
  static bool isStoredPath(String value) => false;

  /// @deprecated MinIO n'existe plus dans l'infrastructure — retourne
  /// toujours false. Conservé pour compatibilité de signature.
  static bool isLegacyMinioUrl(String value) => false;

  /// Convertit une liste de références média en liste d'URLs affichables.
  /// Avec Cloudinary, équivaut à filtrer les entrées vides.
  static List<String> listToUrls(
    List<String> items, {
    String? apiBaseUrl,
  }) =>
      items.where((item) => item.isNotEmpty).toList();
}
