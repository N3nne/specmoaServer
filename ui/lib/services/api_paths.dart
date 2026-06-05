class ApiPaths {
  const ApiPaths._();

  static const certifications = '/certifications';

  static String certification(String id) => '/certifications/$id';

  static const todayStudyTasks = '/study-tasks/today';

  static String completeStudyTask(String id) => '/study-tasks/$id/complete';

  static const todayStudySessions = '/study-sessions/today';
  static const studySessions = '/study-sessions';
}
