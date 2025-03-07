import 'dart:async';
import 'package:build/build.dart';
import 'package:postgres/postgres.dart';
import 'package:supabase_model_generator/src/generators/enum_generator.dart';
import 'package:yaml/yaml.dart';
import 'package:path/path.dart' as p;

import '../config/database_config.dart';
import '../parsers/supabase_schema_parser.dart';
import '../generators/model_generator.dart';
import '../generators/repository_generator.dart';

class ModelBuilder implements Builder {
  final BuilderOptions options;

  ModelBuilder(this.options);

  @override
  Map<String, List<String>> get buildExtensions {
    return const {
      '.dart': ['.model.dart', '.repository.dart'],
    };
  }

  @override
  Future<void> build(BuildStep buildStep) async {
    // Try to load configuration from current directory first
    String yamlString;
    try {
      yamlString = await buildStep.readAsString(
        AssetId(buildStep.inputId.package, 'supabase_config.yaml'),
      );
    } catch (_) {
      // If not found in package root, try the current directory
      try {
        yamlString = await buildStep.readAsString(
          AssetId(buildStep.inputId.package,
              '${buildStep.inputId.path}/../../../supabase_config.yaml'),
        );
      } catch (_) {
        log.warning(
            'No supabase_config.yaml found in package root or current directory. Skipping model generation.');
        return;
      }
    }
    final yamlMap = loadYaml(yamlString) as Map;

    final dbConfig = DatabaseConfig(
      host: yamlMap['database']['host'] as String,
      port: yamlMap['database']['port'] as int,
      database: yamlMap['database']['name'] as String,
      username: yamlMap['database']['username'] as String,
      password: yamlMap['database']['password'] as String,
      useSSL: yamlMap['database']['use_ssl'] as bool? ?? false,
    );

    // Parse included tables (if provided)
    final includeTables = yamlMap['tables'] != null
        ? List<String>.from(yamlMap['tables'] as List)
        : null;

    // Parse schema
    final parser = SupabaseSchemaParser(dbConfig);
    final tables = await parser.parseSchema(includeTables: includeTables);

    // Extract enums from check constraints
    final connection = PostgreSQLConnection(
      dbConfig.host,
      dbConfig.port,
      dbConfig.database,
      username: dbConfig.username,
      password: dbConfig.password,
      useSSL: dbConfig.useSSL,
    );

    try {
      await connection.open();
      final enums = await parser.extractEnums(connection);

      // Generate enums
      final enumGenerator = EnumGenerator();
      for (final enumDef in enums) {
        final enumContent = enumGenerator.generateEnum(enumDef);
        final enumAsset = AssetId(
          buildStep.inputId.package,
          p.join('lib', 'models', 'generated', 'enums',
              '${enumDef.name.toLowerCase()}.dart'),
        );
        await buildStep.writeAsString(enumAsset, enumContent);

        // Update table column type if it matches an enum
        for (final table in tables) {
          if (table.name == enumDef.tableName) {
            for (final column in table.columns) {
              if (column.name == enumDef.columnName) {
                column.isEnum = true;
                column.enumType = enumDef.name;
              }
            }
          }
        }
      }
    } finally {
      await connection.close();
    }

    // Generate model and repository classes
    final modelGenerator = ModelGenerator();
    final repositoryGenerator = RepositoryGenerator();

    for (final table in tables) {
      // Generate model
      final modelContent = modelGenerator.generateModel(table);
      final modelAsset = AssetId(
        buildStep.inputId.package,
        p.join('lib', 'models', 'generated', '${table.name}.dart'),
      );
      await buildStep.writeAsString(modelAsset, modelContent);

      // Generate repository
      final repositoryContent = repositoryGenerator.generateRepository(table);
      final repositoryAsset = AssetId(
        buildStep.inputId.package,
        p.join('lib', 'repositories', 'generated',
            '${table.name}_repository.dart'),
      );
      await buildStep.writeAsString(repositoryAsset, repositoryContent);
    }
  }
}
