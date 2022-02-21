import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:manager_activites/login/views/form.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class LoginView extends StatefulWidget {
  static const route = "/login";
  const LoginView({Key? key}) : super(key: key);

  @override
  _LoginViewState createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: Stack(
      children: [
        Center(
          child: Container(
            child: Column(
              // mainAxisSize: MainAxisSize.max,
              children: [
                Expanded(
                  child: ClipPath(
                    child: Container(
                      // padding: EdgeInsets.symmetric(vertical: 190),
                      color: Colors.blue,
                      child: Center(
                        child: Text(
                          AppLocalizations.of(context)!.appName,
                          style: TextStyle(
                              fontSize: 24, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                    clipper: CustomClipPath(),
                  ),
                ),
                Expanded(
                  child: Container(
                      child: Padding(
                    padding: EdgeInsets.only(left: 40, right: 40),
                    child: LoginForm(),
                  )),
                ),
              ],
            ),
            // height: MediaQuery.of(context).size.height / 2,
          ),
        ),
      ],
    ));
  }
}

class CustomClipPath extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    Path path = Path();
    path.lineTo(0, size.height);
    path.quadraticBezierTo(
        size.width / 4, size.height - 40, size.width / 2, size.height - 20);
    path.quadraticBezierTo(
        3 / 4 * size.width, size.height, size.width, size.height - 30);
    path.lineTo(size.width, 0);

    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}
