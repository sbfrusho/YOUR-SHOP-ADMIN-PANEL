abstract final class AppRoutes {
  static const splash = '/';
  static const login = '/login';
  static const forgotPassword = '/forgot-password';

  /// Responsive shell: dashboard, orders, products, catalogue, customers.
  static const shell = '/admin';
  static const settings = '/settings';

  /// Order detail; the ID is a path parameter so web links work.
  static const orderDetail = '/orders/:id';
  static String orderDetailFor(String id) => '/orders/$id';
}
