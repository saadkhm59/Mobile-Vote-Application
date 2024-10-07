import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:vote2/auth/adminpage.dart';
import 'package:vote2/auth/home.dart';

class LoginPage extends StatefulWidget {
  LoginPage({super.key, required this.onTap});
  final Function()? onTap;

  // bool isUser;

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  bool authenticated = false;
  Widget? x;
  // text editing controllers
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  // sign user in method
  void signUserIn() async {
    // show loading circle
    showDialog(
      context: context,
      builder: (context) {
        return const Center(
          child: CircularProgressIndicator(),
        );
      },
    );

    // try sign in

    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: emailController.text,
        password: passwordController.text,
      );
      // route();
      // pop the loading circle
      Navigator.pop(context);
    } on FirebaseAuthException catch (e) {
      // pop the loading circle
      Navigator.pop(context);
      print(e.code);

      wrongEmailMessage();
      // WRONG EMAIL
    }
    // Changepage();
  }

  
  // wrong email message popup
  void wrongEmailMessage() {
    showDialog(
      context: context,
      builder: (context) {
        return const AlertDialog(
          backgroundColor: Colors.deepPurple,
          title: Center(
            child: Text(
              'Les données sont incorrectes',
              style: TextStyle(color: Colors.white),
            ),
          ),
        );
      },
    );
  }

  // wrong password message popup

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Vote Day'),
      ),
      body: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.all(20.0),
            child:
                Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              Container(
                height: 300,
                width: 300,
                child: Image(
                  image: AssetImage(
                    "lib/assets/votep.jpg",
                  ),
                ),
              ),
              TextField(
                controller: emailController,
                decoration: InputDecoration(
                  hintText: 'Entrer votre email',
                  labelText: 'Email',
                ),
              ),
              SizedBox(height: 20),
              TextField(
                controller: passwordController,
                obscureText: true,
                decoration: InputDecoration(
                  hintText: 'Entrer votre mot de passe',
                  labelText: 'Mot de passe',
                ),
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: signUserIn,
                child: Text('Login'),
              ),
              SizedBox(height: 20),
              Center(
                  child: GestureDetector(
                onTap: widget
                    .onTap, // Fonction à appeler lors du clic sur le texte
                child: Text(
                  'Créer un Compte',
                  style: TextStyle(
                    fontSize: 20,
                    decoration: TextDecoration.underline,
                    color: Colors.blue,
                  ),
                ),
              )),

              // ElevatedButton(
              //   onPressed: () async {
              //     final authenticate = await localauth.authenticate();
              //     setState(() {
              //       authenticated = authenticate;
              //     });
              //     print(authenticated);
              //   },
              //   child: Text('Face ID'),
              // ),
            ]),
          ),
        ),
      ),
    );
  }
}
