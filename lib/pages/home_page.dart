import 'package:agrefiege/pages/dashboard_page.dart';
import 'package:agrefiege/pages/observation_page.dart';
import 'package:agrefiege/pages/settings_page.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:motion_tab_bar/MotionTabBarController.dart';
import 'package:motion_tab_bar/MotionTabBar.dart';
import 'package:flutter/services.dart';


void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Gestion de Parcelles',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  final String? userEmail;

  const HomePage({Key? key, this.userEmail}) : super(key: key);

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with TickerProviderStateMixin {
  late MotionTabBarController _tabController;
  late bool isAdmin;
  int nombreParcelles = 0;
  List<Map<String, dynamic>> availableLieux = [];
  List<Map<String, dynamic>> availableNotations = [];
  String selectedLieuId = '';
  List<String> selectedNotations = [];
  String _userEmail = '';

  late CollectionReference<Map<String, dynamic>> parcellesCollection;
  late CollectionReference<Map<String, dynamic>> notationsCollection;

  @override
  void initState() {
    super.initState();
    _fetchLieux();
    _fetchNotations();
    _userEmail = FirebaseAuth.instance.currentUser?.email ?? '';
    isAdmin = _userEmail == 'faris.maisonneuve@wanadoo.fr' ||
        FirebaseAuth.instance.currentUser?.email ==
            'faris.maisonneuve@wanadoo.fr';
    _tabController =
        MotionTabBarController(length: isAdmin ? 4 : 4, vsync: this);
    parcellesCollection = FirebaseFirestore.instance.collection('Parcelles');
    notationsCollection =
        FirebaseFirestore.instance.collection('Notations');
  }

  void _fetchLieux() {
    FirebaseFirestore.instance.collection('Lieux').get().then((snapshot) {
      final List<Map<String, dynamic>> lieuxData = snapshot.docs
          .map((doc) => {'id': doc.id, 'nom': doc['Nom_lieu']})
          .toList();
      setState(() {
        availableLieux = lieuxData;
        if (availableLieux.isNotEmpty) {
          selectedLieuId = availableLieux[0]['id'];
        }
      });
    }).catchError((error) {
      // Handle error
    });
  }

  void _fetchNotations() {
    FirebaseFirestore.instance.collection('Notations').get().then((snapshot) {
      final List<Map<String, dynamic>> notationsData = snapshot.docs
          .map((doc) => {'nom': doc['nom'], 'type': doc['type']})
          .toList();
      setState(() {
        availableNotations = notationsData;
      });
    }).catchError((error) {
      // Handle error
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final List<IconData> adminTabs = [
      Icons.home,
      Icons.dashboard,
      Icons.visibility,
      Icons.settings,
    ];

    final List<IconData> observerTabs = [
      Icons.home,
      Icons.dashboard,
      Icons.visibility,
      Icons.settings,
    ];

    final List<Widget> adminPages = [
      _buildAdminHomeView(context),
      DashboardPage(),
      ObservationPage(),
      SettingsPage(),
    ];

    final List<Widget> observerPages = [
      _buildObserverView(context),
      DashboardPage(),
      ObservationPage(),
      SettingsPage(),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(isAdmin ? '' : ''),
        actions: isAdmin
            ? [
                IconButton(
                  icon: const Icon(Icons.add_location),
                  onPressed: () => _addNewLieu(context),
                ),
                IconButton(
                  icon: const Icon(Icons.add_circle_outline),
                  onPressed: () => _addNewParcelle(context),
                ),
                IconButton(
                  icon: const Icon(Icons.person_add),
                  onPressed: () => _createNewObservateur(context),
                ),
                IconButton(
                  icon: const Icon(Icons.note_add),
                  onPressed: () => _addNewNotation(context),
                ),
                IconButton(
  icon: Icon(Icons.add_circle_outline, color: Colors.blue),
  onPressed: () => _addNewAmplitude(context),
),
              ]
            : null,
      ),
      bottomNavigationBar: MotionTabBar(
        labels: isAdmin
            ? ["Accueil", "Tableau de bord", "Observation", "Paramètre"]
            : ["Accueil", "Tableau de bord", "Observation", "Paramètre"],
        initialSelectedTab: isAdmin ? "Accueil" : "Accueil",
        tabIconColor: Colors.blue,
        tabSelectedColor: Colors.blueAccent,
        onTabItemSelected: (int value) {
          setState(() {
            _tabController.index = value;
          });
        },
        icons: isAdmin ? adminTabs : observerTabs,
        textStyle: const TextStyle(color: Colors.blueAccent),
        controller: _tabController,
      ),
      body: IndexedStack(
        index: _tabController.index,
        children: isAdmin ? adminPages : observerPages,
      ),
    );
  }

 Widget _buildAdminHomeView(BuildContext context) {
  return SingleChildScrollView(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ExpansionTile(
          title: Center(
            child: Text(
              'Lieux & Parcelles',
              style: TextStyle(color: Theme.of(context).primaryColor), // Utilisation de la couleur primaire de l'application
            ),
          ),
          childrenPadding: EdgeInsets.symmetric(horizontal: 16),
          collapsedBackgroundColor: Colors.grey[200],
          children: [
            ...availableLieux.map((lieu) {
              return StreamBuilder<QuerySnapshot>(
                stream: parcellesCollection
                    .where('Lieu', isEqualTo: FirebaseFirestore.instance.doc('Lieux/${lieu['id']}'))
                    .snapshots(),
                builder: (context, parcellesSnapshot) {
                  if (parcellesSnapshot.connectionState == ConnectionState.waiting) {
                    return Center(child: CircularProgressIndicator());
                  }
                  if (parcellesSnapshot.hasError) {
                    return Center(child: Text('Erreur: ${parcellesSnapshot.error}'));
                  }

                  final parcelles = parcellesSnapshot.data!.docs;

                  return ExpansionTile(
                    title: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Text(lieu['nom']),
                            SizedBox(width: 8),
                            IconButton(
                              icon: Icon(Icons.edit),
                              onPressed: () => _editLieu(context, lieu['id'], lieu['nom'], parcelles.length),
                            ),
                          ],
                        ),
                        Text('(${parcelles.length} parcelles)'),
                      ],
                    ),
                    childrenPadding: EdgeInsets.symmetric(horizontal: 16),
                    collapsedBackgroundColor: Colors.grey[200],
                    children: [
                      ListView.separated(
                        shrinkWrap: true,
                        itemCount: parcelles.length,
                        separatorBuilder: (context, index) => Divider(),
                        itemBuilder: (context, index) {
                          return ListTile(
                            title: Text('Numéro de parcelle: ${parcelles[index]['Numero_parcelle']}'),
                            onTap: () => _editParcelle(context, parcelles[index].id, parcelles[index].data() as Map<String, dynamic>),
                          );
                        },
                      ),
                    ],
                  );
                },
              );
            }).toList(),
          ],
        ),
        SizedBox(height: 20),
        ExpansionTile(
          title: Center(
            child: Text(
              'Liste des Notations',
              style: TextStyle(color: Theme.of(context).primaryColor), // Utilisation de la couleur primaire de l'application
            ),
          ),
          childrenPadding: EdgeInsets.symmetric(horizontal: 16),
          collapsedBackgroundColor: Colors.grey[200],
          children: [
            StreamBuilder<QuerySnapshot>(
              stream: notationsCollection.snapshots(),
              builder: (context, notationsSnapshot) {
                if (notationsSnapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }
                if (notationsSnapshot.hasError) {
                  return Center(child: Text('Erreur: ${notationsSnapshot.error}'));
                }

                final notations = notationsSnapshot.data!.docs;

                return ListView.separated(
                  shrinkWrap: true,
                  itemCount: notations.length,
                  separatorBuilder: (context, index) => Divider(),
                  itemBuilder: (context, index) {
                    return _buildNotationItem(context, notations[index]);
                  },
                );
              },
            ),
          ],
        ),
        SizedBox(height: 20),
        ExpansionTile(
          title: Center(
            child: Text(
              'Liste des Observateurs',
              style: TextStyle(color: Theme.of(context).primaryColor),
            ),
          ),
          childrenPadding: EdgeInsets.symmetric(horizontal: 16),
          collapsedBackgroundColor: Colors.grey[200],
          children: [
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('Observateurs').snapshots(),
              builder: (context, observateursSnapshot) {
                if (observateursSnapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }
                if (observateursSnapshot.hasError) {
                  return Center(child: Text('Erreur: ${observateursSnapshot.error}'));
                }

                final observateurs = observateursSnapshot.data!.docs;

                return ListView.separated(
                  shrinkWrap: true,
                  itemCount: observateurs.length,
                  separatorBuilder: (context, index) => Divider(),
                  itemBuilder: (context, index) {
                    final observateur = observateurs[index];
                    return ListTile(
                      title: Text('${observateur['Nom']} ${observateur['Prenom']}'),
                      subtitle: Text('Email: ${observateur['email']}'),
                      trailing: IconButton(
                        icon: Icon(Icons.edit),
                        onPressed: () => _editObservateur(context, observateur.id, observateur),
                      ),
                    );
                  },
                );
              },
            ),
          ],
        ),
          SizedBox(height: 20),

        // Liste des Amplitudes
        ExpansionTile(
          title: Center(
            child: Text(
              'Liste des Amplitudes',
              style: TextStyle(color: Theme.of(context).primaryColor),
            ),
          ),
          childrenPadding: EdgeInsets.symmetric(horizontal: 16),
          collapsedBackgroundColor: Colors.grey[200],
          children: [
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('Amplitudes').snapshots(),
              builder: (context, amplitudesSnapshot) {
                if (amplitudesSnapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }
                if (amplitudesSnapshot.hasError) {
                  return Center(child: Text('Erreur: ${amplitudesSnapshot.error}'));
                }

                final amplitudes = amplitudesSnapshot.data!.docs;

                return ListView.separated(
                  shrinkWrap: true,
                  itemCount: amplitudes.length,
                  separatorBuilder: (context, index) => Divider(),
                  itemBuilder: (context, index) {
                    final amplitude = amplitudes[index];
                    return ListTile(
                      title: Text('${amplitude['alias_notation']}'),
                      subtitle: Text('Min: ${amplitude['valeur_min']}, Max: ${amplitude['valeur_max']}'),
                      trailing: IconButton(
                        icon: Icon(Icons.edit),
                        onPressed: () => _editAmplitude(context, amplitude.id, amplitude.data() as Map<String, dynamic>),
                      ),
                    );
                  },
                );
              },
            ),
          ],
        ),
      ],
    ),
  );
}

// Fonction pour modifier une amplitude existante
void _editAmplitude(BuildContext context, String amplitudeId, Map<String, dynamic> amplitudeData) {
  final TextEditingController aliasNotationController = TextEditingController(text: amplitudeData['alias_notation']);
  final TextEditingController minController = TextEditingController(text: amplitudeData['valeur_min'].toString());
  final TextEditingController maxController = TextEditingController(text: amplitudeData['valeur_max'].toString());
  final TextEditingController aliasMinController = TextEditingController(text: amplitudeData['alias_min'] ?? '');
  final TextEditingController aliasMaxController = TextEditingController(text: amplitudeData['alias_max'] ?? '');

  showDialog(
    context: context,
    builder: (BuildContext context) {
      return StatefulBuilder(
        builder: (BuildContext context, StateSetter setState) {
          return AlertDialog(
            title: const Text('Modifier une amplitude de notation'),
            content: SingleChildScrollView(
              child: ListBody(
                children: <Widget>[
                  TextField(
                    controller: aliasNotationController,
                    decoration: const InputDecoration(
                      labelText: 'Alias (ex: DenGa)',
                    ),
                  ),
                  const SizedBox(height: 16.0),
                  TextField(
                    controller: minController,
                    decoration: const InputDecoration(
                      labelText: 'Valeur minimale',
                    ),
                    keyboardType: TextInputType.number,
                  ),
                  TextField(
                    controller: maxController,
                    decoration: const InputDecoration(
                      labelText: 'Valeur maximale',
                    ),
                    keyboardType: TextInputType.number,
                  ),
                  TextField(
                    controller: aliasMinController,
                    decoration: const InputDecoration(
                      labelText: 'Alias pour la valeur minimale',
                    ),
                  ),
                  TextField(
                    controller: aliasMaxController,
                    decoration: const InputDecoration(
                      labelText: 'Alias pour la valeur maximale',
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
                child: const Text('Enregistrer'),
                onPressed: () {
                  final String aliasNotation = aliasNotationController.text.trim();
                  final String minValue = minController.text.trim();
                  final String maxValue = maxController.text.trim();
                  final String aliasMin = aliasMinController.text.trim();
                  final String aliasMax = aliasMaxController.text.trim();

                  if (minValue.isNotEmpty && maxValue.isNotEmpty && aliasNotation.isNotEmpty) {
                    final int min = int.tryParse(minValue) ?? 0;
                    final int max = int.tryParse(maxValue) ?? 0;

                    if (min < max) {
                      final String nomAmplitude = 'note $max';

                      Map<String, dynamic> updatedAmplitudeData = {
                        'valeur_min': min,
                        'valeur_max': max,
                        'alias_min': aliasMin.isEmpty ? null : aliasMin,
                        'alias_max': aliasMax.isEmpty ? null : aliasMax,
                        'alias_notation': aliasNotation,
                        'nom': nomAmplitude,
                      };

                      FirebaseFirestore.instance
                          .collection('Amplitudes')
                          .doc(amplitudeId) // Utiliser .doc() pour mettre à jour un document existant
                          .update(updatedAmplitudeData)
                          .then((_) {
                        Navigator.of(context).pop();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Amplitude modifiée avec succès')),
                        );
                      }).catchError((error) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Erreur lors de la modification de l\'amplitude: $error')),
                        );
                      });
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('La valeur minimale doit être inférieure à la valeur maximale')),
                      );
                    }
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Veuillez remplir tous les champs')),
                    );
                  }
                },
              ),
            ],
          );
        },
      );
    },
  );
}

void _editObservateur(BuildContext context, String observateurId, DocumentSnapshot observateur) {
  final TextEditingController nomController = TextEditingController(text: observateur['Nom']);
  final TextEditingController prenomController = TextEditingController(text: observateur['Prenom']);
  final TextEditingController emailController = TextEditingController(text: observateur['email']);
  
  // Check if observateur is affiliated with multiple lieux
  bool hasMultipleLieux = observateur['Lieux'].length > 1;

  String selectedLieuId = observateur['Lieux'][0].id;

  // If observateur has multiple lieux, disable the selection
  bool isLieuSelectionEnabled = !hasMultipleLieux;

  showDialog(
    context: context,
    builder: (BuildContext context) {
      return StatefulBuilder(
        builder: (BuildContext context, StateSetter setState) {
          return AlertDialog(
            title: const Text('Modifier l\'observateur'),
            content: SingleChildScrollView(
              child: ListBody(
                children: <Widget>[
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
                  DropdownButtonFormField(
                    value: selectedLieuId,
                    items: availableLieux.map((lieu) {
                      return DropdownMenuItem(
                        value: lieu['id'],
                        child: Text(lieu['nom']),
                      );
                    }).toList(),
                    onChanged: isLieuSelectionEnabled ? (value) {
                      setState(() {
                        selectedLieuId = value.toString();
                      });
                    } : null, // Disable onChanged if multiple lieux
                    decoration: InputDecoration(
                      labelText: 'Sélectionnez le lieu',
                      enabled: isLieuSelectionEnabled,
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                child: const Text('Enregistrer'),
                onPressed: () async {
                  final String nom = nomController.text.trim();
                  final String prenom = prenomController.text.trim();
                  final String email = emailController.text.trim();
                  final String lieuId = selectedLieuId;

                  if (nom.isNotEmpty && prenom.isNotEmpty && email.isNotEmpty && lieuId.isNotEmpty) {
                    try {
                      await FirebaseFirestore.instance.collection('Observateurs').doc(observateurId).update({
                        'Nom': nom,
                        'Prenom': prenom,
                        'email': email,
                        'Lieux': [
                          FirebaseFirestore.instance.collection('Lieux').doc(lieuId)
                        ],
                      });

                      Navigator.of(context).pop();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Observateur mis à jour avec succès'),
                        ),
                      );
                    } catch (error) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Erreur lors de la mise à jour de l\'observateur: $error'),
                        ),
                      );
                    }
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Veuillez remplir tous les champs'),
                      ),
                    );
                  }
                },
              ),
            ],
          );
        },
      );
    },
  );
}


void _editParcelle(BuildContext context, String parcelleId, Map<String, dynamic> parcelle) {
  final TextEditingController numeroParcelleController = TextEditingController(text: parcelle['Numero_parcelle'].toString());
  String selectedLieuId = parcelle['Lieu'].id;
  List<String> selectedNotations = List<String>.from(parcelle['Notations']);

  showDialog(
    context: context,
    builder: (BuildContext context) {
      return StatefulBuilder(
        builder: (BuildContext context, StateSetter setState) {
          return AlertDialog(
            title: const Text('Modifier la parcelle'),
            content: SingleChildScrollView(
              child: ListBody(
                children: <Widget>[
                  TextField(
                    controller: numeroParcelleController,
                    decoration: const InputDecoration(
                      labelText: 'Numéro de la parcelle',
                    ),
                    keyboardType: TextInputType.number,
                  ),
                  DropdownButtonFormField(
                    value: selectedLieuId,
                    items: availableLieux.map((lieu) {
                      return DropdownMenuItem(
                        value: lieu['id'],
                        child: Text(lieu['nom']),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        selectedLieuId = value.toString();
                      });
                    },
                    decoration: const InputDecoration(
                      labelText: 'Sélectionnez le lieu',
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: availableNotations.map((notation) {
                      return CheckboxListTile(
                        title: Text(notation['nom']),
                        value: selectedNotations.contains(notation['nom']),
                        onChanged: (bool? value) {
                          setState(() {
                            if (value!) {
                              selectedNotations.add(notation['nom']);
                            } else {
                              selectedNotations.remove(notation['nom']);
                            }
                          });
                        },
                      );
                    }).toList(),
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
                child: const Text('Modifier'),
                onPressed: () {
                  final int? numeroParcelle = int.tryParse(numeroParcelleController.text);

                  if (numeroParcelle != null && selectedLieuId.isNotEmpty) {
                    final Map<String, dynamic> updatedParcelle = {
                      'Numero_parcelle': numeroParcelle,
                      'Lieu': FirebaseFirestore.instance.doc('Lieux/$selectedLieuId'),
                      'Notations': selectedNotations,
                    };

                    FirebaseFirestore.instance
                        .collection('Parcelles')
                        .doc(parcelleId)
                        .update(updatedParcelle)
                        .then((_) {
                      Navigator.of(context).pop();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Parcelle modifiée avec succès')),
                      );
                    }).catchError((error) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Erreur lors de la modification de la parcelle: $error')),
                      );
                    });
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Veuillez remplir tous les champs avec des valeurs valides')),
                    );
                  }
                },
              ),
            ],
          );
        },
      );
    },
  );
}


Widget _buildNotationItem(BuildContext context, DocumentSnapshot document) {
  Map<String, dynamic> notation = document.data() as Map<String, dynamic>;

  // Fonction pour mapper les types de notes aux plages respectives
  String getNotationRange(String type) {
    switch (type) {
      case 'note 3':
        return 'note 0 à 3';
      case 'note 4':
        return 'note 0 à 4';
      case 'note 9':
        return 'note 1 à 9';
      default:
        return type; // Retourne le type inchangé s'il ne correspond à aucun cas
    }
  }

  return ListTile(
    title: Text(notation['nom']),
    subtitle: Text('Type: ${getNotationRange(notation['type'])}'),
    trailing: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: Icon(Icons.edit),
          onPressed: () => _editNotation(context, document.id, notation),
        ),
      ],
    ),
  );
}


//  Widget _buildParcelleItem(BuildContext context, DocumentSnapshot document) {
//     Map<String, dynamic> parcelle = document.data() as Map<String, dynamic>;
//     String lieuId = parcelle['Lieu'].id;

//     return FutureBuilder<DocumentSnapshot>(
//       future: FirebaseFirestore.instance.collection('Lieux').doc(lieuId).get(),
//       builder: (context, snapshot) {
//         if (snapshot.connectionState == ConnectionState.waiting) {
//           return ListTile(
//             title: Text('Parcelle ${parcelle['Numero_parcelle']}'),
//             subtitle: Text('Chargement du lieu...'),
//           );
//         }
//         if (snapshot.hasError || !snapshot.hasData) {
//           return ListTile(
//             title: Text('Parcelle ${parcelle['Numero_parcelle']}'),
//             subtitle: Text('Erreur lors du chargement du lieu'),
//           );
//         }

//         Map<String, dynamic> lieu = snapshot.data!.data() as Map<String, dynamic>;
//         String nomLieu = lieu['Nom_lieu'];

//         return ListTile(
//           title: Text('Parcelle ${parcelle['Numero_parcelle']}'),
//           subtitle: Text('Lieu: $nomLieu'),
//           trailing: Row(
//             mainAxisSize: MainAxisSize.min,
//             children: [
//               IconButton(
//                 icon: Icon(Icons.edit),
//                 onPressed: () => _editParcelle(context, document.id, parcelle),
//               ),
//               IconButton(
//                 icon: Icon(Icons.edit_location),
//                 onPressed: () => _editLieu(context, lieuId, nomLieu, nombreParcelles),
//               ),
//             ],
//           ),
//         );
//       },
//     );
//   }

Widget _buildLieuItem(BuildContext context, DocumentSnapshot document) {
  Map<String, dynamic> lieu = document.data() as Map<String, dynamic>;
  String lieuId = lieu['id'];
  String nomLieu = lieu['Nom_lieu'];
  int nombreParcelles = lieu['Nombre_parcelles'];

  return ListTile(
    title: Text('Lieu: $nomLieu'),
    subtitle: Text('Nombre de parcelles: $nombreParcelles'),
    trailing: IconButton(
      icon: Icon(Icons.edit),
      onPressed: () => _editLieu(context, lieuId, nomLieu, nombreParcelles),
    ),
  );
}



  void _addNewLieu(BuildContext context) {
    final TextEditingController lieuIdController = TextEditingController();
    final TextEditingController nomLieuController = TextEditingController();
    final TextEditingController nombreParcellesController =
        TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Ajouter un nouveau lieu'),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                TextField(
                  controller: lieuIdController,
                  decoration: const InputDecoration(
                    labelText: 'Numéro du lieu',
                  ),
                ),
                TextField(
                  controller: nomLieuController,
                  decoration: const InputDecoration(
                    labelText: 'Nom du lieu',
                  ),
                ),
                TextField(
                  controller: nombreParcellesController,
                  decoration: const InputDecoration(
                    labelText: 'Nombre de parcelles',
                  ),
                  keyboardType: TextInputType.number,
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
              child: const Text('Ajouter'),
              onPressed: () {
                final String lieuId = lieuIdController.text.trim();
                final String nomLieu = nomLieuController.text.trim();
                final int nombreParcelles =
                    int.tryParse(nombreParcellesController.text) ?? 0;

                if (lieuId.isNotEmpty &&
                    nomLieu.isNotEmpty &&
                    nombreParcelles > 0) {
                  FirebaseFirestore.instance
                      .collection('Lieux')
                      .doc(lieuId)
                      .get()
                      .then((docSnapshot) {
                    if (docSnapshot.exists) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text('L\'ID du lieu existe déjà')),
                      );
                    } else {
                      FirebaseFirestore.instance
                          .collection('Lieux')
                          .doc(lieuId)
                          .set({
                        'Nom_lieu': nomLieu,
                        'Nombre_parcelles': nombreParcelles,
                      }).then((value) {
                        Navigator.of(context).pop();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text('Lieu ajouté avec succès')),
                        );
                      }).catchError((error) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                              content: Text(
                                  'Erreur lors de l\'ajout du lieu: $error')),
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
  }
void _addNewAmplitude(BuildContext context) {
  final TextEditingController aliasNotationController = TextEditingController();
  final TextEditingController minController = TextEditingController();
  final TextEditingController maxController = TextEditingController();
  final TextEditingController aliasMinController = TextEditingController();
  final TextEditingController aliasMaxController = TextEditingController();

  showDialog(
    context: context,
    builder: (BuildContext context) {
      return StatefulBuilder(
        builder: (BuildContext context, StateSetter setState) {
          return AlertDialog(
            title: const Text('Ajouter une nouvelle amplitude de notation'),
            content: SingleChildScrollView(
              child: ListBody(
                children: <Widget>[
                  TextField(
                    controller: aliasNotationController,
                    decoration: const InputDecoration(
                      labelText: 'Alias (ATTENTION mettre le meme nom que la notation Par exemple : DenGa)',
                    ),
                  ),
                  const SizedBox(height: 16.0),
                  TextField(
                    controller: minController,
                    decoration: const InputDecoration(
                      labelText: 'Valeur minimale',
                    ),
                    keyboardType: TextInputType.number,
                  ),
                  TextField(
                    controller: maxController,
                    decoration: const InputDecoration(
                      labelText: 'Valeur maximale',
                    ),
                    keyboardType: TextInputType.number,
                  ),
                  TextField(
                    controller: aliasMinController,
                    decoration: const InputDecoration(
                      labelText: 'Alias pour la valeur minimale',
                    ),
                  ),
                  TextField(
                    controller: aliasMaxController,
                    decoration: const InputDecoration(
                      labelText: 'Alias pour la valeur maximale',
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
                child: const Text('Ajouter'),
                onPressed: () {
                  final String aliasNotation = aliasNotationController.text.trim();
                  final String minValue = minController.text.trim();
                  final String maxValue = maxController.text.trim();
                  final String aliasMin = aliasMinController.text.trim();
                  final String aliasMax = aliasMaxController.text.trim();

                  if (minValue.isNotEmpty && maxValue.isNotEmpty && aliasNotation.isNotEmpty) {
                    final int min = int.tryParse(minValue) ?? 0;
                    final int max = int.tryParse(maxValue) ?? 0;

                    if (min < max) {
                      final String nomAmplitude = 'note $max';

                      Map<String, dynamic> amplitudeData = {
                        'valeur_min': min,
                        'valeur_max': max,
                        'alias_min': aliasMin.isEmpty ? null : aliasMin,
                        'alias_max': aliasMax.isEmpty ? null : aliasMax,
                        'alias_notation': aliasNotation,
                        'nom': nomAmplitude,
                      };

                      FirebaseFirestore.instance
                          .collection('Amplitudes')
                          .add(amplitudeData)  // Utiliser .add() pour générer un ID unique
                          .then((_) {
                        Navigator.of(context).pop();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Amplitude ajoutée avec succès')),
                        );
                      }).catchError((error) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Erreur lors de l\'ajout de l\'amplitude: $error')),
                        );
                      });
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('La valeur minimale doit être inférieure à la valeur maximale')),
                      );
                    }
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Veuillez remplir tous les champs')),
                    );
                  }
                },
              ),
            ],
          );
        },
      );
    },
  );
}



  void _addNewParcelle(BuildContext context) {
  final TextEditingController numeroParcelleController = TextEditingController();

  Future<void> _refreshNotations(StateSetter setState) async {
    final notationsSnapshot = await FirebaseFirestore.instance.collection('Notations').get();
    setState(() {
      availableNotations = notationsSnapshot.docs.map((doc) => doc.data()).toList();
    });
  }

  showDialog(
    context: context,
    builder: (BuildContext context) {
      return StatefulBuilder(
        builder: (BuildContext context, StateSetter setState) {
          return AlertDialog(
            title: const Text('Ajouter une nouvelle parcelle'),
            content: SingleChildScrollView(
              child: ListBody(
                children: <Widget>[
                  TextField(
                    controller: numeroParcelleController,
                    decoration: const InputDecoration(
                      labelText: 'Identifiant de la parcelle',
                    ),
                    keyboardType: TextInputType.text, // Permet la saisie de texte avec des caractères spéciaux
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9]')), // Autorise alphanumerique
                    ],
                    // Optionnel: Vous pouvez ajouter un validateur si vous avez un formulaire
                  ),
                  DropdownButtonFormField(
                    value: selectedLieuId,
                    items: availableLieux.map((lieu) {
                      return DropdownMenuItem(
                        value: lieu['id'],
                        child: Text(lieu['nom']),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        selectedLieuId = value.toString();
                      });
                    },
                    decoration: const InputDecoration(
                      labelText: 'Sélectionnez le lieu',
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Notations'),
                      IconButton(
                        icon: Icon(Icons.refresh, color: Colors.blue),
                        onPressed: () => _refreshNotations(setState),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: availableNotations.map((notation) {
                      return CheckboxListTile(
                        title: Text(notation['nom']),
                        value: selectedNotations.contains(notation['nom']),
                        onChanged: (bool? value) {
                          setState(() {
                            if (value!) {
                              selectedNotations.add(notation['nom']);
                            } else {
                              selectedNotations.remove(notation['nom']);
                            }
                          });
                        },
                      );
                    }).toList(),
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
                child: const Text('Ajouter'),
                onPressed: () {
                  final String parcelleId = numeroParcelleController.text.trim();

                  // Vérifier si le texte contient des alphanumeriques uniquement
                  if (!RegExp(r'^[a-zA-Z0-9]+$').hasMatch(parcelleId)) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Le numéro de la parcelle ne peut contenir que des chiffres et des lettres')),
                    );
                  } else if (parcelleId.isNotEmpty && selectedLieuId.isNotEmpty) {
                    FirebaseFirestore.instance
                        .collection('Parcelles')
                        .doc(parcelleId)
                        .get()
                        .then((docSnapshot) {
                      if (docSnapshot.exists) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Le numéro de parcelle existe déjà')),
                        );
                      } else {
                        Map<String, dynamic> parcelleData = {
                          'Numero_parcelle': parcelleId,
                          'Lieu': FirebaseFirestore.instance.doc('Lieux/$selectedLieuId'),
                          'Notations': selectedNotations
                        };

                        FirebaseFirestore.instance
                            .collection('Parcelles')
                            .doc(parcelleId)
                            .set(parcelleData)
                            .then((_) {
                          Navigator.of(context).pop();
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Parcelle ajoutée avec succès')),
                          );
                        }).catchError((error) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Erreur lors de l\'ajout de la parcelle: $error')),
                          );
                        });
                      }
                    });
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Veuillez remplir tous les champs avec des valeurs valides')),
                    );
                  }
                },
              ),
            ],
          );
        },
      );
    },
  );
}



  void _createNewObservateur(BuildContext context) {
  final TextEditingController observateurIdController = TextEditingController();
  final TextEditingController nomController = TextEditingController();
  final TextEditingController prenomController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  String selectedLieuId = availableLieux.isNotEmpty ? availableLieux[0]['id'] : '';

  showDialog(
    context: context,
    builder: (BuildContext context) {
      return StatefulBuilder(
        builder: (BuildContext context, StateSetter setState) {
          return AlertDialog(
            title: const Text('Créer un nouvel observateur'),
            content: SingleChildScrollView(
              child: ListBody(
                children: <Widget>[
                  TextField(
                    controller: observateurIdController,
                    decoration: const InputDecoration(
                      labelText: 'Acronyme',
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
                  DropdownButtonFormField(
                    value: selectedLieuId,
                    items: availableLieux.map((lieu) {
                      return DropdownMenuItem(
                        value: lieu['id'],
                        child: Text(lieu['nom']),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        selectedLieuId = value.toString();
                      });
                    },
                    decoration: const InputDecoration(
                      labelText: 'Sélectionnez le lieu',
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                child: const Text('Créer'),
                onPressed: () async {
                  final String observateurId = observateurIdController.text.trim();
                  final String nom = nomController.text.trim();
                  final String prenom = prenomController.text.trim();
                  final String email = emailController.text.trim();
                  final String lieuId = selectedLieuId;

                  if (observateurId.isNotEmpty &&
                      nom.isNotEmpty &&
                      prenom.isNotEmpty &&
                      email.isNotEmpty &&
                      lieuId.isNotEmpty) {
                    try {
                      // Vérification de l'existence de l'observateur avec le même ID
                      final observateurSnapshot = await FirebaseFirestore.instance
                          .collection('Observateurs')
                          .doc(observateurId)
                          .get();

                      if (observateurSnapshot.exists) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('L\'ID de l\'observateur existe déjà'),
                          ),
                        );
                      } else {
                        // Créer l'utilisateur dans Firebase Authentication
                        await FirebaseAuth.instance.createUserWithEmailAndPassword(
                          email: email, password: 'password');

                        // Ajouter l'utilisateur dans Firestore
                        await FirebaseFirestore.instance
                            .collection('Observateurs')
                            .doc(observateurId)
                            .set({
                          'Nom': nom,
                          'Prenom': prenom,
                          'email': email,
                          'Lieux': [
                            FirebaseFirestore.instance.collection('Lieux').doc(lieuId)
                          ],
                        });

                        Navigator.of(context).pop();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Observateur créé avec succès'),
                          ),
                        );
                      }
                    } catch (error) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Erreur lors de la création de l\'observateur: $error'),
                        ),
                      );
                    }
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Veuillez remplir tous les champs'),
                      ),
                    );
                  }
                },
              ),
            ],
          );
        },
      );
    },
  );
}



void _addNewNotation(BuildContext context) {
  final TextEditingController nomNotationController = TextEditingController();
  final TextEditingController aliasNotationController = TextEditingController();
  bool isLibreNotation = false;
  String? selectedAmplitudeId;

  showDialog(
    context: context,
    builder: (BuildContext dialogContext) {
      return AlertDialog(
        title: const Text('Ajouter une nouvelle notation'),
        content: FutureBuilder<QuerySnapshot>(
          future: FirebaseFirestore.instance.collection('Amplitudes').get(),
          builder: (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return Text('Erreur: ${snapshot.error}');
            }

            if (snapshot.hasData && snapshot.data != null) {
              final List<DropdownMenuItem<String>> amplitudeItems = snapshot.data!.docs
                  .map((DocumentSnapshot document) {
                    final Map<String, dynamic> data = document.data() as Map<String, dynamic>;
                    final int minValue = data['valeur_min'];
                    final int maxValue = data['valeur_max'];
                    final String aliasNotation = data['alias_notation'] ?? 'Sans alias';
                    final String docId = document.id;

                    return DropdownMenuItem<String>(
                      value: docId,
                      child: Text('$minValue à $maxValue ($aliasNotation)'),
                    );
                  }).toList();

              return StatefulBuilder(
                builder: (BuildContext context, StateSetter setState) {
                  return SingleChildScrollView(
                    child: ListBody(
                      children: <Widget>[
                        TextField(
                          controller: nomNotationController,
                          decoration: const InputDecoration(
                            labelText: 'Nom de la notation',
                          ),
                        ),
                        TextField(
                          controller: aliasNotationController,
                          decoration: const InputDecoration(
                            labelText: 'Alias',
                          ),
                        ),
                        Row(
                          children: [
                            Checkbox(
                              value: isLibreNotation,
                              onChanged: (bool? value) {
                                setState(() {
                                  isLibreNotation = value ?? false;
                                  selectedAmplitudeId = null;
                                });
                              },
                            ),
                            const Text('Notation libre'),
                          ],
                        ),
                        if (!isLibreNotation) ...[
                          DropdownButton<String>(
                            value: selectedAmplitudeId,
                            hint: const Text('Choisir l\'amplitude'),
                            items: amplitudeItems,
                            onChanged: (String? value) {
                              setState(() {
                                selectedAmplitudeId = value;
                              });
                            },
                          ),
                        ],
                      ],
                    ),
                  );
                },
              );
            } else {
              return const Text('Pas de données disponibles.');
            }
          },
        ),
        actions: <Widget>[
          TextButton(
            child: const Text('Annuler'),
            onPressed: () {
              Navigator.of(dialogContext).pop();
            },
          ),
          TextButton(
            child: const Text('Ajouter'),
            onPressed: () async {
              final String nomNotation = nomNotationController.text.trim();
              final String aliasNotation = aliasNotationController.text.trim();

              if (nomNotation.isEmpty || aliasNotation.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Veuillez remplir tous les champs')),
                );
                return;
              }

              String typeNotation;
              if (isLibreNotation) {
                typeNotation = 'libre';
              } else {
                final DocumentSnapshot selectedAmplitude = await FirebaseFirestore.instance
                    .collection('Amplitudes')
                    .doc(selectedAmplitudeId)
                    .get();
                final Map<String, dynamic> data = selectedAmplitude.data() as Map<String, dynamic>;
                final int minValue = data['valeur_min'];
                final int maxValue = data['valeur_max'];
                typeNotation = '$minValue à $maxValue';
              }

              try {
                final docRef = FirebaseFirestore.instance.collection('Notations').doc(nomNotation);
                final docSnapshot = await docRef.get();

                if (docSnapshot.exists) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('La notation existe déjà')),
                  );
                } else {
                  await docRef.set({
                    'nom': nomNotation,
                    'alias': aliasNotation,
                    'type': typeNotation,
                  });
                  Navigator.of(dialogContext).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Notation ajoutée avec succès')),
                  );
                }
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Erreur lors de l\'ajout: $e')),
                );
              }
            },
          ),
        ],
      );
    },
  );
}






//   void _editParcelle(BuildContext context, String parcelleId, Map<String, dynamic> parcelle) {
//   final TextEditingController numeroParcelleController = TextEditingController(text: parcelle['Numero_parcelle'].toString());
//   String selectedLieuId = parcelle['Lieu'].id;
//   List<String> selectedNotations = List<String>.from(parcelle['Notations']);

//   showDialog(
//     context: context,
//     builder: (BuildContext context) {
//       return StatefulBuilder(
//         builder: (BuildContext context, StateSetter setState) {
//           return AlertDialog(
//             title: const Text('Modifier la parcelle'),
//             content: SingleChildScrollView(
//               child: ListBody(
//                 children: <Widget>[
//                   TextField(
//                     controller: numeroParcelleController,
//                     decoration: const InputDecoration(
//                       labelText: 'Numéro de la parcelle',
//                     ),
//                     keyboardType: TextInputType.number,
//                   ),
//                   DropdownButtonFormField(
//                     value: selectedLieuId,
//                     items: availableLieux.map((lieu) {
//                       return DropdownMenuItem(
//                         value: lieu['id'],
//                         child: Text(lieu['nom']),
//                       );
//                     }).toList(),
//                     onChanged: (value) {
//                       setState(() {
//                         selectedLieuId = value.toString();
//                       });
//                     },
//                     decoration: const InputDecoration(
//                       labelText: 'Sélectionnez le lieu',
//                     ),
//                   ),
//                   Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: availableNotations.map((notation) {
//                       return CheckboxListTile(
//                         title: Text(notation['nom']),
//                         value: selectedNotations.contains(notation['nom']),
//                         onChanged: (bool? value) {
//                           setState(() {
//                             if (value!) {
//                               selectedNotations.add(notation['nom']);
//                             } else {
//                               selectedNotations.remove(notation['nom']);
//                             }
//                           });
//                         },
//                       );
//                     }).toList(),
//                   ),
//                 ],
//               ),
//             ),
//             actions: <Widget>[
//               TextButton(
//                 child: const Text('Annuler'),
//                 onPressed: () {
//                   Navigator.of(context).pop();
//                 },
//               ),
//               TextButton(
//                 child: const Text('Modifier'),
//                 onPressed: () {
//                   final int? numeroParcelle = int.tryParse(numeroParcelleController.text);

//                   if (numeroParcelle != null && selectedLieuId.isNotEmpty) {
//                     final Map<String, dynamic> updatedParcelle = {
//                       'Numero_parcelle': numeroParcelle,
//                       'Lieu': FirebaseFirestore.instance.doc('Lieux/$selectedLieuId'),
//                       'Notations': selectedNotations,
//                     };

//                     FirebaseFirestore.instance
//                         .collection('Parcelles')
//                         .doc(parcelleId)
//                         .update(updatedParcelle)
//                         .then((_) {
//                       Navigator.of(context).pop();
//                       ScaffoldMessenger.of(context).showSnackBar(
//                         const SnackBar(content: Text('Parcelle modifiée avec succès')),
//                       );
//                     }).catchError((error) {
//                       ScaffoldMessenger.of(context).showSnackBar(
//                         SnackBar(content: Text('Erreur lors de la modification de la parcelle: $error')),
//                       );
//                     });
//                   } else {
//                     ScaffoldMessenger.of(context).showSnackBar(
//                       const SnackBar(content: Text('Veuillez remplir tous les champs avec des valeurs valides')),
//                     );
//                   }
//                 },
//               ),
//             ],
//           );
//         },
//       );
//     },
//   );
// }

void _editLieu(BuildContext context, String lieuId, String nomLieu, int nombreParcelles) {
  final TextEditingController nomLieuController = TextEditingController(text: nomLieu);
  TextEditingController nombreParcellesController;

  // Récupérer le nombre de parcelles depuis Firestore
  FirebaseFirestore.instance.collection('Lieux').doc(lieuId).get().then((doc) {
    if (doc.exists) {
      final int parcelles = doc.data()?['Nombre_parcelles'] ?? 0;
      nombreParcellesController = TextEditingController(text: parcelles.toString());

      // Afficher la boîte de dialogue
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Modifier le lieu'),
            content: SingleChildScrollView(
              child: ListBody(
                children: <Widget>[
                  TextField(
                    controller: nomLieuController,
                    decoration: const InputDecoration(
                      labelText: 'Nom du lieu',
                    ),
                  ),
                  TextField(
                    controller: nombreParcellesController,
                    decoration: const InputDecoration(
                      labelText: 'Nombre de parcelles',
                    ),
                    keyboardType: TextInputType.number,
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
                child: const Text('Modifier'),
                onPressed: () {
                  final String nomLieu = nomLieuController.text.trim();
                  final int nombreParcelles = int.tryParse(nombreParcellesController.text) ?? 0;

                  if (nomLieu.isNotEmpty && nombreParcelles > 0) {
                    final Map<String, dynamic> updatedLieu = {
                      'Nom_lieu': nomLieu,
                      'Nombre_parcelles': nombreParcelles,
                    };

                    FirebaseFirestore.instance
                        .collection('Lieux')
                        .doc(lieuId)
                        .update(updatedLieu)
                        .then((_) {
                      Navigator.of(context).pop();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Lieu modifié avec succès')),
                      );
                    }).catchError((error) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Erreur lors de la modification du lieu: $error')),
                      );
                    });
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Veuillez remplir tous les champs avec des valeurs valides'),
                      ),
                    );
                  }
                },
              ),
            ],
          );
        },
      );
    }
  }).catchError((error) {
    // Gérer les erreurs de récupération depuis Firestore
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Erreur lors de la récupération des données du lieu: $error')),
    );
  });
}
void _editNotation(BuildContext context, String notationId, Map<String, dynamic> notationData) {
  final TextEditingController nomNotationController = TextEditingController(text: notationData['nom']);
  String selectedType = notationData['type'];

  showDialog(
    context: context,
    builder: (BuildContext context) {
      return StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: const Text('Modifier la notation'),
            content: SingleChildScrollView(
              child: ListBody(
                children: <Widget>[
                  TextField(
                    controller: nomNotationController,
                    decoration: const InputDecoration(
                      labelText: 'Nom de la notation',
                    ),
                  ),
                  const SizedBox(height: 16.0),
                                    // A modifier pour la modification 
                  // Text('Type de notation:'),

                  // RadioListTile<String>(
                  //   title: const Text('note 0 à 3'),
                  //   value: 'note 3',
                  //   groupValue: selectedType,
                  //   onChanged: (String? value) {
                  //     setState(() {
                  //       selectedType = value!;
                  //     });
                  //   },
                  // ),
                  // RadioListTile<String>(
                  //   title: const Text('note 0 à 4'),
                  //   value: 'note 4',
                  //   groupValue: selectedType,
                  //   onChanged: (String? value) {
                  //     setState(() {
                  //       selectedType = value!;
                  //     });
                  //   },
                  // ),
                  // RadioListTile<String>(
                  //   title: const Text('note 1 à 9'),
                  //   value: 'note 9',
                  //   groupValue: selectedType,
                  //   onChanged: (String? value) {
                  //     setState(() {
                  //       selectedType = value!;
                  //     });
                  //   },
                  // ),
                  // RadioListTile<String>(
                  //   title: const Text('note libre'),
                  //   value: 'libre',
                  //   groupValue: selectedType,
                  //   onChanged: (String? value) {
                  //     setState(() {
                  //       selectedType = value!;
                  //     });
                  //   },
                  // ),
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
                child: const Text('Enregistrer'),
                onPressed: () {
                  final String nomNotation = nomNotationController.text.trim();

                  if (nomNotation.isNotEmpty && selectedType.isNotEmpty) {
                    FirebaseFirestore.instance
                        .collection('Notations')
                        .doc(notationId)
                        .update({
                          'nom': nomNotation,
                          'type': selectedType,
                        })
                        .then((value) {
                          Navigator.of(context).pop();
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text('Notation modifiée avec succès')),
                          );
                        })
                        .catchError((error) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                                content: Text(
                                    'Erreur lors de la modification de la notation: $error')),
                          );
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
    },
  );
}

// PARTIE NON ADMINISTRATEUR

Future<String> _getLieuNameFromObserverEmail(String userEmail) async {
  try {
    // Recherche de l'observateur par email
    final QuerySnapshot observerSnapshot = await FirebaseFirestore.instance
        .collection('Observateurs')
        .where('email', isEqualTo: userEmail)
        .get();

    if (observerSnapshot.docs.isEmpty) {
      print('Aucun observateur trouvé avec l\'email: $userEmail');
      return 'Nom du lieu non trouvé';
    }

    final observerDoc = observerSnapshot.docs.first;
    final lieuReferences = observerDoc.get('Lieux') as List<dynamic>?;

    if (lieuReferences == null || lieuReferences.isEmpty) {
      print('Le champ "Lieux" est vide ou manquant pour l\'observateur: $userEmail');
      return 'Nom du lieu non trouvé';
    }

    // Supposons que nous voulons récupérer le nom du premier lieu dans la liste
    final lieuDocRef = lieuReferences.first as DocumentReference;

    final lieuSnapshot = await lieuDocRef.get();

    if (!lieuSnapshot.exists) {
      print('Le lieu référencé n\'existe pas dans la collection Lieux');
      return 'Nom du lieu non trouvé';
    }

    final lieuData = lieuSnapshot.data() as Map<String, dynamic>;
    final nomLieu = lieuData['Nom_lieu'] as String?;

    if (nomLieu == null) {
      print('Le champ "Nom_lieu" est manquant dans le document du lieu');
      return 'Nom du lieu non trouvé';
    }

    return nomLieu;
  } catch (e) {
    print('Erreur lors de la récupération du nom du lieu: $e');
    return 'Erreur lors de la récupération du nom du lieu';
  }
}

Widget _buildObserverView(BuildContext context) {
  return FutureBuilder<String>(
    future: _getLieuNameFromObserverEmail(_userEmail),
    builder: (context, snapshot) {
      if (snapshot.connectionState == ConnectionState.waiting) {
        return Center(child: CircularProgressIndicator());
      } else if (snapshot.hasError) {
        return Center(child: Text('Erreur: ${snapshot.error}'));
      } else if (snapshot.hasData) {
        final lieuName = snapshot.data!;
        return Center(
          child: RichText(
            textAlign: TextAlign.center,
            text: TextSpan(
              style: const TextStyle(
                color: Colors.black,
                fontSize: 16.0,
              ),
              children: [
                const TextSpan(
                  text: 'Bienvenue ',
                ),
                TextSpan(
                  text: _userEmail,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const TextSpan(
                  text: ' vous êtes connecté en tant qu\'observateur pour le lieu: ',
                ),
                TextSpan(
                  text: lieuName,
                  style: const TextStyle(
                    color: Colors.blue,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const TextSpan(
                  text: '.',
                ),
              ],
            ),
          ),
        );
      } else {
        return Center(child: Text('Nom du lieu non trouvé'));
      }
    },
  );
}





}

