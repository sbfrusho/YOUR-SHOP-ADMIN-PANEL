import '../../core/utils/json_parsing.dart';

/// `users/{uid}`. Field names (including the historical `adress` spelling)
/// are shared with the admin app.
class UserModel {
  const UserModel({
    required this.uid,
    required this.email,
    this.name = '',
    this.phone = '',
    this.isAdmin = false,
    this.deviceToken = '',
    this.city = '',
    this.state = '',
    this.country = '',
    this.road = '',
    this.postalCode = '',
    this.address = '',
    this.photoUrl = '',
    this.disabled = false,
    this.disabledAt,
  });

  final String uid;
  final String email;
  final String name;
  final String phone;
  final bool isAdmin;
  final String deviceToken;
  final String city;
  final String state;
  final String country;
  final String road;
  final String postalCode;
  final String address;

  /// Profile photo in Firebase Storage (`users/{uid}/avatar.jpg`).
  final String photoUrl;

  /// Set by the `adminSetCustomerDisabled` Cloud Function; the Auth
  /// account is disabled too, so the customer can't sign in.
  final bool disabled;
  final DateTime? disabledAt;

  /// Name to show, falling back to the email.
  String get displayName => name.trim().isEmpty ? email : name.trim();

  /// Up to two initials for an avatar placeholder.
  String get initials {
    final parts = displayName
        .split(RegExp(r'[\s@._-]+'))
        .where((p) => p.isNotEmpty)
        .toList();
    if (parts.isEmpty) return '?';
    final first = parts.first[0];
    final second = parts.length > 1 ? parts[1][0] : '';
    return (first + second).toUpperCase();
  }

  /// Whether [query] (lower case) matches the name, email or phone.
  bool matchesQuery(String query) {
    if (query.isEmpty) return true;
    final digits = query.replaceAll(RegExp('[^0-9]'), '');
    return name.toLowerCase().contains(query) ||
        email.toLowerCase().contains(query) ||
        uid.toLowerCase() == query ||
        (digits.length >= 3 &&
            phone.replaceAll(RegExp('[^0-9]'), '').contains(digits));
  }

  factory UserModel.fromMap(Map<String, dynamic> map, {String? uid}) =>
      UserModel(
        uid: asString(map['uId'], fallback: uid ?? ''),
        email: asString(map['email']),
        name: asString(map['name']),
        phone: asString(map['phone']),
        isAdmin: asBool(map['isAdmin']),
        deviceToken: asString(map['deviceToken']),
        city: asString(map['city']),
        state: asString(map['state']),
        country: asString(map['country']),
        road: asString(map['road']),
        postalCode: asString(map['postalCode']),
        address: asString(map['adress']),
        photoUrl: asString(map['photoUrl']),
        disabled: asBool(map['disabled']),
        disabledAt: asDateTime(map['disabledAt']),
      );

  Map<String, dynamic> toMap() => {
    'uId': uid,
    'email': email,
    'name': name,
    'phone': phone,
    'isAdmin': isAdmin,
    'deviceToken': deviceToken,
    'city': city,
    'state': state,
    'country': country,
    'road': road,
    'postalCode': postalCode,
    'adress': address,
    'photoUrl': photoUrl,
  };

  /// Fields a customer may edit themselves.
  Map<String, dynamic> toProfileUpdate() => {
    'name': name,
    'phone': phone,
    'city': city,
    'state': state,
    'country': country,
    'road': road,
    'postalCode': postalCode,
    'adress': address,
  };

  UserModel copyWith({
    String? name,
    String? phone,
    String? city,
    String? state,
    String? country,
    String? road,
    String? postalCode,
    String? address,
    String? photoUrl,
  }) => UserModel(
    uid: uid,
    email: email,
    isAdmin: isAdmin,
    deviceToken: deviceToken,
    name: name ?? this.name,
    phone: phone ?? this.phone,
    city: city ?? this.city,
    state: state ?? this.state,
    country: country ?? this.country,
    road: road ?? this.road,
    postalCode: postalCode ?? this.postalCode,
    address: address ?? this.address,
    photoUrl: photoUrl ?? this.photoUrl,
  );
}
