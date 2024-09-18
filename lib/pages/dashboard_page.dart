import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:path_provider/path_provider.dart';
import 'package:csv/csv.dart';
import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server/gmail.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({Key? key}) : super(key: key);

  @override
  _DashboardPageState createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  late User _user;
  List<Map<String, dynamic>> _observations = [];
  List<Map<String, dynamic>> _filteredObservations = [];
  bool _isAscending = true;
  int _sortColumnIndex = 0;
  int _currentLimit = 2;
  final int _defaultLimit = 2;

  // Contrôleurs pour les filtres
  TextEditingController _lieuController = TextEditingController();
  DateTime? _startDate;
  DateTime? _endDate;

  @override
  void initState() {
    super.initState();
    _getUserData();
  }

  Future<void> _getUserData() async {
    FirebaseAuth auth = FirebaseAuth.instance;
    _user = auth.currentUser!;
    
    List<Map<String, dynamic>> allObservations = [];

    if (_user.email == 'faris.maisonneuve@wanadoo.fr') {
      final lieuxSnapshot = await FirebaseFirestore.instance.collection('Lieux').get();
      for (final lieuDoc in lieuxSnapshot.docs) {
        final parcellesSnapshot = await FirebaseFirestore.instance
            .collection('Parcelles')
            .where('Lieu', isEqualTo: lieuDoc.reference)
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
              'Parcelle': {
                'reference': observationData['Parcelle'],
                'numero': parcelleData['Numero_parcelle']
              },
              'Date_observation': DateTime.fromMillisecondsSinceEpoch(
                  observationData['Date_observation'].millisecondsSinceEpoch),
              'Lieu': lieuDoc.data()['Nom_lieu'],
            };
          }).toList();
          allObservations.addAll(observations);
        }
      }
    } else {
      final userSnapshot = await FirebaseFirestore.instance
          .collection('Observateurs')
          .where('email', isEqualTo: _user.email)
          .get();

      final userSnapshotData = userSnapshot.docs.first.data();
      final lieux = userSnapshotData['Lieux'];

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
              'Parcelle': {
                'reference': observationData['Parcelle'],
                'numero': parcelleData['Numero_parcelle']
              },
              'Date_observation': DateTime.fromMillisecondsSinceEpoch(
                  observationData['Date_observation'].millisecondsSinceEpoch),
              'Lieu': lieuSnapshot.data()['Nom_lieu'],
            };
          }).toList();
          allObservations.addAll(observations);
        }
      }
    }

    setState(() {
      _observations = allObservations;
      _filteredObservations = allObservations;
    });
  }

  void _sort<T>(Comparable<T> Function(Map<String, dynamic> observation) getField,
      int columnIndex, bool ascending) {
    _filteredObservations.sort((a, b) {
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

  void _filterObservations() {
    List<Map<String, dynamic>> filtered = _observations;

    if (_user.email == 'faris.maisonneuve@wanadoo.fr' && _lieuController.text.isNotEmpty) {
      filtered = filtered.where((observation) =>
        observation['Lieu'].toLowerCase().contains(_lieuController.text.toLowerCase())).toList();
    }

    if (_startDate != null && _endDate != null) {
      filtered = filtered.where((observation) {
        DateTime date = observation['Date_observation'];
        return date.isAfter(_startDate!) && date.isBefore(_endDate!);
      }).toList();
    } else if (_startDate != null) {
      filtered = filtered.where((observation) =>
        observation['Date_observation'].isAfter(_startDate!)).toList();
    } else if (_endDate != null) {
      filtered = filtered.where((observation) =>
        observation['Date_observation'].isBefore(_endDate!)).toList();
    }

    setState(() {
      _filteredObservations = filtered;
    });
  }

  Future<void> _sendEmailWithAttachment(String filePath, BuildContext context) async {
    final String email = _user.email ?? 'default@example.com'; // Email de l'utilisateur connecté

    String username = 'agrefiege@gmail.com'; // Email de l'expéditeur
    String password = 'emem bvrj qqea xbib'; // Mot de passe de l'application

    final smtpServer = gmail(username, password);

    final message = Message()
      ..from = Address(username, 'Faris') // Nom de l'expéditeur
      ..recipients.add(email) // Email du destinataire
      ..subject = 'Export des observations'
      ..text = 'Voici les observations exportées en pièce jointe.'
      ..attachments.add(FileAttachment(File(filePath))); // Attache le fichier exporté

    try {
      final sendReport = await send(message, smtpServer);
      print('Message envoyé : ' + sendReport.toString());
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text("E-mail envoyé avec succès à $email"),
      ));
    } on MailerException catch (e) {
      print('Échec de l\'envoi de l\'e-mail.');
      print(e.message);
      for (var p in e.problems) {
        print('Problème : ${p.code}: ${p.msg}');
      }
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text("Échec de l'envoi de l'e-mail."),
      ));
    }
  }

  Future<void> _exportToExcel() async {
  // Limite les observations exportées à celles actuellement visibles
  final List<List<dynamic>> rows = [
    ['Date', 'Lieu', 'Parcelle', 'Notation', 'Note']
  ]; // Header

  final visibleObservations = _filteredObservations.take(_currentLimit).toList();

  for (var observation in visibleObservations) {
    rows.add([
      DateFormat('dd/MM/yyyy HH:mm').format(observation['Date_observation']),
      observation['Lieu'],
      observation['Parcelle']['numero'].toString(),
      observation['Notations'],
      observation['Note'],
    ]);
  }

  final csvString = const ListToCsvConverter().convert(rows);
  final csvStringWithSemicolons = csvString.replaceAll(',', ';');

  // Prépare le fichier CSV
  final Directory? directory = await getTemporaryDirectory();
  final String directoryPath = directory!.path;
  final String filePath = '$directoryPath/observations_${DateTime.now()}.csv';

  final File file = File(filePath);
  await file.writeAsString(csvStringWithSemicolons);

  // Envoie l'email avec le fichier attaché
  await _sendEmailWithAttachment(filePath, context);
}


  void _loadMore() {
    setState(() {
      _currentLimit += 2;
    });
  }

  void _loadLess() {
    setState(() {
      _currentLimit = (_currentLimit - 2).clamp(_defaultLimit, _filteredObservations.length);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        actions: [
          PopupMenuButton<String>(
            onSelected: (String value) async {
              if (value == 'Exporter vers Excel') {
                await _exportToExcel();
              }
            },
            itemBuilder: (BuildContext context) => [
              PopupMenuItem(
                value: 'Exporter vers Excel',
                child: Text('Exporter vers Excel'),
              ),
            ],
          ),
          SizedBox(width: 10),
          IconButton(
            onPressed: _getUserData,
            icon: Icon(Icons.refresh),
            tooltip: 'Actualiser',
          ),
        ],
      ),
      body: Column(
        children: [
          if (_user.email == 'faris.maisonneuve@wanadoo.fr') ...[
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _lieuController,
                      decoration: InputDecoration(
                        labelText: 'Filtrer par lieu',
                      ),
                      onChanged: (value) {
                        _filterObservations();
                      },
                    ),
                  ),
                ],
              ),
            ),
          ],
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  ElevatedButton(
                    onPressed: () async {
                      DateTime? pickedDate = await showDatePicker(
                        context: context,
                        initialDate: DateTime.now(),
                        firstDate: DateTime(2000),
                        lastDate: DateTime(2101),
                      );
                      if (pickedDate != null && pickedDate != _startDate) {
                        setState(() {
                          _startDate = pickedDate;
                          _filterObservations();
                        });
                      }
                    },
                    child: Text(_startDate == null ? 'Choisir Date Début' : DateFormat('dd/MM/yyyy').format(_startDate!)),
                  ),
                  SizedBox(width: 10),
                  ElevatedButton(
                    onPressed: () async {
                      DateTime? pickedDate = await showDatePicker(
                        context: context,
                        initialDate: DateTime.now(),
                        firstDate: DateTime(2000),
                        lastDate: DateTime(2101),
                      );
                      if (pickedDate != null && pickedDate != _endDate) {
                        setState(() {
                          _endDate = pickedDate;
                          _filterObservations();
                        });
                      }
                    },
                    child: Text(_endDate == null ? 'Choisir Date Fin' : DateFormat('dd/MM/yyyy').format(_endDate!)),
                  ),
                  SizedBox(width: 10),
                  ElevatedButton(
                    onPressed: () {
                      _loadMore();
                    },
                    child: Text('Charger Plus'),
                  ),
                  SizedBox(width: 10),
                  ElevatedButton(
                    onPressed: () {
                      _loadLess();
                    },
                    child: Text('Charger Moins'),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: _filteredObservations.isEmpty
                ? const Text('Aucune observation trouvée.')
                : SingleChildScrollView(
                    scrollDirection: Axis.vertical,
                    child: FittedBox(
                      fit: BoxFit.fitWidth,
                      child: DataTable(
                        sortColumnIndex: _sortColumnIndex,
                        sortAscending: _isAscending,
                        columns: [
                          DataColumn(
                            label: const Text('Date'),
                            onSort: (columnIndex, ascending) => _sort<DateTime>(
                                (observation) => observation['Date_observation'],
                                columnIndex,
                                ascending),
                          ),
                          DataColumn(
                            label: const Text('Lieu'),
                            onSort: (columnIndex, ascending) => _sort<String>(
                                (observation) => observation['Lieu'],
                                columnIndex,
                                ascending),
                          ),
                          DataColumn(
                            label: const Text('Parcelle'),
                            onSort: (columnIndex, ascending) => _sort<int>(
                                (observation) => observation['Parcelle']['numero'],
                                columnIndex,
                                ascending),
                          ),
                          DataColumn(
                            label: const Text('Notation'),
                            onSort: (columnIndex, ascending) => _sort<String>(
                                (observation) => observation['Notations'],
                                columnIndex,
                                ascending),
                          ),
                          DataColumn(
                            label: const Text('Note'),
                            onSort: (columnIndex, ascending) => _sort<String>(
                                (observation) => observation['Note'],
                                columnIndex,
                                ascending),
                          ),
                        ],
                        rows: _filteredObservations
                            .take(_currentLimit)
                            .map(
                              (observation) => DataRow(
                                cells: [
                                  DataCell(Text(DateFormat('dd/MM/yyyy HH:mm')
                                      .format(observation['Date_observation']))),
                                  DataCell(Text(observation['Lieu'])),
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
          ),
        ],
      ),
    );
  }
}
