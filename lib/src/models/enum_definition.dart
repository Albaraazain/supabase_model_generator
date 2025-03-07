class EnumDefinition {
  final String name;
  final String? description;
  final List<String> values;
  final String tableName;
  final String columnName;

  EnumDefinition({
    required this.name,
    this.description,
    required this.values,
    required this.tableName,
    required this.columnName,
  });
}