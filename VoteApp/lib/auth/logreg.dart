import 'package:flutter/material.dart';
import 'package:vote2/auth/login.dart';
import 'package:vote2/auth/register.dart';

class logreg extends StatefulWidget {
  const logreg({super.key});

  @override
  State<logreg> createState() => _logregState();
}

class _logregState extends State<logreg> {
  bool showLoginPage = true;

  void togglePages() {
    setState(() {
      showLoginPage = !showLoginPage;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (showLoginPage) {
      return LoginPage(onTap: togglePages,);
    } else
      return RegisterPage(onTap: togglePages,);
  }
}
 