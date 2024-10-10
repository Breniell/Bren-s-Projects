import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_web_auth/flutter_web_auth.dart';
import 'package:oauth2/oauth2.dart' as oauth2;

// Paramètres OAuth2
final authorizationEndpoint = Uri.parse(
    'https://sso.bitkap.africa/realms/bitkap_dev/protocol/openid-connect/auth');
final tokenEndpoint = Uri.parse(
    'https://sso.bitkap.africa/realms/bitkap_dev/protocol/openid-connect/token');
final redirectUrl = Uri.parse('com.example.app:/oauth2redirect');
final clientId = 'angolar_test';
final secret = '';
final FlutterSecureStorage storage = const FlutterSecureStorage();

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Keycloak OAuth2 Authentification',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: LoginPage(),
    );
  }
}

class LoginPage extends StatefulWidget {
  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  oauth2.Client? _client;

  @override
  void initState() {
    super.initState();
    _loadTokens();
  }

  Future<void> _loadTokens() async {
    String? accessToken = await storage.read(key: 'accessToken');
    String? refreshToken = await storage.read(key: 'refreshToken');

    if (accessToken != null && refreshToken != null) {
      final credentials = oauth2.Credentials(accessToken,
          refreshToken: refreshToken, tokenEndpoint: tokenEndpoint);
      _client = oauth2.Client(credentials, identifier: clientId);
    }
  }

  Future<void> _authenticate() async {
    final grant = oauth2.AuthorizationCodeGrant(
      clientId,
      authorizationEndpoint,
      tokenEndpoint,
      secret: secret.isNotEmpty ? secret : null,
    );

    final authorizationUrl =
    grant.getAuthorizationUrl(redirectUrl, scopes: ['openid', 'profile', 'email']);

    final result = await FlutterWebAuth.authenticate(
      url: authorizationUrl.toString(),
      callbackUrlScheme: 'com.example.app',
    );

    final authorizationCode = Uri.parse(result).queryParameters['code'];

    if (authorizationCode != null) {
      await _exchangeCodeForToken(authorizationCode);
    }
  }

  Future<void> _exchangeCodeForToken(String authorizationCode) async {
    try {
      _client = await oauth2.AuthorizationCodeGrant(
        clientId,
        authorizationEndpoint,
        tokenEndpoint,
        secret: secret.isNotEmpty ? secret : null,
      ).handleAuthorizationResponse({'code': authorizationCode});

      await storage.write(key: 'accessToken', value: _client!.credentials.accessToken);
      await storage.write(key: 'refreshToken', value: _client!.credentials.refreshToken);
    } catch (e) {
      print('Erreur lors de l\'échange du code d\'autorisation: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.blue[300]!, Colors.blue[700]!],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Bienvenue à Bitkap',
                  style: TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 50),
                ElevatedButton(
                  onPressed: _authenticate,
                  child: Text(
                    'Se connecter avec Keycloak',
                    style: TextStyle(fontSize: 18),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.yellow[600],
                    padding: EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                    elevation: 5,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                SizedBox(height: 30),
                Text(
                  'En vous connectant, vous acceptez nos Conditions d\'utilisation.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}