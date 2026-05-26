import 'database_connection_result.dart';

Future<DatabaseConnectionResult> checkDatabaseConnection() async {
  return const DatabaseConnectionResult(
    connected: false,
    message:
        'Flutter Web no puede conectarse directamente a Postgres. Usa un backend/API para proteger las credenciales.',
  );
}
