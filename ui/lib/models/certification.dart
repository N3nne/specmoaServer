enum CertificationStatus {
  inProgress,
  scheduled,
  certified,
}

class Certification {
  const Certification({
    required this.title,
    required this.category,
    required this.description,
    required this.progress,
    required this.status,
    required this.examDate,
    required this.score,
  });

  final String title;
  final String category;
  final String description;
  final double progress;
  final CertificationStatus status;
  final String examDate;
  final int score;
}
