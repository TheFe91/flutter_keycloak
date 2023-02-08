import 'dart:convert';
import 'dart:developer';

import 'token_storage.dart';

/// Get the Realm URL
String getRealmURL(String realm, String authServerUrl) {
  final url = authServerUrl.endsWith('/') ? authServerUrl : '$authServerUrl/';
  return '${url}realms/${Uri.encodeComponent(realm)}';
}

/// Extract the key from the JTW Token Payload
int extractKeyFromJwtTokenPayload(String key, String token) {
  final tokenBody = token.split('.')[1];
  final stringToBase64 = utf8.fuse(base64);
  final decoded = stringToBase64.decode(tokenBody);
  final map = json.decode(decoded);
  return map[key];
}

/// Get if AT is expired
Future<bool> isAccessTokenExpired() async {
  try {
    final tokens = getTokens();
    final accessToken = tokens!['access_token'];
    final tokenExpirationTime =
        extractKeyFromJwtTokenPayload('exp', accessToken);
    final int nowMillis = DateTime.now().millisecondsSinceEpoch;
    final int tokenExpMillis = tokenExpirationTime * 1000;
    return tokenExpMillis > nowMillis;
  } catch (e) {
    log('Error in \'isAccessTokenExpired()\' call: $e');
    return false;
  }
}

/// Get if AT will expire in less than specified seconds
Future<bool> willAccessTokenExpireInLessThan(int seconds) async {
  try {
    final tokens = getTokens();
    final accessToken = tokens!['access_token'];
    final tokenExpirationTime =
        extractKeyFromJwtTokenPayload('exp', accessToken);
    final int nowMillis = DateTime.now().millisecondsSinceEpoch;
    final int tokenExpMillis = tokenExpirationTime * 1000;
    return (tokenExpMillis - nowMillis) < seconds;
  } catch (e) {
    log('Error in \'willAccessTokenExpireInLessThan()\' call: $e');
    return false;
  }
}
