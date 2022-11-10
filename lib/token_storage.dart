import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get_storage/get_storage.dart';

import 'constants.dart';

/// Save the credentials to the SharedPrefs
Future<void> saveCredentials(Map credentials) async {
  const storage = FlutterSecureStorage();
  await storage.write(
      key: Constants.credentials, value: json.encode(credentials));
}

/// Save the configuration to the SharedPrefs
void saveConfiguration(Map conf) {
  GetStorage().write(Constants.config, conf);
}

/// Save the tokens to the SharedPrefs
void saveTokens(Map tokens) {
  GetStorage().write(Constants.tokens, tokens);
}

/// Get the credentials from the SharedPrefs
Future<Map?> getCredentials() async {
  const storage = FlutterSecureStorage();
  final credentials = await storage.read(key: Constants.credentials);
  return credentials != null ? json.decode(credentials) : null;
}

/// Get the configuration from the SharedPrefs
Map? getConfiguration() => GetStorage().read(Constants.config);

/// Get the tokens from the SharedPrefs
Map? getTokens() => GetStorage().read(Constants.tokens);

/// Clear the plugin's SharedPrefs keys
Future<void> clearSession() async {
  const storage = FlutterSecureStorage();
  storage.delete(key: Constants.credentials);
  GetStorage().remove(Constants.config);
  GetStorage().remove(Constants.tokens);
}
