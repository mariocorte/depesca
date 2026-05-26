import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:postgres/postgres.dart';

import 'database_connection_result.dart';

Future<DatabaseConnectionResult> checkDatabaseConnection() async {
  final host = dotenv.env['POSTGRES_HOST']?.trim() ?? '';
  final database = dotenv.env['POSTGRES_DATABASE']?.trim() ?? '';
  final username = dotenv.env['POSTGRES_USER']?.trim() ?? '';
  final password = dotenv.env['POSTGRES_PASSWORD']?.trim() ?? '';
  final port = int.tryParse(dotenv.env['POSTGRES_PORT'] ?? '') ?? 5432;
  final useSsl = (dotenv.env['POSTGRES_SSL'] ?? '').toLowerCase() == 'true';

  if (host.isEmpty || database.isEmpty || username.isEmpty) {
    return const DatabaseConnectionResult(
      connected: false,
      message: 'Faltan datos en .env: host, base o usuario.',
    );
  }

  Connection? connection;

  try {
    connection = await Connection.open(
      Endpoint(
        host: host,
        database: database,
        username: username,
        password: password,
        port: port,
      ),
      settings: ConnectionSettings(
        sslMode: useSsl ? SslMode.require : SslMode.disable,
      ),
    ).timeout(const Duration(seconds: 8));

    await connection.execute('SELECT 1').timeout(const Duration(seconds: 8));

    return DatabaseConnectionResult(
      connected: true,
      message: 'Conectado a la base "$database".',
    );
  } catch (error) {
    return DatabaseConnectionResult(
      connected: false,
      message: 'No se pudo conectar a Postgres: $error',
    );
  } finally {
    await connection?.close();
  }
}
