import 'package:agrefiege/pages/dashboard_page.dart';
import 'package:agrefiege/pages/observation_page.dart';
import 'package:agrefiege/pages/profile_page.dart';
import 'package:agrefiege/pages/settings_page.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:motion_tab_bar/MotionTabBarController.dart';
import 'package:motion_tab_bar/MotionTabBar.dart';

class HomePage extends StatefulWidget {
  final String? userEmail;

  const HomePage({Key? key, this.userEmail}) : super(key: key);

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with TickerProviderStateMixin {
  late MotionTabBarController _tabController;
  late bool isAdmin;

  late CollectionReference<Map<String, dynamic>>
      parcellesCollection; // Déclaration de la collection de parcelles
  late CollectionReference<Map<String, dynamic>>
      notationsCollection; // Déclaration de la collection de notations

  @override
  void initState() {
    super.initState();
    isAdmin = widget.userEmail == 'faris.maisonneuve@wanadoo.fr' ||
        FirebaseAuth.instance.currentUser?.email ==
            'faris.maisonneuve@wanadoo.fr';
    _tabController =
        MotionTabBarController(length: isAdmin ? 4 : 4, vsync: this);
    parcellesCollection = FirebaseFirestore.instance.collection(
        'Parcelles'); // Initialisation de la collection de parcelles
    notationsCollection = FirebaseFirestore.instance.collection(
        'Notations'); // Initialisation de la collection de notations
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
                  icon: Icon(Icons.add_location),
                  onPressed: () => _addNewLieu(context),
                ),
                IconButton(
                  icon: Icon(Icons.add_circle_outline),
                  onPressed: () => _addNewParcelle(context),
                ),
                IconButton(
                  icon: Icon(Icons.person_add),
                  onPressed: () => _createNewObservateur(context),
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
        textStyle: TextStyle(color: Colors.blueAccent),
        controller: _tabController,
      ),
      body: IndexedStack(
        index: _tabController.index,
        children: isAdmin ? adminPages : observerPages,
      ),
    );
  }

  Widget _buildAdminHomeView(BuildContext context) {
    String userEmail =
        FirebaseAuth.instance.currentUser?.email ?? 'Utilisateur';
    String adminMessage =
        isAdmin ? 'Vous êtes connecté en tant qu\'administrateur.' : '';

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'Bienvenue $userEmail',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16.0,
            ),
          ),
          SizedBox(height: 8.0),
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
    String userEmail =
        FirebaseAuth.instance.currentUser?.email ?? 'Utilisateur';

    // Observateur Home avec message et email en gras
    return Center(
      child: RichText(
        textAlign: TextAlign.center,
        text: TextSpan(
          style: TextStyle(
            color: Colors.black,
            fontSize: 16.0,
          ),
          children: [
            TextSpan(
              text: 'Bienvenue ',
            ),
            TextSpan(
              text: userEmail,
              style: TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
            TextSpan(
              text: ' vous êtes connecté en tant qu\'observateur.',
            ),
          ],
        ),
      ),
    );
  }

  void _addNewLieu(BuildContext context) {
    final TextEditingController _lieuIdController = TextEditingController();
    final TextEditingController _nomLieuController = TextEditingController();
    final TextEditingController _nombreParcellesController =
        TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Ajouter un nouveau lieu'),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                TextField(
                  controller: _lieuIdController,
                  decoration: InputDecoration(
                    labelText: 'ID du lieu',
                  ),
                ),
                TextField(
                  controller: _nomLieuController,
                  decoration: InputDecoration(
                    labelText: 'Nom du lieu',
                  ),
                ),
                TextField(
                  controller: _nombreParcellesController,
                  decoration: InputDecoration(
                    labelText: 'Nombre de parcelles',
                  ),
                  keyboardType: TextInputType.number,
                ),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: Text('Annuler'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text('Ajouter'),
              onPressed: () {
                final String lieuId = _lieuIdController.text.trim();
                final String nomLieu = _nomLieuController.text.trim();
                final int nombreParcelles =
                    int.tryParse(_nombreParcellesController.text) ?? 0;

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
                        SnackBar(content: Text('L\'ID du lieu existe déjà')),
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
                          SnackBar(content: Text('Lieu ajouté avec succès')),
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
                    SnackBar(
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
    final TextEditingController _parcelleIdController = TextEditingController();
    final TextEditingController _numeroParcelleController =
        TextEditingController();
    final TextEditingController _lieuIdController = TextEditingController();
    final TextEditingController _notationsController =
        TextEditingController(); // Contrôleur pour les notations

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Ajouter une nouvelle parcelle'),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                TextField(
                  controller: _parcelleIdController,
                  decoration: InputDecoration(
                    labelText: 'ID de la parcelle (custom)',
                  ),
                ),
                TextField(
                  controller: _numeroParcelleController,
                  decoration: InputDecoration(
                    labelText: 'Numéro de la parcelle',
                  ),
                  keyboardType: TextInputType.number,
                ),
                TextField(
                  controller: _lieuIdController,
                  decoration: InputDecoration(
                    labelText: 'ID du lieu référencé',
                  ),
                ),
                TextField(
                  controller: _notationsController,
                  decoration: InputDecoration(
                    labelText: 'Notations (séparées par des virgules)',
                  ),
                ),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: Text('Annuler'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text('Ajouter'),
              onPressed: () {
                final String parcelleId = _parcelleIdController.text.trim();
                final int? numeroParcelle =
                    int.tryParse(_numeroParcelleController.text);
                final String lieuId = _lieuIdController.text.trim();
                final String notations = _notationsController
                    .text; // Obtenez les valeurs de notation

                if (parcelleId.isNotEmpty &&
                    numeroParcelle != null &&
                    lieuId.isNotEmpty) {
                  FirebaseFirestore.instance
                      .collection('Parcelles')
                      .doc(parcelleId)
                      .get()
                      .then((docSnapshot) {
                    if (docSnapshot.exists) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                            content: Text('L\'ID de la parcelle existe déjà')),
                      );
                    } else {
                      FirebaseFirestore.instance
                          .collection('Parcelles')
                          .doc(parcelleId)
                          .set({
                        'Numero_parcelle': numeroParcelle,
                        'Lieu': FirebaseFirestore.instance.doc('Lieux/$lieuId'),
                      }).then((value) {
                        // Créez le document de notation correspondant
                        Map<String, dynamic> notationData = {
                          'Parcelle': parcellesCollection.doc(parcelleId),
                        };
                        // Ajoutez chaque champ de notation avec sa valeur
                        notations.split(',').forEach((notation) {
                          notationData[notation.trim()] = '';
                        });
                        // Enregistrez le document de notation dans la collection de notations
                        notationsCollection.doc(parcelleId).set(notationData);
                        Navigator.of(context).pop();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
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
                    SnackBar(
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

  void _createNewObservateur(BuildContext context) {
    final TextEditingController _observateurIdController =
        TextEditingController();
    final TextEditingController _nomController = TextEditingController();
    final TextEditingController _prenomController = TextEditingController();
    final TextEditingController _emailController = TextEditingController();
    final TextEditingController _lieuIdController = TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Créer un nouvel observateur'),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                TextField(
                  controller: _observateurIdController,
                  decoration: InputDecoration(
                    labelText: 'ID de l\'observateur (custom)',
                  ),
                ),
                TextField(
                  controller: _nomController,
                  decoration: InputDecoration(
                    labelText: 'Nom',
                  ),
                ),
                TextField(
                  controller: _prenomController,
                  decoration: InputDecoration(
                    labelText: 'Prénom',
                  ),
                ),
                TextField(
                  controller: _emailController,
                  decoration: InputDecoration(
                    labelText: 'Email',
                  ),
                ),
                TextField(
                  controller: _lieuIdController,
                  decoration: InputDecoration(
                    labelText: 'ID du lieu référencé',
                  ),
                ),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: Text('Annuler'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text('Créer'),
              onPressed: () {
                final String observateurId =
                    _observateurIdController.text.trim();
                final String nom = _nomController.text.trim();
                final String prenom = _prenomController.text.trim();
                final String email = _emailController.text.trim();
                final String lieuId = _lieuIdController.text.trim();

                if (observateurId.isNotEmpty &&
                    nom.isNotEmpty &&
                    prenom.isNotEmpty &&
                    email.isNotEmpty &&
                    lieuId.isNotEmpty) {
                  FirebaseFirestore.instance
                      .collection('Observateurs')
                      .doc(observateurId)
                      .get()
                      .then((docSnapshot) {
                    if (docSnapshot.exists) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                            content:
                                Text('L\'ID de l\'observateur existe déjà')),
                      );
                    } else {
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
                          SnackBar(
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
                    SnackBar(
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
