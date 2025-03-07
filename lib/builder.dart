import 'package:build/build.dart';
import 'package:source_gen/source_gen.dart';
import 'package:yaml/yaml.dart';

import 'src/builders/model_builder.dart';

Builder supabseModelBuilder(BuilderOptions options) => 
    ModelBuilder(options);