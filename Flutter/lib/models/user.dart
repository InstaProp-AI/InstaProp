enum AccountType { user, developer }

class Account {
  final int accountId;
  final String firstName;
  final String lastName;
  final String phoneNumber;
  final String email;
  final AccountType type;
  final bool isVerified;
  final DateTime createdAt;
  final DateTime? updatedAt;

  Account({
    required this.accountId,
    required this.firstName,
    required this.lastName,
    required this.phoneNumber,
    required this.email,
    required this.type,
    required this.isVerified,
    required this.createdAt,
    this.updatedAt,
  });

  factory Account.fromJson(Map<String, dynamic> json) {
    return Account(
      accountId: json['accountId'] ?? json['AccountId'] ?? 0,
      firstName: json['firstName'] ?? json['FirstName'] ?? '',
      lastName: json['lastName'] ?? json['LastName'] ?? '',
      phoneNumber: json['phoneNumber'] ?? json['PhoneNumber'] ?? '',
      email: json['email'] ?? json['Email'] ?? '',
      type: AccountType.values.firstWhere(
        (e) =>
            e.toString().split('.').last ==
            (json['type'] ?? json['Type'] ?? 'user'),
        orElse: () => AccountType.user,
      ),
      isVerified: json['isVerified'] ?? json['IsVerified'] ?? false,
      createdAt: DateTime.parse(
        json['createdAt'] ??
            json['CreatedAt'] ??
            DateTime.now().toIso8601String(),
      ),
      updatedAt: json['updatedAt'] != null || json['UpdatedAt'] != null
          ? DateTime.parse(json['updatedAt'] ?? json['UpdatedAt'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'accountId': accountId,
      'firstName': firstName,
      'lastName': lastName,
      'phoneNumber': phoneNumber,
      'email': email,
      'type': type.toString().split('.').last,
      'isVerified': isVerified,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  String get fullName => '$firstName $lastName';
}
