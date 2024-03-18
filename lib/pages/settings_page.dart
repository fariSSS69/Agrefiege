import 'package:flutter/material.dart';
import 'package:motion_tab_bar/MotionTabBarController.dart';
import 'package:motion_tab_bar/MotionTabBar.dart';
import 'package:agrefiege/pages/dashboard_page.dart';
import 'package:agrefiege/pages/home_page.dart';
import 'package:agrefiege/pages/profile_page.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({Key? key}) : super(key: key);

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage>
    with TickerProviderStateMixin {
  late MotionTabBarController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = MotionTabBarController(
      initialIndex: 3,
      length: 4,
      vsync: this,
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
      ),
      bottomNavigationBar: MotionTabBar(
        controller: _tabController,
        initialSelectedTab: "Paramètre",
        labels: const ["Tableau de bord", "Accueil", "Profil", "Paramètre"],
        icons: const [
          Icons.dashboard,
          Icons.home,
          Icons.people_alt,
          Icons.settings
        ],
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
            _tabController.index = value;
          });
          switch (value) {
            case 0:
              Navigator.of(context)
                  .push(MaterialPageRoute(builder: (_) => DashboardPage()));
              break;
            case 1:
              Navigator.of(context)
                  .push(MaterialPageRoute(builder: (_) => HomePage()));
              break;
            case 2:
              Navigator.of(context)
                  .push(MaterialPageRoute(builder: (_) => ProfilePage()));
              break;
            case 3:
              break;
          }
        },
      ),
      body: Center(
        child: const Text('Parametre Page Content'),
      ),
    );
  }
}
