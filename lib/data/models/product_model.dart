import '../../core/config/app_config.dart';
import '../../core/utils/json_parsing.dart';
import '../../core/utils/pricing.dart';

/// `products/{productId}`, shared with the customer app.
///
/// Legacy formats are kept on write: prices and stock are **strings**,
/// sizes share one stock counter. `salePercent` (number) and `isArchived`
/// were added by the admin panel; the customer app reads `salePrice`.
class ProductModel {
  const ProductModel({
    required this.id,
    required this.name,
    this.description = '',
    this.categoryId = '',
    this.categoryName = '',
    this.fullPrice = 0,
    this.salePrice = 0,
    this.isSale = false,
    this.salePercent = 0,
    this.stock = 0,
    this.sizes = const [],
    this.images = const [],
    this.sellerEmail = '',
    this.deliveryTime = '',
    this.isArchived = false,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String name;
  final String description;
  final String categoryId;
  final String categoryName;
  final double fullPrice;
  final double salePrice;
  final bool isSale;

  /// 0 to [Pricing.maxPercent].
  final int salePercent;
  final int stock;
  final List<String> sizes;
  final List<String> images;
  final String sellerEmail;
  final String deliveryTime;
  final bool isArchived;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  String? get thumbnail => images.isEmpty ? null : images.first;

  /// What the customer pays.
  double get price => isSale && salePrice > 0 ? salePrice : fullPrice;
  bool get hasDiscount => price < fullPrice && price > 0;

  bool get isOutOfStock => stock <= 0;
  bool get isLowStock => !isOutOfStock && stock <= AppConfig.lowStockThreshold;

  factory ProductModel.fromMap(Map<String, dynamic> map, {String? id}) {
    final full = asDouble(map['fullPrice']);
    final sale = asDouble(map['salePrice']);
    final isSale = asBool(map['isSale']);
    final stored = asInt(map['salePercent'], fallback: -1);
    return ProductModel(
      id: asString(map['productId'], fallback: id ?? ''),
      name: asString(map['productName']),
      description: asString(map['productDescription']),
      categoryId: asString(map['categoryId']),
      categoryName: asString(map['categoryName']),
      fullPrice: full,
      salePrice: sale,
      isSale: isSale,
      salePercent: stored >= 0
          ? stored
          : (isSale ? Pricing.percentOff(full, sale) : 0),
      stock: asInt(map['quantity']),
      sizes: asStringList(map['productSizes']),
      images: asStringList(map['productImages']),
      sellerEmail: asString(map['email']),
      deliveryTime: asString(map['deliveryTime']),
      isArchived: asBool(map['isArchived']),
      createdAt: asDateTime(map['createdAt']),
      updatedAt: asDateTime(map['updatedAt']),
    );
  }

  /// Fields the form owns, in the legacy formats. Timestamps are added by
  /// the repository.
  Map<String, dynamic> toMap() {
    final onSale = isSale && salePercent > 0;
    // An explicit salePrice wins (kept from legacy data); otherwise it is
    // computed from the percentage.
    final sale = !onSale
        ? fullPrice
        : (salePrice > 0
              ? salePrice
              : Pricing.salePrice(fullPrice, salePercent));
    return {
      'productId': id,
      'productName': name,
      'productDescription': description,
      'categoryId': categoryId,
      'categoryName': categoryName,
      'fullPrice': Pricing.legacyString(fullPrice),
      'salePrice': Pricing.legacyString(sale),
      'isSale': onSale,
      'salePercent': onSale ? salePercent : 0,
      'quantity': '$stock',
      'productSizes': sizes,
      'productImages': images,
      'email': sellerEmail,
      'deliveryTime': deliveryTime,
      'isArchived': isArchived,
    };
  }
}
