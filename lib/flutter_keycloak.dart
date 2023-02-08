import 'dart:developer';
import 'dart:io';

import 'package:dio/dio.dart';

import 'token_storage.dart';
import 'utils.dart';

/// A Flutter plugin to manage the keycloak authentication,
/// managing on the local storage the tokens and the credentials
class FlutterKeycloak {
  /// Get KeyCloak Realm Configuration
  Future getConf(String url) async {
    final response = await Dio().get(url);
    return response.data;
  }

  /// Real login process
  Future _performLogin(
    dynamic conf,
    String username,
    String password, {
    String? scope,
    bool storeInfo = true,
  }) async {
    final resource = conf['resource'];
    final realm = conf['realm'];
    final credentials = conf['credentials'];
    final authServerUrl = conf['auth-server-url'];
    final url =
        '${getRealmURL(realm, authServerUrl)}/protocol/openid-connect/token';

    try {
      final dio = Dio();
      dio.options.headers[HttpHeaders.acceptHeader] = 'application/json';
      dio.options.headers[HttpHeaders.contentTypeHeader] =
          'application/x-www-form-urlencoded';
      final response = await dio.post(
        url,
        data: {
          'grant_type': 'password',
          'username': username,
          'password': password,
          'client_id': Uri.encodeComponent(resource),
          'client_secret': credentials != null ? credentials['secret'] : null,
          'scope': scope,
        },
      );

      if (response.statusCode == 200) {
        final jsonResponse = response.data;
        if (storeInfo) {
          saveConfiguration(conf);
          saveTokens(jsonResponse);
          await saveCredentials({'username': username, 'password': password});
        }
        return jsonResponse;
      }

      log(
        'Error during kc-api-login, '
        '${response.statusCode}: '
        '${response.data.toString()}',
      );
    } catch (e) {
      rethrow;
    }
  }

  /// Init the login process
  Future login(
    dynamic conf,
    String username,
    String password, {
    String? scope,
    bool storeInfo = true,
  }) async =>
      await _performLogin(
        conf,
        username,
        password,
        scope: scope,
        storeInfo: storeInfo,
      );

  /// Automatically redo the login
  Future refreshLogin({
    inputConf,
    inputCredentials,
    scope,
    storeInfo = true,
  }) async {
    final conf = inputConf ?? getConfiguration();
    if (conf == null) {
      throw 'Error during kc-refresh-login: '
          'Could not read configuration from storage';
    }

    final credentials = inputCredentials ?? await getCredentials();
    if (credentials == null) {
      throw 'Error during kc-refresh-login:  Could not read from AsyncStorage';
    }

    final username = credentials['username'];
    final password = credentials['password'];

    if (username == null || password == null) {
      throw 'Error during kc-refresh-login: Username or Password not found';
    }

    _performLogin(conf, username, password, scope: scope, storeInfo: storeInfo);
  }

  /// Get User Info
  Future retrieveUserInfo({inputConf, inputTokens}) async {
    final conf = inputConf ?? getConfiguration();

    if (conf == null) {
      throw 'Error during kc-retrieve-user-info: '
          'Could not read configuration from storage';
    }

    final realm = conf['realm'];
    final authServerUrl = conf['auth-server-url'];
    final savedTokens = inputTokens ?? getTokens();

    if (savedTokens == null) {
      throw 'Error during kc-retrieve-user-info, savedTokens is $savedTokens';
    }

    final userInfoUrl =
        '${getRealmURL(realm, authServerUrl)}/protocol/openid-connect/userinfo';

    final dio = Dio();
    dio.options.headers[HttpHeaders.acceptHeader] = 'application/json';
    dio.options.headers[HttpHeaders.contentTypeHeader] =
        'application/x-www-form-urlencoded';
    dio.options.headers[HttpHeaders.authorizationHeader] =
        'Bearer ${savedTokens['access_token']}';

    final response = await dio.get(userInfoUrl);

    if (response.statusCode == 200) {
      return response.data;
    }

    throw 'Error during kc-retrieve-user-info: '
        '${response.statusCode}: '
        '${response.data}';
  }

  /// Gets the refresh token
  Future refreshToken({inputConf, inputTokens}) async {
    final conf = inputConf ?? getConfiguration();

    if (conf == null) {
      throw 'Could not read configuration from storage';
    }

    final resource = conf['resource'];
    final realm = conf['realm'];
    final credentials = conf['credentials'];
    final authServerUrl = conf['auth-server-url'];

    final savedTokens = inputTokens ?? getTokens();

    if (savedTokens == null) {
      throw 'Error during kc-refresh-token, savedTokens is $savedTokens';
    }

    final refreshTokenUrl =
        '${getRealmURL(realm, authServerUrl)}/protocol/openid-connect/token';

    final dio = Dio();
    dio.options.headers[HttpHeaders.acceptHeader] = 'application/json';
    dio.options.headers[HttpHeaders.contentTypeHeader] =
        'application/x-www-form-urlencoded';

    final response = await dio.post(
      refreshTokenUrl,
      data: {
        'grant_type': 'refresh_token',
        'refresh_token': savedTokens['refresh_token'],
        'client_id': Uri.encodeComponent(resource),
        'client_secret': credentials != null ? credentials['secret'] : null,
      },
    );
    final jsonResponse = await response.data;

    if (response.statusCode == 200) {
      saveTokens(jsonResponse);
      return jsonResponse;
    }

    throw 'Error during kc-refresh-token, '
        '${response.statusCode}: '
        '${response.data}';
  }

  /// Logs the user out
  Future logout({bool destroySession = true, inputConf, inputTokens}) async {
    if (destroySession) {
      final conf = inputConf ?? getConfiguration();

      if (conf == null) {
        throw 'Could not read configuration from storage';
      }

      final realm = conf['realm'];
      final authServerUrl = conf['auth-server-url'];
      final savedTokens = inputTokens ?? getTokens();

      if (savedTokens == null) {
        throw 'Error during kc-logout, savedTokens is $savedTokens';
      }

      final logoutUrl =
          '${getRealmURL(realm, authServerUrl)}/protocol/openid-connect/logout';

      final dio = Dio();
      dio.options.headers[HttpHeaders.acceptHeader] = 'application/json';
      dio.options.headers[HttpHeaders.contentTypeHeader] =
          'application/x-www-form-urlencoded';

      final response = await dio.get(logoutUrl);

      if (response.statusCode == 200) {
        await clearSession();
        return;
      }

      throw 'Error during kc-logout: ${response.statusCode}: ${response.data}';
    }

    await clearSession();
    return;
  }
}
