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
    String adminMessage =
        isAdmin ? 'Vous êtes connecté en tant qu\'administrateur.' : '';

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'Bienvenue $_userEmail',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16.0,
            ),
          ),
          const SizedBox(height: 8.0),
          Text(
            adminMessage,
            style: TextStyle(
              fontStyle: isAdmin ? FontStyle.italic : FontStyle.normal,
              fontSize: 14.0,
            ),
          ),
        ],
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
                    labelText: 'ID du lieu',
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
                    // Liste de CheckBoxes pour sélectionner les notations
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
                    final int? numeroParcelle =
                        int.tryParse(numeroParcelleController.text);

                    if (numeroParcelle != null && selectedLieuId.isNotEmpty) {
                      // Utilisation du numéro de parcelle comme identifiant unique
                      final String parcelleId = numeroParcelle.toString();

                      FirebaseFirestore.instance
                          .collection('Parcelles')
                          .doc(parcelleId)
                          .get()
                          .then((docSnapshot) {
                        if (docSnapshot.exists) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text('Le numéro de parcelle existe déjà')),
                          );
                        } else {
                          // Ajouter les données de la parcelle à Firestore
                          Map<String, dynamic> parcelleData = {
                            'Numero_parcelle': numeroParcelle,
                            'Lieu': FirebaseFirestore.instance
                                .doc('Lieux/$selectedLieuId'),
                            'Notations': selectedNotations // Ajouter les notations sélectionnées ici
                          };

                          FirebaseFirestore.instance
                              .collection('Parcelles')
                              .doc(parcelleId)
                              .set(parcelleData)
                              .then((_) {
                            Navigator.of(context).pop();
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text('Parcelle ajoutée avec succès')),
                            );
                          }).catchError((error) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                  content: Text(
                                      'Erreur lors de l\'ajout de la parcelle: $error')),
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
      },
    );
  }

  void _createNewObservateur(BuildContext context) {
    final TextEditingController nomObservateurController =
        TextEditingController();
    final TextEditingController emailObservateurController =
        TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Créer un nouvel observateur'),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                TextField(
                  controller: nomObservateurController,
                  decoration: const InputDecoration(
                    labelText: 'Nom de l\'observateur',
                  ),
                ),
                TextField(
                  controller: emailObservateurController,
                  decoration: const InputDecoration(
                    labelText: 'Email de l\'observateur',
                  ),
                  keyboardType: TextInputType.emailAddress,
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
                final String nomObservateur =
                    nomObservateurController.text.trim();
                final String emailObservateur =
                    emailObservateurController.text.trim();

                if (nomObservateur.isNotEmpty &&
                    emailObservateur.isNotEmpty &&
                    emailObservateur.contains('@')) {
                  FirebaseFirestore.instance
                      .collection('Observateurs')
                      .doc(emailObservateur)
                      .get()
                      .then((docSnapshot) {
                    if (docSnapshot.exists) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text(
                                'L\'observateur avec cet email existe déjà')),
                      );
                    } else {
                      FirebaseFirestore.instance
                          .collection('Observateurs')
                          .doc(emailObservateur)
                          .set({
                        'Nom': nomObservateur,
                        'Email': emailObservateur,
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
              child: const Text('Ajouter'),
              onPressed: () {
                final String nomNotation = nomNotationController.text.trim();
                final String typeNotation = typeNotationController.text.trim();

                if (nomNotation.isNotEmpty && typeNotation.isNotEmpty) {
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

