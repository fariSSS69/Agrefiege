import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

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
          title: const Text(
            'Confirmer la déconnexion',
            style: TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
          content: const SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text('Voulez-vous vraiment vous déconnecter ?'),
              ],
            ),
          ),
          actionsPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          actionsAlignment: MainAxisAlignment.spaceBetween,
          actions: <Widget>[
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                foregroundColor: Colors.white, backgroundColor: Colors.redAccent,
              ),
              child: const Text('Se déconnecter'),
              onPressed: () {
                Navigator.of(dialogContext).pop();
                _signOut();
              },
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                foregroundColor: Colors.black, backgroundColor: Colors.grey.shade200,
              ),
              child: const Text('Annuler'),
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
                  child: const Text(
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
          const Expanded(
            child: Center(
                // Contenu de la page Paramètre
                ),
          ),
        ],
      ),
    );
  }
}
