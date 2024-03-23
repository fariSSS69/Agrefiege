import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ObservationPage extends StatefulWidget {
  @override
  _ObservationPageState createState() => _ObservationPageState();
}

class _ObservationPageState extends State<ObservationPage> {
  late User _user;
  String? _lieuId;
  String? _selectedParcelle;
  String? _selectedNotation;
  TextEditingController _notesController =
      TextEditingController(); // Contrôleur pour le champ de texte des notes

  @override
  void initState() {
    super.initState();
    _getUserData();
  }

  Future<void> _getUserData() async {
    FirebaseAuth auth = FirebaseAuth.instance;
    _user = auth.currentUser!;
    final userSnapshot = await FirebaseFirestore.instance
        .collection('Observateurs')
        .where('email', isEqualTo: _user.email)
        .get();
    final userSnapshotData = userSnapshot.docs.first.data();
    _lieuId = userSnapshotData['Lieux'][0].id;
    setState(
        () {}); // Ajouter setState() pour notifier Flutter que l'état de la page a changé
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Observation Page'),
      ),
      body: Center(
        child: _lieuId == null
            ? CircularProgressIndicator()
            : FutureBuilder<QuerySnapshot>(
                future: FirebaseFirestore.instance
                    .collection('Parcelles')
                    .where('Lieu',
                        isEqualTo:
                            FirebaseFirestore.instance.doc('Lieux/$_lieuId'))
                    .get(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return CircularProgressIndicator();
                  } else if (snapshot.hasError) {
                    return Text('Error: ${snapshot.error}');
                  } else if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return Text('Aucune parcelle disponible pour ce lieu');
                  } else {
                    List<String> parcelles = snapshot.data!.docs
                        .map((doc) => doc['Numero_parcelle'].toString())
                        .toList();
                    return Column(
                      children: [
                        Text(
                          'Parcelles',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        DropdownButton<String>(
                          value: _selectedParcelle,
                          onChanged: (newValue) {
                            setState(() {
                              _selectedParcelle = newValue;
                              _selectedNotation =
                                  null; // Réinitialiser la notation sélectionnée
                            });
                          },
                          items: parcelles
                              .map<DropdownMenuItem<String>>((String value) {
                            return DropdownMenuItem<String>(
                              value: value,
                              child: Text(value),
                            );
                          }).toList(),
                        ),
                        SizedBox(height: 20),
                        if (_selectedParcelle != null)
                          FutureBuilder<QuerySnapshot>(
                            future: FirebaseFirestore.instance
                                .collection('Notations')
                                .where('Parcelle',
                                    isEqualTo: FirebaseFirestore.instance
                                        .doc('Parcelles/$_selectedParcelle'))
                                .get(),
                            builder: (context, snapshot) {
                              if (snapshot.connectionState ==
                                  ConnectionState.waiting) {
                                return CircularProgressIndicator();
                              } else if (snapshot.hasError) {
                                return Text('Error: ${snapshot.error}');
                              } else if (!snapshot.hasData ||
                                  snapshot.data!.docs.isEmpty) {
                                return Text(
                                    'Aucune notation disponible pour cette parcelle');
                              } else {
                                var notationData = snapshot.data!.docs.first
                                    .data()! as Map<String, dynamic>;
                                List<String> notations =
                                    notationData.keys.toList();
                                return Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Notations',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    DropdownButton<String>(
                                      value: _selectedNotation,
                                      onChanged: (newValue) {
                                        setState(() {
                                          _selectedNotation = newValue;
                                        });
                                      },
                                      items: notations
                                          .map<DropdownMenuItem<String>>(
                                              (String value) {
                                        return DropdownMenuItem<String>(
                                          value: value,
                                          child: Text(value),
                                        );
                                      }).toList(),
                                    ),
                                    SizedBox(height: 20),
                                    Text(
                                      'Notes',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    TextField(
                                      controller: _notesController,
                                      decoration: InputDecoration(
                                        hintText: 'Entrez vos notes ici...',
                                        border: OutlineInputBorder(),
                                      ),
                                      maxLines:
                                          5, // Définir le nombre maximum de lignes pour le champ de texte
                                    ),
                                  ],
                                );
                              }
                            },
                          ),
                      ],
                    );
                  }
                },
              ),
      ),
    );
  }
}
