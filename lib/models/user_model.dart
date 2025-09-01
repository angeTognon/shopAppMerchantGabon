class User {
  final String id;
  final String email;
  final String firstName;
  final String lastName;
  final String? phone;
  final int points;
  final String tier;
  final String memberSince;
  final String storeName;
  final List<Map<String, dynamic>> rewards; // <-- Ajoute cette ligne

  User({
    required this.id,
    required this.email,
    required this.firstName,
    required this.lastName,
    this.phone,
    required this.points,
    required this.tier,
    required this.memberSince,
    required this.storeName,
    required this.rewards, // <-- Ajoute ici aussi
  });

    factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'].toString(),
      email: json['email'] ?? '',
      firstName: json['firstName'] ?? json['first_name'] ?? '',
      lastName: json['lastName'] ?? json['last_name'] ?? '',
      phone: json['phone'],
      points: json['points'] is int ? json['points'] : int.tryParse(json['points'].toString()) ?? 0,
      tier: json['tier'] ?? '',
      memberSince: json['memberSince'] ?? json['member_since'] ?? '',
      storeName: json['storeName'] ?? json['store_name'] ?? '',
            rewards: (json['rewards'] is List)
          ? (json['rewards'] as List)
              .where((e) => e != null)
              .map((e) => Map<String, dynamic>.from(e as Map))
              .toList()
          : <Map<String, dynamic>>[],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'firstName': firstName,
      'lastName': lastName,
      'phone': phone,
      'points': points,
      'tier': tier,
      'memberSince': memberSince,
      'storeName': storeName,
      'rewards': rewards, // <-- Ajoute ici aussi
    };
  }

  User copyWith({
    String? id,
    String? email,
    String? firstName,
    String? lastName,
    String? phone,
    int? points,
    String? tier,
    String? memberSince,
    String? storeName,
    List<Map<String, dynamic>>? rewards, // <-- Ajoute ici aussi
  }) {
    return User(
      id: id ?? this.id,
      email: email ?? this.email,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      phone: phone ?? this.phone,
      points: points ?? this.points,
      tier: tier ?? this.tier,
      memberSince: memberSince ?? this.memberSince,
      storeName: storeName ?? this.storeName,
      rewards: rewards ?? this.rewards, // <-- Ajoute ici aussi
    );
  }
}
class Purchase {
  final int id;
  final String date;
  final double amount;
  final int points;
  final String store;
  final List<String> items;
  final String status;

  Purchase({
    required this.id,
    required this.date,
    required this.amount,
    required this.points,
    required this.store,
    required this.items,
    required this.status,
  });
}

class Reward {
  final int id;
  final String title;
  final String description;
  final int points;
  final String category;
  final bool available;
  final String iconName;
  final String color;
  final String store; // <-- Ajoute ceci

  Reward({
    required this.id,
    required this.title,
    required this.description,
    required this.points,
    required this.category,
    required this.available,
    required this.iconName,
    required this.color,
    required this.store, // <-- Et ici
  });
    factory Reward.fromJson(Map<String, dynamic> json) {
    return Reward(
      id: json['id'],
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      points: json['points'] ?? 0,
      category: json['category'] ?? '',
      available: json['available'] ?? false,
      iconName: json['iconName'] ?? 'card_giftcard',
      color: json['color'] ?? '0xFF3B82F6',
      store: json['store'] ?? '',
    );
  }
}

class Bonus {
  final int id;
  final String title;
  final String description;
  final int points;
  final String dateEarned;
  final String type;
  final String iconName;
  final String color;

  Bonus({
    required this.id,
    required this.title,
    required this.description,
    required this.points,
    required this.dateEarned,
    required this.type,
    required this.iconName,
    required this.color,
  });
}