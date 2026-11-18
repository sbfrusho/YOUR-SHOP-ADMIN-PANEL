/// Firestore collection names shared with the customer app.
/// Changing any value here is a data migration, not a refactor.
abstract final class FirestorePaths {
  static const users = 'users';
  static const products = 'products';
  static const categories = 'categories';
  static const banners = 'banners';
  static const orders = 'orders';
  static const orderItems = 'items';
}
