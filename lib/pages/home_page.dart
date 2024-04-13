import 'package:agrefiege/pages/dashboard_page.dart';
import 'package:agrefiege/pages/observation_page.dart';
import 'package:agrefiege/pages/settings_page.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:motion_tab_bar/MotionTabBarController.dart';
import 'package:motion_tab_bar/MotionTabBar.dart';

class HomePage extends StatefulWidget {
  final String? userEmail;

  const HomePage({super.key, this.userEmail});

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with TickerProviderStateMixin {
  late MotionTabBarController _tabController;
  late bool isAdmin;
  String _userEmail = '';

  late CollectionReference<Map<String, dynamic>>
      parcellesCollection; // Déclaration de la collection de parcelles
  late CollectionReference<Map<String, dynamic>>
      notationsCollection; // Déclaration de la collection de notations

  @override
  void initState() {
    super.initState();
    _userEmail = FirebaseAuth.instance.currentUser?.email ?? '';
    isAdmin = _userEmail == 'faris.maisonneuve@wanadoo.fr' ||
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
      const DashboardPage(),
      const ObservationPage(),
      const SettingsPage(),
    ];

    final List<Widget> observerPages = [
      _buildObserverView(context),
      const DashboardPage(),
      const ObservationPage(),
      const SettingsPage(),
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
    // Observateur Home avec message et email en gras
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
    final TextEditingController parcelleIdController = TextEditingController();
    final TextEditingController numeroParcelleController =
        TextEditingController();
    final TextEditingController lieuIdController = TextEditingController();
    final TextEditingController notationsController =
        TextEditingController(); // Contrôleur pour les notations

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Ajouter une nouvelle parcelle'),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                TextField(
                  controller: parcelleIdController,
                  decoration: const InputDecoration(
                    labelText: 'ID de la parcelle (custom)',
                  ),
                ),
                TextField(
                  controller: numeroParcelleController,
                  decoration: const InputDecoration(
                    labelText: 'Numéro de la parcelle',
                  ),
                  keyboardType: TextInputType.number,
                ),
                TextField(
                  controller: lieuIdController,
                  decoration: const InputDecoration(
                    labelText: 'ID du lieu référencé',
                  ),
                ),
                TextField(
                  controller: notationsController,
                  decoration: const InputDecoration(
                    labelText: 'Notations (séparées par des virgules)',
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
                final String parcelleId = parcelleIdController.text.trim();
                final int? numeroParcelle =
                    int.tryParse(numeroParcelleController.text);
                final String lieuId = lieuIdController.text.trim();
                final String notations =
                    notationsController.text; // Obtenez les valeurs de notation

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
                        const SnackBar(
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
  }

  void _createNewObservateur(BuildContext context) {
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
              onPressed: () async {
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
                      await FirebaseAuth.instance
                          .createUserWithEmailAndPassword(
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
                          FirebaseFirestore.instance
                              .collection('Lieux')
                              .doc(lieuId)
                        ],
                      });

                      Navigator.of(context).pop();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text('Observateur créé avec succès')),
                      );
                    }
                  } catch (error) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                          content: Text(
                              'Erreur lors de la création de l\'observateur: $error')),
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
}
