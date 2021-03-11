import 'package:flutter/material.dart';

import 'package:flutter_keycloak/flutter_keycloak.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Keycloak Example',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: FlutterKeycloakExample('Flutter Keycloak Example'),
    );
  }
}

class FlutterKeycloakExample extends StatefulWidget {
  final String title;

  FlutterKeycloakExample(this.title);

  @override
  _FlutterKeycloakExampleState createState() => _FlutterKeycloakExampleState();
}

class _FlutterKeycloakExampleState extends State<FlutterKeycloakExample> {
  FlutterKeycloak _flutterKeycloak = FlutterKeycloak();
  SharedPreferences? prefs;
  String _currentPrefs = '';
  Map? _conf;
  TextEditingController _confController = TextEditingController();
  TextEditingController _usernameController = TextEditingController();
  TextEditingController _passwordController = TextEditingController();
  TextEditingController _scopeController = TextEditingController();

  @override
  initState() {
    SharedPreferences.getInstance().then((sp) => prefs = sp);
    super.initState();
  }

  @override
  void dispose() {
    _confController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    _scopeController.dispose();
    super.dispose();
  }

  void printStorage() {
    setState(() {
      _currentPrefs = '';
      if (prefs!.getKeys().length > 0) {
        for (var key in prefs!.getKeys()) {
          _currentPrefs = '${_currentPrefs}\n${prefs!.getString(key)}';
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Center(
          child: _conf != null
              ? ListView(
                  children: <Widget>[
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _usernameController,
                            decoration: InputDecoration(hintText: 'Username'),
                          ),
                        ),
                        SizedBox(width: 20),
                        Expanded(
                          child: TextFormField(
                            controller: _passwordController,
                            decoration: InputDecoration(hintText: 'Password'),
                          ),
                        ),
                        SizedBox(width: 20),
                        Expanded(
                          child: TextFormField(
                            controller: _scopeController,
                            decoration: InputDecoration(hintText: 'Scope'),
                          ),
                        ),
                      ],
                    ),
                    ElevatedButton(
                      onPressed: () async {
                        await _flutterKeycloak.login(
                          _conf,
                          _usernameController.text,
                          _passwordController.text,
                          scope: _scopeController.text != ''
                              ? _scopeController.text
                              : 'info',
                        );
                        printStorage();
                      },
                      child: Text('LOGIN'),
                    ),
                    ElevatedButton(
                      onPressed: () async {
                        final userInfo =
                            await _flutterKeycloak.retrieveUserInfo();
                        setState(() {
                          _currentPrefs = userInfo.toString();
                        });
                      },
                      child: Text('GET USER INFO'),
                    ),
                    ElevatedButton(
                      onPressed: () async {
                        await _flutterKeycloak.refreshLogin(
                          scope: 'openid info offline_access',
                        );
                        printStorage();
                      },
                      child: Text('REFRESH LOGIN'),
                    ),
                    ElevatedButton(
                      onPressed: () async {
                        await _flutterKeycloak.refreshToken();
                        printStorage();
                      },
                      child: Text('REFRESH TOKEN'),
                    ),
                    ElevatedButton(
                      onPressed: () async {
                        await _flutterKeycloak.logout();
                        printStorage();
                      },
                      child: Text('LOGOUT'),
                    ),
                    Text(_currentPrefs),
                  ],
                )
              : Column(
                  children: [
                    TextFormField(
                      controller: _confController,
                      decoration:
                          InputDecoration(hintText: 'Type here the config url'),
                    ),
                    ElevatedButton(
                      onPressed: () => _flutterKeycloak
                          .getConf(_confController.text)
                          .then((conf) => setState(() => _conf = conf)),
                      child: Text('GET CONF AND PROCEED'),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}
