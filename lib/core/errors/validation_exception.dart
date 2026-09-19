class ValidationException<T> implements Exception {
  const ValidationException(this.errors);

  final Map<T, String> errors;

  @override
  String toString() => 'ValidationException($errors)';
}
