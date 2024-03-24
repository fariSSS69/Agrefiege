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

  @override
  void initState() {
    super.initState();
    // TODO Changer l'adresse email par l'adresse email de l'administrateur
    isAdmin = widget.userEmail == 'faris.maisonneuve@wanadoo.fr' ||
        FirebaseAuth.instance.currentUser?.email ==
            'faris.maisonneuve@wanadoo.fr';
    _tabController =
        MotionTabBarController(length: isAdmin ? 4 : 4, vsync: this);
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
      _buildAdminHomeView(),
      DashboardPage(),
      ObservationPage(),
      SettingsPage(),
    ];

    final List<Widget> observerPages = [
      // _buildObserverView(), la premiere page qui s'affichera (definis plus bas)
      _buildObserverView(),
      DashboardPage(),
      ObservationPage(),
      SettingsPage(),
    ];

    return Scaffold(
      appBar: AppBar(),
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

  Widget _buildAdminHomeView() {
    return FutureBuilder<QuerySnapshot>(
      future: FirebaseFirestore.instance.collection('Lieux').get(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Erreur: ${snapshot.error}'));
        }
        if (snapshot.hasData) {
          if (snapshot.data!.docs.isEmpty) {
            return Center(child: Text('Aucun lieu trouvé.'));
          }

          List<DropdownMenuItem<String>> dropdownItems = snapshot.data!.docs
              .map((doc) {
                var lieu = doc.data() as Map<String, dynamic>;
                if (lieu['Nom_lieu'] == null) {
                  return null;
                }
                return DropdownMenuItem<String>(
                  value: lieu['Nom_lieu'],
                  child: Text(lieu['Nom_lieu']),
                );
              })
              .where((item) => item != null)
              .cast<DropdownMenuItem<String>>()
              .toList();

          if (dropdownItems.isEmpty) {
            return Center(child: Text('Aucun lieu trouvé.'));
          }

          return Center(
            child: DropdownButton<String>(
              value: dropdownItems.first.value,
              items: dropdownItems,
              onChanged: (value) {
                // A changer TODO
                print('Lieu sélectionné: $value');
              },
            ),
          );
        }
        return Center(child: Text('Aucune donnée disponible.'));
      },
    );
  }

  Widget _buildObserverView() {
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
}
