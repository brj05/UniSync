import 'package:google_generative_ai/google_generative_ai.dart';
import '../config/gemini_config.dart';

enum ModerationResultType {
  approved,
  warning,
  blocked,
}

enum ModerationStatus {
  approved,
  warning,
  blocked,
}

class ModerationResult {
  final ModerationResultType type;
  final String message;
  final String reason;

  const ModerationResult({
    required this.type,
    required this.message,
    required this.reason,
  });

  ModerationStatus get status {
    switch (type) {
      case ModerationResultType.approved:
        return ModerationStatus.approved;
      case ModerationResultType.warning:
        return ModerationStatus.warning;
      case ModerationResultType.blocked:
        return ModerationStatus.blocked;
    }
  }
}

class ContentModerationService {
  static final GenerativeModel _model = GenerativeModel(
    model: 'gemini-2.0-flash',
    apiKey: GeminiConfig.apiKey,
  );

  static const List<String> _blockedPhrases = [
    'kill yourself',
    'go die',
    'you should die',
    'nobody will miss you',
    'you are worthless',
    'you deserve to suffer',
    'your life has no value',
    'i will kill you',
    'i will beat you',
    'i know where you live',
    'i will ruin your life',
    'i will leak your photos',
    'i will expose you',
    'everyone hates you',
    'go away forever',
    'you are a burden',
    'you are a waste',
    "why don't you disappear",
    'send nudes',
    'show your body',
    'slut',
    'whore',
    'randi',
    'characterless girl',
    'item',
    'mc',
    'bc',
    'bkl',
    'madarchod',
    'bhenchod',
    'chutiya',
    'gandu',
    'harami',
    'lavde',
    'lund',
    'jhaatu',
    'kamina',
  ];

  static const List<String> _warningPhrases = [
    'idiot',
    'dumb',
    'stupid',
    'loser',
    'useless',
    'annoying',
    'cringe',
    'attention seeker',
    'fake',
    'pathetic',
    'shut up',
    'nobody cares',
    'get lost',
    'stop talking',
    'embarrassing',
    'bro thinks he is cool',
    'cry more',
    'nobody likes you',
    'you are not good enough',
    'why are you even here',
    'you are the problem',
    'stay away from us',
    'leave the group',
    'know your place',
    'chapri',
    'gawar',
    'nibba',
    'nibbi',
    'wannabe',
    'chamcha',
    'oversmart',
    'faltu',
    'bakwaas',
    'pagal',
    'nalayak',
    'bewakoof',
    'nikamma',
  ];

  static const List<String> _talkItOutSafe = [
    'i feel alone',
    'i feel lonely',
    'i hate my life',
    'i am stressed',
    'i am anxious',
    'nobody understands me',
    'i feel worthless',
    'i feel like giving up',
  ];

  static final List<RegExp> _blockedRegex = [
    RegExp(r'b\s*[.\-_@* ]?\s*c', caseSensitive: false),
    RegExp(r'm\s*[.\-_@* ]?\s*c', caseSensitive: false),
    RegExp(r'm\s*[a@]\s*d\s*a\s*r\s*c\s*h\s*o\s*d', caseSensitive: false),
    RegExp(r'g\s*a+\s*[a@]?\s*n\s*d\s*u', caseSensitive: false),
    RegExp(r'c\s*h\s*[u*]\s*t\s*i\s*y\s*a', caseSensitive: false),
  ];

  static Future<ModerationResult> checkText(
    String text, {
    required String type,
  }) async {
    final cleaned = text.trim().toLowerCase();

    if (cleaned.isEmpty) {
      return const ModerationResult(
        type: ModerationResultType.approved,
        message: '',
        reason: 'Empty text',
      );
    }

    if (type == 'talkitout') {
      for (final safe in _talkItOutSafe) {
        if (cleaned.contains(safe)) {
          return const ModerationResult(
            type: ModerationResultType.approved,
            message: '',
            reason: 'Allowed emotional TalkItOut expression',
          );
        }
      }
    }

    final local = _checkLocalRules(cleaned);
    if (local != null) return local;

    if (_needsGeminiCheck(cleaned)) {
      return await _checkWithGemini(cleaned);
    }

    return const ModerationResult(
      type: ModerationResultType.approved,
      message: '',
      reason: 'No harmful content detected',
    );
  }

  Future<ModerationResult> moderate(
    String text, {
    String type = 'comment',
  }) {
    return checkText(text, type: type);
  }

  static ModerationResult? _checkLocalRules(String text) {
    for (final phrase in _blockedPhrases) {
      if (text.contains(phrase)) {
        return ModerationResult(
          type: ModerationResultType.blocked,
          message:
              'Your message cannot be posted because it contains harmful or offensive language.',
          reason: 'Blocked phrase detected: $phrase',
        );
      }
    }

    for (final regex in _blockedRegex) {
      if (regex.hasMatch(text)) {
        return const ModerationResult(
          type: ModerationResultType.blocked,
          message:
              'Your message cannot be posted because it contains harmful or offensive language.',
          reason: 'Blocked abusive variation detected',
        );
      }
    }

    for (final phrase in _warningPhrases) {
      if (text.contains(phrase)) {
        return ModerationResult(
          type: ModerationResultType.warning,
          message:
              'Your message may sound hurtful or inappropriate. Please consider rewriting it.',
          reason: 'Warning phrase detected: $phrase',
        );
      }
    }

    return null;
  }

  static bool _needsGeminiCheck(String text) {
    final emotional = [
      'nobody wants you',
      'everybody would be happier without you',
      'ruining everything',
      'stop existing',
      'great job ruining',
      'nobody here really wants you',
    ];

    if (text.contains('!!!') || text.contains('???')) return true;

    for (final item in emotional) {
      if (text.contains(item)) return true;
    }

    return false;
  }

  static Future<ModerationResult> _checkWithGemini(String text) async {
    try {
      final prompt = '''
You are moderating content for a student social platform called UniSync.

Return ONLY one word:
APPROVED
WARNING
BLOCKED

Rules:
- APPROVED for normal conversation, emotional venting, sadness, loneliness, stress, anxiety, or harmless criticism
- WARNING for mocking, trolling, discouraging, passive-aggressive or emotionally harmful language
- BLOCKED for abuse, bullying, threats, hate, self-harm encouragement, sexual harassment, discrimination, or telling someone they should die/disappear

Text:
"$text"
''';
      print('Sending to Gemini: $text');
      final response = await _model.generateContent([
        Content.text(prompt),
      ]);
      print('Raw Gemini response: ${response.text}');
      final result = (response.text ?? '').trim().toUpperCase();

      if (result.contains('BLOCKED')) {
        return const ModerationResult(
          type: ModerationResultType.blocked,
          message:
              'Your message cannot be posted because it contains harmful or offensive language.',
          reason: 'Gemini marked the content as blocked',
        );
      }

      if (result.contains('WARNING')) {
        return const ModerationResult(
          type: ModerationResultType.warning,
          message:
              'Your message may sound hurtful or inappropriate. Please consider rewriting it.',
          reason: 'Gemini marked the content as warning',
        );
      }

      return const ModerationResult(
        type: ModerationResultType.approved,
        message: '',
        reason: 'Gemini approved the content',
      );
      
    } catch (e) {
      print('Error occurred while checking with Gemini: $e');
      return const ModerationResult(       
        type: ModerationResultType.warning,
        message:
            'Unable to fully verify message safety. Please review and try again.',
        reason: 'Gemini moderation failed',
      );
    }
  }
}
