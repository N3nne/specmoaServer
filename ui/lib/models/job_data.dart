class JobPosting {
  const JobPosting({
    required this.id,
    required this.companyName,
    required this.title,
    required this.occupation,
    required this.region,
    required this.employmentType,
    required this.experienceLevel,
    required this.keywords,
    required this.closesAt,
    required this.status,
  });

  factory JobPosting.fromJson(Map<String, dynamic> json) => JobPosting(
        id: json['id'] as String,
        companyName: json['companyName'] as String,
        title: json['title'] as String,
        occupation: json['occupation'] as String,
        region: json['region'] as String,
        employmentType: json['employmentType'] as String,
        experienceLevel: json['experienceLevel'] as String?,
        keywords: (json['keywords'] as List).cast<String>(),
        closesAt: json['closesAt'] == null
            ? null
            : DateTime.parse(json['closesAt'] as String),
        status: json['status'] as String,
      );

  final String id;
  final String companyName;
  final String title;
  final String occupation;
  final String region;
  final String employmentType;
  final String? experienceLevel;
  final List<String> keywords;
  final DateTime? closesAt;
  final String status;

  String get companyBadge {
    final suffix = companyName.split(' ').last;
    return int.tryParse(suffix) != null
        ? suffix
        : String.fromCharCodes(companyName.runes.take(2));
  }

  String get experienceLabel => switch (experienceLevel) {
        'entry' => '신입',
        'experienced' => '경력',
        'any' => '경력 무관',
        _ => '경력 정보 없음',
      };

  String get employmentLabel => switch (employmentType) {
        'full_time' => '정규직',
        'contract' => '계약직',
        'intern' => '인턴',
        _ => employmentType,
      };

  String deadlineLabel(DateTime asOf) {
    if (status == 'closed') return '마감';
    if (status == 'upcoming') return '접수 예정';
    if (closesAt == null) return '마감일 미정';
    final end = closesAt!.toLocal();
    final now = asOf.toLocal();
    final days = DateTime.utc(end.year, end.month, end.day)
        .difference(DateTime.utc(now.year, now.month, now.day))
        .inDays;
    return days <= 0 ? '오늘 마감' : 'D-$days';
  }
}

class JobPage {
  const JobPage({
    required this.items,
    required this.total,
    required this.offset,
    required this.synthetic,
    required this.notice,
    required this.asOf,
  });

  factory JobPage.fromJson(Map<String, dynamic> json) => JobPage(
        items: (json['items'] as List)
            .map((item) =>
                JobPosting.fromJson((item as Map).cast<String, dynamic>()))
            .toList(),
        total: (json['total'] as num).toInt(),
        offset: (json['offset'] as num).toInt(),
        synthetic: json['synthetic'] as bool,
        notice: json['notice'] as String,
        asOf: DateTime.parse(json['asOf'] as String),
      );

  final List<JobPosting> items;
  final int total;
  final int offset;
  final bool synthetic;
  final String notice;
  final DateTime asOf;
}

class JobOccupation {
  const JobOccupation(this.value, this.count);
  final String value;
  final int count;

  String get label => switch (value) {
        'frontend' => '프론트엔드/웹',
        'backend' => '백엔드/서버',
        'mobile' => '모바일 앱',
        'data' => '데이터 분석',
        'design' => 'UX/UI 디자인',
        'marketing' => '마케팅',
        'accounting' => '회계/재무',
        'electrical' => '전기설비',
        'safety' => '산업안전',
        'mechanical' => '기계설계',
        _ => value,
      };
}

class JobRequirement {
  const JobRequirement(
      {required this.kind,
      required this.name,
      required this.required,
      this.minimumScore});

  factory JobRequirement.fromJson(Map<String, dynamic> json) => JobRequirement(
        kind: json['kind'] as String,
        name: json['name'] as String,
        required: json['required'] as bool,
        minimumScore: json['minimumScore'] as num?,
      );

  final String kind;
  final String name;
  final bool required;
  final num? minimumScore;

  String get label => kind == 'language_score' && minimumScore != null
      ? '$name ${minimumScore! % 1 == 0 ? minimumScore!.toInt() : minimumScore}점 이상'
      : name;
}

class JobDetail {
  const JobDetail(
      {required this.job,
      required this.synthetic,
      required this.notice,
      required this.canApply,
      this.description,
      this.educationLevel,
      this.minExperienceMonths,
      this.salaryText,
      this.requirements,
      this.sourceUrl,
      this.opensAt,
      this.postedAt});

  factory JobDetail.fromJson(Map<String, dynamic> json) => JobDetail(
        job: JobPosting.fromJson(json),
        synthetic: json['synthetic'] as bool,
        notice: json['notice'] as String,
        canApply: json['canApply'] as bool,
        description: json['description'] as String?,
        educationLevel: json['educationLevel'] as String?,
        minExperienceMonths: (json['minExperienceMonths'] as num?)?.toInt(),
        salaryText: json['salaryText'] as String?,
        sourceUrl: json['sourceUrl'] as String?,
        requirements: (json['requirements'] as List?)
            ?.map((item) =>
                JobRequirement.fromJson((item as Map).cast<String, dynamic>()))
            .toList(),
        opensAt: json['opensAt'] == null
            ? null
            : DateTime.parse(json['opensAt'] as String),
        postedAt: json['postedAt'] == null
            ? null
            : DateTime.parse(json['postedAt'] as String),
      );

  final JobPosting job;
  final bool synthetic;
  final String notice;
  final bool canApply;
  final String? description, educationLevel, salaryText, sourceUrl;
  final int? minExperienceMonths;
  final List<JobRequirement>? requirements;
  final DateTime? opensAt, postedAt;

  Uri? get sourceUri {
    if (synthetic || sourceUrl == null) return null;
    final uri = Uri.tryParse(sourceUrl!);
    return uri != null &&
            uri.scheme == 'https' &&
            uri.host.isNotEmpty &&
            uri.userInfo.isEmpty
        ? uri
        : null;
  }

  bool get canOpenApplication =>
      canApply && job.status == 'open' && sourceUri != null;

  String get educationLabel => switch (educationLevel) {
        'any' => '제한 없음',
        'high_school' => '고등학교 졸업 이상',
        'associate' => '전문학사 이상',
        'bachelor' => '학사 이상',
        'master' => '석사 이상',
        'doctor' => '박사 이상',
        _ => '정보 없음',
      };

  String get experienceLabel {
    if (job.experienceLevel == 'any') return '무관';
    if (job.experienceLevel != 'experienced' || minExperienceMonths == null) {
      return job.experienceLabel;
    }
    final months = minExperienceMonths!;
    final years = months ~/ 12;
    final remainder = months % 12;
    return '${[
      if (years > 0) '$years년',
      if (remainder > 0 || years == 0) '$remainder개월'
    ].join(' ')} 이상';
  }
}
