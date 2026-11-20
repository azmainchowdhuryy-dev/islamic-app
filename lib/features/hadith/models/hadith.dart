class Hadith {
  final String id;
  final int order;
  final String category;
  final String arabicText;
  final String banglaTranslation;
  final String englishTranslation;
  final String narrator;
  final String reference;
  final String source;
  final String grade;
  final String translationSource;
  final String licenseNote;
  final bool dailyEligible;
  final bool verified;
  final String verifiedBy;
  final String verifiedDate;

  const Hadith({
    required this.id,
    required this.order,
    required this.category,
    required this.arabicText,
    required this.banglaTranslation,
    required this.englishTranslation,
    required this.narrator,
    required this.reference,
    required this.source,
    required this.grade,
    required this.translationSource,
    required this.licenseNote,
    required this.dailyEligible,
    required this.verified,
    required this.verifiedBy,
    required this.verifiedDate,
  });

  factory Hadith.fromJson(Map<String, dynamic> j) => Hadith(
        id: j['id'] as String,
        order: (j['order'] ?? 0) as int,
        category: (j['category'] ?? '') as String,
        arabicText: (j['arabic_text'] ?? '') as String,
        banglaTranslation: (j['bangla_translation'] ?? '') as String,
        englishTranslation: (j['english_translation'] ?? '') as String,
        narrator: (j['narrator'] ?? '') as String,
        reference: (j['reference'] ?? '') as String,
        source: (j['source'] ?? '') as String,
        grade: (j['grade'] ?? '') as String,
        translationSource: (j['translation_source'] ?? '') as String,
        licenseNote: (j['license_note'] ?? '') as String,
        dailyEligible: (j['daily_eligible'] ?? false) as bool,
        verified: (j['verified'] ?? false) as bool,
        verifiedBy: (j['verified_by'] ?? '') as String,
        verifiedDate: (j['verified_date'] ?? '') as String,
      );
}
