import 'package:supabase_model_generator/supabase_model_generator.dart';
import 'package:supabase_model_generator/src/supabase_model_generator_base.dart';
import 'package:test/test.dart';

void main() {
  group('Basic functionality tests', () {
    final awesome = Awesome();

    setUp(() {
      // Additional setup goes here.
    });

    test('First Test', () {
      expect(awesome.isAwesome, isTrue);
    });
  });

  group('Model generation tests', () {
    late TableDefinition testTable;
    late ColumnDefinition idColumn;
    late ColumnDefinition nameColumn;
    late ColumnDefinition descriptionColumn;
    late ModelGenerator modelGenerator;

    setUp(() {
      // Create a test table definition
      idColumn = ColumnDefinition(
        name: 'id',
        dataType: 'integer',
        isNullable: false,
        isPrimaryKey: true,
      );
      
      nameColumn = ColumnDefinition(
        name: 'name',
        dataType: 'text',
        isNullable: false,
        description: 'The name of the item',
      );
      
      descriptionColumn = ColumnDefinition(
        name: 'description',
        dataType: 'text',
        isNullable: true,
      );
      
      testTable = TableDefinition(
        name: 'test_items',
        description: 'A table for testing items',
        columns: [idColumn, nameColumn, descriptionColumn],
      );
      
      modelGenerator = ModelGenerator();
    });

    test('Model generation produces valid Dart code', () {
      final modelCode = modelGenerator.generateModel(testTable);
      
      // Verify the model code contains expected elements
      expect(modelCode, contains('class TestItems'));
      expect(modelCode, contains('final int id;'));
      expect(modelCode, contains('final String name;'));
      expect(modelCode, contains('final String? description;'));
      expect(modelCode, contains('TestItems({'));
      expect(modelCode, contains('required this.id,'));
      expect(modelCode, contains('required this.name,'));
      expect(modelCode, contains('this.description,'));
      expect(modelCode, contains('static TestItems fromJson(Map<String, dynamic> json)'));
      expect(modelCode, contains('Map<String, dynamic> toJson()'));
      expect(modelCode, contains('TestItems copyWith('));
    });
  });

  group('Repository generation tests', () {
    late TableDefinition testTable;
    late RepositoryGenerator repositoryGenerator;

    setUp(() {
      // Create a test table definition
      testTable = TableDefinition(
        name: 'test_items',
        description: 'A table for testing items',
        columns: [
          ColumnDefinition(
            name: 'id',
            dataType: 'integer',
            isNullable: false,
            isPrimaryKey: true,
          ),
          ColumnDefinition(
            name: 'name',
            dataType: 'text',
            isNullable: false,
          ),
        ],
      );
      
      repositoryGenerator = RepositoryGenerator();
    });

    test('Repository generation produces valid Dart code', () {
      final repoCode = repositoryGenerator.generateRepository(testTable);
      
      // Verify the repository code contains expected elements
      expect(repoCode, contains('class TestItemsRepository'));
      expect(repoCode, contains('final SupabaseClient _supabase;'));
      expect(repoCode, contains('Future<List<TestItems>> getAll()'));
      expect(repoCode, contains('Future<TestItems?> getById(int id)'));
      expect(repoCode, contains('Future<TestItems> insert(TestItems model)'));
      expect(repoCode, contains('Future<TestItems> update(TestItems model)'));
      expect(repoCode, contains('Future<void> delete(int id)'));
      expect(repoCode, contains('Stream<List<TestItems>> stream()'));
    });
  });

  group('Enum generation tests', () {
    late EnumDefinition testEnum;
    late EnumGenerator enumGenerator;

    setUp(() {
      // Create a test enum definition
      testEnum = EnumDefinition(
        name: 'UserRole',
        description: 'User role types',
        values: ['admin', 'user', 'guest'],
        tableName: 'users',
        columnName: 'role',
      );
      
      enumGenerator = EnumGenerator();
    });

    test('Enum generation produces valid Dart code', () {
      final enumCode = enumGenerator.generateEnum(testEnum);
      
      // Verify the enum code contains expected elements
      expect(enumCode, contains('enum UserRole {'));
      expect(enumCode, contains('/// admin'));
      expect(enumCode, contains('admin,'));
      expect(enumCode, contains('/// user'));
      expect(enumCode, contains('user,'));
      expect(enumCode, contains('/// guest'));
      expect(enumCode, contains('guest'));
      expect(enumCode, contains('static UserRole? fromString(String value)'));
      expect(enumCode, contains('@override'));
      expect(enumCode, contains('String toString()'));
    });
  });
}
