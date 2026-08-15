class Project {
  final int id;
  final String name;
  final bool isActive;
  final String description;

  Project({
    required this.id,
    required this.name,
    required this.isActive,
    required this.description,
  });

  factory Project.fromJson(Map<String, dynamic> json) {
    return Project(
      id: int.parse(json['id'].toString()),
      name: json['name']?.toString() ?? '',
      isActive: json['is_active']?.toString() == '1',
      description: json['description']?.toString() ?? '',
    );
  }

  @override
  String toString() => 'Project(id: $id, name: "$name", active: $isActive)';
}
