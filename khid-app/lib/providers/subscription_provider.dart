// lib/providers/subscription_provider.dart
//
// État d'abonnement de visibilité du worker (modèle économique du memoire :
// abonnement de visibilité, pas de commission). Un worker non abonné garde
// l'accès client complet mais ses fonctionnalités worker sont verrouillées.

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/user_model.dart';
import 'auth_providers.dart';
import 'core_providers.dart';

/// Document utilisateur courant (avec les champs d'abonnement).
/// Invalider ce provider après activation pour rafraîchir les gates.
final currentUserDocProvider = FutureProvider.autoDispose<UserModel?>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return null;
  return ref.watch(firestoreServiceProvider).getUser(user.uid);
});

/// Vrai si l'utilisateur courant a un abonnement de visibilité actif.
/// Pendant le chargement / en cas d'erreur → false (verrouillé par défaut).
final isSubscribedProvider = Provider.autoDispose<bool>((ref) {
  return ref.watch(currentUserDocProvider).maybeWhen(
        data: (u) => u?.isSubscribed ?? false,
        orElse: () => false,
      );
});
