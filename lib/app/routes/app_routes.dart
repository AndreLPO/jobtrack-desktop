abstract final class AppRoutes {
  static const dashboard = '/dashboard';
  static const applications = '/applications';
  static const newApplication = '/applications/new';
  static const editApplication = '/applications/:id/edit';
  static const followUps = '/follow-ups';
  static const settings = '/settings';

  static String editApplicationPath(String id) => '/applications/$id/edit';
}
