import 'package:flutter/material.dart';
import 'package:motion_tab_bar/MotionTabBar.dart';
import 'package:motion_tab_bar/MotionTabBarController.dart';
import 'package:agrefiege/pages/dashboard_page.dart';
import 'package:agrefiege/pages/profile_page.dart';
import 'package:agrefiege/pages/settings_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with TickerProviderStateMixin {
  late MotionTabBarController _motionTabBarController;
  int _selectedIndex = 1; // L'index de départ correspond à l'onglet "Accueil"

  @override
  void initState() {
    super.initState();
    _motionTabBarController = MotionTabBarController(
      initialIndex: _selectedIndex,
      length: 4,
      vsync: this,
    );
  }

  @override
  void dispose() {
    _motionTabBarController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Les pages que vous souhaitez afficher
    final List<Widget> _pages = [
      DashboardPage(),
      Container(), // Remplacez par votre véritable page d'accueil
      ProfilePage(),
      SettingsPage(),
    ];

    return Scaffold(
      appBar: AppBar(
      ),
      bottomNavigationBar: MotionTabBar(
        controller: _motionTabBarController,
        initialSelectedTab: "Accueil", // L'onglet sélectionné au démarrage
        labels: const ["Tableau de bord", "Accueil", "Profil", "Paramètre"],
        icons: const [Icons.dashboard, Icons.home, Icons.people_alt, Icons.settings],
        tabSize: 50,
        tabBarHeight: 55,
        textStyle: const TextStyle(
          fontSize: 12,
          color: Colors.black,
          fontWeight: FontWeight.w500,
        ),
        tabIconColor: Colors.blue[600],
        tabIconSize: 28.0,
        tabIconSelectedSize: 26.0,
        tabSelectedColor: Colors.blue[900],
        tabIconSelectedColor: Colors.white,
        tabBarColor: Colors.white,
        onTabItemSelected: (int value) {
          setState(() {
            _selectedIndex = value; // Mettre à jour l'index de l'onglet sélectionné
            _motionTabBarController.index = value; // Mettre à jour le contrôleur de l'onglet
          });
        },
      ),
      body: IndexedStack(
        index: _selectedIndex, // L'index de la page actuelle
        children: _pages, // Les pages à afficher
      ),
    );
  }
}