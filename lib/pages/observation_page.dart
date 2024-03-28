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
        'notes': TextEditingController(),
      });
    });
  }

  Future<Map<String, dynamic>> _getNotationData(String parcelleId) async {
    final notationDoc = await FirebaseFirestore.instance
        .collection('Notations')
        .where('Parcelle',
            isEqualTo: FirebaseFirestore.instance.doc('Parcelles/$parcelleId'))
        .get()
        .then((querySnapshot) => querySnapshot.docs.first);

    return notationDoc.data() as Map<String, dynamic>;
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
                    return Column(
                      children: [
                        Table(
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
                                          ? FutureBuilder<Map<String, dynamic>>(
                                              future: _getNotationData(
                                                  row['parcelle']),
                                              builder:
                                                  (context, notationSnapshot) {
                                                if (notationSnapshot
                                                        .connectionState ==
                                                    ConnectionState.waiting) {
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
                                                      notationSnapshot.data!;
                                                  List<String> notations =
                                                      notationData.keys
                                                          .where((key) =>
                                                              key !=
                                                              'Parcelle') // Filtrer l'élément "Parcelle"
                                                          .toList();
                                                  return DropdownButton<String>(
                                                    value: row['notation'],
                                                    onChanged: (newValue) {
                                                      setState(() {
                                                        row['notation'] =
                                                            newValue;
                                                      });
                                                    },
                                                    items: notations.map<
                                                            DropdownMenuItem<
                                                                String>>(
                                                        (String value) {
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
                                      controller: row['notes'],
                                      decoration: InputDecoration(
                                        hintText: 'Entrez vos notes ici...',
                                        border: OutlineInputBorder(),
                                      ),
                                      maxLines: 1,
                                    ),
                                  ),
                                ],
                              );
                            }).toList(),
                          ],
                        ),
                        ElevatedButton(
                          onPressed: _addRow,
                          child: Text('Ajouter une ligne'),
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
