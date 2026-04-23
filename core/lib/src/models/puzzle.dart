class Puzzle {
  const Puzzle({
    required this.id,
    required this.slug,
    required this.vectorUrl,
    required this.category,
    required this.difficulty,
  });

  final String id;
  final String slug;
  final String vectorUrl;
  final String category;
  final int difficulty;

  factory Puzzle.fromJson(Map<String, dynamic> json) => Puzzle(
        id: json['id'] as String,
        slug: json['slug'] as String,
        vectorUrl: json['vector_url'] as String,
        category: json['category'] as String,
        difficulty: (json['difficulty'] as num).toInt(),
      );
}

class PuzzleTranslation {
  const PuzzleTranslation({
    required this.puzzleId,
    required this.langCode,
    required this.targetWord,
    required this.acceptedSynonyms,
    this.phonetic,
  });

  final String puzzleId;
  final String langCode;
  final String targetWord;
  final List<String> acceptedSynonyms;
  final String? phonetic;

  /// All accepted forms (target + synonyms), used by the matcher.
  List<String> get allAcceptedForms => [targetWord, ...acceptedSynonyms];

  factory PuzzleTranslation.fromJson(Map<String, dynamic> json) =>
      PuzzleTranslation(
        puzzleId: json['puzzle_id'] as String,
        langCode: json['lang_code'] as String,
        targetWord: json['target_word'] as String,
        acceptedSynonyms: (json['accepted_synonyms'] as List?)
                ?.map((e) => e as String)
                .toList() ??
            const [],
        phonetic: json['phonetic'] as String?,
      );
}
