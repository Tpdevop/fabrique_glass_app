// ignore_for_file: prefer_const_constructors, use_build_context_synchronously

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:myapp/auth/login.dart';
import 'package:myapp/data/mongo_database.dart';
import 'factory_details_page.dart';
import 'received_requests_page.dart';

class HomePage extends StatefulWidget {
  final String userType;
  final String userEmail;

  HomePage({required this.userType, required this.userEmail});

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage>
    with SingleTickerProviderStateMixin {
  late Future<Map<String, dynamic>> _userFuture;
  late AnimationController _controller;
  late Animation<double> _animation;
  late Animation<Offset> _slideAnimation;
  String _userPhoto = ''; // Variable to store user's photo URL
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _userFuture = _fetchUserData();
    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    );
    _slideAnimation = Tween<Offset>(
      begin: Offset(0, 0.5),
      end: Offset(0, 0),
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));

    // Start the animation
    _controller.forward();
  }

  Future<Map<String, dynamic>> _fetchUserData() async {
    Map<String, dynamic> userData =
        await MongoDatabase.getUserByEmail(widget.userEmail);
    _userPhoto = userData['photo'] ??
        ''; // Assuming 'photo' is the key for user's photo URL
    return userData;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _logout() {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => LoginPage()),
      (Route<dynamic> route) => false,
    );
  }

  void _openDrawer() {
    _scaffoldKey.currentState!.openEndDrawer();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _userPhoto = pickedFile.path;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        title: Text('الرئيسية',
            style: TextStyle(color: Colors.white, fontSize: 27.0)),
        backgroundColor: Colors.deepPurple[700],
        actions: [
          IconButton(
            icon: Icon(
              Icons.account_circle,
              color: Colors.white,
              size: 30.0,
            ),
            onPressed: _openDrawer,
          ),
        ],
        automaticallyImplyLeading: false,
      ),
      endDrawer: Drawer(
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
              return Directionality(
                textDirection: TextDirection.rtl,
                child: ListView(
                  padding: EdgeInsets.zero,
                  children: <Widget>[
                    UserAccountsDrawerHeader(
                      accountName: Text('${user['nom']} ${user['prenom']}'),
                      accountEmail: Text(widget.userEmail),
                      currentAccountPicture: Stack(
                        children: [
                          CircleAvatar(
                            backgroundImage: _userPhoto.isNotEmpty
                                ? FileImage(File(_userPhoto))
                                : AssetImage('images/person_icon.png'),
                            radius: 40,
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: GestureDetector(
                              onTap: _pickImage,
                              child: CircleAvatar(
                                backgroundColor: Colors.white,
                                radius: 15,
                                child: Icon(
                                  Icons.camera_alt,
                                  size: 15,
                                  color: Colors.deepPurple[700],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    ListTile(
                      leading: Icon(Icons.person, color: Colors.deepPurple),
                      title: Text('معلومات المستخدم'),
                      onTap: () {
                        // Handle user information tap
                      },
                    ),
                    Divider(),
                    ListTile(
                      leading: Icon(Icons.settings, color: Colors.deepPurple),
                      title: Text('الإعدادات'),
                      onTap: () {
                        // Handle settings tap
                      },
                    ),
                    Divider(),
                    ListTile(
                      leading: Icon(Icons.logout, color: Colors.red),
                      title: Text(
                        'تسجيل الخروج',
                        style: TextStyle(color: Colors.red),
                      ),
                      onTap: _logout,
                    ),
                  ],
                ),
              );
            }
          },
        ),
      ),
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: Padding(
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
                final clientId = user['ID_Client'];
                if (widget.userType == 'client') {
                  return _buildClientView(clientId);
                } else if (widget.userType == 'proprietaire') {
                  return _buildProprietaireView();
                } else {
                  return Center(child: Text('Type d\'utilisateur inconnu.'));
                }
              }
            },
          ),
        ),
      ),
    );
  }

  Widget _buildClientView(int clientId) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'مرحبًا بك',
          style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.deepPurple[700]),
        ),
        SizedBox(height: 16),
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
                    return FactoryCard(
                      factory: factory,
                      animation: _animation,
                      slideAnimation: _slideAnimation,
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
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'مرحبًا بك',
          style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.deepPurple[700]),
        ),
        SizedBox(height: 16),
        ElevatedButton.icon(
          icon: Icon(Icons.receipt),
          label: Text('Voir les demandes reçues'),
          style: ElevatedButton.styleFrom(
            foregroundColor: Colors.white,
            backgroundColor: Colors.orange,
            textStyle: TextStyle(fontWeight: FontWeight.bold),
            padding: EdgeInsets.symmetric(vertical: 12, horizontal: 24),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10.0),
            ),
          ),
          onPressed: () async {
            String trimmedEmail = widget.userEmail.trim();
            int? ownerId =
                await MongoDatabase.getProprietaireParEmail(trimmedEmail);
            if (ownerId != null) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ReceivedRequestsPage(ownerId: ownerId),
                ),
              );
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                    content: Text('Propriétaire non trouvé pour cet email.')),
              );
            }
          },
        ),
      ],
    );
  }
}

class FactoryCard extends StatelessWidget {
  final Map<String, dynamic> factory;
  final Animation<double> animation;
  final Animation<Offset> slideAnimation;
  final VoidCallback onTap;

  const FactoryCard({
    required this.factory,
    required this.animation,
    required this.slideAnimation,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    String nom = factory['nom'];
    String prenom = factory['prenom'];

    return SlideTransition(
      position: slideAnimation,
      child: Card(
        margin: EdgeInsets.symmetric(vertical: 8.0, horizontal: 10.0),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15.0),
        ),
        elevation: 5,
        child: ListTile(
          contentPadding: EdgeInsets.all(15.0),
          leading: FadeTransition(
            opacity: animation,
            child: Icon(Icons.factory, color: Colors.orange, size: 40),
          ),
          title: Text(
            "La fabrique de $nom $prenom",
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
          subtitle: Text(factory['location'], style: TextStyle(fontSize: 16)),
          trailing: Icon(Icons.arrow_forward_ios, color: Colors.grey),
          onTap: onTap,
        ),
      ),
    );
  }
}
