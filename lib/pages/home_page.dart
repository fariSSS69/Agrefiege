import 'package:agrefiege/pages/dashboard_page.dart';
import 'package:agrefiege/pages/observation_page.dart';
import 'package:agrefiege/pages/settings_page.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:motion_tab_bar/MotionTabBarController.dart';
import 'package:motion_tab_bar/MotionTabBar.dart';

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
          title: Center(child: Text('Liste des Parcelles')),
          childrenPadding: EdgeInsets.symmetric(horizontal: 16),
          collapsedBackgroundColor: Colors.grey[200],
          children: [
            StreamBuilder<QuerySnapshot>(
              stream: parcellesCollection.snapshots(),
              builder: (context, parcellesSnapshot) {
                if (parcellesSnapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }
                if (parcellesSnapshot.hasError) {
                  return Center(child: Text('Erreur: ${parcellesSnapshot.error}'));
                }

                final parcelles = parcellesSnapshot.data!.docs;

                return ListView.separated(
                  shrinkWrap: true,
                  itemCount: parcelles.length,
                  separatorBuilder: (context, index) => Divider(),
                  itemBuilder: (context, index) {
                    return _buildParcelleItem(context, parcelles[index]);
                  },
                );
              },
            ),
          ],
        ),
        SizedBox(height: 20),
        ExpansionTile(
          title: Center(child: Text('Liste des Notations')),
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
      ],
    ),
  );
}



Widget _buildNotationItem(BuildContext context, DocumentSnapshot document) {
  Map<String, dynamic> notation = document.data() as Map<String, dynamic>;

  return ListTile(
    title: Text(notation['nom']),
    subtitle: Text('Type: ${notation['type']}'),
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


 Widget _buildParcelleItem(BuildContext context, DocumentSnapshot document) {
    Map<String, dynamic> parcelle = document.data() as Map<String, dynamic>;
    String lieuId = parcelle['Lieu'].id;

    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance.collection('Lieux').doc(lieuId).get(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return ListTile(
            title: Text('Parcelle ${parcelle['Numero_parcelle']}'),
            subtitle: Text('Chargement du lieu...'),
          );
        }
        if (snapshot.hasError || !snapshot.hasData) {
          return ListTile(
            title: Text('Parcelle ${parcelle['Numero_parcelle']}'),
            subtitle: Text('Erreur lors du chargement du lieu'),
          );
        }

        Map<String, dynamic> lieu = snapshot.data!.data() as Map<String, dynamic>;
        String nomLieu = lieu['Nom_lieu'];

        return ListTile(
          title: Text('Parcelle ${parcelle['Numero_parcelle']}'),
          subtitle: Text('Lieu: $nomLieu'),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: Icon(Icons.edit),
                onPressed: () => _editParcelle(context, document.id, parcelle),
              ),
              IconButton(
                icon: Icon(Icons.edit_location),
                onPressed: () => _editLieu(context, lieuId, nomLieu, nombreParcelles),
              ),
            ],
          ),
        );
      },
    );
  }

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


  Widget _buildObserverView(BuildContext context) {
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
              text: ' vous êtes connecté en tant qu\'observateur.',
            ),
          ],
        ),
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
                  final int? numeroParcelle = int.tryParse(numeroParcelleController.text);

                  if (numeroParcelle != null && selectedLieuId.isNotEmpty) {
                    final String parcelleId = numeroParcelle.toString();

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
                          'Numero_parcelle': numeroParcelle,
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
                      labelText: 'Numéro de l\'observateur',
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
  final TextEditingController typeNotationController = TextEditingController();

  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: const Text('Ajouter une nouvelle notation'),
        content: SingleChildScrollView(
          child: ListBody(
            children: <Widget>[
              TextField(
                controller: nomNotationController,
                decoration: const InputDecoration(
                  labelText: 'Nom de la notation',
                ),
              ),
              TextField(
                controller: typeNotationController,
                decoration: const InputDecoration(
                  labelText: 'Type de notation (fixe ou libre)',
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
              final String nomNotation = nomNotationController.text.trim();
              final String typeNotation = typeNotationController.text.trim().toLowerCase();

              if (nomNotation.isNotEmpty && typeNotation.isNotEmpty) {
                if (typeNotation == 'fixe' || typeNotation == 'libre') {
                  FirebaseFirestore.instance
                      .collection('Notations')
                      .doc(nomNotation)
                      .get()
                      .then((docSnapshot) {
                    if (docSnapshot.exists) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text('La notation existe déjà')),
                      );
                    } else {
                      FirebaseFirestore.instance
                          .collection('Notations')
                          .doc(nomNotation)
                          .set({
                        'nom': nomNotation,
                        'type': typeNotation,
                      }).then((value) {
                        Navigator.of(context).pop();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text('Notation ajoutée avec succès')),
                        );
                      }).catchError((error) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                              content: Text(
                                  'Erreur lors de l\'ajout de la notation: $error')),
                        );
                      });
                    }
                  });
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text(
                            'Type de notation invalide. Utilisez "fixe" ou "libre"')),
                  );
                }
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
  final TextEditingController typeNotationController = TextEditingController(text: notationData['type']);

  showDialog(
    context: context,
    builder: (BuildContext context) {
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
              TextField(
                controller: typeNotationController,
                decoration: const InputDecoration(
                  labelText: 'Type de notation',
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
              final String nomNotation = nomNotationController.text.trim();
              final String typeNotation = typeNotationController.text.trim();

              if (nomNotation.isNotEmpty && typeNotation.isNotEmpty) {
                FirebaseFirestore.instance
                    .collection('Notations')
                    .doc(notationId)
                    .update({
                      'nom': nomNotation,
                      'type': typeNotation,
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
}

}

