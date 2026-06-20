class FilterCategory {
  const FilterCategory({
    required this.id,
    required this.name,
    required this.values,
  });

  final String id;
  final String name;
  final List<String> values;

  bool get isNew => id.trim().isEmpty;

  factory FilterCategory.fromJson(Map<String, dynamic> json) {
    final valuesRaw = json['values'];
    final values = switch (valuesRaw) {
      final List<dynamic> list => [
          for (final item in list) item.toString(),
        ],
      _ => const <String>[],
    };

    return FilterCategory(
      id: '${json['id']}',
      name: '${json['name']}',
      values: values,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'values': values,
      };

  FilterCategory copyWith({
    String? id,
    String? name,
    List<String>? values,
  }) {
    return FilterCategory(
      id: id ?? this.id,
      name: name ?? this.name,
      values: values ?? this.values,
    );
  }
}
