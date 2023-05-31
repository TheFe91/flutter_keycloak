import 'package:flutter/material.dart';
import 'package:flutter_keycloak/flutter_keycloak.dart';
import 'package:flutter_keycloak/token_storage.dart';
import 'package:get_storage/get_storage.dart';

void main() async {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Keycloak Example',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const FlutterKeycloakExample('Flutter Keycloak Example'),
    );
  }
}

class FlutterKeycloakExample extends StatefulWidget {
  final String title;

  const FlutterKeycloakExample(this.title, {Key? key}) : super(key: key);

  @override
  FlutterKeycloakExampleState createState() => FlutterKeycloakExampleState();
}

class FlutterKeycloakExampleState extends State<FlutterKeycloakExample> {
  final FlutterKeycloak _flutterKeycloak = FlutterKeycloak();
  late final TextEditingController _confController;
  late final TextEditingController _usernameController;
  late final TextEditingController _passwordController;
  late final TextEditingController _scopeController;

  String _currentPrefs = '';
  Map? _conf;

  @override
  void initState() {
    GetStorage.init();
    _confController = TextEditingController();
    _usernameController = TextEditingController();
    _passwordController = TextEditingController();
    _scopeController = TextEditingController();
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
    getCredentials().then((credentials) {
      setState(() {
        _currentPrefs =
            '${getConfiguration()}\n\n${getTokens()}\n\n$credentials';
      });
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
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _usernameController,
                            decoration:
                                const InputDecoration(hintText: 'Username'),
                          ),
                        ),
                        const SizedBox(width: 20),
                        Expanded(
                          child: TextFormField(
                            controller: _passwordController,
                            decoration:
                                const InputDecoration(hintText: 'Password'),
                          ),
                        ),
                        const SizedBox(width: 20),
                        Expanded(
                          child: TextFormField(
                            controller: _scopeController,
                            decoration:
                                const InputDecoration(hintText: 'Scope'),
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
                              : 'offline_access',
                        );
                        printStorage();
                      },
                      child: const Text('LOGIN'),
                    ),
                    ElevatedButton(
                      onPressed: () async {
                        final userInfo =
                            await _flutterKeycloak.retrieveUserInfo();
                        setState(() {
                          _currentPrefs = userInfo.toString();
                        });
                      },
                      child: const Text('GET USER INFO'),
                    ),
                    ElevatedButton(
                      onPressed: () async {
                        await _flutterKeycloak.refreshLogin(
                          scope: 'offline_access',
                        );
                        printStorage();
                      },
                      child: const Text('REFRESH LOGIN'),
                    ),
                    ElevatedButton(
                      onPressed: () async {
                        await _flutterKeycloak.refreshToken();
                        printStorage();
                      },
                      child: const Text('REFRESH TOKEN'),
                    ),
                    ElevatedButton(
                      onPressed: () async {
                        await _flutterKeycloak.logout();
                        setState(() {
                          _currentPrefs = '';
                        });
                      },
                      child: const Text('LOGOUT'),
                    ),
                    if (_currentPrefs != '') Text(_currentPrefs),
                  ],
                )
              : Column(
                  children: [
                    TextFormField(
                      controller: _confController,
                      decoration: const InputDecoration(
                          hintText: 'Type here the config url'),
                    ),
                    ElevatedButton(
                      onPressed: () => _flutterKeycloak
                          .getConf(_confController.text)
                          .then((conf) => setState(() => _conf = conf)),
                      child: const Text('GET CONF AND PROCEED'),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}
