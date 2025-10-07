enum AccountType { user, developer, admin }

class KycDocument {
  final String docType;
  final String imageUrl;
  final DateTime uploadedAt;

  KycDocument({
    required this.docType,
    required this.imageUrl,
    required this.uploadedAt,
  });

  factory KycDocument.fromJson(Map<String, dynamic> json) {
    return KycDocument(
      docType: json['docType'] ?? json['DocType'] ?? '',
      imageUrl: json['imageUrl'] ?? json['ImgUrl'] ?? '',
      uploadedAt: DateTime.parse(
        json['uploadedAt'] ??
            json['UploadedAt'] ??
            DateTime.now().toIso8601String(),
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'docType': docType,
      'imageUrl': imageUrl,
      'uploadedAt': uploadedAt.toIso8601String(),
    };
  }
}

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
  final List<KycDocument> kycDocuments;

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
    this.kycDocuments = const [],
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
            e.toString().split('.').last.toLowerCase() ==
            (json['type'] ?? json['Type'] ?? 'user').toString().toLowerCase(),
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
      kycDocuments: json['userDocs'] != null || json['UserDocs'] != null
          ? (json['userDocs'] ?? json['UserDocs'] ?? [])
                .map<KycDocument>((doc) => KycDocument.fromJson(doc))
                .toList()
          : [],
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
      'kycDocuments': kycDocuments.map((doc) => doc.toJson()).toList(),
    };
  }

  String get fullName => '$firstName $lastName';
}
