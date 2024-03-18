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

  @override
  void initState() {
    super.initState();
    _motionTabBarController = MotionTabBarController(
      initialIndex: 1,
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
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
      ),
      bottomNavigationBar: MotionTabBar(
        controller: _motionTabBarController,
        initialSelectedTab: "Accueil",
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
            _motionTabBarController.index = value;
          });
          switch (value) {
            case 0:
              Navigator.of(context)
                  .push(MaterialPageRoute(builder: (_) => DashboardPage()));
              break;
            case 1:
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
      body:
          Container(), 
          
    );
  }
}
