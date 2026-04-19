class SocialAccount {
  const SocialAccount({
    required this.provider, // 'google', 'facebook', 'apple'
    required this.uid,
    this.email,
    this.displayName,
  });

  final String provider;
  final String uid;
  final String? email;
  final String? displayName;

  factory SocialAccount.fromMap(Map<String, dynamic> map) {
    return SocialAccount(
      provider: map['provider'] as String,
      uid: map['uid'] as String,
      email: map['email'] as String?,
      displayName: map['displayName'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'provider': provider,
      'uid': uid,
      'email': email,
      'displayName': displayName,
    };
  }

  SocialAccount copyWith({
    String? provider,
    String? uid,
    String? email,
    String? displayName,
  }) {
    return SocialAccount(
      provider: provider ?? this.provider,
      uid: uid ?? this.uid,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
    );
  }
}
