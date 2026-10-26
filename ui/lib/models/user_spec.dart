enum SpecType {
  certification('certification', '자격증'),
  languageScore('language_score', '어학 성적'),
  educationRecord('education_record', '학점·학력'),
  award('award', '수상·공모전'),
  project('project', '프로젝트'),
  workExperience('work_experience', '인턴십·실무'),
  externalActivity('external_activity', '대외활동·서포터즈'),
  training('training', '교육·부트캠프');

  const SpecType(this.apiValue, this.label);
  final String apiValue;
  final String label;
  bool get isExamScore => index < 4;
  static SpecType parse(String value) =>
      values.firstWhere((type) => type.apiValue == value);
}

class UserSpec {
  const UserSpec(
      {required this.id, required this.type, required this.data, this.title});
  final String id;
  final SpecType type;
  final String? title;
  final Map<String, dynamic> data;
  String get displayTitle =>
      title?.trim().isNotEmpty == true ? title! : '${type.label} (이름 미입력)';
  String text(String key) => data[key]?.toString() ?? '';
  factory UserSpec.fromJson(Map<String, dynamic> json) => UserSpec(
        id: json['id'] as String,
        type: SpecType.parse(json['type'] as String),
        title: json['title'] as String?,
        data: (json['data'] as Map?)?.cast<String, dynamic>() ?? {},
      );
}
