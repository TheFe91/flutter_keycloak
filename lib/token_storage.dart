import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'constants.dart';

/// Save the credentials to the SharedPrefs
Future<void> saveCredentials (Map credentials) async {
  final sp = await SharedPreferences.getInstance();
  await sp.setString(CREDENTIALS, json.encode(credentials));
}

/// Save the configuration to the SharedPrefs
Future<void> saveConfiguration(Map conf) async {
  final sp = await SharedPreferences.getInstance();
  await sp.setString(CONFIG, json.encode(conf));
}

/// Save the tokens to the SharedPrefs
Future<void> saveTokens(Map tokens) async {
  final sp = await SharedPreferences.getInstance();
  await sp.setString(TOKENS, json.encode(tokens));
}

/// Get the credentials from the SharedPrefs
Future<Map?> getCredentials() async {
  final sp = await SharedPreferences.getInstance();
  final credentials = await sp.getString(CREDENTIALS);
  return credentials != null ? json.decode(credentials) : null;
}

/// Get the configuration from the SharedPrefs
Future<Map?> getConfiguration() async {
  final sp = await SharedPreferences.getInstance();
  final conf = await sp.getString(CONFIG);
  return conf != null ? json.decode(conf) : null;
}

/// Get the tokens from the SharedPrefs
Future<Map?> getTokens() async {
  final sp = await SharedPreferences.getInstance();
  final tokens = await sp.getString(TOKENS);
  return tokens != null ? json.decode(tokens) : null;
}

/// Clear the plugin's SharedPrefs keys
Future<void> clearSession() async {
  final sp = await SharedPreferences.getInstance();
  await sp.remove(CONFIG);
  await sp.remove(TOKENS);
  await sp.remove(CREDENTIALS);
}