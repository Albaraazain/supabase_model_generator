import 'package:postgres/postgres.dart';
import 'package:supabase_model_generator/src/models/enum_definition.dart';

import '../config/database_config.dart';
import '../models/column_definition.dart';
import '../models/table_definition.dart';

class SupabaseSchemaParser {
  final DatabaseConfig config;

  SupabaseSchemaParser(this.config);

  Future<PostgreSQLConnection> createConnection() async {
    final connection = PostgreSQLConnection(
      config.host,
      config.port,
      config.database,
      username: config.username,
      password: config.password,
      useSSL: config.useSSL,
    );
    
    await connection.open();
    return connection;
  }

  Future<List<TableDefinition>> parseSchema(
      {List<String>? includeTables}) async {
    final connection = PostgreSQLConnection(
      config.host,
      config.port,
      config.database,
      username: config.username,
      password: config.password,
      useSSL: config.useSSL,
    );

    try {
      await connection.open();

      // Get tables
      final tables = await _fetchTables(connection, includeTables);

      // Get columns for each table
      for (final table in tables) {
        table.columns = await _fetchColumns(connection, table.name);
      }

      // Get foreign keys
      await _fetchForeignKeys(connection, tables);

      return tables;
    } finally {
      await connection.close();
    }
  }

  Future<List<TableDefinition>> _fetchTables(
    PostgreSQLConnection connection,
    List<String>? includeTables,
  ) async {
    final query = '''
      SELECT table_name, obj_description(('"' || table_name || '"')::regclass) as description
      FROM information_schema.tables
      WHERE table_schema = 'public'
      AND table_type = 'BASE TABLE'
      ${includeTables != null ? "AND table_name IN (${includeTables.map((_) => "@tableName").join(",")})" : ""}
      ORDER BY table_name
    ''';

    final params = includeTables != null
        ? includeTables.asMap().map((i, name) => MapEntry("tableName$i", name))
        : <String, dynamic>{};

    final results = await connection.query(query, substitutionValues: params);

    return results.map((row) {
      return TableDefinition(
        name: row[0] as String,
        description: row[1] as String?,
      );
    }).toList();
  }

  Future<List<ColumnDefinition>> _fetchColumns(
    PostgreSQLConnection connection,
    String tableName,
  ) async {
    final query = '''
      SELECT 
        column_name, 
        data_type, 
        is_nullable = 'YES' as is_nullable,
        column_default,
        col_description('"$tableName"'::regclass, ordinal_position) as description,
        (SELECT COUNT(*) FROM information_schema.key_column_usage 
         WHERE table_name = @tableName AND column_name = c.column_name) > 0 as is_primary_key
      FROM information_schema.columns c
      WHERE table_name = @tableName
      ORDER BY ordinal_position
    ''';

    final results = await connection.query(
      query,
      substitutionValues: {'tableName': tableName},
    );

    return results.map((row) {
      return ColumnDefinition(
        name: row[0] as String,
        dataType: row[1] as String,
        isNullable: row[2] as bool,
        defaultValue: row[3] as String?,
        description: row[4] as String?,
        isPrimaryKey: row[5] as bool,
      );
    }).toList();
  }

  Future<void> _fetchForeignKeys(
    PostgreSQLConnection connection,
    List<TableDefinition> tables,
  ) async {
    final tableMap = {for (var table in tables) table.name: table};

    final query = '''
      SELECT
        tc.table_name, 
        kcu.column_name, 
        ccu.table_name AS foreign_table_name,
        ccu.column_name AS foreign_column_name
      FROM information_schema.table_constraints tc
      JOIN information_schema.key_column_usage kcu
        ON tc.constraint_name = kcu.constraint_name
      JOIN information_schema.constraint_column_usage ccu
        ON ccu.constraint_name = tc.constraint_name
      WHERE tc.constraint_type = 'FOREIGN KEY'
        AND tc.table_schema = 'public'
    ''';

    final results = await connection.query(query);

    for (final row in results) {
      final tableName = row[0] as String;
      final columnName = row[1] as String;
      final foreignTableName = row[2] as String;
      final foreignColumnName = row[3] as String;

      final table = tableMap[tableName];
      final foreignTable = tableMap[foreignTableName];

      if (table != null && foreignTable != null) {
        final column = table.columns.firstWhere(
          (col) => col.name == columnName,
          orElse: () => throw Exception(
              'Column $columnName not found in table $tableName'),
        );

        column.isForeignKey = true;
        column.foreignTable = foreignTableName;
        column.foreignColumn = foreignColumnName;
      }
    }
  }

  Future<List<EnumDefinition>> extractEnums(
      PostgreSQLConnection connection) async {
    final enums = <EnumDefinition>[];

    final query = '''
    SELECT
      ccu.table_name,
      ccu.column_name,
      cc.check_clause
    FROM information_schema.table_constraints tc
    JOIN information_schema.check_constraints cc
      ON tc.constraint_name = cc.constraint_name
    JOIN information_schema.constraint_column_usage ccu
      ON tc.constraint_name = ccu.constraint_name
    WHERE tc.constraint_type = 'CHECK'
      AND tc.table_schema = 'public'
      AND cc.check_clause LIKE '%IN (%'
  ''';

    final results = await connection.query(query);

    for (final row in results) {
      final tableName = row[0] as String;
      final columnName = row[1] as String;
      final checkClause = row[2] as String;

      // Extract values from the check clause
      final regex = RegExp(r"IN \(([^)]+)\)");
      final match = regex.firstMatch(checkClause);

      if (match != null) {
        final valuesString = match.group(1)!;
        final valuesList = valuesString
            .split(',')
            .map((s) => s.trim().replaceAll("'", ""))
            .toList();

        final enumName =
            '${_formatClassName(tableName)}${_formatClassName(columnName)}Enum';

        enums.add(EnumDefinition(
          name: enumName,
          values: valuesList,
          tableName: tableName,
          columnName: columnName,
        ));
      }
    }

    return enums;
  }

  static String _formatClassName(String name) {
    return name
        .split('_')
        .map((part) =>
            part.isEmpty ? '' : part[0].toUpperCase() + part.substring(1))
        .join('');
  }
}
