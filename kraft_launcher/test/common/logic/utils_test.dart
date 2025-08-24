import 'package:clock/clock.dart';
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

  group('hasExpired', () {
    test('returns true when expired', () {
      final fixedDateTime = DateTime(2027, 3, 12, 15);
      withClock(Clock.fixed(fixedDateTime), () {
        expect(
          fixedDateTime.subtract(const Duration(seconds: 1)).hasExpired,
          true,
        );
      });
    });

    test('returns false when not expired', () {
      final fixedDateTime = DateTime(2027, 3, 12, 15);
      withClock(Clock.fixed(fixedDateTime), () {
        expect(fixedDateTime.add(const Duration(seconds: 1)).hasExpired, false);
      });
    });
  });
}
