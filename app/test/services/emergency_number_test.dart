import 'package:digital_saver/services/emergency_service.dart';
import 'package:digital_saver/services/gemini_service.dart';
import 'package:flutter_test/flutter_test.dart';

/// The AI assistant must never hand out an emergency number that disagrees with
/// the one the rest of the app dials.
///
/// It previously had Egypt's 123 written into the prompt as literal text while
/// the app itself dialled 999, so anyone asking the assistant for emergency
/// help in the UK was given a number belonging to another country. A wrong
/// emergency number is worse than no advice at all, so this is pinned.
void main() {
  tearDown(() {
    EmergencyService.emergencyNumber = '999';
  });

  group('the assistant prompt uses the configured number', () {
    test('the default number appears in the prompt', () {
      EmergencyService.emergencyNumber = '999';
      expect(
        GeminiService.systemPrompt,
        contains('999'),
        reason: 'the prompt must name the number the app actually dials',
      );
    });

    test('changing the setting changes the prompt', () {
      EmergencyService.emergencyNumber = '911';
      expect(GeminiService.systemPrompt, contains('911'));

      EmergencyService.emergencyNumber = '112';
      expect(
        GeminiService.systemPrompt,
        contains('112'),
        reason: 'the prompt is resolved per call, not cached at startup',
      );
    });

    test('the previous number does not linger after a change', () {
      EmergencyService.emergencyNumber = '999';
      expect(GeminiService.systemPrompt, isNot(contains('{{EMERGENCY')));

      EmergencyService.emergencyNumber = '112';
      expect(GeminiService.systemPrompt, isNot(contains('999')));
    });
  });

  group('no foreign emergency numbers are hardcoded in the prompt', () {
    // Every number that was ever wrong in this prompt, or is a valid number for
    // some country we are not necessarily in.
    test('no Egyptian numbers remain', () {
      for (final line in GeminiService.systemPrompt.split('\n')) {
        if (line.contains('Egypt ambulance')) {
          fail('the prompt still names Egyptian services: $line');
        }
      }
    });

    test('only the configured number is offered', () {
      EmergencyService.emergencyNumber = '999';
      final prompt = GeminiService.systemPrompt;

      // Only lines that actually name a number someone would dial are checked.
      // Matching the whole prompt gives false positives: "180" is also a blood
      // pressure threshold in the hypertensive crisis line.
      final dialledLines = prompt
          .split('\n')
          .where((line) =>
              RegExp(r'call\s+\d').hasMatch(line) ||
              line.toLowerCase().contains('emergency number'))
          .join('\n');

      expect(dialledLines, isNotEmpty, reason: 'the guidance must still exist');
      expect(dialledLines, contains('999'));

      // Whole-word matches, so ">180 / >120" cannot trip this.
      for (final foreign in <String>['911', '112', '122', '123', '180']) {
        expect(
          RegExp(r'\b$foreign\b').hasMatch(dialledLines),
          isFalse,
          reason: '$foreign must not be offered as an emergency number',
        );
      }
    });
  });

  group('setEmergencyNumber validation', () {
    test('rejects something that is not a number', () {
      EmergencyService.emergencyNumber = '999';
      expect(EmergencyService.setEmergencyNumber('ring me maybe'), isFalse);
      expect(
        EmergencyService.emergencyNumber,
        '999',
        reason: 'a rejected value must not overwrite the working one',
      );
    });

    test('rejects a too-short number', () {
      expect(EmergencyService.setEmergencyNumber('9'), isFalse);
    });

    test('accepts a configured country number', () {
      expect(EmergencyService.setEmergencyNumber('911'), isTrue);
      expect(EmergencyService.emergencyNumber, '911');
    });

    test('strips formatting characters a person might paste', () {
      expect(EmergencyService.setEmergencyNumber('999'), isTrue);
      expect(EmergencyService.emergencyNumber, '999');
    });
  });
}