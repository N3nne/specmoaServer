import 'job_comparison.dart';

class AiDemoAvailability {
  const AiDemoAvailability(
      {required this.enabled,
      required this.profileLabel,
      required this.profileSummary});

  factory AiDemoAvailability.fromJson(Map<String, dynamic> json) {
    if (json['enabled'] is! bool ||
        json['synthetic'] != true ||
        json['profileId'] != 'backend') {
      throw const FormatException('Invalid AI demo availability');
    }
    return AiDemoAvailability(
        enabled: json['enabled'] as bool,
        profileLabel: _text(json['profileLabel']),
        profileSummary: _text(json['profileSummary']));
  }

  final bool enabled;
  final String profileLabel, profileSummary;
}

class AiDemoReason {
  const AiDemoReason(
      {required this.specQuote,
      required this.jobQuote,
      required this.explanation});

  factory AiDemoReason.fromJson(Map<String, dynamic> json) {
    if (!_text(json['specId']).startsWith('demo-backend-')) {
      throw const FormatException('Mismatched AI demo evidence');
    }
    _text(json['specField']);
    _text(json['jobField']);
    return AiDemoReason(
        specQuote: _text(json['specQuote']),
        jobQuote: _text(json['jobQuote']),
        explanation: _text(json['explanation']));
  }

  final String specQuote, jobQuote, explanation;
}

class AiDemoRecommendation {
  const AiDemoRecommendation(
      {required this.rank,
      required this.externalId,
      required this.companyName,
      required this.title,
      required this.region,
      required this.experienceLevel,
      required this.employmentType,
      required this.reasons,
      required this.cautions,
      required this.comparison});

  factory AiDemoRecommendation.fromJson(Map<String, dynamic> json) {
    final id = _text(json['jobExternalId']);
    final rank = json['rank'];
    if (!RegExp(r'^specmoa-demo-v1-\d{3}$').hasMatch(id) ||
        rank is! int ||
        rank < 1 ||
        rank > 3 ||
        !const ['entry', 'experienced', 'any', null]
            .contains(json['experienceLevel']) ||
        !const ['full_time', 'contract', 'intern']
            .contains(json['employmentType'])) {
      throw const FormatException('Invalid AI demo job');
    }
    final reasons = _list(json['reasons'])
        .map((e) => AiDemoReason.fromJson(_object(e)))
        .toList();
    final cautions = _list(json['cautions']).map(_text).toList();
    if (reasons.isEmpty || reasons.length > 3 || cautions.length > 3) {
      throw const FormatException('Invalid AI recommendation details');
    }
    return AiDemoRecommendation(
        rank: rank,
        externalId: id,
        companyName: _text(json['companyName']),
        title: _text(json['title']),
        region: _text(json['region']),
        experienceLevel: json['experienceLevel'] as String?,
        employmentType: json['employmentType'] as String,
        reasons: List.unmodifiable(reasons),
        cautions: List.unmodifiable(cautions),
        comparison: JobComparison.fromJson(_object(json['comparison'])));
  }

  final int rank;
  final String externalId, companyName, title, region, employmentType;
  final String? experienceLevel;
  final List<AiDemoReason> reasons;
  final List<String> cautions;
  final JobComparison comparison;

  String get metadata => '$region · ${switch (experienceLevel) {
        'entry' => '신입',
        'experienced' => '경력',
        'any' => '경력 무관',
        _ => '경력 미제공',
      }} · ${switch (employmentType) {
        'full_time' => '정규직',
        'contract' => '계약직',
        _ => '인턴',
      }}';
}

class AiDemoResult {
  const AiDemoResult(
      {required this.model,
      required this.generatedAt,
      required this.cached,
      required this.notice,
      required this.profileLabel,
      required this.profileSummary,
      required this.candidateCount,
      required this.items});

  factory AiDemoResult.fromJson(Map<String, dynamic> json) {
    final timestamp = DateTime.tryParse(
        json['generatedAt'] is String ? json['generatedAt'] as String : '');
    final count = json['candidateCount'];
    if (json['method'] != 'gemini-demo-v1' ||
        json['synthetic'] != true ||
        json['profileId'] != 'backend' ||
        json['cached'] is! bool ||
        timestamp == null ||
        !timestamp.isUtc ||
        count is! int ||
        count < 0) {
      throw const FormatException('Invalid AI demo result');
    }
    final items = _list(json['items'])
        .map((e) => AiDemoRecommendation.fromJson(_object(e)))
        .toList();
    if (items.length > 3 ||
        items.length > count ||
        items.map((e) => e.externalId).toSet().length != items.length ||
        items.indexed.any((e) => e.$2.rank != e.$1 + 1)) {
      throw const FormatException('Inconsistent AI demo ranking');
    }
    return AiDemoResult(
        model: _text(json['model']),
        generatedAt: timestamp,
        cached: json['cached'] as bool,
        notice: _text(json['notice']),
        profileLabel: _text(json['profileLabel']),
        profileSummary: _text(json['profileSummary']),
        candidateCount: count,
        items: List.unmodifiable(items));
  }

  final String model, notice, profileLabel, profileSummary;
  final DateTime generatedAt;
  final bool cached;
  final int candidateCount;
  final List<AiDemoRecommendation> items;
}

String _text(Object? value) {
  if (value is! String || value.trim().isEmpty || value.length > 500) {
    throw const FormatException('Invalid AI demo text');
  }
  return value;
}

List _list(Object? value) {
  if (value is! List) throw const FormatException('Invalid AI demo list');
  return value;
}

Map<String, dynamic> _object(Object? value) {
  if (value is! Map || value.keys.any((e) => e is! String)) {
    throw const FormatException('Invalid AI demo object');
  }
  return value.cast<String, dynamic>();
}
