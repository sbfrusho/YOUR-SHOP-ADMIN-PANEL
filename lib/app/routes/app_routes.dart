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

  static const productNew = '/products/new';
  static const productEdit = '/products/edit/:id';
  static String productEditFor(String id) => '/products/edit/$id';

  static const categoryNew = '/categories/new';
  static const categoryEdit = '/categories/edit/:id';
  static String categoryEditFor(String id) => '/categories/edit/$id';

  static const customerDetail = '/customers/:id';
  static String customerDetailFor(String id) => '/customers/$id';
}
