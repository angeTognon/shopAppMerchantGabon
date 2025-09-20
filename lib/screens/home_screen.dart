import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:merchant/const.dart';
import 'package:merchant/models/user_model.dart';
import 'package:merchant/screens/auth_screen.dart';
import 'package:merchant/screens/qr_scanner_screen.dart';
import 'package:merchant/services/auth_service.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

// Service pour les réglages commerçant
class MerchantSettingsService {
  static Future<bool> saveSettings({
    required int merchantId,
    required String storeName,
    required String description,
    required int pointsPerScan,
    required List<Map<String, String>> rewards,
    int? id, // pour update
  }) async {
    final action = id == null ? 'add' : 'update';
    final response = await http.post(
      Uri.parse('$baseUrl/merchant_settings.php?action=$action'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'id': id,
        'merchant_id': merchantId,
        'store_name': storeName,
        'description': description,
        'points_per_scan': pointsPerScan,
        'rewards': rewards,
      }),
    );
    final data = jsonDecode(response.body);
    if ((response.statusCode == 200 || response.statusCode == 201) &&
        data['success'] == true) {
      return true;
    }
    throw Exception(data['error'] ?? 'Erreur lors de la sauvegarde');
  }

  static Future<Map<String, dynamic>?> getSettings(int merchantId) async {
    final response = await http.get(
      Uri.parse(
        '$baseUrl/merchant_settings.php?action=get&merchant_id=$merchantId',
      ),
    );
    final data = jsonDecode(response.body);
    if (response.statusCode == 200 && data['id'] != null) {
      return data;
    }
    return null;
  }
}

class HomeScreen extends StatefulWidget {
  final User user;
  final Function(User) onUserUpdate;

  const HomeScreen({super.key, required this.user, required this.onUserUpdate});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Map<String, dynamic>> _notifications = [
    {
      'id': 1,
      'title': 'Nouvelle offre disponible',
      'message': '20% sur votre prochain achat',
      'type': 'offer',
    },
    {
      'id': 2,
      'title': 'Points à expirer',
      'message': '500 points expirent dans 7 jours',
      'type': 'warning',
    },
  ];
  bool _isSaving = false;

  List<TextEditingController> rewardTypeControllers = [];
  List<TextEditingController> rewardValueControllers = [];

  // Variables pour les formulaires intégrés
  bool _showSettingsForm = false;
  bool _showPointsForm = false;

  // Réglages commerçant
  late String storeName;
  late String description;
  List<Map<String, String>> rewards = []; // <-- CORRECT: commence vide
  int pointsToSet = 50;
  int? settingsId; // Pour update

  final _settingsFormKey = GlobalKey<FormState>();
  final _pointsFormKey = GlobalKey<FormState>();
  late TextEditingController storeNameController;
  late TextEditingController descriptionController;
  late TextEditingController pointsToSetController;

  @override
  void initState() {
    super.initState();
    storeNameController = TextEditingController(text: widget.user.storeName);
    descriptionController = TextEditingController();
    pointsToSetController = TextEditingController(text: '50');
    storeName = widget.user.storeName;
    description = '';
    pointsToSet = 50;
    // Ajoute un champ vide si rewards est vide

    _syncRewardControllers();
    _loadMerchantSettings();
    loadMerchantNotifications();
  }

  @override
  void dispose() {
    for (final c in rewardTypeControllers) {
      c.dispose();
    }
    for (final c in rewardValueControllers) {
      c.dispose();
    }
    storeNameController.dispose();
    descriptionController.dispose();
    pointsToSetController.dispose();
    super.dispose();
  }

  Future<void> _loadMerchantSettings() async {
    try {
      final data = await MerchantSettingsService.getSettings(
        int.parse(widget.user.id),
      );
      if (data != null) {
                final rewardsList = (data['rewards'] as List)
            .map<Map<String, String>>(
              (e) => {
                'type': e['type'] ?? '',
                'value': e['value'] ?? '',
                'reward': e['reward'] ?? '', // <-- Ajoute cette ligne !
              },
            )
            .toList();
        setState(() {
          settingsId = data['id'];
          storeName = data['store_name'] ?? '';
          description = data['description'] ?? '';
          pointsToSet = data['points_per_scan'] ?? 50;
          rewards = rewardsList;

          _syncRewardControllers();
          storeNameController.text = storeName;
          descriptionController.text = description;
          pointsToSetController.text = pointsToSet.toString();
        });
      }
    } catch (e) {
      print('Erreur chargement settings: $e');
    }
  }

  Future<void> _saveMerchantSettings() async {
    if (!_settingsFormKey.currentState!.validate()) return;
    setState(() => _isSaving = true);
    try {
      await MerchantSettingsService.saveSettings(
        merchantId: int.parse(widget.user.id),
        storeName: storeNameController.text,
        description: descriptionController.text,
        pointsPerScan: int.tryParse(pointsToSetController.text) ?? 50,
        rewards: rewards,
        id: settingsId,
      );
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Réglages enregistrés')));
      setState(() {
        storeName = storeNameController.text;
        description = descriptionController.text;
        pointsToSet = int.tryParse(pointsToSetController.text) ?? 50;
        _showSettingsForm = false;
      });
      widget.onUserUpdate(
        widget.user.copyWith(
          storeName: storeNameController.text,
          rewards: rewards, // <-- Ajoute cette ligne !
        ),
      );
    } catch (e) {
      print(e);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
      );
    } finally {
      setState(() => _isSaving = false);
    }
  }

  String _userToQrData(User user) {
    final data = {
      'firstName': user.firstName,
      'lastName': user.lastName,
      'email': user.email,
      'tier': user.tier,
      'points': user.points,
    };
    return data.toString();
  }
  // ...existing code...

  void _openQRScanner() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            QRScannerScreen(onScanSuccess: _handleQRScanSuccess),
      ),
    );
  }

  Future<void> addPointsToClient(String clientId, int points) async {
    final response = await http.post(
      Uri.parse('$baseUrl/add_points.php'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'client_id': clientId,
        'points': points,
        'store_name': storeName, // Ajoute le nom de la boutique ici
      }),
    );
    if (response.statusCode != 200) {
      throw Exception('Erreur lors de l\'ajout des points');
    }
  }

  Future<Map<String, dynamic>?> fetchClientInfo(String clientId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/get_client.php?id=$clientId'),
      headers: {'Content-Type': 'application/json'},
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data['success'] == true && data['client'] != null) {
        return data['client'];
      }
    }
    return null;
  }

        void _handleQRScanSuccess(String clientId) async {
      print('QR callback reçu: $clientId');
      final pointsEarned = pointsToSet;
    
      try {
        // Récupère les infos du client AVANT d'ajouter les points
        final clientInfo = await fetchClientInfo(clientId);
    
        // Détermine le niveau max (le plus grand "value" dans rewards)
        int maxLevelPoints = 0;
        for (final reward in rewards) {
          final value = int.tryParse(reward['value'] ?? '') ?? 0;
          if (value > maxLevelPoints) maxLevelPoints = value;
        }
    
        final currentPoints = clientInfo?['points'] ?? 0;
    
        if (currentPoints >= maxLevelPoints && maxLevelPoints > 0) {
          // Niveau max déjà atteint, on remet à zéro et on NE RAJOUTE PAS de points
          await resetClientPoints(clientId);
    
          await addMerchantNotification(
            title: 'Niveau maximum atteint',
            message: clientInfo != null
                ? 'Le client ${clientInfo['first_name']} ${clientInfo['last_name']} recommence à zéro.'
                : 'Le client $clientId recommence à zéro.',
            type: 'info',
          );
    
          // Affiche le dialog
          showDialog(
            context: context,
            builder: (context) => Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.emoji_events, color: Color(0xFF10B981), size: 60),
                    const SizedBox(height: 16),
                    const Text(
                      'Niveau maximum atteint !',
                      style: TextStyle(
                        fontSize: 20,
                        fontFamily: "b",
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF10B981),
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      clientInfo != null
                          ? 'Le client ${clientInfo['first_name']} ${clientInfo['last_name']} recommence à zéro.'
                          : 'Le client $clientId recommence à zéro.',
                      style: const TextStyle(fontSize: 16, fontFamily: "r"),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF10B981),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        onPressed: () => Navigator.pop(context),
                        child: const Text(
                          'Fermer',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontFamily: "r",
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        } else {
          // Ajoute les points normalement
          await addPointsToClient(clientId, pointsEarned);
    
          await addMerchantNotification(
            title: 'Points attribués !',
            message: clientInfo != null
                ? 'Le client ${clientInfo['first_name']} ${clientInfo['last_name']} a reçu $pointsEarned points'
                : 'Le client $clientId a reçu $pointsEarned points',
            type: 'success',
          );
    
          // Affiche le dialog
          showDialog(
            context: context,
            builder: (context) => Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.emoji_events, color: Color(0xFF10B981), size: 60),
                    const SizedBox(height: 16),
                    const Text(
                      'Points attribués !',
                      style: TextStyle(
                        fontSize: 20,
                        fontFamily: "b",
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF10B981),
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      clientInfo != null
                          ? 'Le client ${clientInfo['first_name']} ${clientInfo['last_name']} a reçu $pointsEarned points 🎉'
                          : 'Le client $clientId a reçu $pointsEarned points 🎉',
                      style: const TextStyle(fontSize: 16, fontFamily: "r"),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF10B981),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        onPressed: () => Navigator.pop(context),
                        child: const Text(
                          'Fermer',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontFamily: "r",
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }
    
        // Recharge la liste
        await loadMerchantNotifications();
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red),
        );
      }
    }
Future<void> resetClientPoints(String clientId) async {
  final response = await http.post(
    Uri.parse('$baseUrl/reset_points.php'),
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode({'client_id': clientId}),
  );
  if (response.statusCode != 200) {
    throw Exception('Erreur lors de la remise à zéro des points');
  }
}
  Future<void> addMerchantNotification({
    required String title,
    required String message,
    required String type,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/merchant_notifications.php?action=add'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'merchant_id': widget.user.id,
        'title': title,
        'message': message,
        'type': type,
      }),
    );
    if (response.statusCode != 200) {
      throw Exception('Erreur lors de l\'ajout de la notification');
    }
  }

  Future<void> loadMerchantNotifications() async {
    final response = await http.get(
      Uri.parse(
        '$baseUrl/merchant_notifications.php?action=get&merchant_id=${widget.user.id}',
      ),
      headers: {'Content-Type': 'application/json'},
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data['success'] == true && data['notifications'] != null) {
        setState(() {
          _notifications = List<Map<String, dynamic>>.from(
            data['notifications'],
          );
        });
      }
    }
  }

  Future<void> deleteMerchantNotification(int id) async {
    final response = await http.get(
      Uri.parse('$baseUrl/merchant_notifications.php?action=delete&id=$id'),
      headers: {'Content-Type': 'application/json'},
    );
    if (response.statusCode == 200) {
      setState(() {
        _notifications.removeWhere((n) => n['id'] == id);
      });
    }
  }
    List<TextEditingController> rewardLabelControllers = [];

  // ...existing code...
    void _syncRewardControllers() {
    while (rewardTypeControllers.length < rewards.length) {
      rewardTypeControllers.add(TextEditingController(text: rewards[rewardTypeControllers.length]['type']));
      rewardValueControllers.add(TextEditingController(text: rewards[rewardValueControllers.length]['value']));
      rewardLabelControllers.add(TextEditingController(text: rewards[rewardLabelControllers.length]['reward'] ?? ''));
    }
    while (rewardTypeControllers.length > rewards.length) {
      rewardTypeControllers.removeLast().dispose();
      rewardValueControllers.removeLast().dispose();
      rewardLabelControllers.removeLast().dispose();
    }
  }

  @override
  Widget build(BuildContext context) {
    final nextTierPoints = _getNextTierPoints(widget.user.tier);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.all(20.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Store name (left)
                    Expanded(
                      child: Text(
                        storeName,
                        style: const TextStyle(
                          fontSize: 17,
                          fontFamily: "b",
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF3B82F6),
                        ),
                      ),
                    ),
                    // Customer name (right)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        const Text(
                          'Bonjour,',
                          style: TextStyle(
                            fontFamily: "r",
                            fontSize: 16,
                            color: Color(0xFF6B7280),
                          ),
                        ),
                        Text(
                          '${widget.user.firstName} ${widget.user.lastName}',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            fontFamily: "b",
                            color: Color(0xFF1F2937),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ).animate().fadeIn(duration: 600.ms),

              // QR Scanner Button
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: Container(
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF10B981), Color(0xFF059669)],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF10B981).withOpacity(0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: () => _openQRScanner(),
                      child: Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.qr_code_scanner,
                              size: 32,
                              color: Colors.white,
                            ),
                            const SizedBox(width: 16),
                            const Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Scanner QR Code',
                                    style: TextStyle(
                                      fontSize: 17,
                                      fontFamily: "b",
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    'Attribuez des points instantanément',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontFamily: "r",
                                      color: Colors.white70,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ).animate().slideX(delay: 200.ms, duration: 600.ms),
              const SizedBox(height: 20),

              // Formulaire Réglages commerçant
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Ma Boutique',
                      style: TextStyle(
                        fontSize: 16,
                        fontFamily: "b",
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1F2937),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(top: 20.0),
                      child: Form(
                        key: _settingsFormKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            TextFormField(
                              controller: storeNameController,
                              style: const TextStyle(fontFamily: "r",fontSize: 14),
                              decoration: InputDecoration(
                                labelStyle: const TextStyle(fontFamily: "r",fontSize: 14),
                                labelText: 'Nom de la boutique',
                                prefixIcon: const Icon(Icons.store),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                filled: true,
                                fillColor: Colors.white,
                              ),
                              validator: (v) => v == null || v.isEmpty
                                  ? 'Champ obligatoire'
                                  : null,
                              onChanged: (v) => storeName = v,
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: descriptionController,
                               style: const TextStyle(fontFamily: "r",fontSize: 14),
                              decoration: InputDecoration(
                                labelStyle: const TextStyle(fontFamily: "r",fontSize: 14),
                                labelText: 'Description (optionnel)',
                                // labelStyle: const TextStyle(fontFamily: "r",fontSize: 14),
                                prefixIcon: const Icon(Icons.info_outline),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                filled: true,
                                fillColor: Colors.white,
                              ),
                              onChanged: (v) => description = v,
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: pointsToSetController,
                               style: const TextStyle(fontFamily: "r",fontSize: 14),
                              decoration: InputDecoration(
                                labelStyle: const TextStyle(fontFamily: "r",fontSize: 14),
                                labelText: 'Points attribués par scan',
                                prefixIcon: const Icon(Icons.confirmation_num),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                filled: true,
                                fillColor: Colors.white,
                              ),
                              keyboardType: TextInputType.number,
                              onChanged: (v) => setState(
                                () => pointsToSet = int.tryParse(v) ?? 0,
                              ),
                            ),
                               if (rewards.isNotEmpty)const SizedBox(height: 20),
                                                        if (rewards.isNotEmpty)
                              const Text(
                                "Niveaux de récompenses",
                                style: TextStyle(
                                  fontSize: 16,
                                  fontFamily: "b",
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF1F2937),
                                ),
                              ),
                               if (rewards.isNotEmpty)const SizedBox(height: 20),
                            ...rewards.asMap().entries.map((entry) {
                              int idx = entry.key;
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 12.0),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: TextFormField(
                                        controller: rewardTypeControllers[idx],
                                        decoration: InputDecoration(
                                          labelText: 'Niveau',
                                          prefixIcon: const Icon(
                                            Icons.card_giftcard,
                                          ),
                                          border: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(
                                              10,
                                            ),
                                          ),
                                          filled: true,
                                          fillColor: Colors.white,
                                        ),
                                        onChanged: (v) =>
                                            rewards[idx]['type'] = v,
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: TextFormField(
                                        controller: rewardValueControllers[idx],
                                        decoration: InputDecoration(
                                          labelText: 'Points',
                                          prefixIcon: const Icon(Icons.star),
                                          border: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(
                                              10,
                                            ),
                                          ),
                                          filled: true,
                                          fillColor: Colors.white,
                                        ),
                                        onChanged: (v) =>
                                            rewards[idx]['value'] = v,
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(
                                        Icons.delete,
                                        color: Colors.redAccent,
                                      ),
                                      onPressed: rewards.length > 1
                                          ? () => setState(() {
                                              rewards.removeAt(idx);
                                              _syncRewardControllers();
                                            })
                                          : null,
                                    ),
                                  ],
                                ),
                              );
                            }),
                                                        // ... section "Niveaux de récompenses" ...
                            
                               if (rewards.isNotEmpty)const SizedBox(height: 24),
                               if (rewards.isNotEmpty)const Text(
                              "Récompenses par niveau",
                              style: TextStyle(
                                fontSize: 16,
                                fontFamily: "b",
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1F2937),
                              ),
                            ),
                              if (rewards.isNotEmpty) const SizedBox(height: 16),
                                                        ...rewards.asMap().entries.map((entry) {
                              int idx = entry.key;
                              if (idx >= rewardTypeControllers.length ||
                                  idx >= rewardValueControllers.length ||
                                  idx >= rewardLabelControllers.length) {
                                return const SizedBox.shrink();
                              }
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 12.0),
                                child: Row(
                                  children: [
                                    Expanded(
                                      flex: 2,
                                      child: Text(
                                        rewardTypeControllers[idx].text.isNotEmpty
                                            ? rewardTypeControllers[idx].text
                                            : 'Niveau ${idx + 1}',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 15,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      flex: 5,
                                      child: TextFormField(
                                        controller: rewardLabelControllers[idx],
                                        decoration: InputDecoration(
                                          labelText: 'Récompense pour ce niveau',
                                          prefixIcon: const Icon(Icons.emoji_events),
                                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                          filled: true,
                                          fillColor: Colors.white,
                                        ),
                                        onChanged: (v) => rewards[idx]['reward'] = v,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }),
                            Align(
                              alignment: Alignment.centerLeft,
                              child: TextButton.icon(
                                icon: const Icon(
                                  Icons.add,
                                  color: Color(0xFF10B981),
                                ),
                                label: const Text(
                                  'Ajouter un niveau de récompense',
                                  style: TextStyle(
                                    color: Color(0xFF10B981),
                                    fontFamily: "b",
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                onPressed: () {
                                  setState(() {
                                    rewards.add({'type': '', 'value': '', 'reward': ''});
                                    _syncRewardControllers();
                                  });
                                },
                              ),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton.icon(
                              icon: const Icon(Icons.save),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF10B981),
                                minimumSize: const Size.fromHeight(48),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              onPressed: _isSaving
                                  ? null
                                  : _saveMerchantSettings,
                              label: _isSaving
                                  ? const SizedBox(
                                      width: 24,
                                      height: 24,
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 2.5,
                                      ),
                                    )
                                  : const Text(
                                      'Enregistrer',
                                      style: TextStyle(
                                        fontSize: 16,
                                        color: Colors.white,
                                      ),
                                    ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 22),

              // Notifications
              if (_notifications.isNotEmpty) ...[
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Notifications',
                        style: TextStyle(
                          fontSize: 16,
                          fontFamily: "b",
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1F2937),
                        ),
                      ),
                      const SizedBox(height: 16),
                      ..._notifications.map(
                        (notification) => _buildNotificationCard(notification),
                      ),
                    ],
                  ),
                ).animate().fadeIn(delay: 800.ms, duration: 600.ms),

                const SizedBox(height: 22),
              ],

              // // Recent Activity
              // Padding(
              //   padding: const EdgeInsets.symmetric(horizontal: 20.0),
              //   child: Column(
              //     crossAxisAlignment: CrossAxisAlignment.start,
              //     children: [
              //       const Text(
              //         'Activité récente',
              //         style: TextStyle(
              //           fontSize: 16,
              //           fontFamily: "b",
              //           fontWeight: FontWeight.bold,
              //           color: Color(0xFF1F2937),
              //         ),
              //       ),
              //       const SizedBox(height: 16),
              //       Container(
              //         width: double.infinity,
              //         padding: const EdgeInsets.all(20),
              //         decoration: BoxDecoration(
              //           color: Colors.white,
              //           borderRadius: BorderRadius.circular(12),
              //           boxShadow: [
              //             BoxShadow(
              //               color: Colors.black.withOpacity(0.1),
              //               blurRadius: 8,
              //               offset: const Offset(0, 2),
              //             ),
              //           ],
              //         ),
              //         child: const Column(
              //           crossAxisAlignment: CrossAxisAlignment.start,
              //           children: [
              //             Text(
              //               '3 achats ce mois-ci',
              //               style: TextStyle(
              //                 fontSize: 14,
              //                 fontFamily: "b",
              //                 fontWeight: FontWeight.w600,
              //                 color: Color(0xFF1F2937),
              //               ),
              //             ),
              //             SizedBox(height: 4),
              //             Text(
              //               'Continuez pour gagner plus de points !',
              //               style: TextStyle(
              //                 fontSize: 13,
              //                 fontFamily: "r",
              //                 color: Color(0xFF6B7280),
              //               ),
              //             ),
              //           ],
              //         ),
              //       ),
              //     ],
              //   ),
              // ).animate().fadeIn(delay: 1000.ms, duration: 600.ms),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNotificationCard(Map<String, dynamic> notification) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  notification['title'],
                  style: const TextStyle(
                    fontSize: 14,
                    fontFamily: "b",
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1F2937),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  notification['message'],
                  style: const TextStyle(
                    fontFamily: "r",
                    fontSize: 13,
                    color: Color(0xFF6B7280),
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.delete, color: Colors.redAccent),
            onPressed: () => deleteMerchantNotification(notification['id']),
          ),
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: notification['type'] == 'offer'
                  ? const Color(0xFF10B981)
                  : const Color(0xFFF59E0B),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ],
      ),
    );
  }

  // void _openQRScanner() {
  //   // Navigator.push(
  //   //   context,
  //   //   MaterialPageRoute(
  //   //     builder: (context) => QRScannerScreen(
  //   //       onScanSuccess: _handleQRScanSuccess,
  //   //     ),
  //   //   ),
  //   // );
  // }

  // void _handleQRScanSuccess(String data) {
  //   // Utilise pointsToSet pour le nombre de points à accorder
  //   final pointsEarned = pointsToSet;

  //   // Update user points
  //   final updatedUser = widget.user.copyWith(
  //     points: widget.user.points + pointsEarned,
  //   );
  //   AuthService.updateUserPoints(widget.user, pointsEarned);
  //   widget.onUserUpdate(updatedUser);

  //   // Add success notification
  //   setState(() {
  //     _notifications.insert(0, {
  //       'id': DateTime.now().millisecondsSinceEpoch,
  //       'title': 'Points gagnés !',
  //       'message': 'Vous avez gagné $pointsEarned points',
  //       'type': 'success',
  //     });
  //   });

  //   // Show success dialog
  //   showDialog(
  //     context: context,
  //     builder: (context) => AlertDialog(
  //       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
  //       title: const Row(
  //         children: [
  //           Icon(Icons.check_circle, color: Color(0xFF10B981)),
  //           SizedBox(width: 8),
  //           Text('Félicitations !'),
  //         ],
  //       ),
  //       content: Text('Vous avez gagné $pointsEarned points !'),
  //       actions: [
  //         TextButton(
  //           onPressed: () => Navigator.pop(context),
  //           child: const Text('OK'),
  //         ),
  //       ],
  //     ),
  //   );
  // }

  int _getNextTierPoints(String tier) {
    switch (tier) {
      case 'Bronze':
        return 1000;
      case 'Silver':
        return 2500;
      case 'Gold':
        return 5000;
      default:
        return 1000;
    }
  }

  Color _getTierColor(String tier) {
    switch (tier) {
      case 'Bronze':
        return const Color.fromARGB(255, 255, 225, 195);
      case 'Silver':
        return const Color(0xFFC0C0C0);
      case 'Gold':
        return const Color(0xFFFFD700);
      default:
        return const Color(0xFF3B82F6);
    }
  }
}
