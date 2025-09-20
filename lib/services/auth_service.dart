import 'dart:convert';
import 'package:merchant/models/user_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  static const String _userKey = 'current_user';

  static Future<User?> getCurrentUser() async {
    final prefs = await SharedPreferences.getInstance();
    final userJson = prefs.getString(_userKey);
    if (userJson != null) {
      return User.fromJson(jsonDecode(userJson));
    }
    return null;
  }

  static Future<void> saveUser(User user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userKey, jsonEncode(user.toJson()));
  }

  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_userKey);
    await prefs.setBool('has_seen_onboarding', false);
  }

  static Future<User> login(String email, String password) async {
    // Simulate API call
    await Future.delayed(const Duration(seconds: 2));
    if (email == 'demo@example.com' && password == 'demo123') {
      final user = User(
        id: '1',
        email: email,
        firstName: 'Marie',
        lastName: 'Dupont',
        phone: '+33 6 12 34 56 78',
        points: 2450,
        tier: 'Gold',
        memberSince: '2022',
        storeName: 'Boutique Fashion',
        rewards: [],
        status: 'Inactif', // Changé pour tester
        customMessage: 'Votre compte a été suspendu pour non-paiement. Veuillez contacter le service client.',
      );
      await saveUser(user);
      return user;
    } else if (email == 'test@example.com' && password == 'test123') {
      // Utilisateur de test avec statut actif
      final user = User(
        id: '2',
        email: email,
        firstName: 'Test',
        lastName: 'User',
        phone: '+33 6 00 00 00 00',
        points: 100,
        tier: 'Bronze',
        memberSince: '2024',
        storeName: 'Test Store',
        rewards: [],
        status: 'Actif',
        customMessage: null,
      );
      await saveUser(user);
      return user;
    } else {
      throw Exception('Identifiants incorrects');
    }
  }

  static Future<User> register(Map<String, String> userData) async {
    // Simulate API call
    await Future.delayed(const Duration(seconds: 2));
    final user = User(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      email: userData['email']!,
      firstName: userData['firstName']!,
      lastName: userData['lastName']!,
      phone: userData['phone'],
      points: 100, // Welcome bonus
      tier: 'Bronze',
      memberSince: DateTime.now().year.toString(),
      storeName: 'Boutique Fashion',
      rewards: [],
      status: 'Actif',
      customMessage: null,
    );
    await saveUser(user);
    return user;
  }

  static Future<void> updateUserPoints(User user, int pointsToAdd) async {
    final updatedUser = user.copyWith(points: user.points + pointsToAdd);
    await saveUser(updatedUser);
  }
}