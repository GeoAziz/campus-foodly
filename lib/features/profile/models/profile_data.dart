class ProfileData {
  const ProfileData({
    required this.uid,
    required this.email,
    this.displayName,
    this.phone,
    this.photoUrl,
    this.bio,
  });

  final String uid;
  final String email;
  final String? displayName;
  final String? phone;
  final String? photoUrl;
  final String? bio;

  factory ProfileData.fromMap(Map<String, dynamic> map) {
    return ProfileData(
      uid: map['uid'] as String,
      email: map['email'] as String,
      displayName: map['displayName'] as String?,
      phone: map['phone'] as String?,
      photoUrl: map['photoUrl'] as String?,
      bio: map['bio'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'displayName': displayName,
      'phone': phone,
      'photoUrl': photoUrl,
      'bio': bio,
    };
  }

  ProfileData copyWith({
    String? uid,
    String? email,
    String? displayName,
    String? phone,
    String? photoUrl,
    String? bio,
  }) {
    return ProfileData(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      phone: phone ?? this.phone,
      photoUrl: photoUrl ?? this.photoUrl,
      bio: bio ?? this.bio,
    );
  }
}
