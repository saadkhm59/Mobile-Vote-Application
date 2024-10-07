import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';

class AdminPage extends StatefulWidget {
  @override
  _AdminPageState createState() => _AdminPageState();
}

class _AdminPageState extends State<AdminPage> {
  final TextEditingController voteNameController = TextEditingController();
  List<TextEditingController> choiceControllers = [TextEditingController()];
  final TextEditingController startDateController = TextEditingController();
  final TextEditingController endDateController = TextEditingController();

  void addChoice() {
    setState(() {
      choiceControllers.add(TextEditingController());
    });
  }

  void addVote(BuildContext context) {
    String voteName = voteNameController.text;
    List<String> choices = choiceControllers
        .map((controller) => controller.text)
        .where((choice) => choice.isNotEmpty)
        .toList();
    DateTime startDate = DateTime.tryParse(startDateController.text) ?? DateTime.now();
    DateTime endDate = DateTime.tryParse(endDateController.text) ?? DateTime.now();

    if (voteName.isNotEmpty && choices.isNotEmpty && startDate.isBefore(endDate)) {
      FirebaseFirestore.instance.collection('votes').add({
        'name': voteName,
        'choices': choices,
        'startDate': startDate,
        'endDate': endDate,
      }).then((value) {
        // Réinitialiser les champs après l'ajout du vote
        voteNameController.clear();
        choiceControllers.forEach((controller) => controller.clear());
        startDateController.clear();
        endDateController.clear();

        // Afficher un message de succès
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Vote ajouté avec succès !'),
        ));
      }).catchError((error) {
        // Gérer les erreurs
        print('Erreur lors de l\'ajout du vote: $error');
      });
    } else {
      // Afficher un message d'erreur si des champs sont vides ou incorrects
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Veuillez remplir tous les champs correctement !'),
        backgroundColor: Colors.red,
      ));
    }
  }

  void editVote(String voteId) {
    FirebaseFirestore.instance.collection('votes').doc(voteId).get().then((voteDoc) {
      String currentName = voteDoc['name'];
      List<dynamic> currentChoices = voteDoc['choices'];
      DateTime currentStartDate = (voteDoc['startDate'] as Timestamp).toDate();
      DateTime currentEndDate = (voteDoc['endDate'] as Timestamp).toDate();

      // Contrôleurs pour les champs modifiés
      TextEditingController updatedNameController = TextEditingController(text: currentName);
      List<TextEditingController> updatedChoiceControllers = currentChoices.map((choice) => TextEditingController(text: choice)).toList();
      TextEditingController updatedStartDateController = TextEditingController(text: currentStartDate.toString());
      TextEditingController updatedEndDateController = TextEditingController(text: currentEndDate.toString());

      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Modifier le vote'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: updatedNameController,
                decoration: InputDecoration(labelText: 'Nom du vote'),
              ),
              for (int i = 0; i < updatedChoiceControllers.length; i++)
                TextField(
                  controller: updatedChoiceControllers[i],
                  decoration: InputDecoration(labelText: 'Choix ${i + 1}'),
                ),
              TextField(
                controller: updatedStartDateController,
                keyboardType: TextInputType.datetime,
                decoration: InputDecoration(labelText: 'Date de début'),
              ),
              TextField(
                controller: updatedEndDateController,
                keyboardType: TextInputType.datetime,
                decoration: InputDecoration(labelText: 'Date de fin'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                String updatedName = updatedNameController.text;
                List<String> updatedChoices = updatedChoiceControllers.map((controller) => controller.text).where((choice) => choice.isNotEmpty).toList();
                DateTime updatedStartDate = DateTime.tryParse(updatedStartDateController.text) ?? DateTime.now();
                DateTime updatedEndDate = DateTime.tryParse(updatedEndDateController.text) ?? DateTime.now();

                if (updatedName.isNotEmpty && updatedChoices.isNotEmpty && updatedStartDate.isBefore(updatedEndDate)) {
                  FirebaseFirestore.instance.collection('votes').doc(voteId).update({
                    'name': updatedName,
                    'choices': updatedChoices,
                    'startDate': updatedStartDate,
                    'endDate': updatedEndDate,
                  }).then((_) {
                    Navigator.pop(context); // Fermer la boîte de dialogue après la modification
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text('Vote modifié avec succès !'),
                    ));
                  }).catchError((error) {
                    print('Erreur lors de la modification du vote: $error');
                  });
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text('Veuillez remplir tous les champs correctement !'),
                    backgroundColor: Colors.red,
                  ));
                }
              },
              child: Text('Modifier'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context); // Annuler la modification
              },
              child: Text('Annuler'),
            ),
          ],
        ),
      );
    }).catchError((error) {
      print('Erreur lors de la récupération du vote: $error');
    });
  }

  void deleteVote(String voteId) {
    FirebaseFirestore.instance.collection('votes').doc(voteId).delete().then((_) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Vote supprimé avec succès !'),
      ));
    }).catchError((error) {
      print('Erreur lors de la suppression du vote: $error');
    });
  }

  void viewResults(String voteId) {
    FirebaseFirestore.instance
        .collection('elections')
        .where('voteId', isEqualTo: voteId)
        .get()
        .then((querySnapshot) {
      Map<String, int> results = {};
      for (var doc in querySnapshot.docs) {
        String choice = doc['choix'];
        if (results.containsKey(choice)) {
          results[choice] = results[choice]! + 1;
        } else {
          results[choice] = 1;
        }
      }
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Résultats du vote'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: results.entries
                .map((entry) => ListTile(
                      title: Text(entry.key),
                      trailing: Text(entry.value.toString()),
                    ))
                .toList(),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text('Fermer'),
            ),
          ],
        ),
      );
    }).catchError((error) {
      print('Erreur lors de la récupération des résultats: $error');
    });
  }

  void signOut() async {
    try {
      await FirebaseAuth.instance.signOut();
      // Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (context) => LoginPage(onTap: () {  },)));
    } catch (e) {
      print('Erreur lors de la déconnexion : $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Page d\'administration'),
        actions: [
          IconButton(
            onPressed: signOut,
            icon: Icon(Icons.exit_to_app),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                controller: voteNameController,
                decoration: InputDecoration(labelText: 'Nom du vote'),
              ),
              SizedBox(height: 16.0),
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (int i = 0; i < choiceControllers.length; i++)
                    TextField(
                      controller: choiceControllers[i],
                      decoration: InputDecoration(labelText: 'Choix ${i + 1}'),
                    ),
                  ElevatedButton(
                    onPressed: addChoice,
                    child: Text('Ajouter un choix'),
                  ),
                ],
              ),
              SizedBox(height: 16.0),
              TextField(
                controller: startDateController,
                keyboardType: TextInputType.datetime,
                decoration: InputDecoration(labelText: 'Date de début'),
              ),
              TextField(
                controller: endDateController,
                keyboardType: TextInputType.datetime,
                decoration: InputDecoration(labelText: 'Date de fin'),
              ),
              SizedBox(height: 32.0),
              ElevatedButton(
                onPressed: () => addVote(context),
                child: Text('Ajouter le vote'),
              ),
              SizedBox(height: 32.0),
              Text(
                'Liste des Votes',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance.collection('votes').snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return Center(child: CircularProgressIndicator());
                  }
                  return ListView.builder(
                    shrinkWrap: true,
                    itemCount: snapshot.data!.docs.length,
                    itemBuilder: (context, index) {
                      var vote = snapshot.data!.docs[index];
                      return ListTile(
                        title: Text(vote['name']),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Date de début: ${DateFormat('yyyy-MM-dd').format((vote['startDate'] as Timestamp).toDate())}'),
                            Text('Date de fin: ${DateFormat('yyyy-MM-dd').format((vote['endDate'] as Timestamp).toDate())}'),
                          ],
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              onPressed: () => deleteVote(vote.id),
                              icon: Icon(Icons.delete),
                            ),
                            IconButton(
                              onPressed: () => editVote(vote.id),
                              icon: Icon(Icons.edit),
                            ),
                            IconButton(
                              onPressed: () => viewResults(vote.id),
                              icon: Icon(Icons.bar_chart),
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

void main() {
  runApp(MaterialApp(
    home: AdminPage(),
  ));
}
