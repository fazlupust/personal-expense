import 'entry_type.dart';

class CategoryModel {
  const CategoryModel({
    required this.name,
    required this.emoji,
    required this.type,
    this.isDefault = false,
  });

  final String name;
  final String emoji;
  final EntryType type;
  final bool isDefault;

  Map<String, dynamic> toJson() => {
        'name': name,
        'emoji': emoji,
        'type': type.name,
        'isDefault': isDefault,
      };

  factory CategoryModel.fromJson(Map<String, dynamic> j) => CategoryModel(
        name: j['name'] as String,
        emoji: j['emoji'] as String,
        type: EntryType.values.byName(j['type'] as String),
        isDefault: (j['isDefault'] as bool?) ?? false,
      );
}
