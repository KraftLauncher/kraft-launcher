import 'package:kraft_launcher/account/logic/account_utils.dart';
import 'package:test/test.dart';

import '../../common/test_constants.dart';
import '../data/minecraft_account_utils.dart';

void main() {
  final account1 = createMinecraftAccount(id: '1', username: 'Steve');
  final account2 = createMinecraftAccount(id: '2', username: 'Alex');
  final account3 = createMinecraftAccount(id: '3', username: 'Herobrine');
  final account4 = createMinecraftAccount(id: '4', username: 'steve_the_miner');

  final accounts = [account1, account2, account3, account4];

  group('updateById', () {
    test('updates and returns a new unmodifiable list', () {
      const newUsername = 'NewSteve';
      final updatedList = accounts.updateById(
        account1.id,
        (account) => account.copyWith(username: newUsername),
      );

      expect(updatedList.length, accounts.length);
      expect(
        updatedList,
        [...accounts]..[0] = account1.copyWith(username: newUsername),
      );

      expect(() => updatedList.add(account1), throwsUnsupportedError);
    });
  });

  group('findIndexById', () {
    test('throws $ArgumentError if the id is not found', () {
      expect(
        () => accounts.findIndexById(TestConstants.anyString),
        throwsArgumentError,
      );
    });

    test('returns correct index', () {
      for (final (index, account) in accounts.indexed) {
        expect(accounts.findIndexById(account.id), index);
      }
    });
  });

  group('findById', () {
    test('throws $ArgumentError if the id is not found', () {
      expect(
        () => accounts.findById(TestConstants.anyString),
        throwsArgumentError,
      );
    });

    test('returns correct index', () {
      for (final account in accounts) {
        expect(accounts.findById(account.id), account);
      }
    });
  });

  group('filterByUsername', () {
    test('returns case-insensitive matches', () {
      final result = accounts.filterByUsername('steve');

      expect(result.length, 2);
      expect(
        result.map((e) => e.username),
        containsAll([account1.username, account4.username]),
      );
    });

    test('trims both query and usernames', () {
      final searchUsername = account2.username;

      final result = accounts.filterByUsername('  $searchUsername  ');

      expect(result.length, 1);
      expect(result.first.username, searchUsername);
    });

    test('returns empty list when no match', () {
      final result = accounts.filterByUsername('no match');
      expect(result, isEmpty);
    });
  });
}
