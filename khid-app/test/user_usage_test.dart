// Check for the metering logic: UserModel's DAILY online-time counter and
// MONTHLY bid counter. Daily counter freezes when offline, resets at local
// midnight (stale bucket = 0, midnight-straddling session counts from 00:00),
// never goes backwards. Bid counter mirrors it per month. Entitlements
// (quota / weekend / bid access) come from stored pack fields.

import 'package:flutter_test/flutter_test.dart';
import 'package:khidmeti/models/user_model.dart';

UserModel _worker({
  required bool online,
  int usage = 0,
  String? day,
  DateTime? since,
  int? price,
  int? dailyQuota,
  int? bidQuota,
  int bidsUsed = 0,
  String? bidMonth,
}) =>
    UserModel(
      id: 'w1',
      name: 'W',
      email: '',
      phoneNumber: '',
      role: 'worker',
      lastUpdated: DateTime(2020),
      isOnline: online,
      usageSeconds: usage,
      usageDay: day,
      onlineSince: since,
      subscriptionPrice: price,
      dailyQuotaSeconds: dailyQuota,
      monthlyBidQuota: bidQuota,
      bidsUsed: bidsUsed,
      bidMonth: bidMonth,
    );

void main() {
  final now = DateTime(2026, 1, 1, 12, 0, 0);
  final today = UserModel.dayKey(now);       // '2026-01-01'
  final thisMonth = UserModel.monthKey(now); // '2026-01'

  test('offline + today\'s bucket → frozen at usageSeconds', () {
    expect(
        _worker(online: false, usage: 3600, day: today).usageSecondsAt(now),
        3600);
  });

  test('offline + stale bucket (yesterday) → 0 — daily reset', () {
    expect(
        _worker(online: false, usage: 3600, day: '2025-12-31')
            .usageSecondsAt(now),
        0);
  });

  test('online → today\'s bucket + current session', () {
    final since = now.subtract(const Duration(seconds: 90));
    expect(
        _worker(online: true, usage: 3600, day: today, since: since)
            .usageSecondsAt(now),
        3690);
  });

  test('online session straddling midnight → only counts since 00:00', () {
    // Online since 23:00 yesterday; at 12:00 today only 12 h count, and the
    // stale bucket is dropped.
    final since = DateTime(2025, 12, 31, 23, 0, 0);
    expect(
        _worker(online: true, usage: 3600, day: '2025-12-31', since: since)
            .usageSecondsAt(now),
        12 * 3600);
  });

  test('clock skew (onlineSince in future) never subtracts', () {
    final since = now.add(const Duration(seconds: 30));
    expect(
        _worker(online: true, usage: 3600, day: today, since: since)
            .usageSecondsAt(now),
        3600);
  });

  test('quotaExhaustedAt reads the stored daily quota (null = unlimited)', () {
    expect(
        _worker(online: false, dailyQuota: 5 * 3600, usage: 5 * 3600, day: today)
            .quotaExhaustedAt(now),
        isTrue);
    // Stale bucket → counts as 0 today → not exhausted.
    expect(
        _worker(online: false,
                dailyQuota: 5 * 3600, usage: 5 * 3600, day: '2025-12-31')
            .quotaExhaustedAt(now),
        isFalse);
    expect(
        _worker(online: false, usage: 20 * 3600, day: today)
            .quotaExhaustedAt(now),
        isFalse);
  });

  test('canBid: 0 = no access, null = unlimited, N = finite', () {
    expect(_worker(online: false, bidQuota: 0).canBid, isFalse);
    expect(_worker(online: false).canBid, isTrue);
    expect(_worker(online: false, bidQuota: 20).canBid, isTrue);
  });

  test('bidsRemainingAt: monthly bucket with lazy rollover', () {
    // Same month: 20 − 5 = 15 left.
    expect(
        _worker(online: false,
                bidQuota: 20, bidsUsed: 5, bidMonth: thisMonth)
            .bidsRemainingAt(now),
        15);
    // Stale month bucket → full quota again.
    expect(
        _worker(online: false,
                bidQuota: 20, bidsUsed: 20, bidMonth: '2025-12')
            .bidsRemainingAt(now),
        20);
    // Exhausted, floored at 0.
    expect(
        _worker(online: false,
                bidQuota: 20, bidsUsed: 25, bidMonth: thisMonth)
            .bidsRemainingAt(now),
        0);
    // Unlimited pack → null.
    expect(_worker(online: false).bidsRemainingAt(now), isNull);
  });
}
