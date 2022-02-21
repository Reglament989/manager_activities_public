import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

final usersRef =
    FirebaseFirestore.instance.collection('users').withConverter<User>(
          fromFirestore: (snapshot, _) => User.fromJson(snapshot.data()!),
          toFirestore: (user, _) => user.toJson(),
        );

final subUsersRef = FirebaseFirestore.instance.collection('users');

// TODO: NEED TO CREAETE Relationships
class User {
  User(
      {this.email,
      this.note,
      required this.firstName,
      this.lastName,
      required this.orders,
      required this.phone,
      this.dateOfBirth});

  final String? email;
  final String firstName;
  final String? lastName;
  final List<String> orders;
  final String phone;
  final DateTime? dateOfBirth;
  List<String>? subNumbers;
  final String? note;

  @override
  String toString() {
    return '$firstName $lastName $phone $email $subNumbers $note';
  }

  @override
  bool operator ==(Object other) {
    if (other.runtimeType != runtimeType) {
      return false;
    }
    return other is User && other.phone == phone && other.email == email;
  }

  @override
  int get hashCode => hashValues(email, phone);

  List<String> props(context) => [
        AppLocalizations.of(context)!
            .contactPageTemplate(firstName, lastName ?? ""),
        AppLocalizations.of(context)!.clientPhone + phone,
        ...?subNumbers
            ?.map((e) => AppLocalizations.of(context)!.clientSecondaryPhone + e)
            .toList(),
        if (note != null) note!,
      ];

  factory User.fromJson(json) {
    final List<String> orders = [];
    if (json['orders'] != null) {
      for (var item in json['orders']) {
        orders.add(item as String);
      }
    }

    final dateOfBirth =
        json['dateOfBirth'] != null ? json['dateOfBirth'].toDate() : null;

    return User(
        note: json['note'] as String?,
        email: json['email'] as String?,
        firstName: json['first_name'] as String,
        lastName: json['last_name'] as String,
        orders: orders,
        phone: json['phone'] as String,
        dateOfBirth: dateOfBirth);
  }

  Map<String, dynamic> toJson() => {
        'email': email,
        'first_name': firstName,
        'last_name': lastName,
        'orders': orders,
        'phone': phone,
        'dateOfBirth': dateOfBirth,
        'note': note,
      };

  static Future<List<User>> getAllUsers() async {
    final rawUsers = await usersRef.get();
    final List<User> users = [];
    for (final user in rawUsers.docs) {
      users.add(user.data());
    }
    return users;
  }

  static Future<User?> find(User user) async {
    final rawUser = await usersRef.doc(user.phone).get();
    if (rawUser.exists) {
      await usersRef.doc(user.phone).set(user);
    }
    return rawUser.data();
  }

  Future<User> save() async {
    await usersRef.doc(phone).set(this);
    return this;
  }

  Future<User?> sync() async {
    final user = await usersRef.doc(phone).get();
    return user.data();
  }

  Future delete() async {
    await usersRef.doc(phone).delete();
  }

  Future<void> addSubNumberPhone(String newPhone) async {
    final col = subUsersRef.doc(phone).collection("subNumbers");
    await col.doc(newPhone).set({'phone': newPhone});
  }

  Future<List<String>?> fetchSubNumbers() async {
    final col = subUsersRef.doc(phone).collection("subNumbers");
    final data = await col.get();
    if (data.size > 0) {
      final list = data.docs.map((e) => e.data()['phone'] as String).toList();
      subNumbers = list;
      return list;
    }
  }

  Future<void> deleteSubNumber(String number) async {
    final col = subUsersRef.doc(phone).collection("subNumbers");
    await col.doc(number).delete();
  }
}
