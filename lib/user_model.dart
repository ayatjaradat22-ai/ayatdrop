class UserModel {
  String? uid;
  String? name;
  String? email;
  String? photoUrl; // تم التوحيد إلى photoUrl بدلاً من imageUrl
  bool isPremium;
  double walletBalance;
  DateTime? subscriptionDate;

  UserModel({
    this.uid,
    this.name,
    this.email,
    this.photoUrl,
    this.isPremium = false,
    this.walletBalance = 0.0,
    this.subscriptionDate,
  });

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      uid: map['uid'],
      name: map['name'],
      email: map['email'],
      photoUrl: map['photoUrl'], // تم التحديث هنا
      isPremium: map['isPremium'] ?? false,
      walletBalance: (map['walletBalance'] ?? 0.0).toDouble(),
      subscriptionDate: map['subscriptionDate'] != null
          ? (map['subscriptionDate'] as dynamic).toDate()
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'name': name,
      'email': email,
      'photoUrl': photoUrl, // تم التحديث هنا
      'isPremium': isPremium,
      'walletBalance': walletBalance,
      'subscriptionDate': subscriptionDate,
    };
  }
}
