import 'package:cloud_firestore/cloud_firestore.dart';

class User {
  String? get id => _id;
  final String name;
  final String username;
  final String email;
  //TODO: Impl of publickey
  String? publicKeyJwb;
  final String? photoUrl;
  String? _id;
  bool active;
  DateTime lastSeen;

  User({
    required this.name,
    required this.email,
    required this.username,
    required this.lastSeen,
    required this.publicKeyJwb,
    this.active = false,
    this.photoUrl,
    String? id,
  }) {
    this._id ??= id;
  }

  Map<String, dynamic> toJSON() => {
    "id": id,
    "name": name,
    "username": username,
    "email": email,
    "photo_url": photoUrl,
    "public_key_jwb": publicKeyJwb,
    "last_seen": lastSeen,
    "active": active,
  };

  factory User.fromJSON(Map<String, dynamic> map) {
    User user = User(
      username: map["username"]!,
      name: map["name"] ?? "Anonymous",
      publicKeyJwb: map["public_key"],
      email: map["email"]!,
      lastSeen: (map["last_seen"] is DateTime
          ? map["last_seen"]
          : map["last_seen"] is Timestamp
          ? (map["last_seen"] as Timestamp).toDate()
          : DateTime.parse(
              map["last_seen"] ?? DateTime.now().toIso8601String(),
            )),
      photoUrl: map["photo_url"],
      active: map["active"] ?? false,
    );
    user._id = map["id"];

    return user;
  }
}
