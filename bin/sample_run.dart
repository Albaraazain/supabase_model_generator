import 'dart:io';
import 'package:yaml/yaml.dart';
import 'package:supabase_model_generator/src/config/database_config.dart';
import 'package:supabase_model_generator/src/parsers/supabase_schema_parser.dart';
import 'package:supabase_model_generator/src/generators/model_generator.dart';
import 'package:supabase_model_generator/src/generators/repository_generator.dart';
import 'package:supabase_model_generator/src/generators/enum_generator.dart';

void main() async {
  // Load config
  final file = File('supabase_config.yaml');
  if (!await file.exists()) {
    print('Error: supabase_config.yaml not found!');
    exit(1);
  }

  final yamlString = await file.readAsString();
  final yamlMap = loadYaml(yamlString) as Map;
  
  final dbConfig = DatabaseConfig(
    host: yamlMap['database']['host'] as String,
    port: yamlMap['database']['port'] as int,
    database: yamlMap['database']['name'] as String,
    username: yamlMap['database']['username'] as String,
    password: yamlMap['database']['password'] as String,
    useSSL: yamlMap['database']['use_ssl'] as bool? ?? false,
  );
  
  print('Connecting to database...');
  final parser = SupabaseSchemaParser(dbConfig);
  
  print('Fetching schema...');
  final tables = await parser.parseSchema();
  
  print('Found ${tables.length} tables:');
  for (final table in tables) {
    print('- ${table.name} (${table.columns.length} columns)');
  }
  
  // Create output directories
  final modelsDir = Directory('output/models');
  final reposDir = Directory('output/repositories');
  final enumsDir = Directory('output/enums');
  
  await modelsDir.create(recursive: true);
  await reposDir.create(recursive: true);
  await enumsDir.create(recursive: true);
  
  // Generate models and repositories
  final modelGen = ModelGenerator();
  final repoGen = RepositoryGenerator();
  final enumGen = EnumGenerator();
  
  for (final table in tables) {
    final modelContent = modelGen.generateModel(table);
    final repoContent = repoGen.generateRepository(table);
    
    await File('${modelsDir.path}/${table.name}.dart').writeAsString(modelContent);
    await File('${reposDir.path}/${table.name}_repository.dart').writeAsString(repoContent);
  }
  
  // Extract and generate enums
  print('Extracting enums...');
  final connection = await parser.createConnection();
  try {
    final enums = await parser.extractEnums(connection);
    
    print('Found ${enums.length} enums:');
    for (final enumDef in enums) {
      print('- ${enumDef.name} (${enumDef.values.length} values)');
      
      final enumContent = enumGen.generateEnum(enumDef);
      await File('${enumsDir.path}/${enumDef.name.toLowerCase()}.dart').writeAsString(enumContent);
    }
  } finally {
    await connection.close();
  }
  
  print('Generated models, repositories, and enums in the output directory.');
}