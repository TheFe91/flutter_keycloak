library flutter_keycloak;

import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';

import 'token_storage.dart';
import 'utils.dart';

/// A Flutter plugin to manage the keycloak authentication,
/// managing on the local storage the tokens and the credentials
class FlutterKeycloak {
  /// Real login process
  Future performLogin(
    dynamic conf,
    String username,
    String password, {
    String scope = 'info',
  }) async {
    final resource = conf['resource'];
    final realm = conf['realm'];
    final credentials = conf['credentials'];
    final authServerUrl = conf['auth-server-url'];
    final url =
        '${getRealmURL(realm, authServerUrl)}/protocol/openid-connect/token';
    // final options = { headers: basicHeaders, method, body};

    final response = await Dio().post(
      url,
      data: {
        'grant_type': 'password',
        'username': username,
        'password': password,
        'client_id': Uri.encodeComponent(resource),
        'client_secret': credentials ? credentials.secret : null,
        'scope': scope,
      },
      options: Options(
        headers: {'Accept': 'application/json'},
        contentType: 'application/x-www-form-urlencoded',
      ),
    );

    if (response.statusCode == 200) {
      final jsonResponse = response.data;
      await saveConfiguration(conf);
      await saveTokens(jsonResponse);
      await saveCredentials({'username': username, 'password': password});
      return jsonResponse;
    }

    print(
      'Error during kc-api-login, '
      '${response.statusCode}: '
      '${response.data.toString()}',
    );
    // throw Exce({...jsonResponse, status: fullResponse.status});
  }

  /// Get the tokens from AS
  Future retrieveTokens(
    dynamic conf,
    String code,
    Function resolve,
    Function reject,
    String deepLinkUrl,
  ) async {
    final resource = conf['resource'];
    final realm = conf['realm'];
    final redirectUri = conf['redirectUri'];
    final credentials = conf['credentials'];
    final authServerUrl = conf['auth-server-url'];

    final tokenUrl =
        '${getRealmURL(realm, authServerUrl)}/protocol/openid-connect/token';

    final headers = {'Accept': 'application/json'};

    if (credentials != null && credentials['secret'] != null) {
      final stringToBase64 = utf8.fuse(base64);
      final encodedKey =
          stringToBase64.encode('$resource:${credentials['secret']}');
      headers[HttpHeaders.authorizationHeader] = 'Basic $encodedKey';
    }

    final response = await Dio().post(
      tokenUrl,
      data: {
        'grant_type': 'authorization_code',
        'redirect_uri': redirectUri,
        'client_id': resource,
        'code': code,
      },
      options: Options(
        headers: headers,
        contentType: 'application/x-www-form-urlencoded',
      ),
    );

    final jsonResponse = response.data;

    if (response.statusCode == 200) {
      await saveConfiguration(conf);
      await saveTokens(jsonResponse);
      resolve({'tokens': jsonResponse, 'deepLinkUrl': deepLinkUrl});
    } else {
      print('Error during kc-retrieve-tokens');
      reject(jsonResponse);
    }
  }

  /// Init the login process
  void login(
    dynamic conf,
    String username,
    String password, {
    String scope = 'info',
  }) async =>
      await performLogin(conf, username, password, scope: scope);
}
