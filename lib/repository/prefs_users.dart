import 'package:cloud_firestore/cloud_firestore.dart';

final userPrefRef = FirebaseFirestore.instance
    .collection('users_prefs')
    .withConverter<UserPrefs>(
      fromFirestore: (snapshot, _) => UserPrefs.fromJson(snapshot.data()!),
      toFirestore: (event, _) => event.toJson(),
    );

class UserPrefs {
  final bool? isAdmin;

  UserPrefs(this.isAdmin);

  factory UserPrefs.fromJson(json) {
    return UserPrefs(json['isAdmin'] as bool?);
  }

  Map<String, dynamic> toJson() => {'isAdmin': isAdmin};
}
