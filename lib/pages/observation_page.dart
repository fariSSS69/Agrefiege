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
  String? _imageUrl;

  // Récupération de l'image
  Future<String?> _getImageUrl(String lieuId) async {
    final DocumentSnapshot<Map<String, dynamic>> lieuSnapshot =
        await FirebaseFirestore.instance.collection('Lieux').doc(lieuId).get();

    if (lieuSnapshot.exists) {
      return lieuSnapshot.data()?['fileUrl'];
    } else {
      return null;
    }
  }

  Future<void> _getImageForLieu(String lieuId) async {
    final imageUrl = await _getImageUrl(lieuId);
    setState(() {
      _imageUrl = imageUrl;
    });
  }

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

    setState(() {
      _lieuId = userSnapshotData['Lieux'][0].id;

      // Vérification que _lieuId n'est pas nul avant de récupérer l'image
      if (_lieuId != null) {
        _getImageForLieu(_lieuId!);
      }
    });

    // Si l'utilisateur est l'administrateur, chargez tous les lieux
    if (_user.email == 'dours.ollivier0822@orange.fr') {
      final lieuxSnapshot =
          await FirebaseFirestore.instance.collection('Lieux').get();
      setState(() {
        _lieuxDropdownItems = lieuxSnapshot.docs
            .map((doc) => DropdownMenuItem<String>(
                  value: doc.id,
                  child: Text(doc.data()['Nom_lieu'] as String),
                ))
            .toList();

        // Vérifier que _lieuxDropdownItems n'est pas nul ou vide avant d'accéder à ses éléments
        if (_lieuxDropdownItems != null && _lieuxDropdownItems!.isNotEmpty) {
          _lieuId = _lieuxDropdownItems!.first.value;
          if (_lieuId != null) {
            _getImageForLieu(_lieuId!);
          }
        }
      });
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
        'selectedNotationType': null,
        'noteController': TextEditingController(), // Champ de texte pour la note
          'isSelected': false,  // Assurez-vous d'initialiser cela
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

  Future<List<Map<String, dynamic>>> _getAmplitudes() async {
    final QuerySnapshot<Map<String, dynamic>> snapshot =
        await FirebaseFirestore.instance.collection('Amplitudes').get();
    return snapshot.docs.map((doc) => doc.data()).toList();
  }

  Future<List<Map<String, dynamic>>> _getNotationData(String parcelleId) async {
    final DocumentSnapshot<Map<String, dynamic>> parcelleSnapshot =
        await FirebaseFirestore.instance.collection('Parcelles').doc(parcelleId).get();

    List<Map<String, dynamic>> notationsWithTypes = [];

    if (parcelleSnapshot.exists) {
      List<dynamic> notations = parcelleSnapshot.data()!['Notations'];

      for (String nomNotation in notations) {
        final DocumentSnapshot<Map<String, dynamic>> notationSnapshot =
            await FirebaseFirestore.instance.collection('Notations').doc(nomNotation).get();

        if (notationSnapshot.exists) {
          var notationData = notationSnapshot.data()!;
          print('Fetched Notation Data for $nomNotation: $notationData'); // Debug: Print fetched data
          notationsWithTypes.add({
            'nom': nomNotation,
            'type': notationData['type'],
            'alias': notationData['alias'] // Add alias to the data
          });
        } else {
          print('Notation $nomNotation does not exist.');
        }
      }
    } else {
      print('Parcelle with ID $parcelleId does not exist.');
    }

    return notationsWithTypes;
  }
void _addRowsForParcelle(String parcelleId) async {
  final notationData = await _getNotationData(parcelleId);
  setState(() {
    _rows.clear(); // Efface les lignes existantes
    for (var notation in notationData) {
      _rows.add({
        'parcelle': parcelleId,
        'notation': notation['nom'],
        'selectedNotationType': null,
        'noteController': TextEditingController(),
        'Note': TextEditingController(),
        'selected': false, // Ajout de la case à cocher
      });
    }
    _hasUnsavedData = true;
  });
}

// Méthode pour mettre à jour l'observation
Future<void> _updateObservation(String parcelleId, String notationName, String noteText) async {
  final docRef = FirebaseFirestore.instance.collection('Observations')
      .where('Parcelle', isEqualTo: FirebaseFirestore.instance.doc('Parcelles/$parcelleId'))
      .where('Notations', isEqualTo: notationName)
      .limit(1); // Limit to 1 document

  final QuerySnapshot<Map<String, dynamic>> snapshot = await docRef.get();
  if (snapshot.docs.isNotEmpty) {
    final documentId = snapshot.docs.first.id; // Get the document ID
    await FirebaseFirestore.instance.collection('Observations').doc(documentId).update({
      'Note': noteText, // Remplacez par le nom de votre colonne pour la note
    });
  }
}

  Future<bool> _doesObservationExist(String parcelleId, String notationName) async {
    final QuerySnapshot<Map<String, dynamic>> snapshot = await FirebaseFirestore.instance
        .collection('Observations')
        .where('Parcelle', isEqualTo: FirebaseFirestore.instance.doc('Parcelles/$parcelleId'))
        .where('Notations', isEqualTo: notationName)
        .get();
    return snapshot.docs.isNotEmpty;
  }

Future<void> _saveData() async {
  bool isSaved = false;

  for (int i = 0; i < _rows.length; i++) {
    final row = _rows[i];

    // Vérifiez si la case est cochée
    if (row['isSelected'] ?? false) {  
      final parcelleId = row['parcelle'];
      final notationName = row['notation'];
      final TextEditingController noteController = 
          row['selectedNotationType'] == 'libre' ? 
          row['noteController'] : row['Note'];
      final String noteText = noteController.text;

      // Imprimer les valeurs récupérées pour débogage
      print('Processing observation for parcelle: $parcelleId, notation: $notationName, note: $noteText');

      if (parcelleId != null && notationName != null && noteText.isNotEmpty) {
        // Ajoutez une nouvelle observation sans vérification d'existence
        await _addObservation(parcelleId, notationName, noteText);
        print('Added new observation for parcelle: $parcelleId, notation: $notationName');
        isSaved = true;
      }
    }
  }

  if (isSaved) {
    setState(() {
      _hasUnsavedData = false; // Réinitialisez l'état après l'enregistrement
      _rows.clear(); // Vider les lignes après un enregistrement réussi
    });
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Données enregistrées avec succès')));
  } else {
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Aucune donnée sélectionnée à enregistrer')));
  }
}





  Future<void> _addObservation(String parcelleId, String notation, String note) async {
  // Ajoutez simplement la nouvelle observation à Firestore sans vérification de remplacement
  await FirebaseFirestore.instance.collection('Observations').add({
    'Date_observation': Timestamp.now(),
    'Observateur': FirebaseFirestore.instance.doc('Observateurs/${_user.uid}'),
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

  Future<bool> _showReplaceDialog() async {
    return await showDialog<bool>(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('Confirmation'),
              content: const Text('Une observation similaire existe déjà. Voulez-vous la remplacer ?'),
              actions: <Widget>[
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop(false);
                  },
                  child: const Text('Non'),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop(true);
                  },
                  child: const Text('Oui'),
                ),
              ],
            );
          },
        ) ??
        false;
  }
  
@override
Widget build(BuildContext context) {
  return Scaffold(
    appBar: AppBar(),
    body: SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Afficher l'image uniquement pour les observateurs
          if (_user.email != 'dours.ollivier0822@orange.fr') ...[
            _imageUrl != null
                ? InteractiveViewer(
                    child: Image.network(
                      _imageUrl!,
                      height: 300, // Ajuste la hauteur selon tes besoins
                      width: double.infinity,
                      fit: BoxFit.contain,
                    ),
                  )
                : const Text('Aucune image disponible'), // Message si l'image n'est pas encore chargée
          ],

          if (_user.email == 'dours.ollivier0822@orange.fr') ...[
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
                .where('Lieu', isEqualTo: FirebaseFirestore.instance.doc('Lieux/$_lieuId'))
                .get(),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Text('Erreur: ${snapshot.error}');
              } else if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return const Text('Aucune parcelle disponible pour ce lieu');
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
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                const TableCell(
                                  child: Text(
                                    'Notations',
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                const TableCell(
                                  child: Text(
                                    'Notes',
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                const TableCell(
                                  child: Text(
                                    'Choisir',
                                    style: TextStyle(
                                      fontSize: 15,
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
                                            row['notation'] = null; // Réinitialise la notation lorsque la parcelle change
                                            // Ajoute toutes les notations associées à la nouvelle parcelle
                                            _addRowsForParcelle(newValue!); // Appelle la méthode pour ajouter les notations
                                          });
                                        },
                                        items: parcelles.map<DropdownMenuItem<String>>(
                                          (String value) {
                                            return DropdownMenuItem<String>(
                                              value: value,
                                              child: Text(value),
                                            );
                                          },
                                        ).toList(),
                                      ),
                                    ),
                                  ),
                                  TableCell(
                                    child: Container(
                                      height: 56,
                                      alignment: Alignment.center,
                                      child: row['parcelle'] != null
                                          ? FutureBuilder<List<Map<String, dynamic>>>(
                                              future: _getNotationData(row['parcelle']),
                                              builder: (context, snapshot) {
                                                if (snapshot.hasError) {
                                                  return Text('Erreur: ${snapshot.error}');
                                                } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                                                  return Container();
                                                } else {
                                                  List<Map<String, dynamic>> notationsData = snapshot.data!;
                                                  return DropdownButton<String>(
                                                    value: row['notation'],
                                                    onChanged: (newValue) {
                                                      setState(() {
                                                        row['notation'] = newValue;
                                                        row['Note'] = TextEditingController();
                                                        row['selectedNotationType'] = notationsData.firstWhere(
                                                          (notation) => notation['nom'] == newValue,
                                                          orElse: () => {'type': null},
                                                        )['type'];
                                                        row['isSelected'] = true; // Coche automatiquement "Choisir"
                                                      });
                                                    },
                                                    items: notationsData.map<DropdownMenuItem<String>>(
                                                      (Map<String, dynamic> notation) {
                                                        return DropdownMenuItem<String>(
                                                          value: notation['nom'],
                                                          child: ConstrainedBox(
                                                            constraints: BoxConstraints(
                                                              maxWidth: 50, // Ajuste la largeur maximale de la liste déroulante de Notations
                                                            ),
                                                            child: Tooltip(
                                                              message: (notation['alias'] != null && notation['alias']!.isNotEmpty)
                                                                  ? '${notation['nom']} (${notation['alias']})'
                                                                  : notation['nom'],
                                                              child: Text(
                                                                (notation['alias'] != null && notation['alias']!.isNotEmpty)
                                                                    ? '${notation['nom']} (${notation['alias']})'
                                                                    : notation['nom'],
                                                                overflow: TextOverflow.ellipsis,
                                                              ),
                                                            ),
                                                          ),
                                                        );
                                                      },
                                                    ).toList(),
                                                    isExpanded: true, // Permet à DropdownButton d'occuper toute la largeur disponible
                                                  );
                                                }
                                              },
                                            )
                                          : Container(),
                                    ),
                                  ),
                                    TableCell(
  child: (row['notation'] == null || row['notation'] == '')
      ? Container() // Gestion des autres cas où row['notation'] est null
      : FutureBuilder<List<Map<String, dynamic>>>(
          future: _getAmplitudes(), // Appel à la méthode pour obtenir les amplitudes
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return Center(child: Text('Erreur de chargement des amplitudes'));
            }

            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return Container(); // Renvoie un Container vide si aucune donnée n'est disponible
            }

            final List<Map<String, dynamic>> amplitudes = snapshot.data!;
            final String selectedNotation = row['notation'] ?? ''; // S'assurer que c'est une chaîne

            // Vérifiez si la notation est de type libre
            if (row['selectedNotationType'] == 'libre' || selectedNotation.contains('libre')) {
              // Afficher un champ de texte pour les notations libres
              final TextEditingController noteController = row['Note'];
              return Container(
                height: 56,
                alignment: Alignment.center,
                child: TextField(
                  controller: noteController,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(),
                    hintText: 'Entrez la note',
                  ),
                  keyboardType: TextInputType.text,
                  onChanged: (text) {
                    setState(() {
                      row['isSelected'] = text.isNotEmpty; // Coche automatiquement "Choisir" si une note est saisie
                    });
                  },
                ),
              );
            } else {
              // Si le type n'est pas libre, recherchez l'amplitude correspondante
              final amplitude = amplitudes.firstWhere(
                (amp) => amp['alias_notation'] == selectedNotation,
                orElse: () => {'valeur_min': 0, 'valeur_max': 11, 'alias_min': '', 'alias_max': ''},
              );

              final int min = amplitude['valeur_min'] as int;
              final int max = amplitude['valeur_max'] as int;
              final String aliasMin = amplitude['alias_min'] as String;
              final String aliasMax = amplitude['alias_max'] as String;

              final TextEditingController noteController = row['Note'];

              return Container(
                height: 56,
                alignment: Alignment.center,
                child: DropdownButton<String>(
                  value: noteController.text.isNotEmpty ? noteController.text : null,
                  onChanged: (newValue) {
                    setState(() {
                      noteController.text = newValue ?? '';
                      row['isSelected'] = true; // Coche automatiquement "Choisir"
                    });
                  },
                  items: List<String>.generate(max - min + 1, (index) => '${min + index}')
                      .map<DropdownMenuItem<String>>(
                        (String value) {
                          final int intValue = int.parse(value);
                          final String displayText = intValue == min
                              ? '$value ($aliasMin)'
                              : intValue == max
                                  ? '$value ($aliasMax)'
                                  : value;

                          return DropdownMenuItem<String>(
                            value: value,
                            child: ConstrainedBox(
                              constraints: BoxConstraints(
                                maxWidth: 50, // Ajuste la largeur maximale du DropdownButton
                              ),
                              child: Text(
                                displayText,
                                overflow: TextOverflow.ellipsis, // Tronque le texte si nécessaire
                              ),
                            ),
                          );
                        },
                      ).toList(),
                  isExpanded: true, // Permet au DropdownButton de s'étendre sur toute la largeur disponible
                ),
              );
            }
          },
        ),
),

                                  TableCell(
                                    child: Checkbox(
                                      value: row['isSelected'] ?? false, // Utiliser un champ booléen pour l'état de la case à cocher
                                      onChanged: (bool? value) {
                                        setState(() {
                                          row['isSelected'] = value ?? false; // Mettre à jour l'état de la case à cocher, s'assurer que c'est toujours un booléen
                                          print('Row ${_rows.indexOf(row)} selected: ${row['isSelected']}'); // Imprimez l'état
                                        });
                                      },
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
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        child: Row(
                          children: [
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 8),
                                child: ElevatedButton(
                                  onPressed: _addRow,
                                  child: const Text('Ajouter une ligne'),
                                  style: ElevatedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                    textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(0)),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 8),
                                child: ElevatedButton(
                                  onPressed: _saveData,
                                  child: const Text('Enregistrer les données'),
                                  style: ElevatedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                    textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(0)),
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