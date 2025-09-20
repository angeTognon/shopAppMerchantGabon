import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:merchant/models/user_model.dart';
import 'package:merchant/screens/history_screen.dart';
import 'package:merchant/screens/home_screen.dart';
import 'package:merchant/screens/profile_screen.dart';
import 'package:merchant/screens/rewards_screen.dart';
import 'package:merchant/screens/support_screen.dart';
import 'package:merchant/services/auth_service.dart';
import 'package:merchant/config/api_config.dart';
import 'package:http/http.dart' as http;

class MainScreen extends StatefulWidget {
  final User user;
  

  const MainScreen({super.key, required this.user});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;
  late User _user;
  Timer? _statusTimer;
  bool _isCheckingStatus = false;

  @override
  void initState() {
    super.initState();
    _user = widget.user;
    _startStatusCheck();
  }

  @override
  void dispose() {
    _stopStatusCheck();
    super.dispose();
  }

  void _updateUser(User updatedUser) {
    setState(() {
      _user = updatedUser;
    });
  }

  void _startStatusCheck() {
    _statusTimer = Timer.periodic(Duration(seconds: ApiConfig.statusCheckInterval), (timer) {
      _checkUserStatus();
    });
  }

  // Méthode utilisée pour arrêter proprement la vérification du statut
  void _stopStatusCheck() {
    _statusTimer?.cancel();
    _statusTimer = null;
  }

  Future<void> _checkUserStatus() async {
    // Éviter les appels simultanés
    if (_isCheckingStatus) return;
    
    _isCheckingStatus = true;
    
    try {
      print('Vérification du statut pour l\'utilisateur: ${_user.id}');
      final response = await http.get(
        Uri.parse(ApiConfig.getMerchantUrl(_user.id)),
        headers: {'Content-Type': 'application/json'},
      ).timeout(ApiConfig.requestTimeout);

      print('Réponse du serveur: ${response.statusCode}');
      print('Corps de la réponse: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data['merchant'] != null) {
          final merchantData = data['merchant'];
          final newStatus = merchantData['status'];
          final newCustomMessage = merchantData['customMessage'] ?? merchantData['custom_message'];

          print('Nouveau statut reçu: $newStatus');
          print('Nouveau message: $newCustomMessage');
          print('Statut actuel: ${_user.status}');

          // Vérifier si le statut a changé
          if (_user.status != newStatus || _user.customMessage != newCustomMessage) {
            print('Changement de statut détecté! Mise à jour...');
            if (mounted) {
              setState(() {
                _user = _user.copyWith(
                  status: newStatus,
                  customMessage: newCustomMessage,
                );
              });
              
              // Sauvegarder le nouvel état
              await AuthService.saveUser(_user);
              print('Statut mis à jour et sauvegardé');
            }
          } else {
            print('Aucun changement de statut détecté');
          }
        } else {
          print('Erreur dans la réponse: ${data['error'] ?? 'Données manquantes'}');
        }
      } else {
        print('Erreur HTTP: ${response.statusCode}');
      }
    } catch (e) {
      // En cas d'erreur, on continue sans interrompre l'application
      print('Erreur lors de la vérification du statut: $e');
    } finally {
      _isCheckingStatus = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    // Debug: Afficher le statut actuel
    print('Statut actuel de l\'utilisateur: ${_user.status}');
    print('Message personnalisé: ${_user.customMessage}');
    
    // Vérifier si le statut de l'utilisateur est différent de "Actif"
    if (_user.status != null && _user.status != 'Actif') {
      print('Affichage de l\'écran d\'inactivité');
      return Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.info_outline, size: 64, color: Color(0xFF3B82F6)),
                const SizedBox(height: 16),
                const Text(
                  "Votre compte n'est pas actif",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF111827),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _user.customMessage?.isNotEmpty == true
                      ? _user.customMessage!
                      : "Veuillez contacter le support pour activer votre compte.",
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 16,
                    color: Color(0xFF6B7280),
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: () async {
                    await AuthService.logout();
                    Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
                  },
                  icon: const Icon(Icons.logout),
                  label: const Text('Se déconnecter'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF3B82F6),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final rewardLevels = _user.rewards
        .map((r) => (r['type'] ?? '').toString())
        .where((t) => t.isNotEmpty)
        .toList();
    print('Reward Levels: $rewardLevels');
    final screens = [
      HomeScreen(user: _user, onUserUpdate: _updateUser),
      RewardsScreen(user: _user, rewardLevels: rewardLevels),
      HistoryScreen(user: _user),
      SupportScreen(user: _user),
      ProfileScreen(user: _user, onUserUpdate: _updateUser),
    ];

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: screens,
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        selectedItemColor: const Color(0xFF3B82F6),
        unselectedItemColor: const Color(0xFF6B7280),
        backgroundColor: Colors.white,
        elevation: 8,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Accueil',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.card_giftcard),
            label: 'Récompenses',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.history),
            label: 'Historique',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.support_agent),
            label: 'Support',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profil',
          ),
        ],
      ),
    );
  }
}