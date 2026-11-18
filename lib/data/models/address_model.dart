import '../../core/utils/json_parsing.dart';

/// `users/{uid}/addresses/{id}`, written by the customer app (read-only
/// here).
class AddressModel {
  const AddressModel({
    required this.id,
    this.label = '',
    this.fullName = '',
    this.phone = '',
    this.address = '',
    this.street = '',
    this.city = '',
    this.state = '',
    this.postalCode = '',
    this.country = '',
    this.isDefault = false,
  });

  final String id;
  final String label;
  final String fullName;
  final String phone;
  final String address;
  final String street;
  final String city;
  final String state;
  final String postalCode;
  final String country;
  final bool isDefault;

  factory AddressModel.fromMap(
    Map<String, dynamic> map, {
    required String id,
  }) => AddressModel(
    id: id,
    label: asString(map['label']),
    fullName: asString(map['fullName']),
    phone: asString(map['phone']),
    address: asString(map['address']),
    street: asString(map['street']),
    city: asString(map['city']),
    state: asString(map['state']),
    postalCode: asString(map['postalCode']),
    country: asString(map['country']),
    isDefault: asBool(map['isDefault']),
  );

  /// One line, empty parts skipped.
  String get formatted => [
    address,
    street,
    city,
    [state, postalCode].where((s) => s.isNotEmpty).join(' '),
    country,
  ].where((s) => s.trim().isNotEmpty).join(', ');
}
