/// Strategy for handling duplicate routes in the navigation stack.
enum OctopusDuplicateStrategy {
  /// Remove duplicate routes, keeping only the last occurrence.

  remove,

  /// Allow duplicate routes by making them unique with auto-generated

  /// arguments.

  /// This preserves all routes in the stack with unique keys.

  allow,
}
