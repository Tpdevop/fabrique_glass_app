// home_page.dart
import 'package:flutter/material.dart';
import 'package:myapp/data/mongo_database.dart';
import 'factory_details_page.dart'; // Create this page to show factory details
import 'received_requests_page.dart'; // Create this page to show received requests

class HomePage extends StatefulWidget {
  final String userType;
  final String userEmail;

  HomePage({required this.userType, required this.userEmail});

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late Future<Map<String, dynamic>> _userFuture;
  late int _clientId;

  @override
  void initState() {
    super.initState();
    _userFuture = MongoDatabase.getUserByEmail(widget.userEmail);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('الرئيسية'), // Home in Arabic
        actions: [
          IconButton(
            icon: Icon(Icons.menu),
            onPressed: () {
              // Add your menu action here
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: FutureBuilder<Map<String, dynamic>>(
          future: _userFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(child: CircularProgressIndicator());
            } else if (snapshot.hasError) {
              return Center(child: Text('Erreur: ${snapshot.error}'));
            } else if (!snapshot.hasData) {
              return Center(child: Text('Aucun utilisateur trouvé.'));
            } else {
              final user = snapshot.data!;
              _clientId = user['ID_Client'];
              if (widget.userType == 'client') {
                return _buildClientView(_clientId);
              } else if (widget.userType == 'proprietaire') {
                return _buildProprietaireView();
              } else {
                return Center(child: Text('Type d\'utilisateur inconnu.'));
              }
            }
          },
        ),
      ),
    );
  }

  Widget _buildClientView(int clientId) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        Text(
          'Bienvenue, Client',
          style: TextStyle(fontSize: 24),
        ),
        Expanded(
          child: FutureBuilder<List<Map<String, dynamic>>>(
            future: MongoDatabase.getAllFactories(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(child: CircularProgressIndicator());
              } else if (snapshot.hasError) {
                return Center(child: Text('Erreur: ${snapshot.error}'));
              } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return Center(child: Text('Aucune fabrique trouvée.'));
              } else {
                final factories = snapshot.data!;
                return ListView.builder(
                  itemCount: factories.length,
                  itemBuilder: (context, index) {
                    final factory = factories[index];
                    String nom = factory['nom'];
                    String prenom = factory['prenom'];
                    return ListTile(
                      title: Text("La fabrique de $nom $prenom"),
                      subtitle: Text(factory['location']),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => FactoryDetailsPage(
                              factoryId: factory['ID_Proprietaire'],
                              clientId: clientId,
                            ),
                          ),
                        );
                      },
                    );
                  },
                );
              }
            },
          ),
        ),
      ],
    );
  }

  Widget _buildProprietaireView() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        Text(
          'Bienvenue, Propriétaire',
          style: TextStyle(fontSize: 24),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) =>
                    ReceivedRequestsPage(userEmail: widget.userEmail),
              ),
            );
          },
          child: Text('Voir les demandes reçues'),
        ),
      ],
    );
  }
}
