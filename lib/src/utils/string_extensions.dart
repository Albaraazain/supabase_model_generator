extension StringExtension on String {
  String get pascalCase {
    if (isEmpty) return this;
    return split('_')
        .map((word) => word.isEmpty ? '' : word[0].toUpperCase() + word.substring(1).toLowerCase())
        .join();
  }
} 