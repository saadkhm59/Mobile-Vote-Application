import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:vote2/auth/adminpage.dart';
import 'logreg.dart';
import 'listevote.dart';


class AuthPage extends StatefulWidget {
  const AuthPage({Key? key});

  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  Future<Widget> _getHomePageOrAdminPage() async {
    User? user = FirebaseAuth.instance.currentUser;
    try {
      DocumentSnapshot documentSnapshot = await FirebaseFirestore.instance
          .collection('Users')
          .doc(user!.uid)
          .get();

      if (documentSnapshot.get('role') == "User") {
        return VoteListPage();
      } else {
        return AdminPage();
      }
    } on FirebaseAuthException catch (e) {
      print(e.code);
      // Gérer l'erreur ici (par exemple, afficher un message d'erreur)
      return Container(); // Retourne un widget vide pour l'instant
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            return FutureBuilder<Widget>(
              future: _getHomePageOrAdminPage(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  // Affichez un indicateur de chargement ici si nécessaire
                  return CircularProgressIndicator();
                } else if (snapshot.hasError) {
                  // Gérez l'erreur ici (par exemple, affichez un message d'erreur)
                  return Text("Erreur : ${snapshot.error}");
                } else {
                  return snapshot.data ?? Container(); // Retourne un widget vide par défaut
                }
              },
            );
          } else {
            return logreg();
          }
        },
      ),
    );
  }
}