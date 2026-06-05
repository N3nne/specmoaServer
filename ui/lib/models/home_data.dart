class HomeData {
  const HomeData({
    required this.myCertifications,
    required this.popularCertifications,
    required this.popularQuestions,
    required this.successStories,
  });

  final List<HomeUserCertification> myCertifications;
  final List<HomePopularCertification> popularCertifications;
  final List<HomeCommunityPost> popularQuestions;
  final List<HomeSuccessStory> successStories;

  factory HomeData.fromJson(Map<String, dynamic> json) {
    return HomeData(
      myCertifications: _list(json['myCertifications'])
          .map(HomeUserCertification.fromJson)
          .toList(),
      popularCertifications: _list(json['popularCertifications'])
          .map(HomePopularCertification.fromJson)
          .toList(),
      popularQuestions: _list(json['popularQuestions'])
          .map(HomeCommunityPost.fromJson)
          .toList(),
      successStories:
          _list(json['successStories']).map(HomeSuccessStory.fromJson).toList(),
    );
  }
}

class HomeUserCertification {
  const HomeUserCertification({
    required this.id,
    required this.status,
    required this.certified,
    required this.certification,
    this.certifiedOn,
    this.targetExamDate,
    this.nextExam,
  });

  final String id;
  final String status;
  final bool certified;
  final String? certifiedOn;
  final String? targetExamDate;
  final HomeCertificationSummary certification;
  final HomeNextExam? nextExam;

  factory HomeUserCertification.fromJson(Map<String, dynamic> json) {
    return HomeUserCertification(
      id: json['id'] as String? ?? '',
      status: json['status'] as String? ?? 'planned',
      certified: json['certified'] as bool? ?? false,
      certifiedOn: json['certifiedOn'] as String?,
      targetExamDate: json['targetExamDate'] as String?,
      certification: HomeCertificationSummary.fromJson(
        (json['certification'] as Map?)?.cast<String, dynamic>() ?? {},
      ),
      nextExam: json['nextExam'] == null
          ? null
          : HomeNextExam.fromJson(
              (json['nextExam'] as Map).cast<String, dynamic>(),
            ),
    );
  }
}

class HomeCertificationSummary {
  const HomeCertificationSummary({
    required this.id,
    required this.name,
    required this.category,
  });

  final String id;
  final String name;
  final String category;

  factory HomeCertificationSummary.fromJson(Map<String, dynamic> json) {
    return HomeCertificationSummary(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      category: json['category'] as String? ?? '',
    );
  }
}

class HomeNextExam {
  const HomeNextExam({
    required this.id,
    required this.title,
    required this.startsOn,
    required this.dDay,
  });

  final String id;
  final String title;
  final String startsOn;
  final int dDay;

  factory HomeNextExam.fromJson(Map<String, dynamic> json) {
    return HomeNextExam(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      startsOn: json['startsOn'] as String? ?? '',
      dDay: json['dDay'] as int? ?? 0,
    );
  }
}

class HomePopularCertification {
  const HomePopularCertification({
    required this.rank,
    required this.id,
    required this.name,
    required this.category,
    required this.examineeCount,
  });

  final int rank;
  final String id;
  final String name;
  final String category;
  final int examineeCount;

  factory HomePopularCertification.fromJson(Map<String, dynamic> json) {
    return HomePopularCertification(
      rank: json['rank'] as int? ?? 0,
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      category: json['category'] as String? ?? '',
      examineeCount: json['examineeCount'] as int? ?? 0,
    );
  }
}

class HomeCommunityPost {
  const HomeCommunityPost({
    required this.id,
    required this.title,
    required this.body,
    required this.certificationName,
    required this.authorName,
    required this.likeCount,
    required this.commentCount,
    required this.viewCount,
    required this.acceptedAnswerBody,
    required this.acceptedAnswerAuthorName,
    required this.dummy,
  });

  final String id;
  final String title;
  final String body;
  final String certificationName;
  final String authorName;
  final int likeCount;
  final int commentCount;
  final int viewCount;
  final String acceptedAnswerBody;
  final String acceptedAnswerAuthorName;
  final bool dummy;

  factory HomeCommunityPost.fromJson(Map<String, dynamic> json) {
    final acceptedAnswer =
        (json['acceptedAnswer'] as Map?)?.cast<String, dynamic>() ?? {};
    final acceptedAuthor =
        (acceptedAnswer['author'] as Map?)?.cast<String, dynamic>() ?? {};

    return HomeCommunityPost(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      body: json['body'] as String? ?? '',
      certificationName: json['certificationName'] as String? ?? '자격증',
      authorName: json['authorName'] as String? ?? '익명',
      likeCount: json['likeCount'] as int? ?? 0,
      commentCount: json['commentCount'] as int? ?? 0,
      viewCount: json['viewCount'] as int? ?? 0,
      acceptedAnswerBody: acceptedAnswer['body'] as String? ?? '',
      acceptedAnswerAuthorName:
          acceptedAuthor['displayName'] as String? ?? '익명',
      dummy: json['dummy'] as bool? ?? false,
    );
  }
}

class HomeSuccessStory {
  const HomeSuccessStory({
    required this.id,
    required this.title,
    required this.description,
    required this.body,
    required this.certificationName,
    required this.studyPeriodDays,
    required this.studyMethod,
    required this.score,
    required this.examAttempt,
    required this.authorName,
    required this.likeCount,
    required this.commentCount,
    required this.viewCount,
    required this.dummy,
  });

  final String id;
  final String title;
  final String description;
  final String body;
  final String certificationName;
  final int studyPeriodDays;
  final String studyMethod;
  final String score;
  final String examAttempt;
  final String authorName;
  final int likeCount;
  final int commentCount;
  final int viewCount;
  final bool dummy;

  factory HomeSuccessStory.fromJson(Map<String, dynamic> json) {
    return HomeSuccessStory(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      description:
          json['description'] as String? ?? json['body'] as String? ?? '',
      body: json['body'] as String? ?? json['description'] as String? ?? '',
      certificationName: json['certificationName'] as String? ?? '자격증',
      studyPeriodDays: json['studyPeriodDays'] as int? ?? 21,
      studyMethod: json['studyMethod'] as String? ?? '',
      score: json['score'] as String? ?? '',
      examAttempt: json['examAttempt'] as String? ?? '초시',
      authorName: json['authorName'] as String? ?? '익명',
      likeCount: json['likeCount'] as int? ?? 0,
      commentCount: json['commentCount'] as int? ?? 0,
      viewCount: json['viewCount'] as int? ?? 0,
      dummy: json['dummy'] as bool? ?? false,
    );
  }
}

List<Map<String, dynamic>> _list(Object? value) {
  if (value is! List) {
    return const [];
  }

  return value
      .whereType<Map>()
      .map((item) => item.cast<String, dynamic>())
      .toList();
}
