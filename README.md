# Supabase Model Generator

A powerful code generator that automatically creates Dart models and repositories from your Supabase database schema. This package streamlines your development workflow by generating type-safe Dart code that integrates seamlessly with your Supabase backend.

## Features

- 🚀 Automatic model generation from Supabase schema
- 📦 Type-safe repository classes for each model
- 🔄 Built-in CRUD operations
- 🛠 Customizable code generation
- 🎯 Full type safety and null safety support
- 🔍 Automatic relationship handling

## Installation

Add the following to your `pubspec.yaml`:

```yaml
dependencies:
  supabase_model_generator: ^0.1.0

dev_dependencies:
  build_runner: ^2.3.3
```

## Configuration

1. Create a `supabase_config.yaml` file in your project root (you can copy from `supabase_config.yaml.template`):

```yaml
project_id: your-project-id
database_url: postgresql://postgres:postgres@localhost:54322/postgres
output_directory: lib/models
```

2. Configure your database connection details.

## Usage

1. Run the generator:

```bash
dart run build_runner build
```

2. Use the generated models and repositories:

```dart
// Using a generated model
final user = User(
  id: 1,
  name: 'John Doe',
  email: 'john@example.com',
);

// Using a generated repository
final userRepository = UserRepository();
await userRepository.create(user);
final users = await userRepository.findAll();
```

## Generated Code Structure

The generator creates two files for each table in your Supabase database:
- `{model_name}.model.dart`: Contains the model class with all properties
- `{model_name}.repository.dart`: Contains the repository class with CRUD operations

## Customization

You can customize the generation process by:
1. Adding annotations to control field generation
2. Configuring relationships in your schema
3. Extending generated classes with custom functionality

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.