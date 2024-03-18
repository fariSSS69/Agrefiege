import 'package:flutter/material.dart';
import 'package:motion_tab_bar/MotionTabBar.dart';
import 'package:motion_tab_bar/MotionTabBarController.dart';
import 'package:agrefiege/pages/home_page.dart';
import 'package:agrefiege/pages/profile_page.dart';
import 'package:agrefiege/pages/settings_page.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({Key? key}) : super(key: key);

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage>
    with TickerProviderStateMixin {
  late MotionTabBarController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = MotionTabBarController(
      initialIndex: 0,
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
        initialSelectedTab: "Tableau de bord",
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
              Navigator.of(context)
                  .push(MaterialPageRoute(builder: (_) => SettingsPage()));
              break;
          }
        },
      ),
      body: Center(
        child: const Text('Tableau de bord Page Content'),
      ),
    );
  }
}
