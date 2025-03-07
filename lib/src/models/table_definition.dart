import 'column_definition.dart';

class TableDefinition {
  final String name;
  final String? description;
  List<ColumnDefinition> columns;

  TableDefinition({
    required this.name,
    this.description,
    this.columns = const [],
  });

  String get className => _formatClassName(name);

  static String _formatClassName(String tableName) {
    return tableName
        .split('_')
        .map((part) => part.isEmpty 
            ? '' 
            : part[0].toUpperCase() + part.substring(1))
        .join('');
  }
}