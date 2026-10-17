/// A topic label such as "Science". Display names are localised by [slug];
/// [name] is the fallback for labels added after this app version shipped.
class Label {
  const Label({required this.id, required this.slug, required this.name});

  factory Label.fromJson(Map<String, Object?> json) => Label(
    id: (json['id']! as num).toInt(),
    slug: json['slug']! as String,
    name: json['name']! as String,
  );

  final int id;
  final String slug;
  final String name;

  @override
  bool operator ==(Object other) => other is Label && other.id == id;

  @override
  int get hashCode => id.hashCode;
}
