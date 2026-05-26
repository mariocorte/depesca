class DatabaseConnectionResult {
  const DatabaseConnectionResult({
    required this.connected,
    required this.message,
  });

  final bool connected;
  final String message;
}
