import 'package:flutter/material.dart';
import 'package:merchant/models/user_model.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:merchant/const.dart';

class HistoryScreen extends StatefulWidget {
  final User user;

  const HistoryScreen({super.key, required this.user});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> with WidgetsBindingObserver {
  String _selectedPeriod = 'Tous';
  String _selectedStore = 'Toutes';
  String _searchQuery = '';

  final List<String> _periods = ['Tous', 'Cette semaine', 'Ce mois', 'Cette année'];

  List<dynamic> _notifications = [];
  bool _loading = true;
  bool _firstLoad = true;

  Future<void> _deleteNotification(dynamic notif) async {
    final notifId = notif['id'];
    if (notifId == null) return;
    final response = await http.post(
      Uri.parse('$baseUrl/merchant_notifications.php'),
      body: {
        'action': 'delete',
        'id': notifId.toString(),
      },
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data['success'] == true) {
        setState(() {
          _notifications.removeWhere((n) => n['id'] == notifId);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Notification supprimée'), backgroundColor: Color(0xFF10B981)),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(data['error'] ?? 'Erreur lors de la suppression'), backgroundColor: Colors.red),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Erreur réseau'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    fetchNotifications();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      fetchNotifications();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_firstLoad) {
      _firstLoad = false;
      return;
    }
    fetchNotifications();
  }

  Future<void> fetchNotifications() async {
    setState(() {
      _loading = true;
    });
    final response = await http.get(
      Uri.parse('$baseUrl/merchant_notifications.php?action=get&merchant_id=${widget.user.id}'),
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data['success'] == true && data['notifications'] != null) {
        setState(() {
          _notifications = data['notifications'];
          _loading = false;
        });
      } else {
        setState(() {
          _loading = false;
        });
      }
    } else {
      setState(() {
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Filtrage dynamique par nom du client (dans le message)
    final filteredNotifications = _searchQuery.trim().isEmpty
        ? _notifications
        : _notifications.where((notif) {
            final message = (notif['message'] ?? '').toLowerCase();
            return message.contains(_searchQuery.toLowerCase());
          }).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Historique',
                    style: TextStyle(
                      fontFamily: "b",
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1F2937),
                    ),
                  ),
                  IconButton(
                    onPressed: fetchNotifications,
                    icon: const Icon(Icons.refresh, color: Color(0xFF3B82F6)),
                  ),
                ],
              ),
            ),
            // Zone de recherche
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.07),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    const Icon(Icons.search, color: Color(0xFF9CA3AF)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        onChanged: (value) {
                          setState(() {
                            _searchQuery = value;
                          });
                        },
                        decoration: const InputDecoration(
                          hintText: 'Rechercher un client',
                          border: InputBorder.none,
                          hintStyle: TextStyle(
                            color: Color(0xFF9CA3AF),
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            // Period filter
            SizedBox(
              height: 40,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: _periods.length,
                itemBuilder: (context, index) {
                  final period = _periods[index];
                  final isSelected = _selectedPeriod == period;
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedPeriod = period;
                      });
                    },
                    child: Container(
                      margin: const EdgeInsets.only(right: 12, bottom: 3),
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                      decoration: BoxDecoration(
                        color: isSelected ? const Color(0xFF3B82F6) : Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.07),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          period,
                          style: TextStyle(
                            fontFamily: "r",
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: isSelected ? Colors.white : const Color(0xFF6B7280),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 18),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 23),
              child: Text(
                            "Glissez une notification vers la gauche pour la supprimer.",
                            style: TextStyle(
                              fontFamily: "r",
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color:  const Color(0xFF6B7280),
                            ),
                          ),
            ),
            // Historique des notifications (points octroyés)
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : filteredNotifications.isEmpty
                      ? const Center(
                          child: Text(
                            "Aucune notification trouvée.",
                            style: TextStyle(fontSize: 15, color: Color(0xFF6B7280)),
                          ),
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          itemCount: filteredNotifications.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 12),
                          itemBuilder: (context, index) {
                            final notif = filteredNotifications[index];
                            final type = notif['type'] ?? 'info';
                            final iconData = type == 'success'
                                ? Icons.check_circle
                                : type == 'info'
                                    ? Icons.info
                                    : Icons.notifications;
                            final iconColor = type == 'success'
                                ? const Color(0xFF10B981)
                                : type == 'info'
                                    ? const Color(0xFF3B82F6)
                                    : const Color(0xFFF59E0B);

                            return Dismissible(
                              key: ValueKey(notif['id']),
                              direction: DismissDirection.endToStart,
                              background: Container(
                                alignment: Alignment.centerRight,
                                padding: const EdgeInsets.symmetric(horizontal: 24),
                                color: Colors.red,
                                child: const Icon(Icons.delete, color: Colors.white, size: 28),
                              ),
                              confirmDismiss: (direction) async {
                                return await showDialog(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    backgroundColor: Colors.white,
                                    title: const Text('Supprimer la notification',style :TextStyle(fontFamily: "b",fontSize: 16)),
                                    content: const Text('Voulez-vous vraiment supprimer cette notification ?',style :TextStyle(fontFamily: "r")),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.of(context).pop(false),
                                        child: const Text('Annuler',style :TextStyle(fontFamily: "r")),
                                      ),
                                      TextButton(
                                        onPressed: () => Navigator.of(context).pop(true),
                                        child: const Text('Supprimer', style: TextStyle(color: Colors.red,fontFamily: "r") ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                              onDismissed: (_) => _deleteNotification(notif),
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.06),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      decoration: BoxDecoration(
                                        color: iconColor.withOpacity(0.12),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      padding: const EdgeInsets.all(10),
                                      child: Icon(iconData, color: iconColor, size: 26),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Expanded(
                                                child: Text(
                                                  notif['title'] ?? '',
                                                  style: const TextStyle(
                                                    fontFamily: "b",
                                                    fontSize: 16,
                                                    fontWeight: FontWeight.bold,
                                                    color: Color(0xFF1F2937),
                                                  ),
                                                ),
                                              ),
                                              Text(
                                                _formatDate(notif['created_at'] ?? ''),
                                                style: const TextStyle(
                                                  fontSize: 12,
                                                  color: Color(0xFF9CA3AF),
                                                  fontFamily: "r",
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 6),
                                          Text(
                                            notif['message'] ?? '',
                                            style: const TextStyle(
                                              fontFamily: "r",
                                              fontSize: 14,
                                              color: Color(0xFF374151),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(String dateString) {
    if (dateString.isEmpty) return '';
    final date = DateTime.tryParse(dateString);
    if (date == null) return dateString;
    final months = [
      'janvier', 'février', 'mars', 'avril', 'mai', 'juin',
      'juillet', 'août', 'septembre', 'octobre', 'novembre', 'décembre'
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }
}