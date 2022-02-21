import 'package:firebase_auth/firebase_auth.dart';
import 'package:manager_activites/repository/repository.dart';
import 'package:provider/provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

Future<String?> loginWithEmailAndPassword(
    {required String password, required String email, required context}) async {
  // try {
  //   Provider.of<UserRepository>(context, listen: false).signIn(email, password);
  // } on FirebaseAuthException catch (e) {
  //   print(e.message);
  //   if (e.code == 'user-not-found') {
  //     return AppLocalizations.of(context)!.errorFirebaseUserNotFound;
  //   } else if (e.code == 'wrong-password') {
  //     return AppLocalizations.of(context)!.errorFirebaseWrongPassword;
  //   }
  //   return e.message;
  // } catch (e) {
  //   print(e.toString());
  //   return e.toString();
  // }
}
