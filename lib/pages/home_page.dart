import 'package:agrefiege/pages/dashboard_page.dart';
import 'package:agrefiege/pages/profile_page.dart';
import 'package:agrefiege/pages/settings_page.dart';
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
      Icons.people,
      Icons.settings,
    ];

    final List<IconData> observerTabs = [
      Icons.home,
      Icons.dashboard,
      Icons.people,
      Icons.settings,
    ];

    final List<Widget> adminPages = [
      _buildAdminHomeView(),
      DashboardPage(),
      ProfilePage(),
      SettingsPage(),
    ];

    final List<Widget> observerPages = [
      // _buildObserverView(), la premiere page qui s'affichera (definis plus bas)
      _buildObserverView(),
      DashboardPage(),
      ProfilePage(),
      SettingsPage(),
    ];

    return Scaffold(
      appBar: AppBar(),
      bottomNavigationBar: MotionTabBar(
        labels: isAdmin
            ? ["Home", "Dashboard", "Profile", "Settings"]
            : ["Home", "Dashboard", "Profile", "Settings"],
        initialSelectedTab: isAdmin ? "Home" : "Home",
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
    // Admin Home avec list
    return Center(
      child: DropdownButton<String>(
        items: <String>['Option 1', 'Option 2', 'Option 3', 'Option 4']
            .map((String value) {
          return DropdownMenuItem<String>(
            value: value,
            child: Text(value),
          );
        }).toList(),
        onChanged: (_) {
          // Logic to handle selection here
        },
      ),
    );
  }

  Widget _buildObserverView() {
    // Observateur Home avec message
    return Center(
      child: Text(
          'Vous êtes connecté en tant qu\'observateur, vous êtes observateur du site de'),
    );
  }
}
