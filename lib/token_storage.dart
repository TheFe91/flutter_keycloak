import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'constants.dart';

/// Save the credentials to the SharedPrefs
Future<void> saveCredentials(Map credentials) async {
  const storage = FlutterSecureStorage();
  await storage.write(
      key: Constants.credentials, value: json.encode(credentials));
}

/// Save the configuration to the SharedPrefs
Future<void> saveConfiguration(Map conf) async {
  const storage = FlutterSecureStorage();
  await storage.write(key: Constants.config, value: json.encode(conf));
}

/// Save the tokens to the SharedPrefs
Future<void> saveTokens(Map tokens) async {
  const storage = FlutterSecureStorage();
  await storage.write(key: Constants.tokens, value: json.encode(tokens));
}

/// Get the credentials from the SharedPrefs
Future<Map?> getCredentials() async {
  const storage = FlutterSecureStorage();
  final credentials = await storage.read(key: Constants.credentials);
  return credentials != null ? json.decode(credentials) : null;
}

/// Get the configuration from the SharedPrefs
Future<Map?> getConfiguration() async {
  const storage = FlutterSecureStorage();
  final conf = await storage.read(key: Constants.config);
  return conf != null ? json.decode(conf) : null;
}

/// Get the tokens from the SharedPrefs
Future<Map?> getTokens() async {
  const storage = FlutterSecureStorage();
  final tokens = await storage.read(key: Constants.tokens);
  return tokens != null ? json.decode(tokens) : null;
}

/// Clear the plugin's SharedPrefs keys
Future<void> clearSession() async {
  const storage = FlutterSecureStorage();
  storage.deleteAll();
}
