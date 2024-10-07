import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

void main() => runApp(MyApp());

class Vote {
  final String id;
  final String name;
  final List<String> choices;
  final DateTime startDate;
  final DateTime endDate;

  Vote(this.id, this.name, this.choices, this.startDate, this.endDate);
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Votes',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: VoteListPage(),
    );
  }
}

class VoteListPage extends StatefulWidget {
  @override
  _VoteListPageState createState() => _VoteListPageState();
}

class _VoteListPageState extends State<VoteListPage> {
  List<Vote> votes = [];

  @override
  void initState() {
    super.initState();
    fetchVotes();
  }

  Future<void> fetchVotes() async {
    try {
      QuerySnapshot querySnapshot =
          await FirebaseFirestore.instance.collection('votes').get();
      List<Vote> fetchedVotes = querySnapshot.docs.map((doc) {
        List<String> choices = List.from(doc['choices'] ?? []);
        DateTime startDate = (doc['startDate'] as Timestamp).toDate();
        DateTime endDate = (doc['endDate'] as Timestamp).toDate();
        return Vote(doc.id, doc['name'] ?? '', choices, startDate, endDate);
      }).toList();
      setState(() {
        votes = fetchedVotes;
      });
    } catch (e) {
      print('Erreur lors de la récupération des votes : $e');
    }
  }

  void signUserOut() {
    FirebaseAuth.instance.signOut();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Liste des Votes'),
        actions: [
          IconButton(
            onPressed: signUserOut,
            icon: Icon(Icons.exit_to_app),
          ),
        ],
      ),
      body: votes.isEmpty
          ? Center(child: CircularProgressIndicator())
          : CustomScrollView(
              slivers: [
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      return Card(
                        margin: EdgeInsets.all(10),
                        elevation: 4,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16.0),
                        ),
                        child: Column(
                          children: [
                            Padding(
                              padding: EdgeInsets.all(16.0),
                              child: Text(
                                votes[index].name,
                                style: TextStyle(fontSize: 18),
                              ),
                            ),
                            Text(
                              'Date de début: ${DateFormat('yyyy-MM-dd').format(votes[index].startDate)}',
                              style: TextStyle(fontSize: 16),
                            ),
                            Text(
                              'Date de fin: ${DateFormat('yyyy-MM-dd').format(votes[index].endDate)}',
                              style: TextStyle(fontSize: 16),
                            ),
                            SizedBox(height: 20),
                            ElevatedButton(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        VoteDetailsPage(votes[index]),
                                  ),
                                );
                              },
                              child: Text('Accéder au vote'),
                            ),
                          ],
                        ),
                      );
                    },
                    childCount: votes.length,
                  ),
                ),
              ],
            ),
    );
  }
}

class VoteDetailsPage extends StatefulWidget {
  final Vote vote;

  VoteDetailsPage(this.vote);

  @override
  State<VoteDetailsPage> createState() => _VoteDetailsPageState();
}

class _VoteDetailsPageState extends State<VoteDetailsPage> {
  String selectedChoice = '';
  bool hasVoted = false; // Ajout d'un booléen pour vérifier si l'utilisateur a déjà voté
  final FirebaseAuth _auth = FirebaseAuth.instance;

  @override
  void initState() {
    super.initState();
    checkIfUserVoted();
  }

  Future<void> checkIfUserVoted() async {
    try {
      User? user = _auth.currentUser;
      if (user != null) {
        QuerySnapshot querySnapshot = await FirebaseFirestore.instance
            .collection('elections')
            .where('voteId', isEqualTo: widget.vote.id)
            .where('email', isEqualTo: user.email)
            .get();

        if (querySnapshot.docs.isNotEmpty) {
          setState(() {
            hasVoted = true;
          });
        }
      }
    } catch (e) {
      print('Erreur lors de la vérification du vote : $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    User? user = _auth.currentUser;
    return Scaffold(
      appBar: AppBar(
        title: Text('Détails du Vote'),
      ),
      body: SingleChildScrollView(
        child: Center(
          child: Column(
            children: <Widget>[
              SizedBox(height: 150),
              Text(
                widget.vote.name,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 20,
                  color: Colors.black,
                  decoration: TextDecoration.none,
                ),
              ),
              SizedBox(height: 50),
              Wrap(
                alignment: WrapAlignment.center,
                children: widget.vote.choices.map((choice) {
                  return ChoiceButton(
                    choice: choice,
                    isSelected: selectedChoice == choice,
                    onTap: () {
                      setState(() {
                        selectedChoice = choice;
                      });
                    },
                  );
                }).toList(),
              ),
              SizedBox(height: 50),
              hasVoted // Vérifie si l'utilisateur a déjà voté
                  ? Text(
                      'Vous avez déjà voté pour ce vote.',
                      style: TextStyle(fontSize: 18, color: Colors.red),
                    )
                  : ElevatedButton(
                      onPressed: () {
                        if (hasVoted) return; // Empêche l'utilisateur de voter à nouveau
                        if (selectedChoice == '') {
                          showDialog(
                            context: context,
                            builder: (context) {
                              return const AlertDialog(
                                backgroundColor: Colors.deepPurple,
                                title: Center(
                                  child: Text(
                                    'Vous n\'avez pas encore choisi une option!',
                                    style: TextStyle(color: Colors.white),
                                  ),
                                ),
                              );
                            },
                          );
                        } else {
                          CollectionReference collRef =
                              FirebaseFirestore.instance.collection('elections');
                          collRef.add({
                            'voteId': widget.vote.id, // Add the vote ID
                            'choix': selectedChoice,
                            'email': user?.email
                          });
                          Navigator.of(context).pushReplacement(
                              MaterialPageRoute(builder: (context) => ThankYouPage()));
                        }
                      },
                      child: Text('Voter'),
                    ),
              SizedBox(height: 50),
              Text(
                'Date de début: ${DateFormat('yyyy-MM-dd').format(widget.vote.startDate)}',
                style: TextStyle(fontSize: 16),
              ),
              Text(
                'Date de fin: ${DateFormat('yyyy-MM-dd').format(widget.vote.endDate)}',
                style: TextStyle(fontSize: 16),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
class ChoiceButton extends StatelessWidget {
  final String choice;
  final bool isSelected;
  final Function() onTap;

  const ChoiceButton({
    Key? key,
    required this.choice,
    required this.isSelected,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: EdgeInsets.all(10),
        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? Colors.blue : Colors.grey[300],
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          choice,
          style: TextStyle(
            fontSize: 20,
            color: Colors.black,
            decoration: TextDecoration.none,
          ),
        ),
      ),
    );
  }
}



class ThankYouPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Merci pour votre vote!',
              style: TextStyle(fontSize: 24),
            ),
            SizedBox(height: 20), // Ajoute un espace entre le texte et le bouton
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context); // Retourne à la page précédente
              },
              child: Text('Retour'),
            ),
          ],
        ),
      ),
    );
  }
}

