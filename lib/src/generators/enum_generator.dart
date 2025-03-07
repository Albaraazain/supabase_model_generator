import 'package:code_builder/code_builder.dart';
import 'package:dart_style/dart_style.dart';
import 'package:built_collection/built_collection.dart';

import '../models/enum_definition.dart';

class EnumGenerator {
  final DartFormatter _formatter = DartFormatter();
  
  String generateEnum(EnumDefinition enumDef) {
    final enumBuilder = EnumBuilder()
      ..name = enumDef.name;
    
    if (enumDef.description != null) {
      enumBuilder.docs = ListBuilder<String>(['/// ${enumDef.description}']);
    }
    
    // Add values
    for (final value in enumDef.values) {
      enumBuilder.values.add(EnumValue((b) => b
        ..name = _formatEnumValue(value)
        ..docs = ListBuilder<String>(['/// $value'])));
    }
    
    // Add fromString method
    final fromStringMethod = Method((b) => b
      ..name = 'fromString'
      ..static = true
      ..returns = Reference('${enumDef.name}?')
      ..requiredParameters.add(Parameter((b) => b
        ..name = 'value'
        ..type = Reference('String')))
      ..body = Code(_generateFromStringBody(enumDef)));
    
    // Add toString method
    final toStringMethod = Method((b) => b
      ..name = 'toString'
      ..annotations.add(Reference('override'))
      ..returns = Reference('String')
      ..body = Code(_generateToStringBody(enumDef)));
    
    enumBuilder.methods.addAll([fromStringMethod, toStringMethod]);
    
    final emitter = DartEmitter();
    final libraryBuilder = LibraryBuilder();
    
    libraryBuilder.body.add(enumBuilder.build());
    
    return _formatter.format('${libraryBuilder.build().accept(emitter)}');
  }
  
  String _formatEnumValue(String value) {
    // Replace spaces with underscores and convert to camelCase
    final sanitized = value
        .replaceAll(RegExp(r'[^a-zA-Z0-9_]'), '_')
        .replaceAll(RegExp(r'_+'), '_');
    
    // Ensure it starts with a lowercase letter
    if (sanitized.isEmpty) return 'unknown';
    return sanitized[0].toLowerCase() + sanitized.substring(1);
  }
  
  String _generateFromStringBody(EnumDefinition enumDef) {
    final buffer = StringBuffer();
    buffer.writeln('switch (value) {');
    
    for (final value in enumDef.values) {
      final enumValue = _formatEnumValue(value);
      buffer.writeln('  case \'$value\':');
      buffer.writeln('    return ${enumDef.name}.$enumValue;');
    }
    
    buffer.writeln('  default:');
    buffer.writeln('    return null;');
    buffer.writeln('}');
    
    return buffer.toString();
  }
  
  String _generateToStringBody(EnumDefinition enumDef) {
    final buffer = StringBuffer();
    buffer.writeln('switch (this) {');
    
    for (final value in enumDef.values) {
      final enumValue = _formatEnumValue(value);
      buffer.writeln('  case ${enumDef.name}.$enumValue:');
      buffer.writeln('    return \'$value\';');
    }
    
    buffer.writeln('}');
    
    return buffer.toString();
  }
}