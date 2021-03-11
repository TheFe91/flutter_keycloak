import 'dart:convert';

import 'token_storage.dart';

/// Get the Realm URL
String getRealmURL(String realm, String authServerUrl) {
  final url = authServerUrl.endsWith('/') ? authServerUrl : '$authServerUrl/';
  return '${url}realms/${Uri.encodeComponent(realm)}';
}

/// Extract the key from the JTW Token Payload
String extractKeyFromJwtTokenPayload(String key, String token) {
  final tokenBody = token.split('.')[1];
  final stringToBase64 = utf8.fuse(base64);
  final decoded = stringToBase64.decode(tokenBody);
  final map = json.decode(decoded);
  return map[key];
}

/// Get if AT is expired
Future<bool> isAccessTokenExpired() async {
  try {
    final tokens = await getTokens();
    final accessToken = tokens!['access_token'];
    final tokenExpirationTime = int.parse(extractKeyFromJwtTokenPayload(
        'exp', accessToken));
    final now = DateTime
        .now()
        .second;
    return tokenExpirationTime > now;
  }
  catch (e) {
    print('Error in \'isAccessTokenExpired()\' call: $e');
    return false;
  }
}

/// Get if AT will expire in less than specified seconds
Future<bool> willAccessTokenExpireInLessThan(int seconds) async {
  try {
    final tokens = await getTokens();
    final accessToken = tokens!['access_token'];
    final tokenExpirationTime = int.parse(extractKeyFromJwtTokenPayload(
        'exp', accessToken));
    final now = DateTime
        .now()
        .second;
    return (tokenExpirationTime - now) < seconds;
  }
  catch (e) {
    print('Error in \'isAccessTokenExpired()\' call: $e');
    return false;
  }
}