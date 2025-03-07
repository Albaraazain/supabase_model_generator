import 'package:code_builder/code_builder.dart';
import 'package:dart_style/dart_style.dart';
import 'package:built_collection/built_collection.dart';

import '../models/table_definition.dart';
import '../models/column_definition.dart';

class ModelGenerator {
  final DartFormatter _formatter = DartFormatter();

  String generateModel(TableDefinition table) {
    final classBuilder = ClassBuilder()..name = table.className;

    if (table.description != null) {
      classBuilder.docs = ListBuilder(['/// ${table.description}']);
    }

    // Add fields (prevent duplicates)
    final seenFields = <String>{};
    for (final column in table.columns) {
      if (!seenFields.contains(column.fieldName)) {
        classBuilder.fields.add(_buildField(column));
        seenFields.add(column.fieldName);
      }
    }

    // Add constructor (prevent duplicates)
    final constructor = ConstructorBuilder();
    seenFields.clear();
    for (final column in table.columns) {
      if (!seenFields.contains(column.fieldName)) {
        // Fields should be required if they are:
        // 1. Primary keys, or
        // 2. Non-nullable fields without default values
        final isRequired = column.isPrimaryKey || !column.isNullable;
        constructor.optionalParameters.add(Parameter((b) => b
          ..name = column.fieldName
          ..named = true
          ..required = isRequired
          ..toThis = true));
        seenFields.add(column.fieldName);
      }
    }
    classBuilder.constructors.add(constructor.build());

    // Add fromJson method
    classBuilder.methods.add(_buildFromJsonMethod(table));

    // Add toJson method
    classBuilder.methods.add(_buildToJsonMethod(table));

    // Add copyWith method
    classBuilder.methods.add(_buildCopyWithMethod(table));

    final emitter = DartEmitter();
    final libraryBuilder = LibraryBuilder();

    // Add imports
    // Note: dart:convert is not needed since we're not using jsonEncode/jsonDecode

    // Add enum imports
    for (final column in table.columns) {
      if (column.isEnum && column.enumType != null) {
        final enumPath = './enums/${column.enumType!.toLowerCase()}.dart';
        libraryBuilder.directives.add(Directive.import(enumPath));
      }
    }

    libraryBuilder.body.add(classBuilder.build());

    return _formatter.format('${libraryBuilder.build().accept(emitter)}');
  }

  Field _buildField(ColumnDefinition column) {
    final fieldBuilder = FieldBuilder()
      ..name = column.fieldName
      ..type = Reference(column.dartType)
      ..modifier = FieldModifier.final$;

    if (column.description != null) {
      fieldBuilder.docs = ListBuilder(['/// ${column.description}']);
    }

    return fieldBuilder.build();
  }

  Method _buildFromJsonMethod(TableDefinition table) {
    final code = StringBuffer();
    code.writeln('return ${table.className}(');

    final seenFields = <String>{};
    for (final column in table.columns) {
      final fieldName = column.fieldName;
      if (!seenFields.contains(fieldName)) {
        final jsonKey = column.name;
        final dartType = column.dartType;

        if (column.isEnum && column.enumType != null) {
          if (column.isNullable) {
            code.writeln(
                '  $fieldName: json[\'$jsonKey\'] != null ? ${column.enumType}.fromString(json[\'$jsonKey\'] as String) : null,');
          } else {
            code.writeln(
                '  $fieldName: ${column.enumType}.fromString(json[\'$jsonKey\'] as String)!,');
          }
        } else if (dartType.contains('DateTime')) {
          if (column.isNullable) {
            code.writeln(
                '  $fieldName: json[\'$jsonKey\'] != null ? DateTime.parse(json[\'$jsonKey\'] as String) : null,');
          } else {
            code.writeln(
                '  $fieldName: DateTime.parse(json[\'$jsonKey\'] as String),');
          }
        } else {
          if (column.isNullable) {
            code.writeln('  $fieldName: json[\'$jsonKey\'] as $dartType,');
          } else {
            code.writeln(
                '  $fieldName: json[\'$jsonKey\'] as ${dartType.endsWith('?') ? dartType.substring(0, dartType.length - 1) : dartType},');
          }
        }
        seenFields.add(fieldName);
      }
    }

    code.writeln(');');

    return Method((b) => b
      ..name = 'fromJson'
      ..static = true
      ..returns = Reference(table.className)
      ..requiredParameters.add(Parameter((b) => b
        ..name = 'json'
        ..type = Reference('Map<String, dynamic>')))
      ..body = Code(code.toString()));
  }

  Method _buildToJsonMethod(TableDefinition table) {
    final code = StringBuffer();
    code.writeln('return {');

    final seenFields = <String>{};
    for (final column in table.columns) {
      final fieldName = column.fieldName;
      if (!seenFields.contains(fieldName)) {
        final jsonKey = column.name;
        final dartType = column.dartType;

        if (column.isEnum) {
          if (column.isNullable) {
            code.writeln('  \'$jsonKey\': $fieldName?.toString(),');
          } else {
            code.writeln('  \'$jsonKey\': $fieldName.toString(),');
          }
        } else if (dartType.contains('DateTime')) {
          if (column.isNullable) {
            code.writeln('  \'$jsonKey\': $fieldName?.toIso8601String(),');
          } else {
            code.writeln('  \'$jsonKey\': $fieldName.toIso8601String(),');
          }
        } else {
          code.writeln('  \'$jsonKey\': $fieldName,');
        }
        seenFields.add(fieldName);
      }
    }

    code.writeln('};');

    return Method((b) => b
      ..name = 'toJson'
      ..returns = Reference('Map<String, dynamic>')
      ..body = Code(code.toString()));
  }

  Method _buildCopyWithMethod(TableDefinition table) {
    final code = StringBuffer();
    code.writeln('return ${table.className}(');

    final seenFields = <String>{};
    for (final column in table.columns) {
      final fieldName = column.fieldName;
      if (!seenFields.contains(fieldName)) {
        code.writeln('  $fieldName: $fieldName ?? this.$fieldName,');
        seenFields.add(fieldName);
      }
    }

    code.writeln(');');

    final method = MethodBuilder()
      ..name = 'copyWith'
      ..returns = Reference(table.className)
      ..body = Code(code.toString());

    seenFields.clear();
    for (final column in table.columns) {
      final fieldName = column.fieldName;
      if (!seenFields.contains(fieldName)) {
        method.optionalParameters.add(Parameter((b) => b
          ..name = fieldName
          ..named = true
          ..required = false
          ..type = Reference(column.dartType == 'dynamic'
              ? 'dynamic'
              : column.isNullable
                  ? column.dartType
                  : '${column.dartType}?')));
        seenFields.add(fieldName);
      }
    }

    return method.build();
  }
}
