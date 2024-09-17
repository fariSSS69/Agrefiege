import 'package:agrefiege/pages/home_page.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:agrefiege/widgets/form_container_widget.dart';
import 'package:agrefiege/global/common/toast.dart';
import '../../firebase_auth_implementation/firebase_auth_services.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  bool _isSigning = false;
  final FirebaseAuthService _auth = FirebaseAuthService();
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Configurer la persistance locale pour que l'utilisateur reste connecté
    _setAuthPersistence();

    // Vérifier si un utilisateur est déjà connecté
    _checkUserStatus();
  }

  Future<void> _setAuthPersistence() async {
    try {
      await FirebaseAuth.instance.setPersistence(Persistence.LOCAL);
    } catch (e) {
      print("Erreur lors de la configuration de la persistance: $e");
    }
  }

  Future<void> _checkUserStatus() async {
    User? currentUser = _firebaseAuth.currentUser;

    if (currentUser != null) {
      // Si un utilisateur est déjà connecté, rediriger vers la page HomePage
      bool isObserver = await verifierObservateur(currentUser.email!);
      if (isObserver) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => HomePage(userEmail: currentUser.email),
          ),
        );
      } else {
        showToast(message: "L'utilisateur n'est pas un observateur.");
      }
    }
  }

  Future<bool> verifierObservateur(String email) async {
    final QuerySnapshot observateurs = await FirebaseFirestore.instance
        .collection('Observateurs')
        .where('email', isEqualTo: email)
        .get();

    return observateurs.docs.isNotEmpty;
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 15),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                "Connexion",
                style: TextStyle(fontSize: 27, fontWeight: FontWeight.bold),
              ),
              const SizedBox(
                height: 30,
              ),
              FormContainerWidget(
                controller: _emailController,
                hintText: "Email",
                isPasswordField: false,
              ),
              const SizedBox(
                height: 10,
              ),
              FormContainerWidget(
                controller: _passwordController,
                hintText: "Mot de passe",
                isPasswordField: true,
              ),
              const SizedBox(
                height: 30,
              ),
              GestureDetector(
                onTap: () {
                  _signIn();
                },
                child: Container(
                  width: double.infinity,
                  height: 45,
                  decoration: BoxDecoration(
                    color: Colors.green,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Center(
                    child: _isSigning
                        ? const CircularProgressIndicator(
                            color: Colors.white,
                          )
                        : const Text(
                            "Connexion",
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              GestureDetector(
                onTap: () {
                  _resetPassword();
                },
                child: const Text(
                  "Mot de passe oublié ?",
                  style: TextStyle(
                    color: Colors.blue,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _signIn() async {
    setState(() {
      _isSigning = true;
    });

    String email = _emailController.text.trim();
    String password = _passwordController.text.trim();

    try {
      UserCredential userCredential = await _firebaseAuth
          .signInWithEmailAndPassword(email: email, password: password);

      bool isObserver = await verifierObservateur(email);
      if (isObserver) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) =>
                HomePage(userEmail: userCredential.user?.email),
          ),
        );
      } else {
        showToast(message: "L'utilisateur n'est pas un observateur.");
      }
    } on FirebaseAuthException catch (e) {
      showToast(message: "Une erreur est survenue: ${e.message}");
    } finally {
      setState(() {
        _isSigning = false;
      });
    }
  }

  void _resetPassword() async {
    String email = _emailController.text.trim();

    try {
      await _firebaseAuth.sendPasswordResetEmail(email: email);
      showToast(message: "Email de réinitialisation envoyé à $email");
    } catch (e) {
      showToast(message: "Une erreur est survenue: $e");
    }
  }
}
