class Category {
  const Category({required this.id, required this.name, required this.emoji});

  final String id;
  final String name;
  final String emoji;

  factory Category.fromJson(Map<String, dynamic> json) => Category(
    id: json['id'] as String,
    name: json['name'] as String,
    emoji: json['emoji'] as String,
  );
}
