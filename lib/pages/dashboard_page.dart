import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({Key? key}) : super(key: key);

  @override
  _DashboardPageState createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  late User _user;
  late List<Map<String, dynamic>> _observations;

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
  final lieux = userSnapshotData['Lieux'];

  List<Map<String, dynamic>> allObservations = [];

  for (final lieuRef in lieux) {
    final lieuSnapshot = await lieuRef.get();
    final parcellesSnapshot = await FirebaseFirestore.instance
        .collection('Parcelles')
        .where('Lieu', isEqualTo: lieuSnapshot.reference)
        .get();

    for (final parcelleDoc in parcellesSnapshot.docs) {
      final parcelleData = parcelleDoc.data();
      final observationsSnapshot = await FirebaseFirestore.instance
          .collection('Observations')
          .where('Parcelle', isEqualTo: parcelleDoc.reference)
          .get();

      final observations = observationsSnapshot.docs.map((doc) {
        final observationData = doc.data();
        return {
          ...observationData,
          'Parcelle': {'reference': observationData['Parcelle'], 'numero': parcelleData['Numero_parcelle']},
        };
      }).toList();
      allObservations.addAll(observations);
    }
  }

  setState(() {
    _observations = allObservations;
  });
}


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Tableau de bord')),
      body: Center(
        child: _observations == null
            ? CircularProgressIndicator()
            : _observations.isEmpty
                ? Text('Aucune observation trouvée.')
                : ListView.builder(
                    itemCount: _observations.length,
                    itemBuilder: (context, index) {
                      final observation = _observations[index];
                      final date = (observation['Date_observation'] as Timestamp).toDate();
                      final parcelle = observation['Parcelle'];
                      final notation = observation['Notations'];
                      final note = observation['Note'];
                      return Card(
                        child: ListTile(
                          title: Text('Observation ${index + 1}'),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Date: ${DateFormat('dd/MM/yyyy').format(date)}'),
                              Text('Parcelle: ${observation['Parcelle']['numero']}'),
                              Text('Notation: $notation'),
                              Text('Note: $note'),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
      ),
    );
  }
}
