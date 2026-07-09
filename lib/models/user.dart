// A plain Dart class mirroring the "user" object your API returns on login.
// `fromJson` turns the decoded JSON map into a typed User object.
class User {
  final int id;
  final String name;
  final String? serviceNumber;
  final String? rank;
  final String? station;
  final String? email;
  final List<String> roles;

  User({
    required this.id,
    required this.name,
    this.serviceNumber,
    this.rank,
    this.station,
    this.email,
    this.roles = const [],
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as int,
      name: json['name'] as String,
      serviceNumber: json['service_number'] as String?,
      rank: json['rank'] as String?,
      station: json['station'] as String?,
      email: json['email'] as String?,
      roles: (json['roles'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
    );
  }
}
