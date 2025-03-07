import 'package:code_builder/code_builder.dart';
import '../models/table_definition.dart';
import '../utils/string_extensions.dart';

class RepositoryGenerator {
  String generateRepository(TableDefinition table) {
    final className = '${table.name.pascalCase}Repository';
    final modelClassName = '${table.name.pascalCase}Model';
    
    return '''
      class $className {
        final supabase = Supabase.instance.client;
        
        Future<List<$modelClassName>> findAll() async {
          final response = await supabase.from('${table.name}').select();
          return response.map((json) => $modelClassName.fromJson(json)).toList();
        }
      }
    ''';
  }

  Method _buildGetAllMethod(TableDefinition table) {
    final modelClassName = '${table.name.pascalCase}Model';
    final tableName = table.name;

    return Method((b) => b
      ..name = 'getAll'
      ..returns = Reference('Future<List<$modelClassName>>')
      ..modifier = MethodModifier.async
      ..body = Code('''
        try {
          final response = await _supabase
              .from('$tableName')
              .select();
              
          return response.map((json) => $modelClassName.fromJson(json)).toList();
        } catch (e) {
          throw Exception('Failed to fetch data: \${e.toString()}');
        }
      '''));
  }

  Method _buildGetByIdMethod(TableDefinition table) {
    final modelClassName = '${table.name.pascalCase}Model';
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
      ..returns = Reference('Future<$modelClassName?>')
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
          return $modelClassName.fromJson(response as Map<String, dynamic>);
        } catch (e) {
          throw Exception('Failed to fetch data: \${e.toString()}');
        }
      '''));
  }

  Method _buildInsertMethod(TableDefinition table) {
    final modelClassName = '${table.name.pascalCase}Model';
    final tableName = table.name;

    return Method((b) => b
      ..name = 'insert'
      ..returns = Reference('Future<$modelClassName>')
      ..requiredParameters.add(Parameter((b) => b
        ..name = 'model'
        ..type = Reference(modelClassName)))
      ..modifier = MethodModifier.async
      ..body = Code('''
        try {
          final response = await _supabase
              .from('$tableName')
              .insert(model.toJson())
              .select()
              .single();
              
          return $modelClassName.fromJson(response as Map<String, dynamic>);
        } catch (e) {
          throw Exception('Failed to insert data: \${e.toString()}');
        }
      '''));
  }

  Method _buildUpdateMethod(TableDefinition table) {
    final modelClassName = '${table.name.pascalCase}Model';
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
      ..returns = Reference('Future<$modelClassName>')
      ..requiredParameters.add(Parameter((b) => b
        ..name = 'model'
        ..type = Reference(modelClassName)))
      ..modifier = MethodModifier.async
      ..body = Code('''
        try {
          final response = await _supabase
              .from('$tableName')
              .update(model.toJson())
              .eq('$pkName', model.$pkFieldName as Object)
              .select()
              .single();
              
          return $modelClassName.fromJson(response as Map<String, dynamic>);
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
    final modelClassName = '${table.name.pascalCase}Model';
    final tableName = table.name;

    // Find primary key column
    final pkColumn = table.columns.firstWhere(
      (col) => col.isPrimaryKey,
      orElse: () => table.columns.first, // Default to first column if no PK
    );

    return Method((b) => b
      ..name = 'stream'
      ..returns = Reference('Stream<List<$modelClassName>>')
      ..body = Code('''
        try {
          return _supabase
              .from('$tableName')
              .stream(primaryKey: ['${pkColumn.name}'])
              .map((list) => list
                  .map((json) => $modelClassName.fromJson(json as Map<String, dynamic>))
                  .toList());
        } catch (e) {
          throw Exception('Failed to stream data: \${e.toString()}');
        }
      '''));
  }
}
