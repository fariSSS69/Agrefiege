import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({Key? key}) : super(key: key);

  @override
  _SettingsPageState createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  Future<void> _signOut() async {
    await FirebaseAuth.instance.signOut();
    Navigator.of(context).pushReplacementNamed('/login');
  }

  Future<void> _showSignOutConfirmationDialog() async {
    return showDialog<void>(
      context: context,
      barrierDismissible:
          true, // L'utilisateur peut fermer la boîte de dialogue en cliquant à l'extérieur
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Text(
            'Confirmer la déconnexion',
            style: TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text('Voulez-vous vraiment vous déconnecter ?'),
              ],
            ),
          ),
          actionsPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          actionsAlignment: MainAxisAlignment.spaceBetween,
          actions: <Widget>[
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                primary: Colors.redAccent,
                onPrimary: Colors.white,
              ),
              child: Text('Se déconnecter'),
              onPressed: () {
                Navigator.of(dialogContext).pop();
                _signOut();
              },
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                primary: Colors.grey.shade200,
                onPrimary: Colors.black,
              ),
              child: Text('Annuler'),
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
            ),
          ],
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: <Widget>[
          SizedBox(
            height: 50,
            child: Container(
              color: Colors.red,
              child: Center(
                child: InkWell(
                  onTap:
                      _showSignOutConfirmationDialog, // Affiche la boîte de dialogue de confirmation
                  child: Text(
                    'Se déconnecter',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: Center(
                // Contenu de la page Paramètre
                ),
          ),
        ],
      ),
    );
  }
}
