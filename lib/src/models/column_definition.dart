class ColumnDefinition {
  final String name;
  final String dataType;
  final bool isNullable;
  final String? defaultValue;
  final String? description;
  final bool isPrimaryKey;
  bool isForeignKey;
  String? foreignTable;
  String? foreignColumn;
  bool isEnum;
  String? enumType;

  ColumnDefinition({
    required this.name,
    required this.dataType,
    required this.isNullable,
    this.defaultValue,
    this.description,
    this.isPrimaryKey = false,
    this.isForeignKey = false,
    this.foreignTable,
    this.foreignColumn,
    this.isEnum = false,
    this.enumType,
  });

  String get fieldName => _formatFieldName(name);
  
  String get dartType {
    if (isEnum && enumType != null) {
      return isNullable ? '$enumType?' : enumType!;
    }
    
    final baseType = _mapPostgresToDartType(dataType);
    return isNullable ? '$baseType?' : baseType;
  }
  static String _formatFieldName(String columnName) {
    final parts = columnName.split('_');
    return parts[0] + 
           parts.skip(1).map((part) => part.isEmpty 
               ? '' 
               : part[0].toUpperCase() + part.substring(1)).join('');
  }

  static String _mapPostgresToDartType(String postgresType) {
    switch (postgresType.toLowerCase()) {
      case 'integer':
      case 'int':
      case 'smallint':
      case 'bigint':
        return 'int';
      case 'real':
      case 'double precision':
      case 'numeric':
      case 'decimal':
        return 'double';
      case 'boolean':
        return 'bool';
      case 'text':
      case 'character varying':
      case 'varchar':
      case 'char':
        return 'String';
      case 'timestamp':
      case 'timestamp without time zone':
      case 'timestamp with time zone':
      case 'date':
        return 'DateTime';
      case 'jsonb':
      case 'json':
        return 'Map<String, dynamic>';
      case 'uuid':
        return 'String'; // Or use a UUID package
      default:
        return 'dynamic';
    }
  }
}