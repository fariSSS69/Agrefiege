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
  List<Map<String, dynamic>> _rows = [];

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
    setState(() {});
  }

  void _addRow() {
    setState(() {
      _rows.add({
        'parcelle': null,
        'notation': null,
        'Note': TextEditingController(),
      });
    });
  }

  void _deleteRow(int index) {
    setState(() {
      _rows.removeAt(index);
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

    return notationDoc.data() as Map<String, dynamic>;
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
          SnackBar(
              content:
                  Text('Vous ne pouvez pas enregistrer des données vides.')),
        );
        return;
      }
    }

    if (isSaved) {
      // Ne montrer le message de succès que si au moins une donnée a été enregistrée
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Données enregistrées avec succès')),
      );
    }
  }

  Future<bool> _showReplaceDialog() async {
    return await showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Text('Confirmation'),
              content: Text(
                  'La parcelle ainsi que la notation existent déjà en base, voulez-vous la remplacer ?'),
              actions: <Widget>[
                TextButton(
                  child: Text('Non'),
                  onPressed: () {
                    Navigator.of(context).pop(false);
                  },
                ),
                TextButton(
                  child: Text('Oui'),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
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
                    return SingleChildScrollView(
                      child: Column(
                        children: [
                          Container(
                            padding: EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Table(
                              children: [
                                TableRow(
                                  children: [
                                    TableCell(
                                      child: Text(
                                        'Parcelles',
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    TableCell(
                                      child: Text(
                                        'Notations',
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    TableCell(
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
                                            items: parcelles
                                                .map<DropdownMenuItem<String>>(
                                                    (String value) {
                                              return DropdownMenuItem<String>(
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
                                                      return CircularProgressIndicator();
                                                    } else if (notationSnapshot
                                                        .hasError) {
                                                      return Text(
                                                          'Error: ${notationSnapshot.error}');
                                                    } else if (notationSnapshot
                                                                .data ==
                                                            null ||
                                                        notationSnapshot
                                                            .data!.isEmpty) {
                                                      return Text(
                                                          'Aucune notation disponible pour cette parcelle');
                                                    } else {
                                                      var notationData =
                                                          notationSnapshot
                                                              .data!;
                                                      List<String> notations =
                                                          notationData.keys
                                                              .where((key) =>
                                                                  key !=
                                                                  'Parcelle')
                                                              .toList();
                                                      return DropdownButton<
                                                          String>(
                                                        value: row['notation'],
                                                        onChanged: (newValue) {
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
                                                            child: Text(value),
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
                                          decoration: InputDecoration(
                                            hintText: 'Entrez vos notes ici...',
                                            border: OutlineInputBorder(),
                                          ),
                                          maxLines: 1,
                                        ),
                                      ),
                                      TableCell(
                                        child: IconButton(
                                          icon: Icon(Icons.delete),
                                          onPressed: () {
                                            _deleteRow(_rows.indexOf(row));
                                          },
                                        ),
                                      ),
                                    ],
                                  );
                                }).toList(),
                              ],
                            ),
                          ),
                          Container(
                            padding: EdgeInsets.symmetric(vertical: 16),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    primary: Colors
                                        .white, // Couleur de fond du bouton
                                    onPrimary: Colors
                                        .black, // Couleur du texte lorsque le bouton est pressé
                                    padding: EdgeInsets.symmetric(
                                        horizontal: 16,
                                        vertical: 12), // Rembourrage du bouton
                                    textStyle: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight
                                            .bold), // Style du texte du bouton
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(
                                          0), // Pas de bord arrondi
                                    ),
                                  ),
                                  onPressed: _addRow,
                                  child: Text('Ajouter une ligne'),
                                ),
                                SizedBox(width: 16),
                                ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    primary: Colors
                                        .white, // Couleur de fond du bouton
                                    onPrimary: Colors
                                        .black, // Couleur du texte lorsque le bouton est pressé
                                    padding: EdgeInsets.symmetric(
                                        horizontal: 16,
                                        vertical: 12), // Rembourrage du bouton
                                    textStyle: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight
                                            .bold), // Style du texte du bouton
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(
                                          0), // Pas de bord arrondi
                                    ),
                                  ),
                                  onPressed: _saveData,
                                  child: Text('Enregistrer les données'),
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
      ),
    );
  }
}
