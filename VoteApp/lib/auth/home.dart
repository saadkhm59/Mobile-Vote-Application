import 'package:flutter/material.dart';
import 'package:flutter_countdown_timer/flutter_countdown_timer.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'tempsfinis.dart';

class Vote {
  final String id;
  final String name;

  Vote(this.id, this.name);
}

class HomePage extends StatefulWidget {
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
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
      List<Vote> fetchedVotes = querySnapshot.docs
          .map((doc) => Vote(doc.id, doc['name'] ?? ''))
          .toList();
      setState(() {
        votes = fetchedVotes;
      });
    } catch (e) {
      print('Erreur lors de la récupération des votes : $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          children: [
            if (votes.isNotEmpty) ChoiceView(vote: votes[0]), // Pass the first vote as an example
            SizedBox(height: 30),
            _buildTimer(context),
            SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}

class ChoiceView extends StatefulWidget {
  final Vote vote;

  ChoiceView({required this.vote});

  @override
  _ChoiceViewState createState() => _ChoiceViewState();
}

class _ChoiceViewState extends State<ChoiceView> {
  final List<String> choices = [
    'Mr.Smahi',
    'Mr.Essajid',
    'Mr.Erradi',
    'M.El Alaoui'
  ];
  String name = 'Votez sur le futur président de la communauté';

  String selectedChoice = '';
  final FirebaseAuth _auth = FirebaseAuth.instance;

  @override
  Widget build(BuildContext context) {
    User? user = _auth.currentUser;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          SizedBox(height: 150),
          Text(
            widget.vote.name,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 20),
          ),
          SizedBox(height: 20),
          Wrap(
            alignment: WrapAlignment.center,
            children: choices.map((choice) {
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
          SizedBox(height: 20),
          ElevatedButton(
            onPressed: () {
              if (selectedChoice == '') {
                showDialog(
                  context: context,
                  builder: (context) {
                    return const AlertDialog(
                      backgroundColor: Colors.deepPurple,
                      title: Center(
                        child: Text(
                          'Vous n\'avez pas encore choisis une option!',
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
        ],
      ),
    );
  }
}

Widget _buildTimer(BuildContext context) {
  int time = 120000;
  return CountdownTimer(
    endTime: DateTime.now().millisecondsSinceEpoch + time, // 120000 milliseconds (2 minutes)
    textStyle: TextStyle(fontSize: 48),
    onEnd: () {
      Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => TimeOutPage()));
    },
  );
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
          style: TextStyle(fontSize: 18),
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
        child: Text('Merci pour votre vote!', style: TextStyle(fontSize: 24)),
      ),
    );
  }
}

class TimeOutPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Text('Temps écoulé', style: TextStyle(fontSize: 24)),
      ),
    );
  }
}
