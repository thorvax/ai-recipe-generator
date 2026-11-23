import 'package:flutter_test/flutter_test.dart';
import 'package:meal_mind/services/username_service.dart';

// Same cases as the website's resources/js/lib/username.test.ts, so both
// apps accept and refuse exactly the same usernames.
void main() {
  group('normalize', () {
    test('trims and lower-cases, like it is stored', () {
      expect(UsernameService.normalize('  Marc_Cooks '), 'marc_cooks');
    });
  });

  group('validate', () {
    for (final ok in ['marc', 'marc_cooks', 'ana.reyes', 'chef2026', 'abc']) {
      test('accepts "$ok"', () {
        expect(UsernameService.validate(ok), isNull);
      });
    }

    test('accepts upper case typing (it is stored lower-case)', () {
      expect(UsernameService.validate('MarcCooks'), isNull);
    });

    test('requires a username', () {
      expect(UsernameService.validate('   '), 'Username is required');
      expect(UsernameService.validate(null), 'Username is required');
    });

    for (final text in ['ab', 'a' * 21]) {
      test('rejects the length of "$text"', () {
        expect(UsernameService.validate(text), 'Use 3 to 20 characters');
      });
    }

    for (final text in ['marc cooks', 'marc-cooks', 'marc@cooks', 'chéf']) {
      test('rejects other characters in "$text"', () {
        expect(
          UsernameService.validate(text),
          'Use only lowercase letters, numbers, dots and underscores',
        );
      });
    }
  });

  group('baseFrom (auto-made usernames)', () {
    test('uses a full name without spaces', () {
      expect(UsernameService.baseFrom('Marc Bartolome'), 'marcbartolome');
    });

    test('uses the part of an email before "@"', () {
      expect(UsernameService.baseFrom('ana.reyes@gmail.com'), 'ana.reyes');
    });

    test('drops characters that are not allowed and edge dots', () {
      expect(UsernameService.baseFrom('.Chef José-Rizal!.'), 'chefjosrizal');
    });

    test('leaves room for 4 digits within the 20-character limit', () {
      final base = UsernameService.baseFrom('a' * 40);
      expect(base.length, 16);
      expect(UsernameService.validate('${base}1234'), isNull);
    });

    test('falls back to "cook" when too little is left', () {
      expect(UsernameService.baseFrom('Jo'), 'cook');
      expect(UsernameService.baseFrom('李明'), 'cook');
    });
  });

  group('suggestions', () {
    // Always 0.999 keeps the word order unchanged, so the result is
    // predictable (same idea as the website test): sky, chef, tasty, ...
    double noShuffle() => 0.999;

    test('mixes a word with the typed name in different ways', () {
      expect(
        UsernameService.suggestions('rashoumon', random: noShuffle),
        ['skyrashoumon', 'rashoumon_chef', 'tasty.rashoumon'],
      );
    });

    test('gives as many valid, different suggestions as asked', () {
      final list = UsernameService.suggestions('rashoumon', count: 6);
      expect(list.length, 6);
      expect(list.toSet().length, 6);
      for (final s in list) {
        expect(UsernameService.validate(s), isNull);
        expect(s, contains('rashoumon'));
        expect(UsernameService.suggestionWords.any(s.contains), isTrue);
      }
    });

    test('shortens a long name so every suggestion fits 20 characters', () {
      for (final s in UsernameService.suggestions('a' * 20, count: 6)) {
        expect(s.length, lessThanOrEqualTo(20));
        expect(UsernameService.validate(s), isNull);
      }
    });

    test('works from capitals and spaces too (stored lower-case)', () {
      expect(
        UsernameService.suggestions('Rash Oumon', count: 1, random: noShuffle),
        ['skyrashoumon'],
      );
    });
  });
}
