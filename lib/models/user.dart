class User {
  final int id;
  final String username;
  final String name;
  final String email;

  User({
    required this.id,
    required this.username,
    required this.name,
    required this.email,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: int.parse(json['id'].toString()),
      username: json['username']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
    );
  }

  @override
  String toString() => 'User(id: $id, username: "$username", name: "$name")';
}
