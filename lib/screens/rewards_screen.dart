import 'package:flutter/material.dart';
import 'package:merchant/const.dart';
import 'package:merchant/models/user_model.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'dart:async';

class RewardsScreen extends StatefulWidget {
  final User user;
  final List<String> rewardLevels;

  const RewardsScreen({
    super.key,
    required this.user,
    required this.rewardLevels,
  });

  @override
  State<RewardsScreen> createState() => _RewardsScreenState();
}

class _RewardsScreenState extends State<RewardsScreen> with WidgetsBindingObserver {
  String _searchQuery = '';
  String _selectedStatus = 'Tous';
  late List<String> _rewardLevels;
  List<Map<String, dynamic>> _allClients = [];
  bool _loading = true;
  bool _firstLoad = true;
  Timer? _refreshTimer;


  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _rewardLevels = widget.rewardLevels;
    _refreshClients();
    _refreshTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      _refreshClients();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _refreshTimer?.cancel();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_firstLoad) {
      _firstLoad = false;
      return;
    }
    _refreshClients();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _refreshClients();
    }
  }

  void _refreshClients() {
    setState(() {
      _loading = true;
    });
    fetchRewardedClients().then((clients) {
      setState(() {
        _allClients = clients;
        _loading = false;
      });
    });
  }

  Future<List<Map<String, dynamic>>> fetchRewardedClients() async {
    final response = await http.get(
      Uri.parse('$baseUrl/rewarded_clients.php?merchant_id=${widget.user.id}'),
      headers: {'Content-Type': 'application/json'},
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data['success'] == true && data['clients'] != null) {
        return List<Map<String, dynamic>>.from(data['clients']);
      }
    }
    return [];
  }

  Future<void> _updateRewardStatus(
    Map<String, dynamic> client,
    String status,
  ) async {
    final response = await http.post(
      Uri.parse('$baseUrl/update_reward_status.php'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'client_id': client['id'],
        'merchant_id': widget.user.id,
        'reward_label': client['reward'],
        'status': status,
      }),
    );
    if (response.statusCode == 200) {
      _refreshClients();
    }
  }

  Widget _buildStatusFilter(String label, Color color) {
    final isSelected = _selectedStatus == label;
    String display;
    switch (label) {
      case 'en_attente':
        display = 'En attente';
        break;
      case 'octroyee':
        display = 'Octroyée';
        break;
      case 'refusee':
        display = 'Refusée';
        break;
      default:
        display = 'Tous';
    }
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedStatus = label;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        margin: const EdgeInsets.only(right: 8),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.15) : Colors.white,
          border: Border.all(color: color.withOpacity(isSelected ? 0.7 : 0.3)),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          display,
          style: TextStyle(
            color: color,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filteredClients = _searchQuery.trim().isEmpty
        ? _allClients
        : _allClients.where((client) {
            final name = "${client['first_name']} ${client['last_name']}".toLowerCase();
            return name.contains(_searchQuery.toLowerCase());
          }).toList();

    final filteredAndStatusClients = _selectedStatus == 'Tous'
        ? filteredClients
        : filteredClients.where((client) => (client['reward_status'] ?? '') == _selectedStatus).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child:
             Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 20,
                    ),
                    child: Text(
                      "Clients récompensés",
                      style: TextStyle(
                        fontSize: 18,
                        fontFamily: "b",
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1F2937),
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20.0),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 2,
                      ),
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
                  const SizedBox(height: 15),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20.0),
                    child: Center(
                      child: Wrap(
                        runSpacing: 8.0,
                        spacing: 8.0,
                        children: [
                          _buildStatusFilter('Tous', Colors.blue),
                          _buildStatusFilter('en_attente', Colors.orange),
                          _buildStatusFilter('octroyee', Colors.green),
                          // _buildStatusFilter('refusee', Colors.red),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 15),
                  Expanded(
                    child: filteredAndStatusClients.isEmpty
                        ? const Center(
                            child: Text(
                              "Aucun client n'a encore obtenu de récompense.",
                              style: TextStyle(fontSize: 15, color: Color(0xFF6B7280)),
                            ),
                          )
                        : ListView.separated(
                            itemCount: filteredAndStatusClients.length,
                            separatorBuilder: (_, __) => const SizedBox(height: 10),
                            itemBuilder: (context, index) {
                              final client = filteredAndStatusClients[index];
                              final rewardLabel = (client['reward'] ?? '').toString();
                              final levelColor = rewardLabel.isNotEmpty
                                  ? const Color(0xFF10B981)
                                  : const Color(0xFF6B7280);
                              final status = (client['reward_status'] ?? '').toString();

                              return Container(
                                margin: const EdgeInsets.symmetric(horizontal: 20),
                                padding: const EdgeInsets.all(18),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(18),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.07),
                                      blurRadius: 12,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                  border: Border.all(
                                    color: rewardLabel.isNotEmpty
                                        ? const Color(0xFF10B981).withOpacity(0.2)
                                        : const Color(0xFFE5E7EB),
                                    width: 1.2,
                                  ),
                                ),
                                child: Column(
                                  children: [
                                    Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        CircleAvatar(
                                          radius: 26,
                                          backgroundColor: rewardLabel.isNotEmpty
                                              ? const Color(0xFF10B981).withOpacity(0.15)
                                              : const Color(0xFF6B7280).withOpacity(0.10),
                                          child: Icon(
                                            rewardLabel.isNotEmpty ? Icons.emoji_events : Icons.person,
                                            color: rewardLabel.isNotEmpty
                                                ? const Color(0xFF10B981)
                                                : const Color(0xFF6B7280),
                                            size: 28,
                                          ),
                                        ),
                                        const SizedBox(width: 18),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Flexible(
                                                    child: Text(
                                                      "${client['first_name']} ${client['last_name']}",
                                                      style: const TextStyle(
                                                        fontSize: 16,
                                                        fontFamily: "b",
                                                        fontWeight: FontWeight.bold,
                                                        color: Color(0xFF1F2937),
                                                      ),
                                                      maxLines: 2,
                                                      softWrap: true,
                                                      overflow: TextOverflow.visible,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(height: 4),
                                              Row(
                                                children: [
                                                  const Icon(
                                                    Icons.star,
                                                    size: 16,
                                                    color: Color(0xFFF59E0B),
                                                  ),
                                                  const SizedBox(width: 4),
                                                  Text(
                                                    "${client['points']} points",
                                                    style: const TextStyle(
                                                      fontSize: 13,
                                                      fontFamily: "b",
                                                      color: Color(0xFFF59E0B),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              if (rewardLabel.isNotEmpty)
                                                Padding(
                                                  padding: const EdgeInsets.only(
                                                    top: 6.0,
                                                  ),
                                                  child: Row(
                                                    children: [
                                                      Icon(
                                                        Icons.card_giftcard,
                                                        color: levelColor,
                                                        size: 18,
                                                      ),
                                                      const SizedBox(width: 6),
                                                      Flexible(
                                                        child: Text(
                                                          "Récompense : $rewardLabel",
                                                          style: TextStyle(
                                                            fontSize: 14,
                                                            fontFamily: "b",
                                                            color: levelColor,
                                                            fontWeight: FontWeight.w600,
                                                          ),
                                                          overflow: TextOverflow.ellipsis,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                    if (status != 'octroyee')
                                      Padding(
                                        padding: const EdgeInsets.only(top: 12.0),
                                        child: SizedBox(
                                          width: double.infinity,
                                          child: ElevatedButton.icon(
                                            icon: const Icon(
                                              Icons.check_circle,
                                              color: Colors.white,
                                              size: 20,
                                            ),
                                            label: const Text(
                                              "Confirmer l'encaissement",
                                              style: TextStyle(
                                                fontFamily: "b",
                                                fontWeight: FontWeight.w600,
                                                fontSize: 14,
                                              ),
                                            ),
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: const Color(0xFF10B981),
                                              foregroundColor: Colors.white,
                                              padding: const EdgeInsets.symmetric(vertical: 12),
                                              shape: RoundedRectangleBorder(
                                                borderRadius: BorderRadius.circular(8),
                                              ),
                                            ),
                                            onPressed: () => _updateRewardStatus(client, 'octroyee'),
                                          ),
                                        ),
                                      )
                                    else
                                      Padding(
                                        padding: const EdgeInsets.only(top: 12.0),
                                        child: SizedBox(
                                          width: double.infinity,
                                          child: ElevatedButton.icon(
                                            icon: const Icon(
                                              Icons.check_circle,
                                              color: Colors.white,
                                              size: 20,
                                            ),
                                            label: const Text(
                                              "Déjà encaissée",
                                              style: TextStyle(
                                                fontFamily: "b",
                                                fontWeight: FontWeight.w600,
                                                fontSize: 14,
                                              ),
                                            ),
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: Colors.grey,
                                              foregroundColor: Colors.white,
                                              padding: const EdgeInsets.symmetric(vertical: 12),
                                              shape: RoundedRectangleBorder(
                                                borderRadius: BorderRadius.circular(8),
                                              ),
                                            ),
                                            onPressed: null,
                                          ),
                                        ),
                                      ),
                                  ],
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
}