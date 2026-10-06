class UserProfile {
  final String id;
  final String name;
  final String email;
  final String? avatarUrl;
  final bool isGuest;
  final bool hideBalance;
  final String? pinCode;
  final bool hasCompletedOnboarding;
  final bool hasCompletedSetup;
  final bool isLoggedIn;
  final bool isAdmin;

  UserProfile({
    required this.id,
    required this.name,
    required this.email,
    this.avatarUrl,
    this.isGuest = false,
    this.hideBalance = true, // Default hidden as per fintech spec
    this.pinCode,
    this.hasCompletedOnboarding = false,
    this.hasCompletedSetup = false,
    this.isLoggedIn = false,
    this.isAdmin = false,
  });

  UserProfile copyWith({
    String? id,
    String? name,
    String? email,
    String? avatarUrl,
    bool? isGuest,
    bool? hideBalance,
    String? pinCode,
    bool? hasCompletedOnboarding,
    bool? hasCompletedSetup,
    bool? isLoggedIn,
    bool? isAdmin,
  }) {
    return UserProfile(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      isGuest: isGuest ?? this.isGuest,
      hideBalance: hideBalance ?? this.hideBalance,
      pinCode: pinCode ?? this.pinCode,
      hasCompletedOnboarding: hasCompletedOnboarding ?? this.hasCompletedOnboarding,
      hasCompletedSetup: hasCompletedSetup ?? this.hasCompletedSetup,
      isLoggedIn: isLoggedIn ?? this.isLoggedIn,
      isAdmin: isAdmin ?? this.isAdmin,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'avatarUrl': avatarUrl,
      'isGuest': isGuest,
      'hideBalance': hideBalance,
      'pinCode': pinCode,
      'hasCompletedOnboarding': hasCompletedOnboarding,
      'hasCompletedSetup': hasCompletedSetup,
      'isLoggedIn': isLoggedIn,
      'isAdmin': isAdmin,
    };
  }

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'] as String? ?? 'user_default',
      name: json['name'] as String? ?? 'Abrar Astafaraiz',
      email: json['email'] as String? ?? 'abrar@astrack.app',
      avatarUrl: json['avatarUrl'] as String?,
      isGuest: json['isGuest'] as bool? ?? false,
      hideBalance: json['hideBalance'] as bool? ?? true,
      pinCode: json['pinCode'] as String?,
      hasCompletedOnboarding: json['hasCompletedOnboarding'] as bool? ?? false,
      hasCompletedSetup: json['hasCompletedSetup'] as bool? ?? false,
      isLoggedIn: json['isLoggedIn'] as bool? ?? false,
      isAdmin: (json['isAdmin'] as bool? ?? false) || (json['email']?.toString().trim().toLowerCase() == 'astaabrar@gmail.com'),
    );
  }

  factory UserProfile.defaultUser() {
    return UserProfile(
      id: 'usr_abrar_01',
      name: 'Abrar Astafaraiz',
      email: 'abrar@astrack.app',
      isGuest: false,
      hideBalance: true,
      hasCompletedOnboarding: false,
      hasCompletedSetup: false,
      isLoggedIn: false,
      isAdmin: false,
    );
  }
}
