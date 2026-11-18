import '../../core/utils/json_parsing.dart';

/// `categories/{id}`. Field names are shared with the customer app.
class CategoryModel {
  const CategoryModel({
    required this.id,
    required this.name,
    this.imageUrl = '',
  });

  final String id;
  final String name;
  final String imageUrl;

  factory CategoryModel.fromMap(Map<String, dynamic> map, {String? id}) =>
      CategoryModel(
        id: asString(map['categoryId'], fallback: id ?? ''),
        name: asString(map['categoryName']),
        imageUrl: asString(map['categoryImg']),
      );

  Map<String, dynamic> toMap() => {
    'categoryId': id,
    'categoryName': name,
    'categoryImg': imageUrl,
  };
}
