class ApiPaths {
  const ApiPaths._();

  static const authLogin = '/auth/login';
  static const authRegister = '/auth/register';
  static const authMe = '/auth/me';
  static const avatars = '/avatars';
  static const profile = '/profile';
  static const profileAvatar = '/profile/avatar';
  static const sections = '/sections';
  static const dailyTest = '/daily-test';
  static const completeDailyTest = '/daily-test/complete';

  static String sectionDetails(int sectionId) => '/sections/$sectionId';

  static String sectionLevels(int sectionId) => '/sections/$sectionId/levels';

  static String levelDetails(int levelId) => '/levels/$levelId';

  static String levelWords(int levelId) => '/levels/$levelId/words';

  static String markLevelWordsLearned(int levelId) =>
      '/levels/$levelId/words/mark-learned';

  static String levelSession(int levelId) => '/levels/$levelId/session';

  static String completeLevel(int levelId) => '/levels/$levelId/complete';
}
