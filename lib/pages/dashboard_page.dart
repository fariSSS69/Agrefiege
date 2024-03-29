import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart' hide Table;
import 'package:flutter/widgets.dart' show Table;


class DashboardPage extends StatefulWidget {
  const DashboardPage({Key? key}) : super(key: key);

  @override
  _DashboardPageState createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<DocumentReference> _getLieuReferenceFromParcelle(DocumentReference parcelleRef) async {
    final parcelleSnapshot = await parcelleRef.get();
    final parcelleData = parcelleSnapshot.data() as Map<String, dynamic>;
    final lieuRef = parcelleData['Lieu'];
    return lieuRef;
  }

  Future<String> _getObservateurName(String observateurId) async {
  final observateurRef = _firestore.collection('Observateurs').doc(observateurId);
  final observateurSnapshot = await observateurRef.get();
  final observateurData = observateurSnapshot.data() as Map<String, dynamic>;
  return '${observateurData['Prenom']} ${observateurData['Nom']}';
}


  Future<String> _getParcelleName(DocumentReference parcelleRef) async {
    final parcelleSnapshot = await parcelleRef.get();
    final parcelleData = parcelleSnapshot.data() as Map<String, dynamic>;
    return parcelleData['Numero_parcelle'].toString();
  }

  Widget _buildObservationsList(DocumentReference lieuRef) {
    return StreamBuilder<List<QueryDocumentSnapshot>>(
      stream: _firestore
          .collection('Observations')
          .snapshots()
          .asyncMap((snapshot) async {
        List<QueryDocumentSnapshot> filteredDocs = [];
        for (final doc in snapshot.docs) {
          final parcelleRef = doc.data()['Parcelle'] as DocumentReference?;
          if (parcelleRef != null) {
            final lieuParcelleRef = await _getLieuReferenceFromParcelle(parcelleRef);

            if (lieuParcelleRef.path == lieuRef.path) {
              filteredDocs.add(doc);
            }
          }
        }
        return filteredDocs;
      }),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return CircularProgressIndicator();
        } else if (snapshot.hasError) {
          return Text('Error: ${snapshot.error}');
        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Text("Aucune observation n'a été trouvée pour le lieu. Veuillez en créer une nouvelle !");
        } else {
          return ListView(
            shrinkWrap: true,
            physics: ClampingScrollPhysics(),
            children: snapshot.data!.map((doc) {
              Map<String, dynamic> observation = doc.data() as Map<String, dynamic>;
              return ListTile(
                title: Text('Observation: ${doc.id}'),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Date: ${DateFormat.yMMMMd().format(observation['Date_observation'].toDate())}'),
                    Text('Notations: ${observation['Notations']}'),
                    Text('Note: ${observation['Note']}'),
                    FutureBuilder<String>(
                      future: _getObservateurName(observation['Observateur'].id),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return Text('Observateur: Chargement...');
                        } else if (snapshot.hasError) {
                          return Text('Observateur: Erreur pendant le chargement');
                        } else {
                          return Text('Observateur: ${snapshot.data}');
                        }
                      },
                    ),
                    FutureBuilder<String>(
                      future: _getParcelleName(observation['Parcelle']),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return Text('Parcelle: Chargement...');
                        } else if (snapshot.hasError) {
                          return Text('Parcelle: Erreur pendant le chargement');
                        } else {
                          return Text('Parcelle: ${snapshot.data}');
                        }
                      },
                    ),
                  ],
                ),
              );
            }).toList(),
          );
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: Center(
        child: FutureBuilder<QuerySnapshot>(
          future: _firestore.collection('Observateurs').get(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return CircularProgressIndicator();
            } else if (snapshot.hasError) {
              return Text('Error: ${snapshot.error}');
            } else if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return Text('No data found');
            } else {
              QueryDocumentSnapshot data = snapshot.data!.docs.first;
              List<DocumentReference>? lieuxRefs = (data['Lieux'] as List<dynamic>?)?.cast<DocumentReference>();
              if (lieuxRefs == null || lieuxRefs.isEmpty) {
                return Text('No locations assigned');
              } else {
                return Column(
                  children: lieuxRefs.map((lieuRef) {
                    return _buildObservationsList(lieuRef);
                  }).toList(),
                );
              }
            }
          },
        ),
      ),
    );
  }
}