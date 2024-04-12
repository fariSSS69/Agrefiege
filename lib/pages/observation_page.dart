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

  Future<Map<String, dynamic>> _getNotationData(String parcelleId) async {
    final parcelleDoc =
        await FirebaseFirestore.instance.doc('Parcelles/$parcelleId').get();
    final parcelleRef = parcelleDoc.reference;

    final notationDoc = await FirebaseFirestore.instance
        .collection('Notations')
        .where('Parcelle', isEqualTo: parcelleRef)
        .get()
        .then((querySnapshot) => querySnapshot.docs.first);

    return notationDoc.data();
  }

  Future<void> _saveData() async {
    bool isSaved = false;
    for (int i = 0; i < _rows.length; i++) {
      final row = _rows[i];
      final parcelleId = row['parcelle'];
      final notation = row['notation'];
      final note = row['Note'].text;

      if (parcelleId != null && notation != null && note.isNotEmpty) {
        // Vérifiez si une observation similaire existe déjà
        final querySnapshot = await FirebaseFirestore.instance
            .collection('Observations')
            .where('Parcelle',
                isEqualTo:
                    FirebaseFirestore.instance.doc('Parcelles/$parcelleId'))
            .where('Notations', isEqualTo: notation)
            .get();

        if (querySnapshot.docs.isNotEmpty) {
          // Il existe déjà une observation similaire
          bool shouldReplace = await _showReplaceDialog();
          if (shouldReplace) {
            // Supprimez l'ancienne observation
            await querySnapshot.docs.first.reference.delete();
            // Ajoutez la nouvelle observation
            await _addObservation(parcelleId, notation, note);
            isSaved = true;
          }
        } else {
          // Aucune observation similaire, ajoutez simplement la nouvelle observation
          await _addObservation(parcelleId, notation, note);
          isSaved = true;
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content:
                  Text('Vous ne pouvez pas enregistrer des données vides.')),
        );
        return;
      }
    }

    if (isSaved) {
      setState(() {
        _rows.clear();
        _hasUnsavedData = false;
      });
      // Ne montrer le message de succès que si au moins une donnée a été enregistrée
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Données enregistrées avec succès')),
      );
    }
  }

  Future<bool> _showReplaceDialog() async {
    return await showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('Confirmation'),
              content: const Text(
                  'La parcelle ainsi que la notation existent déjà en base, voulez-vous la remplacer ?'),
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
        ) ??
        false; // Retourne false si l'utilisateur ferme la boîte de dialogue
  }

  Future<void> _addObservation(
      String parcelleId, String notation, String note) async {
    await FirebaseFirestore.instance.collection('Observations').add({
      'Date_observation': Timestamp.now(),
      'Observateur':
          FirebaseFirestore.instance.doc('Observateurs/${_user.uid}'),
      'Parcelle': FirebaseFirestore.instance.doc('Parcelles/$parcelleId'),
      'Note': note,
      'Notations': notation,
    });
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
                                          TableCell(
                                            child: Container(
                                              height: 56,
                                              alignment: Alignment.center,
                                              child: row['parcelle'] != null
                                                  ? FutureBuilder<
                                                      Map<String, dynamic>>(
                                                      future: _getNotationData(
                                                          row['parcelle']),
                                                      builder: (context,
                                                          notationSnapshot) {
                                                        if (notationSnapshot
                                                                .connectionState ==
                                                            ConnectionState
                                                                .waiting) {
                                                          return const CircularProgressIndicator();
                                                        } else if (notationSnapshot
                                                            .hasError) {
                                                          return Text(
                                                              'Error: ${notationSnapshot.error}');
                                                        } else if (notationSnapshot
                                                                    .data ==
                                                                null ||
                                                            notationSnapshot
                                                                .data!
                                                                .isEmpty) {
                                                          return const Text(
                                                              'Aucune notation disponible pour cette parcelle');
                                                        } else {
                                                          var notationData =
                                                              notationSnapshot
                                                                  .data!;
                                                          List<String>
                                                              notations =
                                                              notationData.keys
                                                                  .where((key) =>
                                                                      key !=
                                                                      'Parcelle')
                                                                  .toList();
                                                          return DropdownButton<
                                                              String>(
                                                            value:
                                                                row['notation'],
                                                            onChanged:
                                                                (newValue) {
                                                              setState(() {
                                                                row['notation'] =
                                                                    newValue;
                                                              });
                                                            },
                                                            items: notations.map<
                                                                DropdownMenuItem<
                                                                    String>>((String
                                                                value) {
                                                              return DropdownMenuItem<
                                                                  String>(
                                                                value: value,
                                                                child:
                                                                    Text(value),
                                                              );
                                                            }).toList(),
                                                          );
                                                        }
                                                      },
                                                    )
                                                  : Container(),
                                            ),
                                          ),
                                          TableCell(
                                            child: TextField(
                                              controller: row['Note'],
                                              decoration: const InputDecoration(
                                                hintText: 'Notes ici...',
                                                border: OutlineInputBorder(),
                                                hintStyle:
                                                    TextStyle(fontSize: 13),
                                              ),
                                              maxLines: 1,
                                            ),
                                          ),
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
                                  mainAxisAlignment: MainAxisAlignment.center,
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
                                            foregroundColor: Colors.black,
                                            backgroundColor: Colors.white,
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
                                            foregroundColor: Colors.black,
                                            backgroundColor: Colors.white,
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
