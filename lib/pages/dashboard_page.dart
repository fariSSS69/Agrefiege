import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({Key? key}) : super(key: key);

  @override
  _DashboardPageState createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  late User _user;
  String _userEmail = '';

  @override
  void initState() {
    super.initState();
    _getUserData();
  }

  Future<void> _getUserData() async {
    FirebaseAuth auth = FirebaseAuth.instance;
    _user = auth.currentUser!;
    _userEmail = _user.email!;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: Center(
        child: FutureBuilder<QuerySnapshot>(
          future: FirebaseFirestore.instance
              .collection('Observateurs')
              .where('email', isEqualTo: _userEmail)
              .get(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return CircularProgressIndicator();
            } else if (snapshot.hasError) {
              return Text('Error: ${snapshot.error}');
            } else if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return Text('No data found');
            } else {
              QueryDocumentSnapshot data = snapshot.data!.docs.first;
              List<DocumentReference>? lieuxRefs =
                  (data['Lieux'] as List<dynamic>?)?.cast<DocumentReference>();
              if (lieuxRefs == null || lieuxRefs.isEmpty) {
                return Text('No locations assigned');
              } else {
                return Column(
                  children: lieuxRefs.map((lieuRef) {
                    return Expanded(
                      child: _buildObservationsList(lieuRef),
                    );
                  }).toList(),
                );
              }
            }
          },
        ),
      ),
    );
  }

  Widget _buildObservationsList(DocumentReference lieuRef) {
    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance.doc(lieuRef.path).get(),
      builder: (context, lieuSnapshot) {
        if (lieuSnapshot.connectionState == ConnectionState.waiting) {
          return CircularProgressIndicator();
        } else if (lieuSnapshot.hasError) {
          return Text('Error: ${lieuSnapshot.error}');
        } else {
          String lieuName = lieuSnapshot.data!['Nom_lieu'] ??
              'Vous n\'êtes affilié à aucun lieu. Veuillez contacter l\'administrateur de l\'application pour être associé à un lieu.';
          return Column(
            children: [
              Text('Lieu: $lieuName'),
              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('Observations')
                    .where('Lieux', isEqualTo: lieuRef)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return CircularProgressIndicator();
                  } else if (snapshot.hasError) {
                    return Text('Error: ${snapshot.error}');
                  } else if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return Text(
                        "Aucune observation n'a été trouvée pour le lieu $lieuName. Veuillez en créer une nouvelle !");
                  } else {
                    return ListView(
                      shrinkWrap: true,
                      physics: ClampingScrollPhysics(),
                      children: snapshot.data!.docs.map((doc) {
                        Map<String, dynamic> observation =
                            doc.data() as Map<String, dynamic>;
                        return ListTile(
                          title: Text('Observation: ${observation['id']}'),
                          subtitle: Text('Details: ${observation['details']}'),
                        );
                      }).toList(),
                    );
                  }
                },
              ),
            ],
          );
        }
      },
    );
  }
}
