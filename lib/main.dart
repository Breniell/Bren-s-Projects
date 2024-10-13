import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_web_auth/flutter_web_auth.dart';
import 'package:oauth2/oauth2.dart' as oauth2;

// Paramètres OAuth2
final authorizationEndpoint = Uri.parse(
    'https://sso.bitkap.africa/realms/bitkap_dev/protocol/openid-connect/auth');
final tokenEndpoint = Uri.parse(
    'https://sso.bitkap.africa/realms/bitkap_dev/protocol/openid-connect/token');
final redirectUrl = Uri.parse('http://localhost:4000/oauth2redirect');
const clientId = 'angolar_test';
const secret = '';
const FlutterSecureStorage storage = FlutterSecureStorage();

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Keycloak OAuth2 Authentification',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const LoginPage(),
    );
  }
}

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

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

      // Rediriger vers la page d'accueil après l'inscription
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const HomePage()),
      );
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
                const Text(
                  'Bienvenue à Bitkap',
                  style: TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 50),
                ElevatedButton(
                  onPressed: _authenticate,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.yellow[600],
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                    elevation: 5,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Se connecter avec Keycloak',
                    style: TextStyle(fontSize: 18),
                  ),
                ),
                const SizedBox(height: 30),
                const Text(
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

// Page d'accueil
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(seconds: 2));
    _animation = Tween<Offset>(begin: const Offset(0, 1), end: const Offset(0, 0)).animate(
        CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Accueil Bitkap', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.blue[900],
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications),
            onPressed: () {
              // Handle notifications
            },
          ),
        ],
      ),
      drawer: _buildDrawer(),
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildWelcomeBanner(),
            _buildFeaturedServices(),
            _buildQuickActions(),
            _buildRecentActivity(),
            _buildFooter(),
          ],
        ),
      ),
    );
  }

  Widget _buildWelcomeBanner() {
    return Stack(
      children: [
        Container(
          height: 200,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.blue[800]!, Colors.blue[400]!],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
        ),
        SlideTransition(
          position: _animation,
          child: const Center(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 50.0),
              child: Text(
                'Bienvenue à Bitkap!',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFeaturedServices() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Services recommandés',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildServiceCard('Échanges', Icons.swap_horiz, Colors.orange),
              _buildServiceCard('Investissements', Icons.trending_up, Colors.green),
              _buildServiceCard('Portefeuille', Icons.account_balance_wallet, Colors.blue),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildServiceCard(String title, IconData icon, Color color) {
    return Expanded(
      child: Card(
        elevation: 5,
        child: InkWell(
          onTap: () {
            // Handle service card click
          },
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Icon(icon, color: color, size: 40),
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(title, style: const TextStyle(fontSize: 18)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickActions() {
    return Padding(
        padding: const EdgeInsets.all(16.0),
    child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
    const Text(
    'Actions rapides',
    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
    ),
    const SizedBox(height: 10),
    Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      _buildQuickAction('Voir portefeuille', Icons.account_balance, Colors.blue),
      _buildQuickAction('Faire un dépôt', Icons.arrow_downward, Colors.green),
      _buildQuickAction('Retirer', Icons.arrow_upward, Colors.red),
    ],
    ),
    ],
    ),
    );
  }

  Widget _buildQuickAction(String title, IconData icon, Color color) {
    return Expanded(
      child: Card(
        elevation: 5,
        child: InkWell(
          onTap: () {
            // Handle quick action click
          },
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Icon(icon, color: color, size: 40),
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(title, style: const TextStyle(fontSize: 18)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRecentActivity() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Activité récente',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          ListView.builder(
            shrinkWrap: true,
            itemCount: 5,
            itemBuilder: (context, index) {
              return ListTile(
                leading: Icon(Icons.history, color: Colors.blue[700]),
                title: Text('Transaction #$index', style: const TextStyle(fontSize: 18)),
                subtitle: Text('Description de la transaction #$index'),
                trailing: const Icon(Icons.arrow_forward_ios),
                onTap: () {
                  // Handle activity tap
                },
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildFooter() {
    return const Padding(
      padding: EdgeInsets.all(16.0),
      child: Column(
        children: [
          Divider(),
          Text(
            '© 2024 Bitkap. Tous droits réservés.',
            style: TextStyle(fontSize: 14, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawer() {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: BoxDecoration(
              color: Colors.blue[900],
            ),
            child: const Text(
              'Menu',
              style: TextStyle(color: Colors.white, fontSize: 24),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.account_circle),
            title: const Text('Mon Profil'),
            onTap: () {
              // Handle profile tap
            },
          ),
          ListTile(
            leading: const Icon(Icons.settings),
            title: const Text('Paramètres'),
            onTap: () {
              // Handle settings tap
            },
          ),
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text('Se déconnecter'),
            onTap: () {
              // Handle logout tap
            },
          ),
        ],
      ),
    );
  }
}

