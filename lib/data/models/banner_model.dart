import '../../core/utils/json_parsing.dart';

/// `banners/{id}`. The customer app reads `imageUrl` and orders the home
/// carousel by `sortOrder` (legacy banners without one come last).
class BannerModel {
  const BannerModel({
    required this.id,
    required this.imageUrl,
    this.sortOrder,
    this.createdAt,
  });

  final String id;
  final String imageUrl;

  /// `null` for legacy banners; set for all once the admin reorders.
  final int? sortOrder;
  final DateTime? createdAt;

  factory BannerModel.fromMap(Map<String, dynamic> map, {required String id}) =>
      BannerModel(
        id: id,
        imageUrl: asString(map['imageUrl']),
        sortOrder: map['sortOrder'] == null ? null : asInt(map['sortOrder']),
        createdAt: asDateTime(map['createdAt']),
      );

  /// Carousel order: by [sortOrder], unnumbered last, then by ID so the
  /// order is stable. The customer app uses the same rule.
  static int compare(BannerModel a, BannerModel b) {
    final x = a.sortOrder, y = b.sortOrder;
    if (x != null && y != null && x != y) return x.compareTo(y);
    if (x == null && y != null) return 1;
    if (x != null && y == null) return -1;
    return a.id.compareTo(b.id);
  }
}
