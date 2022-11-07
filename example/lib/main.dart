import 'package:flutter/material.dart';
import 'package:flutter_keycloak/flutter_keycloak.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

void main() {
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
  _FlutterKeycloakExampleState createState() => _FlutterKeycloakExampleState();
}

class _FlutterKeycloakExampleState extends State<FlutterKeycloakExample> {
  final FlutterKeycloak _flutterKeycloak = FlutterKeycloak();
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  final TextEditingController _confController = TextEditingController(
    text:
        'https://golive.dev.radicalbit.io/muxtenant/kong-api/users-service/api/subtenants/muxtenant/config',
  );
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _scopeController = TextEditingController();

  String _currentPrefs = '';
  Map? _conf;

  @override
  void dispose() {
    _confController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    _scopeController.dispose();
    super.dispose();
  }

  void printStorage() async {
    final all = await _storage.readAll();
    _currentPrefs = '';
    if (all.isNotEmpty) {
      all.forEach((key, value) async {
        _currentPrefs = '$_currentPrefs\n${await _storage.read(key: key)}';
      });
    }
    setState(() {});
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
                        printStorage();
                      },
                      child: const Text('LOGOUT'),
                    ),
                    Text(_currentPrefs),
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
