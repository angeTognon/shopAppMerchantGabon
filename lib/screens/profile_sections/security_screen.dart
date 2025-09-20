import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:merchant/const.dart';
import '../../models/user_model.dart';

class SecurityScreen extends StatefulWidget {
  final User user;
  const SecurityScreen({super.key, required this.user});

  @override
  State<SecurityScreen> createState() => _SecurityScreenState();
}

class _SecurityScreenState extends State<SecurityScreen> {
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _showCurrentPassword = false;
  bool _showNewPassword = false;
  bool _showConfirmPassword = false;
  bool _twoFactorEnabled = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _fetch2FA();
  }

  Future<void> _fetch2FA() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/get_2fa.php?merchant_id=${widget.user.id}'));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          setState(() {
            _twoFactorEnabled = data['enabled'] ?? false;
          });
        }
      }
    } catch (_) {}
  }

  Future<void> _handleChangePassword() async {
    if (_currentPasswordController.text.isEmpty ||
        _newPasswordController.text.isEmpty ||
        _confirmPasswordController.text.isEmpty) {
      _showError('Veuillez remplir tous les champs');
      return;
    }
    if (_newPasswordController.text != _confirmPasswordController.text) {
      _showError('Les nouveaux mots de passe ne correspondent pas');
      return;
    }
    if (_newPasswordController.text.length < 6) {
      _showError('Le nouveau mot de passe doit contenir au moins 6 caractères');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/change_password.php'),
        body: {
          'merchant_id': widget.user.id.toString(),
          'current_password': _currentPasswordController.text,
          'new_password': _newPasswordController.text,
        },
      );
      final data = jsonDecode(response.body);
      setState(() => _isLoading = false);

      if (response.statusCode == 200 && data['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Mot de passe modifié avec succès'),
            backgroundColor: Color(0xFF10B981),
          ),
        );
        _currentPasswordController.clear();
        _newPasswordController.clear();
        _confirmPasswordController.clear();
      } else {
        _showError(data['error'] ?? 'Erreur lors du changement');
      }
    } catch (e) {
      setState(() => _isLoading = false);
      _showError('Erreur réseau');
    }
  }

  Future<void> _handle2FAToggle(bool value) async {
    setState(() => _twoFactorEnabled = value);
    try {
      await http.post(
        Uri.parse('$baseUrl/update_2fa.php'),
        body: {
          'merchant_id': widget.user.id.toString(),
          'enabled': value ? '1' : '0',
        },
      );
    } catch (_) {}
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: const Color(0xFFEF4444),
      ),
    );
  }

  void _showInfoDialog(String title, String content) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontFamily: "b")),
        content: SingleChildScrollView(child: Text(content, style: const TextStyle(fontSize: 14))),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fermer'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back, color: Color(0xFF1F2937)),
        ),
        title: const Text(
          'Sécurité',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            fontFamily: "b",
            color: Color(0xFF1F2937),
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Change Password Section
            _buildSection(
              title: 'Changer le mot de passe',
              child: Column(
                children: [
                  _buildPasswordField(
                    label: 'Mot de passe actuel',
                    controller: _currentPasswordController,
                    showPassword: _showCurrentPassword,
                    onToggleVisibility: () {
                      setState(() {
                        _showCurrentPassword = !_showCurrentPassword;
                      });
                    },
                  ),
                  _buildPasswordField(
                    label: 'Nouveau mot de passe',
                    controller: _newPasswordController,
                    showPassword: _showNewPassword,
                    onToggleVisibility: () {
                      setState(() {
                        _showNewPassword = !_showNewPassword;
                      });
                    },
                  ),
                  _buildPasswordField(
                    label: 'Confirmer le nouveau mot de passe',
                    controller: _confirmPasswordController,
                    showPassword: _showConfirmPassword,
                    onToggleVisibility: () {
                      setState(() {
                        _showConfirmPassword = !_showConfirmPassword;
                      });
                    },
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _handleChangePassword,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF3B82F6),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : const Text(
                              'Changer le mot de passe',
                              style: TextStyle(
                                fontSize: 13,
                                fontFamily: "b",
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            // Two Factor Authentication
            _buildSection(
              title: 'Authentification à deux facteurs',
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: const Color(0xFFDCFCE7),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.security,
                      size: 24,
                      color: Color(0xFF10B981),
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Authentification 2FA',
                          style: TextStyle(
                            fontFamily: "b",
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF1F2937),
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Ajoutez une couche de sécurité supplémentaire à votre compte',
                          style: TextStyle(
                            fontSize: 13,
                            fontFamily: "r",
                            color: Color(0xFF6B7280),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Switch(
                    value: _twoFactorEnabled,
                    onChanged: _handle2FAToggle,
                    activeColor: const Color(0xFF10B981),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            // Privacy Section
            _buildSection(
              title: 'Confidentialité',
              child: Column(
                children: [
                  _buildPrivacyItem(
                    'Politique de confidentialité',
                    onTap: () => _showInfoDialog(
                      'Politique de confidentialité',
                      '''Nous nous engageons à protéger vos données personnelles. Toutes les informations collectées sont utilisées uniquement pour améliorer votre expérience et ne sont jamais partagées sans votre consentement. Vous pouvez à tout moment demander la suppression ou la modification de vos données en nous contactant.''',
                    ),
                  ),
                  _buildPrivacyItem(
                    'Conditions d\'utilisation',
                    onTap: () => _showInfoDialog(
                      'Conditions d\'utilisation',
                      '''En utilisant notre application, vous acceptez de respecter les règles de bonne conduite et d’utiliser les services conformément à la législation en vigueur. Toute utilisation abusive ou frauduleuse entraînera la suspension de votre compte. Pour plus de détails, consultez notre site web.''',
                    ),
                  ),
                  _buildPrivacyItem(
                    'Gestion des données personnelles',
                    onTap: () => _showInfoDialog(
                      'Gestion des données personnelles',
                      '''Vous disposez d’un droit d’accès, de rectification et de suppression de vos données personnelles. Nous appliquons des mesures de sécurité strictes pour garantir la confidentialité de vos informations. Pour toute demande relative à vos données, contactez notre support.''',
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection({required String title, required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              fontFamily: "b",
              color: Color(0xFF1F2937),
            ),
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }

  Widget _buildPasswordField({
    required String label,
    required TextEditingController controller,
    required bool showPassword,
    required VoidCallback onToggleVisibility,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            fontFamily: "r",
            fontWeight: FontWeight.w600,
            color: Color(0xFF374151),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE5E7EB)),
          ),
          child: TextField(
            controller: controller,
            style: const TextStyle(
              fontFamily: "r",
              fontSize: 13,
            ),
            obscureText: !showPassword,
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.lock, color: Color(0xFF9CA3AF)),
              suffixIcon: IconButton(
                onPressed: onToggleVisibility,
                icon: Icon(
                  showPassword ? Icons.visibility_off : Icons.visibility,
                  color: const Color(0xFF9CA3AF),
                ),
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              hintText: label,
              hintStyle: const TextStyle(color: Color(0xFF9CA3AF)),
            ),
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildPrivacyItem(String title, {VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: const BoxDecoration(
          border: Border(
            bottom: BorderSide(color: Color(0xFFF3F4F6)),
          ),
        ),
        child: Text(
          title,
          style: const TextStyle(
            fontSize: 13,
            fontFamily: "r",
            color: Color(0xFF3B82F6),
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }
}