import 'package:flutter/material.dart';
import 'package:merchant/models/user_model.dart';
import 'package:merchant/screens/history_screen.dart';
import 'package:merchant/screens/home_screen.dart';
import 'package:merchant/screens/profile_screen.dart';
import 'package:merchant/screens/rewards_screen.dart';
import 'package:merchant/screens/support_screen.dart';

class MainScreen extends StatefulWidget {
  final User user;
  

  const MainScreen({super.key, required this.user});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;
  late User _user;

  @override
  void initState() {
    super.initState();
    _user = widget.user;
  }

  void _updateUser(User updatedUser) {
    setState(() {
      _user = updatedUser;
    });
  }

  @override
  Widget build(BuildContext context) {
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