class UserModel {
  String? uid;
  String? name;
  String? email;
  String? imageUrl;
  bool isPremium;
  double walletBalance;
  DateTime? subscriptionDate;

  UserModel({
    this.uid,
    this.name,
    this.email,
    this.imageUrl,
    this.isPremium = false, // القيمة الافتراضية مستخدم عادي
    this.walletBalance = 0.0, // الرصيد الافتراضي صفر
    this.subscriptionDate,
  });

  // تحويل البيانات من Firestore (Map) إلى Model
  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      uid: map['uid'],
      name: map['name'],
      email: map['email'],
      imageUrl: map['imageUrl'],
      isPremium: map['isPremium'] ?? false,
      walletBalance: (map['walletBalance'] ?? 0.0).toDouble(),
      // تحويل الـ Timestamp القادم من Firestore إلى DateTime
      subscriptionDate: map['subscriptionDate'] != null
          ? (map['subscriptionDate'] as dynamic).toDate()
          : null,
    );
  }

  // تحويل الـ Model إلى Map لإرساله لـ Firestore
  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'name': name,
      'email': email,
      'imageUrl': imageUrl,
      'isPremium': isPremium,
      'walletBalance': walletBalance,
      'subscriptionDate': subscriptionDate,
    };
  }
}