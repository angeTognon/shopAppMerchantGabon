import 'dart:convert';
import 'package:http/http.dart' as http;

import 'package:flutter/material.dart';
import 'package:merchant/const.dart';
import 'package:merchant/models/user_model.dart';
import 'package:merchant/screens/auth_screen.dart';
import 'package:merchant/screens/profile_sections/bonus_history_screen.dart';
import 'package:merchant/screens/profile_sections/edit_profile_screen.dart';
import 'package:merchant/screens/profile_sections/preferences_screen.dart';
import 'package:merchant/screens/profile_sections/purchase_history_screen.dart';
import 'package:merchant/screens/profile_sections/security_screen.dart';

class ProfileScreen extends StatefulWidget {
  final User user;
  final Function(User) onUserUpdate;

  const ProfileScreen({super.key, required this.user, required this.onUserUpdate});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _notificationsEnabled = true;
  bool _offersEnabled = true;

Future<void> _reloadUser() async {
  final response = await http.get(Uri.parse('$baseUrl/get_merchant.php?id=${widget.user.id}'));
  if (response.statusCode == 200) {
    final data = jsonDecode(response.body);
    if (data['success'] == true && data['merchant'] != null) {
      setState(() {
        widget.onUserUpdate(User.fromJson(data['merchant']));
      });
    }
  }
}
@override
void initState() {
  super.initState();
  _reloadUser();
}
String _formatMemberSince(String dateString) {
  print('memberSince reçu: $dateString');
  if (dateString.isEmpty) return '';
  final date = DateTime.tryParse(dateString);
  if (date == null) return dateString;
  const months = [
    'janvier', 'février', 'mars', 'avril', 'mai', 'juin',
    'juillet', 'août', 'septembre', 'octobre', 'novembre', 'décembre'
  ];
  return '${date.day} ${months[date.month - 1]} ${date.year}';
}
  @override
  Widget build(BuildContext context) {
                                                    String formatted = _formatMemberSince(widget.user.memberSince);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              // Profile Header
              Container(
                margin: const EdgeInsets.all(20),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF3B82F6), Color(0xFF8B5CF6)],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF3B82F6).withOpacity(0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: const Icon(
                        Icons.person,
                        size: 40,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Text(
                          //   formatted.isEmpty ? 'Date inconnue' : 'Membre depuis $formatted',
                          //   style: const TextStyle(
                          //     fontSize: 12,
                          //     fontFamily: "r",
                          //     color: Colors.white70,
                          //   ),
                          // ),
                          Text(
                            '${widget.user.firstName} ${widget.user.lastName}',
                            style: const TextStyle(
                              fontSize: 20,
                      fontFamily: "b",
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            widget.user.email,
                            style: const TextStyle(
                              fontSize: 14,
                      fontFamily: "r",
                              color: Colors.white70,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                              'Membre depuis ${_formatMemberSince(widget.user.memberSince)}',
                                style: const TextStyle(
                                  fontSize: 12,
                      fontFamily: "r",
                                  color: Colors.white70,
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.star,
                                      size: 16,
                                      color: _getTierColor(widget.user.tier),
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      widget.user.tier,
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color: _getTierColor(widget.user.tier),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => _navigateToEditProfile(),
                      icon: const Icon(Icons.edit, color: Colors.white),
                    ),
                  ],
                ),
              ),

              // Stats Cards
              // Padding(
              //   padding: const EdgeInsets.symmetric(horizontal: 20.0),
              //   child: Row(
              //     children: [
              //       Expanded(
              //         child: _buildStatCard(
              //           icon: Icons.star,
              //           value: widget.user.points.toString(),
              //           label: 'Points',
              //           color: const Color(0xFFF59E0B),
              //         ),
              //       ),
              //       const SizedBox(width: 12),
              //       Expanded(
              //         child: _buildStatCard(
              //           icon: Icons.trending_up,
              //           value: '1250.50€',
              //           label: 'Dépensé',
              //           color: const Color(0xFF10B981),
              //         ),
              //       ),
              //       const SizedBox(width: 12),
              //       Expanded(
              //         child: _buildStatCard(
              //           icon: Icons.card_giftcard,
              //           value: '8',
              //           label: 'Récompenses',
              //           color: const Color(0xFF8B5CF6),
              //         ),
              //       ),
              //     ],
              //   ),
              // ),

              // const SizedBox(height: 22),

              // Settings Section
              _buildSection(
                title: 'Paramètres',
                children: [
                  _buildSettingItem(
                    icon: Icons.notifications,
                    title: 'Notifications',
                    trailing: Switch(
                      value: _notificationsEnabled,
                      onChanged: (value) {
                        setState(() {
                          _notificationsEnabled = value;
                        });
                      },
                      activeColor: const Color(0xFF3B82F6),
                    ),
                  ),
                  _buildSettingItem(
                    icon: Icons.local_offer,
                    title: 'Offres personnalisées',
                    trailing: Switch(
                      value: _offersEnabled,
                      onChanged: (value) {
                        setState(() {
                          _offersEnabled = value;
                        });
                      },
                      activeColor: const Color(0xFF8B5CF6),
                    ),
                  ),
                ],
              ),

              // Account Section
              _buildSection(
                title: 'Mon compte',
                children: [
                  _buildMenuItem(
                    icon: Icons.person,
                    title: 'Informations personnelles',
                    onTap: () => _navigateToEditProfile(),
                  ),
                  // _buildMenuItem(
                  //   icon: Icons.settings,
                  //   title: 'Préférences',
                  //   onTap: () => _navigateToPreferences(),
                  // ),
                                    _buildMenuItem(
                    icon: Icons.message,
                    title: 'Message personnalisé client',
                    onTap: _showCustomMessageDialog,
                  ),
                  _buildMenuItem(
                    icon: Icons.security,
                    title: 'Sécurité et confidentialité',
                    onTap: () => _navigateToSecurity(),
                  ),
                 
                ],
              ),

              // Logout Section
              Padding(
                padding: const EdgeInsets.all(20.0),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _handleLogout,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: const Color(0xFFEF4444),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 3,
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.logout, size: 20),
                        SizedBox(width: 8),
                        Text(
                          'Se déconnecter',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
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

  Widget _buildStatCard({
    required IconData icon,
    required String value,
    required String label,
    required Color color,
  }) {
    return Container(
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
      child: Column(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFFF0F9FF),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 20, color: color),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 13,
                      fontFamily: "b",
              fontWeight: FontWeight.bold,
              color: Color(0xFF1F2937),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
                      fontFamily: "r",
              fontSize: 11,
              color: Color(0xFF6B7280),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection({required String title, required List<Widget> children}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
                      fontFamily: "b",
              color: Color(0xFF1F2937),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 20),
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
          child: Column(children: children),
        ),
        const SizedBox(height: 32),
      ],
    );
  }

  Widget _buildSettingItem({
    required IconData icon,
    required String title,
    required Widget trailing,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF3B82F6)),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 14,
                      fontFamily: "r",
                color: Color(0xFF1F2937),
              ),
            ),
          ),
          trailing,
        ],
      ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: const Color(0xFF6B7280)),
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 14,
                      fontFamily: "r",
          color: Color(0xFF1F2937),
        ),
      ),
      trailing: const Icon(Icons.chevron_right, color: Color(0xFF9CA3AF)),
      onTap: onTap,
    );
  }

  Color _getTierColor(String tier) {
    switch (tier) {
      case 'Bronze': return const Color.fromARGB(255, 255, 237, 219);
      case 'Silver': return const Color(0xFFC0C0C0);
      case 'Gold': return const Color(0xFFFFD700);
      default: return const Color(0xFF3B82F6);
    }
  }

  void _navigateToEditProfile() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditProfileScreen(
          user: widget.user,
          onUserUpdate: widget.onUserUpdate,
        ),
      ),
    );
  }

  void _navigateToPreferences() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const PreferencesScreen(),
      ),
    );
  }

  void _navigateToSecurity() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>  SecurityScreen(user: widget.user,),
      ),
    );
  }
void _showCustomMessageDialog() async {
  final controller = TextEditingController();
  String? currentMsg;

  // Récupère le message actuel
  final resp = await http.get(Uri.parse('$baseUrl/get_custom_message.php?id=${widget.user.id}'));
  if (resp.statusCode == 200) {
    final data = jsonDecode(resp.body);
    if (data['success'] == true) {
      currentMsg = data['custom_message'] ?? '';
      controller.text = currentMsg ?? '';
    }
  }

  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text('Message personnalisé',style: TextStyle(fontFamily: "b"),),
      content: TextField(
        style: TextStyle(fontFamily: "r"),
        controller: controller,
        maxLines: 4,
        decoration: const InputDecoration(
          hintText: "Ex: On ne peut scanner ton QR code que si ton achat dépasse 5000 FCFA",
          border: OutlineInputBorder(),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Annuler',style: TextStyle(fontFamily: "b"),),
        ),
        ElevatedButton(
          onPressed: () async {
            final msg = controller.text.trim();
            final res = await http.post(
              Uri.parse('$baseUrl/update_custom_message.php'),
              body: {
                'id': widget.user.id.toString(),
                'custom_message': msg,
              },
            );
            Navigator.pop(context);
            if (res.statusCode == 200 && jsonDecode(res.body)['success'] == true) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Message enregistré'), backgroundColor: Color(0xFF10B981)),
              );
              setState(() {}); // Pour rafraîchir l'affichage si besoin
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Erreur lors de la sauvegarde'), backgroundColor: Colors.red),
              );
            }
          },
          child: const Text('Enregistrer',style: TextStyle(fontFamily: "b"),),
        ),
      ],
    ),
  );
}
  void _navigateToPurchaseHistory() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PurchaseHistoryScreen(user: widget.user),
      ),
    );
  }

  void _navigateToBonusHistory() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BonusHistoryScreen(user: widget.user),
      ),
    );
  }

  void _handleLogout() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Déconnexion'),
        content: const Text('Êtes-vous sûr de vouloir vous déconnecter ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () async {
              await AuthService.logout();
              Navigator.pop(context);
              // Navigate back to auth screen - this would be handled by the main app
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              foregroundColor: Colors.white,
            ),
            child: const Text('Déconnecter'),
          ),
        ],
      ),
    );
  }
}