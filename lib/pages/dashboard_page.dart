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
  bool _isAscending = true;
  int _sortColumnIndex = 0;

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
            'Date_observation': DateTime.fromMillisecondsSinceEpoch(observationData['Date_observation'].millisecondsSinceEpoch),
          };
        }).toList();
        allObservations.addAll(observations);
      }
    }

    setState(() {
      _observations = allObservations;
    });
  }

  void _sort<T>(Comparable<T> getField(Map<String, dynamic> observation), int columnIndex, bool ascending) {
    _observations.sort((a, b) {
      final aValue = getField(a);
      final bValue = getField(b);

      return ascending
          ? Comparable.compare(aValue, bValue)
          : Comparable.compare(bValue, aValue);
    });

    setState(() {
      _sortColumnIndex = columnIndex;
      _isAscending = ascending;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: _observations == null
            ? CircularProgressIndicator()
            : _observations.isEmpty
                ? Text('Aucune observation trouvée.')
                : SingleChildScrollView(
                    scrollDirection: Axis.vertical,
                    child: DataTable(
                      sortColumnIndex: _sortColumnIndex,
                      sortAscending: _isAscending,
                      columns: [
                        DataColumn(
                          label: Text('Date'),
                          onSort: (columnIndex, ascending) => _sort<DateTime>((observation) => observation['Date_observation'], columnIndex, ascending),
                        ),
                        DataColumn(
                          label: Text('Parcelle'),
                          onSort: (columnIndex, ascending) => _sort<int>((observation) => observation['Parcelle']['numero'], columnIndex, ascending),
                        ),
                        DataColumn(
                          label: Text('Notation'),
                          onSort: (columnIndex, ascending) => _sort<String>((observation) => observation['Notations'], columnIndex, ascending),
                        ),
                        DataColumn(
                          label: Text('Note'),
                          onSort: (columnIndex, ascending) => _sort<String>((observation) => observation['Note'], columnIndex, ascending),
                        ),
                      ],
                      rows: _observations
                          .map(
                            (observation) => DataRow(
                              cells: [
                                DataCell(Text(DateFormat('dd/MM/yyyy HH:mm').format(observation['Date_observation']))),
                                DataCell(Text(observation['Parcelle']['numero'].toString())),
                                DataCell(Text(observation['Notations'])),
                                DataCell(Text(observation['Note'])),
                              ],
                            ),
                          )
                          .toList(),
                    ),
                  ),
      ),
    );
  }
}
