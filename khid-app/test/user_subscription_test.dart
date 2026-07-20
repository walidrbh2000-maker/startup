// Check for the money/gate logic: UserModel.isSubscribed expiry handling.
// The visibility + bidding gates depend on this being correct.

import 'package:flutter_test/flutter_test.dart';
import 'package:khidmeti/models/user_model.dart';

UserModel _worker({required bool active, DateTime? until}) => UserModel(
      id: 'w1',
      name: 'W',
      email: '',
      phoneNumber: '',
      role: 'worker',
      lastUpdated: DateTime.now(),
      subscriptionActive: active,
      subscriptionUntil: until,
    );

void main() {
  final future = DateTime.now().add(const Duration(days: 5));
  final past = DateTime.now().subtract(const Duration(days: 1));

  test('active + future expiry → subscribed', () {
    expect(_worker(active: true, until: future).isSubscribed, isTrue);
  });

  test('active flag but expired → NOT subscribed', () {
    expect(_worker(active: true, until: past).isSubscribed, isFalse);
  });

  test('inactive → NOT subscribed regardless of date', () {
    expect(_worker(active: false, until: future).isSubscribed, isFalse);
  });

  test('default worker (never subscribed) → NOT subscribed', () {
    expect(_worker(active: false).isSubscribed, isFalse);
  });
}
