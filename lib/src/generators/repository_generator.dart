import 'package:code_builder/code_builder.dart';
import 'package:dart_style/dart_style.dart';
import 'package:built_collection/built_collection.dart';

import '../models/table_definition.dart';
import '../models/column_definition.dart';

class RepositoryGenerator {
  final DartFormatter _formatter = DartFormatter();

  String generateRepository(TableDefinition table) {
    final className = '${table.className}Repository';
    final columns = table.columns;
    
    final buffer = StringBuffer();
    final classBuilder = ClassBuilder()..name = className;

    // Add docs
    classBuilder.docs =
        ListBuilder<String>(['/// Repository for the ${table.name} table.']);

    // Add fields
    classBuilder.fields.add(Field((b) => b
      ..name = '_supabase'
      ..type = Reference('SupabaseClient')
      ..modifier = FieldModifier.final$));

    // Add constructor with initialization
    classBuilder.constructors.add(Constructor((b) => b
      ..requiredParameters.add(Parameter((b) => b
        ..name = '_supabase'
        ..type = Reference('SupabaseClient')))
      ..initializers.add(Code('_supabase = _supabase'))));

    // Add methods
    classBuilder.methods.add(_buildGetAllMethod(table));
    classBuilder.methods.add(_buildGetByIdMethod(table));
    classBuilder.methods.add(_buildInsertMethod(table));
    classBuilder.methods.add(_buildUpdateMethod(table));
    classBuilder.methods.add(_buildDeleteMethod(table));
    classBuilder.methods.add(_buildStreamMethod(table));

    final emitter = DartEmitter();
    final libraryBuilder = LibraryBuilder();

    // Add imports
    libraryBuilder.directives.add(
        Directive.import('package:supabase_flutter/supabase_flutter.dart'));
    libraryBuilder.directives
        .add(Directive.import('../models/${table.name}.dart'));

    libraryBuilder.body.add(classBuilder.build());

    return _formatter.format('${libraryBuilder.build().accept(emitter)}');
  }

  Method _buildGetAllMethod(TableDefinition table) {
    final modelName = table.className;
    final tableName = table.name;

    return Method((b) => b
      ..name = 'getAll'
      ..returns = Reference('Future<List<$modelName>>')
      ..modifier = MethodModifier.async
      ..body = Code('''
        try {
          final response = await _supabase
              .from('$tableName')
              .select();
              
          final data = response as List<dynamic>;
          return data.map((json) => $modelName.fromJson(json as Map<String, dynamic>)).toList();
        } catch (e) {
          throw Exception('Failed to fetch data: \${e.toString()}');
        }
      '''));
  }

  Method _buildGetByIdMethod(TableDefinition table) {
    final modelName = table.className;
    final tableName = table.name;

    // Find primary key column
    final pkColumn = table.columns.firstWhere(
      (col) => col.isPrimaryKey,
      orElse: () => table.columns.first, // Default to first column if no PK
    );

    final pkName = pkColumn.name;
    final isBackupTable = table.name.endsWith('_backup');
    final pkType = isBackupTable ? 'Object?' : 'Object';

    return Method((b) => b
      ..name = 'getById'
      ..returns = Reference('Future<$modelName?>')
      ..requiredParameters.add(Parameter((b) => b
        ..name = 'id'
        ..type = Reference(pkType)))
      ..modifier = MethodModifier.async
      ..body = Code('''
        try {
          final response = await _supabase
              .from('$tableName')
              .select()
              .eq('$pkName', id as Object)
              .maybeSingle();

          if (response == null) return null;
          return $modelName.fromJson(response as Map<String, dynamic>);
        } catch (e) {
          throw Exception('Failed to fetch data: \${e.toString()}');
        }
      '''));
  }

  Method _buildInsertMethod(TableDefinition table) {
    final modelName = table.className;
    final tableName = table.name;

    return Method((b) => b
      ..name = 'insert'
      ..returns = Reference('Future<$modelName>')
      ..requiredParameters.add(Parameter((b) => b
        ..name = 'model'
        ..type = Reference(modelName)))
      ..modifier = MethodModifier.async
      ..body = Code('''
        try {
          final response = await _supabase
              .from('$tableName')
              .insert(model.toJson())
              .select()
              .single();
              
          return $modelName.fromJson(response as Map<String, dynamic>);
        } catch (e) {
          throw Exception('Failed to insert data: \${e.toString()}');
        }
      '''));
  }

  Method _buildUpdateMethod(TableDefinition table) {
    final modelName = table.className;
    final tableName = table.name;

    // Find primary key column
    final pkColumn = table.columns.firstWhere(
      (col) => col.isPrimaryKey,
      orElse: () => table.columns.first, // Default to first column if no PK
    );

    final pkName = pkColumn.name;
    final pkFieldName = pkColumn.fieldName;
    final useNullablePk = table.name.endsWith('_backup');

    return Method((b) => b
      ..name = 'update'
      ..returns = Reference('Future<$modelName>')
      ..requiredParameters.add(Parameter((b) => b
        ..name = 'model'
        ..type = Reference(modelName)))
      ..modifier = MethodModifier.async
      ..body = Code('''
        try {
          final response = await _supabase
              .from('$tableName')
              .update(model.toJson())
              .eq('$pkName', model.$pkFieldName as Object)
              .select()
              .single();
              
          return $modelName.fromJson(response as Map<String, dynamic>);
        } catch (e) {
          throw Exception('Failed to update data: \${e.toString()}');
        }
      '''));
  }

  Method _buildDeleteMethod(TableDefinition table) {
    final tableName = table.name;

    // Find primary key column
    final pkColumn = table.columns.firstWhere(
      (col) => col.isPrimaryKey,
      orElse: () => table.columns.first, // Default to first column if no PK
    );

    final pkName = pkColumn.name;
    final isBackupTable = table.name.endsWith('_backup');
    final pkType = isBackupTable ? 'Object?' : 'Object';

    return Method((b) => b
      ..name = 'delete'
      ..returns = Reference('Future<void>')
      ..requiredParameters.add(Parameter((b) => b
        ..name = 'id'
        ..type = Reference(pkType)))
      ..modifier = MethodModifier.async
      ..body = Code('''
        try {
          await _supabase
              .from('$tableName')
              .delete()
              .eq('$pkName', id as Object);
        } catch (e) {
          throw Exception('Failed to delete data: \${e.toString()}');
        }
      '''));
  }

  Method _buildStreamMethod(TableDefinition table) {
    final modelName = table.className;
    final tableName = table.name;

    // Find primary key column
    final pkColumn = table.columns.firstWhere(
      (col) => col.isPrimaryKey,
      orElse: () => table.columns.first, // Default to first column if no PK
    );

    return Method((b) => b
      ..name = 'stream'
      ..returns = Reference('Stream<List<$modelName>>')
      ..body = Code('''
        try {
          return _supabase
              .from('$tableName')
              .stream(primaryKey: ['${pkColumn.name}'])
              .map((list) => list
                  .map((json) => $modelName.fromJson(json as Map<String, dynamic>))
                  .toList());
        } catch (e) {
          throw Exception('Failed to stream data: \${e.toString()}');
        }
      '''));
  }
}
