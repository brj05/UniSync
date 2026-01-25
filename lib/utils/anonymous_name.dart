import 'dart:math';

class AnonymousName {
  static final _adjectives = [
    'Silent', 'Brave', 'Calm', 'Gentle', 'Hidden', 'Soft'
  ];

  static final _nouns = [
    'Rain', 'Shadow', 'Wave', 'Moon', 'Cloud', 'Echo'
  ];

  static String generate() {
    final r = Random();
    return '${_adjectives[r.nextInt(_adjectives.length)]}'
           '${_nouns[r.nextInt(_nouns.length)]}'
           '${r.nextInt(100)}';
  }
}
