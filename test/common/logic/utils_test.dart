import 'package:kraft_launcher/common/logic/utils.dart';
import 'package:test/test.dart';

void main() {
  group('expiresInToExpiresAt', () {
    test('returns a $DateTime in the future', () {
      final expiresAt = expiresInToExpiresAt(60);
      expect(expiresAt.isAfter(DateTime.now()), isTrue);
    });

    test('adds the correct duration to the current time', () {
      const expiresIn = 3600;
      final now = DateTime.now();

      final expectedExpiresAt = now.add(const Duration(seconds: expiresIn));
      final actualExpiresAt = expiresInToExpiresAt(expiresIn);

      expect(expectedExpiresAt.year, actualExpiresAt.year);
      expect(expectedExpiresAt.month, actualExpiresAt.month);
      expect(expectedExpiresAt.day, actualExpiresAt.day);
      expect(expectedExpiresAt.hour, actualExpiresAt.hour);
      expect(expectedExpiresAt.minute, actualExpiresAt.minute);
      expect(expectedExpiresAt.second, actualExpiresAt.second);
    });
  });
  test('Wrapped', () {
    const value = 'Example';
    const wrappedValue = Wrapped.value(value);
    expect(wrappedValue.value, value);
  });

  group('requireNotNull', () {
    test('throws if null', () {
      expect(() => requireNotNull(null, name: 'value'), throwsStateError);
    });

    test('returns if not null', () {
      const example = 'not null';
      expect(() => requireNotNull(example, name: 'example'), returnsNormally);
      expect(requireNotNull(example, name: 'example'), example);
    });
  });

  group('ListX', () {
    group('randomElement', () {
      test('throws if list is empty', () {
        final numbers = <int>[];
        expect(() => numbers.randomElement, throwsRangeError);
      });

      test('returns an element from a non-empty list', () {
        final numbers = <int>[1, 2, 3, 4, 5];

        final element = numbers.randomElement;

        expect(numbers.contains(element), true);
      });

      group('indexWhereOrNull', () {
        test('returns index if found', () {
          final numbers = <int>[1, 2, 3, 4, 5];
          final index = numbers.indexWhereOrNull(
            (number) => number == numbers.last,
          );
          expect(index, isNotNull);
          expect(index, numbers.lastIndexOf(numbers.last));
        });

        test('returns null if not found', () {
          final numbers = <int>[1, 2, 3, 4, 5];
          final index = numbers.indexWhereOrNull((number) => number == 10);
          expect(index, isNull);
        });
      });

      group('getNewIndexAfterRemoval', () {
        test('returns null if list is empty', () {
          expect(<int>[].getNewIndexAfterRemoval(-1), null);
        });

        test(
          'returns null if removedIndex is 0 and list had one element before removal',
          () {
            final list = <int>[1];
            list.removeAt(0);
            expect(list.getNewIndexAfterRemoval(0), null);
          },
        );

        test('returns removedIndex if still within bounds', () {
          final list = [1, 2, 3, 4, 5];
          const removeIndex = 1;
          list.removeAt(removeIndex);
          expect(list.getNewIndexAfterRemoval(removeIndex), removeIndex);
        });

        test('returns previous index if removedIndex is the last element', () {
          final list = [1, 2, 3, 4, 5];
          final removeIndex = list.length - 1;
          list.removeAt(removeIndex);
          expect(list.getNewIndexAfterRemoval(removeIndex), removeIndex - 1);
        });
      });

      group('getReplacementElementAfterRemoval', () {
        test('returns null when list is empty', () {
          expect(<int>[].getReplacementElementAfterRemoval(-1), null);
        });

        test('returns null when removing the only element at index 0', () {
          final list = <int>[1];
          list.removeAt(0);
          expect(list.getReplacementElementAfterRemoval(0), null);
        });

        test('returns next element when it exists', () {
          final list = [1, 2, 3, 4, 5];
          const removeIndex = 1;
          final nextElement = list[removeIndex + 1];
          list.removeAt(removeIndex);
          expect(
            list.getReplacementElementAfterRemoval(removeIndex),
            nextElement,
          );
        });

        test('returns previous element when next does not exist', () {
          final list = [1, 2, 3, 4, 5];
          final removeIndex = list.length - 1;
          final previousElement = list[removeIndex - 1];
          list.removeAt(removeIndex);
          expect(
            list.getReplacementElementAfterRemoval(removeIndex),
            previousElement,
          );
        });
      });
    });
  });
}
