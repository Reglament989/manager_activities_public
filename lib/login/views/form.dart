import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:manager_activites/home/view/home_view.dart';
import 'package:manager_activites/login/data/login.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:manager_activites/repository/repository.dart';
import 'package:provider/provider.dart';
import 'package:rounded_loading_button/rounded_loading_button.dart';

class LoginForm extends StatefulWidget {
  const LoginForm({Key? key}) : super(key: key);

  @override
  _LoginFormState createState() => _LoginFormState();
}

class _LoginFormState extends State<LoginForm> {
  final _formKey = GlobalKey<FormState>();
  final _btnController = RoundedLoadingButtonController();
  final nameController = TextEditingController();
  final passwordController = TextEditingController();
  bool isObsecure = true;
  bool loading = false;
  String? error;

  @override
  void dispose() {
    nameController.dispose();
    passwordController.dispose();

    super.dispose();
  }

  setError(String newError) {
    setState(() {
      error = newError;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: SingleChildScrollView(
        child: AutofillGroup(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: TextFormField(
                  autofillHints: [AutofillHints.email, AutofillHints.name],
                  keyboardType: TextInputType.emailAddress,
                  controller: nameController,
                  decoration: InputDecoration(
                      // contentPadding: const EdgeInsets.all(12),
                      suffixIcon: GestureDetector(
                        child: Padding(
                          padding: EdgeInsets.symmetric(horizontal: 8),
                          child: Icon(Icons.alternate_email),
                        ),
                      ),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12)),
                      hintText: AppLocalizations.of(context)!.emailHint),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return AppLocalizations.of(context)!
                          .errorPleaseEntryValue;
                    }
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: TextFormField(
                  obscureText: isObsecure,
                  autofillHints: [AutofillHints.password],
                  keyboardType: TextInputType.text,
                  autocorrect: false,
                  controller: passwordController,
                  decoration: InputDecoration(
                      suffixIcon: GestureDetector(
                        child: Padding(
                          padding: EdgeInsets.symmetric(horizontal: 8),
                          child: Icon(Icons.remove_red_eye),
                        ),
                        onTap: () {
                          setState(() {
                            isObsecure = !isObsecure;
                          });
                        },
                      ),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12)),
                      hintText: AppLocalizations.of(context)!.passwordHint),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return AppLocalizations.of(context)!
                          .errorPleaseEntryValue;
                    }
                  },
                ),
              ),
              if (Provider.of<UserRepository>(context).error != null)
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Container(
                    decoration: BoxDecoration(
                        color: Colors.red[400],
                        borderRadius: BorderRadius.circular(15)),
                    padding: EdgeInsets.all(16),
                    child: Center(
                        child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8.0),
                          child: Icon(Icons.error),
                        ),
                        Text(Provider.of<UserRepository>(context).error!)
                      ],
                    )),
                  ),
                ),
              if (loading)
                Padding(
                  padding: EdgeInsets.all(8),
                  child: CircularProgressIndicator(),
                ),
              Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: RoundedLoadingButton(
                    child: Text(AppLocalizations.of(context)!.loginButton),
                    controller: _btnController,
                    onPressed: () async {
                      if (_formKey.currentState!.validate()) {
                        // LOGIC
                        try {
                          await Provider.of<UserRepository>(context,
                                  listen: false)
                              .signIn(nameController.text.trim(),
                                  passwordController.text.trim(), context);
                        } finally {
                          if (Provider.of<UserRepository>(context,
                                      listen: false)
                                  .error !=
                              null) {
                            _btnController.error();
                          } else {
                            _btnController.success();
                          }
                        }
                      } else {
                        _btnController.error();
                      }
                      Future.delayed(Duration(seconds: 1),
                          () => mounted ? _btnController.reset() : null);
                    },
                  ))
            ],
          ),
        ),
      ),
    );
  }
}
