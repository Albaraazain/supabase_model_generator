/// A library for generating Dart models and repositories from Supabase schema.
library supabase_model_generator;

export 'src/config/database_config.dart';
export 'src/models/table_definition.dart';
export 'src/models/column_definition.dart';
export 'src/models/enum_definition.dart';
export 'src/parsers/supabase_schema_parser.dart';
export 'src/generators/model_generator.dart';
export 'src/generators/repository_generator.dart';
export 'src/generators/enum_generator.dart';