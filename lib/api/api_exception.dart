class ApiException implements Exception {
  const ApiException(this.message, {this.statusCode});
  final String message;
  final int? statusCode;
  bool get isNetworkError => statusCode == null;
  @override
  String toString() => message;
}

String messageFromError(Object error) {
  if (error is ApiException) return error.message;
  return 'Something went wrong. Please try again.';
}
