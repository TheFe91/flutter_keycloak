# flutter_keycloak

Manage your Keycloak tokens in a Flutter app.

This plugin exposes some util methods to interact with [Keycloak][KeycloakHome] in order to handle the user session.

## Documentation

- [Setup][SetupAnchor]
- [API][APIAnchor]
- [Utils][UtilsAnchor]

## Setup

### App configuration

### Imports
Import the library and initialize the plugin
```dart
import 'package:flutter_keycloak/flutter_keycloak.dart';

final FlutterKeycloak _flutterKeycloak = FlutterKeycloak();
```

## API
### login

```dart
void login() async {
  await _flutterKeycloak.login(
    _conf,
    _username,
    _password,
    scope: _scope,
  );
}
```

Sometimes you may need to re-login your user w/ Keycloak via the login process but, for some reason, you don't want / can't display the login page.<br>
This method will re-login your user.

### refreshLogin

```dart
void refreshLogin() async {
  await _flutterKeycloak.refreshLogin(
    scope: 'offline_access',
  );
}
```

### retrieveUserInfo
```dart
void retrieveUserInfo() async {
  final userInfo = await _flutterKeycloak.retrieveUserInfo();
  setState(() {
    _currentPrefs = userInfo.toString();
  });
}
```

### logout
```dart
void logout() async {
  await _flutterKeycloak.logout();
  printStorage();
}
```

_destroySession_: Since the `/openid-connect/token` simply returns an `access token` and doesn't create any session on Keycloak side, if you used the `login` method you want to pass false.<br/>
Passing `true` tries to destroy the session: pay attention that on newer Keycloak versions this raises an error if no session is present, preventing the logout.