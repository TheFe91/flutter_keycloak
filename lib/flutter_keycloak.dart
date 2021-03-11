library flutter_keycloak;

import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';

import 'token_storage.dart';
import 'utils.dart';

/// Basic Headers for requests
const basicHeaders = {
  'Accept': 'application/json',
  'Content-Type': 'application/x-www-form-urlencoded',
};

/// A Flutter plugin to manage the keycloak authentication,
/// managing on the local storage the tokens and the credentials
class FlutterKeycloak {
  /// Real login process
  Future performLogin(dynamic conf,
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
        headers: basicHeaders,
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
  Future retrieveTokens(dynamic conf,
      String code,
      Function resolve,
      Function reject,
      String deepLinkUrl,) async {
    final resource = conf['resource'];
    final realm = conf['realm'];
    final redirectUri = conf['redirectUri'];
    final credentials = conf['credentials'];
    final authServerUrl = conf['auth-server-url'];

    final tokenUrl =
        '${getRealmURL(realm, authServerUrl)}/protocol/openid-connect/token';

    final headers = basicHeaders;

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
      options: Options(headers: headers),
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
  void login(dynamic conf,
      String username,
      String password, {
        String scope = 'info',
      }) async =>
      await performLogin(conf, username, password, scope: scope);

  /// Automatically redo the login
  Future refreshLogin({String scope = 'info'}) async {
    final conf = await getConfiguration();
    if (conf == null) {
      throw 'Error during kc-refresh-login: '
          'Could not read configuration from storage';
    }

    final credentials = await getCredentials();
    if (credentials == null) {
      throw 'Error during kc-refresh-login:  Could not read from AsyncStorage';
    }

    final username = credentials['username'];
    final password = credentials['password'];

    if (username == null || password == null) {
      throw 'Error during kc-refresh-login: Username or Password not found';
    }

    performLogin(conf, username, password, scope: scope);
  }

  /// Get User Info
  Future retrieveUserInfo() async {
    final conf = await getConfiguration();

    if (conf == null) {
      throw 'Error during kc-retrieve-user-info: '
          'Could not read configuration from storage';
    }

    final realm = conf['realm'];
    final authServerUrl = conf['auth-server-url'];
    final savedTokens = await getTokens();

    if (savedTokens == null) {
      throw 'Error during kc-retrieve-user-info, savedTokens is $savedTokens';
    }

    final userInfoUrl =
        '${getRealmURL(realm, authServerUrl)}/protocol/openid-connect/userinfo';

    final headers = basicHeaders;
    headers[HttpHeaders.authorizationHeader] =
    'Bearer ${savedTokens['access_token']}';

    final response = await Dio().get(
      userInfoUrl,
      options: Options(
        headers: headers,
      ),
    );

    if (response.statusCode == 200) {
      return response.data;
    }

    throw 'Error during kc-retrieve-user-info: '
        '${response.statusCode}: '
        '${response.data}';
  }

  /// Gets the refresh token
  Future refreshToken() async {
    final conf = await getConfiguration();

    if (conf == null) {
      throw 'Could not read configuration from storage';
    }

    final resource = conf['resource'];
    final realm = conf['realm'];
    final credentials = conf['credentials'];
    final authServerUrl = conf['auth-server-url'];

    final savedTokens = await getTokens();

    if (savedTokens == null) {
      throw 'Error during kc-refresh-token, savedTokens is $savedTokens';
    }

    final refreshTokenUrl =
        '${getRealmURL(realm, authServerUrl)}/protocol/openid-connect/token';

    final response = await Dio().post(
      refreshTokenUrl,
      data: {
        'grant_type': 'refresh_token',
        'refresh_token': savedTokens['refresh_token'],
        'client_id': Uri.encodeComponent(resource),
        'client_secret': credentials != null ? credentials['secret'] : null,
      },
      options: Options(headers: basicHeaders),
    );
    final jsonResponse = await response.data;

    if (response.statusCode == 200) {
      await saveTokens(jsonResponse);
      return jsonResponse;
    }

    throw 'Error during kc-refresh-token, '
        '${response.statusCode}: '
        '${response.data}';
  }

  /// Logs the user out
  Future logout() async {
    final conf = await getConfiguration();

    if (conf == null) {
      throw 'Could not read configuration from storage';
    }

    final realm = conf['realm'];
    final authServerUrl = conf['auth-server-url'];
    final savedTokens = await getTokens();

    if (savedTokens == null) {
      throw 'Error during kc-logout, savedTokens is $savedTokens';
    }

    final logoutUrl = '${getRealmURL(
        realm, authServerUrl)}/protocol/openid-connect/logout';
    final response = await Dio().get(
      logoutUrl,
      options: Options(headers: basicHeaders),
    );

    if (response.statusCode == 200) {
      await clearSession();
    }

    throw 'Error during kc-logout: ${response.statusCode}: ${response.data}';
  }
}
