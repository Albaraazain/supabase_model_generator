class DatabaseConfig {
  final String host;
  final int port;
  final String database;
  final String username;
  final String password;
  final bool useSSL;

  const DatabaseConfig({
    required this.host,
    required this.port,
    required this.database,
    required this.username,
    required this.password,
    this.useSSL = false,
  });

  factory DatabaseConfig.fromJson(Map<String, dynamic> json) {
    return DatabaseConfig(
      host: json['host'] as String,
      port: json['port'] as int,
      database: json['database'] as String,
      username: json['username'] as String,
      password: json['password'] as String,
      useSSL: json['use_ssl'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'host': host,
      'port': port,
      'database': database,
      'username': username,
      'password': password,
      'use_ssl': useSSL,
    };
  }
}