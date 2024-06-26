import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ObservationPage extends StatefulWidget {
  const ObservationPage({super.key});

  @override
  _ObservationPageState createState() => _ObservationPageState();
}

class _ObservationPageState extends State<ObservationPage> {
  late User _user;
  String? _lieuId;
  final List<Map<String, dynamic>> _rows = [];
  bool _isLoading = true;
  List<DropdownMenuItem<String>>? _lieuxDropdownItems;
  bool _hasUnsavedData = false;

  @override
  void initState() {
    super.initState();
    _getUserData();
    _addRow();
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

    // Si l'utilisateur est l'administrateur, chargez tous les lieux
    if (_user.email == 'faris.maisonneuve@wanadoo.fr') {
      final lieuxSnapshot =
          await FirebaseFirestore.instance.collection('Lieux').get();
      _lieuxDropdownItems = lieuxSnapshot.docs
          .map((doc) => DropdownMenuItem<String>(
                value: doc.id,
                child: Text(doc.data()['Nom_lieu'] as String),
              ))
          .toList();
      if (_lieuxDropdownItems!.isNotEmpty) {
        _lieuId = _lieuxDropdownItems!
            .first.value; // Sélectionnez le premier lieu par défaut
      }
    }

    setState(() {
      _isLoading = false;
    });
  }

  void _addRow() {
    setState(() {
      _rows.add({
        'parcelle': null,
        'notation': null,
        'Note': TextEditingController(),
      });
      _hasUnsavedData = true;
    });
  }

  void _deleteRow(int index) {
    setState(() {
      _rows.removeAt(index);
      if (_rows.isEmpty) {
        _hasUnsavedData = false;
      }
    });
  }

  Future<List<Map<String, dynamic>>> _getNotationData(String parcelleId) async {
  // Récupérer le document de la parcelle à partir de Firestore
  final DocumentSnapshot<Map<String, dynamic>> parcelleSnapshot =
      await FirebaseFirestore.instance.collection('Parcelles').doc(parcelleId).get();

  List<Map<String, dynamic>> notationsWithTypes = [];
  
  if (parcelleSnapshot.exists) {
    List<dynamic> notations = parcelleSnapshot.data()!['Notations'];
    
    for (String nomNotation in notations) {
      // Récupérer chaque document de notation pour obtenir le type
      final DocumentSnapshot<Map<String, dynamic>> notationSnapshot =
        await FirebaseFirestore.instance.collection('Notations').doc(nomNotation).get();

      if (notationSnapshot.exists) {
        notationsWithTypes.add({
          'nom': nomNotation,
          'type': notationSnapshot.data()!['type']
        });
      }
    }
  }

  return notationsWithTypes;
}


   Future<void> _saveData() async {
    bool isSaved = false;
    for (int i = 0; i < _rows.length; i++) {
      final row = _rows[i];
      final parcelleId = row['parcelle'];
      final notationName = row['notation'];
      final TextEditingController noteController = row['Note'];
      final String noteText = noteController.text;

      if (parcelleId != null && notationName != null && noteText.isNotEmpty) {
        final List<Map<String, dynamic>> notationData = await _getNotationData(parcelleId);
        final Map<String, dynamic>? notationInfo = notationData.firstWhere(
            (notation) => notation['nom'] == notationName,
            orElse: () => {'type': null});
        final String? notationType = notationInfo?['type'];
        final bool isNoteValid = notationType == 'libre' ||
            (notationType == 'fixe' &&
                int.tryParse(noteText) != null &&
                int.parse(noteText) >= 1 &&
                int.parse(noteText) <= 9);

        if (!isNoteValid) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('La note pour "$notationName" doit être un nombre entre 1 et 9.')),
          );
          return; // Stop saving if the note is invalid for fixed notations
        }

        // Check if a similar observation already exists
        final querySnapshot = await FirebaseFirestore.instance
            .collection('Observations')
            .where('Parcelle', isEqualTo: FirebaseFirestore.instance.doc('Parcelles/$parcelleId'))
            .where('Notations', isEqualTo: notationName)
            .get();

        if (querySnapshot.docs.isNotEmpty) {
          // If a similar observation exists, ask the user if they want to replace it
          bool shouldReplace = await _showReplaceDialog();
          if (shouldReplace) {
            // Delete the old observation and add the new one
            await querySnapshot.docs.first.reference.delete();
            await _addObservation(parcelleId, notationName, noteText);
            isSaved = true;
          }
        } else {
          // If no similar observation exists, simply add the new observation
          await _addObservation(parcelleId, notationName, noteText);
          isSaved = true;
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Vous ne pouvez pas enregistrer des données vides.')),
        );
        return;
      }
    }

    // Clear the form and reset state if data is saved
    if (isSaved) {
      setState(() {
        _rows.clear();
        _hasUnsavedData = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Données enregistrées avec succès')),
      );
    }
  }

Future<void> _addObservation(String parcelleId, String notation, String note) async {
  await FirebaseFirestore.instance.collection('Observations').add({
    'Date_observation': Timestamp.now(),
    'Observateur': FirebaseFirestore.instance.doc('Observateurs/${_user.uid}'),
    'Parcelle': FirebaseFirestore.instance.doc('Parcelles/$parcelleId'),
    'Note': note,
    'Notations': notation,
  });
}

Future<bool> _showReplaceDialog() async {
  return await showDialog<bool>(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: const Text('Confirmation'),
        content: const Text('Une observation similaire existe déjà. Voulez-vous la remplacer ?'),
        actions: <Widget>[
          TextButton(
            child: const Text('Non'),
            onPressed: () {
              Navigator.of(context).pop(false);
            },
          ),
          TextButton(
            child: const Text('Oui'),
            onPressed: () {
              Navigator.of(context).pop(true);
            },
          ),
        ],
      );
    },
  ) ?? false; // Return false if the dialog is dismissed
}
 

  Future<void> _createNewObservateur(BuildContext context) {
    final TextEditingController observateurIdController =
        TextEditingController();
    final TextEditingController nomController = TextEditingController();
    final TextEditingController prenomController = TextEditingController();
    final TextEditingController emailController = TextEditingController();
    final TextEditingController lieuIdController = TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Créer un nouvel observateur'),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                TextField(
                  controller: observateurIdController,
                  decoration: const InputDecoration(
                    labelText: 'ID de l\'observateur (custom)',
                  ),
                ),
                TextField(
                  controller: nomController,
                  decoration: const InputDecoration(
                    labelText: 'Nom',
                  ),
                ),
                TextField(
                  controller: prenomController,
                  decoration: const InputDecoration(
                    labelText: 'Prénom',
                  ),
                ),
                TextField(
                  controller: emailController,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                  ),
                ),
                TextField(
                  controller: lieuIdController,
                  decoration: const InputDecoration(
                    labelText: 'ID du lieu référencé',
                  ),
                ),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Annuler'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Créer'),
              onPressed: () {
                final String observateurId =
                    observateurIdController.text.trim();
                final String nom = nomController.text.trim();
                final String prenom = prenomController.text.trim();
                final String email = emailController.text.trim();
                final String lieuId = lieuIdController.text.trim();

                if (observateurId.isNotEmpty &&
                    nom.isNotEmpty &&
                    prenom.isNotEmpty &&
                    email.isNotEmpty &&
                    lieuId.isNotEmpty) {
                  // Vérifiez si l'ID de l'observateur existe déjà
                  FirebaseFirestore.instance
                      .collection('Observateurs')
                      .doc(observateurId)
                      .get()
                      .then((docSnapshot) {
                    if (docSnapshot.exists) {
                      // Si l'observateur existe déjà, informer l'utilisateur
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content:
                                Text('L\'ID de l\'observateur existe déjà')),
                      );
                    } else {
                      // Si l'observateur n'existe pas, créez le nouvel observateur
                      FirebaseFirestore.instance
                          .collection('Observateurs')
                          .doc(observateurId)
                          .set({
                        'Nom': nom,
                        'Prenom': prenom,
                        'email': email,
                        'Lieux': [
                          FirebaseFirestore.instance
                              .collection('Lieux')
                              .doc(lieuId)
                        ],
                      }).then((value) {
                        Navigator.of(context).pop();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text('Observateur créé avec succès')),
                        );
                      }).catchError((error) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                              content: Text(
                                  'Erreur lors de la création de l\'observateur: $error')),
                        );
                      });
                    }
                  });
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text(
                            'Veuillez remplir tous les champs avec des valeurs valides')),
                  );
                }
              },
            ),
          ],
        );
      },
    );
    return Future<void>.value();
  }

  Future<void> _showChangeLocationConfirmationDialog(String newLocation) async {
    bool? shouldChangeLocation = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirmation'),
          content: const Text(
              'Vous êtes sur le point de quitter l\'observation en cours. Toutes les données non sauvegardées seront perdues. Voulez-vous quitter l\'observation ?'),
          actions: <Widget>[
            TextButton(
              child: const Text('Non'),
              onPressed: () {
                Navigator.of(context).pop(false);
              },
            ),
            TextButton(
              child: const Text('Oui'),
              onPressed: () {
                Navigator.of(context).pop(true);
              },
            ),
          ],
        );
      },
    );

    if (shouldChangeLocation ?? false) {
      setState(() {
        _lieuId = newLocation;
        _rows.clear();
        _hasUnsavedData = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Column(
                children: [
                  if (_user.email == 'faris.maisonneuve@wanadoo.fr') ...[
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: DropdownButton<String>(
                        isExpanded: true,
                        value: _lieuId,
                        items: _lieuxDropdownItems,
                        hint: const Text('Sélectionnez un lieu'),
                        onChanged: (value) {
                          if (_hasUnsavedData) {
                            _showChangeLocationConfirmationDialog(value!);
                          } else {
                            setState(() {
                              _lieuId = value;
                            });
                          }
                        },
                      ),
                    ),
                  ],
                  FutureBuilder<QuerySnapshot>(
                    future: FirebaseFirestore.instance
                        .collection('Parcelles')
                        .where('Lieu',
                            isEqualTo: FirebaseFirestore.instance
                                .doc('Lieux/$_lieuId'))
                        .get(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const CircularProgressIndicator();
                      } else if (snapshot.hasError) {
                        return Text('Error: ${snapshot.error}');
                      } else if (!snapshot.hasData ||
                          snapshot.data!.docs.isEmpty) {
                        return const Text(
                            'Aucune parcelle disponible pour ce lieu');
                      } else {
                        List<String> parcelles = snapshot.data!.docs
                            .map((doc) => doc['Numero_parcelle'].toString())
                            .toList();
                        return SingleChildScrollView(
                          child: Column(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  border: Border.all(color: Colors.grey),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Table(
                                  children: [
                                    TableRow(
                                      children: [
                                        const TableCell(
                                          child: Text(
                                            'Parcelles',
                                            style: TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                        const TableCell(
                                          child: Text(
                                            'Notations',
                                            style: TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                        const TableCell(
                                          child: Text(
                                            'Notes',
                                            style: TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                        TableCell(
                                          child: Container(),
                                        ),
                                      ],
                                    ),
                                    ..._rows.map((row) {
                                      return TableRow(
                                        children: [
                                          TableCell(
                                            child: Container(
                                              height: 56,
                                              alignment: Alignment.center,
                                              child: DropdownButton<String>(
                                                value: row['parcelle'],
                                                onChanged: (newValue) {
                                                  setState(() {
                                                    row['parcelle'] = newValue;
                                                    row['notation'] = null;
                                                  });
                                                },
                                                items: parcelles.map<
                                                        DropdownMenuItem<
                                                            String>>(
                                                    (String value) {
                                                  return DropdownMenuItem<
                                                      String>(
                                                    value: value,
                                                    child: Text(value),
                                                  );
                                                }).toList(),
                                              ),
                                            ),
                                          ),
                                          //... (autres parties du code)

TableCell(
  child: Container(
    height: 56,
    alignment: Alignment.center,
    child: row['parcelle'] != null
      ? FutureBuilder<List<Map<String, dynamic>>>(
          future: _getNotationData(row['parcelle']),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const CircularProgressIndicator();
            } else if (snapshot.hasError) {
              return Text('Error: ${snapshot.error}');
            } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return const Text('Aucune notation disponible pour cette parcelle');
            } else {
              List<Map<String, dynamic>> notationsData = snapshot.data!;
              return DropdownButton<String>(
                value: row['notation'],
                onChanged: (newValue) {
                  setState(() {
                    row['notation'] = newValue;
                    row['Note'] = TextEditingController();
                    // Réinitialisez le type de notation sélectionné car il peut avoir changé
                    row['selectedNotationType'] = notationsData.firstWhere(
                      (notation) => notation['nom'] == newValue,
                      orElse: () => {'type': null},
                    )['type'];
                  });
                },
                items: notationsData.map<DropdownMenuItem<String>>(
                  (Map<String, dynamic> notation) {
                    return DropdownMenuItem<String>(
                      value: notation['nom'],
                      child: Text(notation['nom']),
                    );
                  },
                ).toList(),
              );
            }
          },
        )
      : Container(),
  ),
),
TableCell(
  child: Container(
    height: 56,
    alignment: Alignment.center,
    child: row['selectedNotationType'] == 'fixe'
      ? DropdownButton<String>(
          value: row['Note'].text.isNotEmpty ? row['Note'].text : null,
          onChanged: (newValue) {
            setState(() {
              row['Note'].text = newValue ?? '';
            });
          },
          items: List<String>.generate(9, (index) => '${index + 1}')
              .map<DropdownMenuItem<String>>(
                (String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                },
              ).toList(),
        )
      : TextField(
          controller: row['Note'],
          decoration: const InputDecoration(
            hintText: 'Notes ici...',
            border: OutlineInputBorder(),
            hintStyle: TextStyle(fontSize: 13),
          ),
          maxLines: 1,
        ),
  ),
),

//... (autres parties du code)
                                          TableCell(
                                            child: IconButton(
                                              icon: const Icon(Icons.delete),
                                              onPressed: () {
                                                _deleteRow(_rows.indexOf(row));
                                              },
                                            ),
                                          ),
                                        ],
                                      );
                                    }),
                                  ],
                                ),
                              ),
                              Container(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 16),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 8),
                                        child: ElevatedButton(
                                          onPressed: _addRow,
                                          child:
                                              const Text('Ajouter une ligne'),
                                          style: ElevatedButton.styleFrom(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 16, vertical: 12),
                                            textStyle: const TextStyle(
                                                fontSize: 18,
                                                fontWeight: FontWeight.bold),
                                            shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(0)),
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 8),
                                        child: ElevatedButton(
                                          onPressed: _saveData,
                                          child: const Text(
                                              'Enregistrer les données'),
                                          style: ElevatedButton.styleFrom(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 16, vertical: 12),
                                            textStyle: const TextStyle(
                                                fontSize: 18,
                                                fontWeight: FontWeight.bold),
                                            shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(0)),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      }
                    },
                  ),
                ],
              ),
            ),
    );
  }
}