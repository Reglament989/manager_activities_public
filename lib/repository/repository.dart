import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/widgets.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:manager_activites/repository/prefs_users.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

enum Status { Uninitialized, Authenticated, Authenticating, Unauthenticated }

class UserRepository with ChangeNotifier {
  FirebaseAuth _auth;
  User? _user;
  bool _isAdmin = false;
  Status _status = Status.Uninitialized;
  String? _error;

  UserRepository.instance() : _auth = FirebaseAuth.instance {
    _auth.authStateChanges().listen(_onAuthStateChanged);
  }

  Status get status => _status;
  User? get user => _user;
  bool get isAdmin => _isAdmin;
  String? get error => _error;

  Future<bool> signIn(
      String email, String password, BuildContext context) async {
    try {
      _status = Status.Authenticating;
      notifyListeners();
      await _auth.signInWithEmailAndPassword(email: email, password: password);
      return true;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found') {
        _error = AppLocalizations.of(context)!.errorFirebaseUserNotFound;
      } else if (e.code == 'wrong-password') {
        _error = AppLocalizations.of(context)!.errorFirebaseWrongPassword;
      }
      _status = Status.Unauthenticated;
      notifyListeners();
      return false;
    }
  }

  Future signOut() async {
    _auth.signOut();
    _status = Status.Unauthenticated;
    notifyListeners();
    return Future.delayed(Duration.zero);
  }

  Future fetchUserPrefs() async {
    /// TODO: FOR OFFLINE USE NEED TO BE
    final rawPrefs = await userPrefRef.doc(_user!.uid).get();
    if (rawPrefs.exists) {
      final prefs = rawPrefs.data();
      if (prefs!.isAdmin != null) {
        _isAdmin = prefs.isAdmin!;
      }
    }
    if (!kIsWeb) {
      final token = await FirebaseMessaging.instance.getToken();
      if (token != null) {
        await saveTokenToDatabase(token);
      }
    }
  }

  Future<void> saveTokenToDatabase(String token) async {
    final userPrefs = await FirebaseFirestore.instance
        .collection('users_prefs')
        .doc(user!.uid)
        .get();
    if (userPrefs.exists) {
      await FirebaseFirestore.instance
          .collection('users_prefs')
          .doc(user!.uid)
          .update({
        'tokens': FieldValue.arrayUnion([token]),
      });
    } else {
      await FirebaseFirestore.instance
          .collection('users_prefs')
          .doc(user!.uid)
          .set({
        'tokens': FieldValue.arrayUnion([token])
      });
    }
  }

  Future<void> _onAuthStateChanged(User? firebaseUser) async {
    if (firebaseUser == null) {
      _status = Status.Unauthenticated;
    } else {
      _user = firebaseUser;
      fetchUserPrefs();
      _status = Status.Authenticated;
    }
    notifyListeners();
  }
}
