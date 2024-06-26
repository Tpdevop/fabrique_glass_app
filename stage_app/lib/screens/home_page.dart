// ignore_for_file: prefer_const_constructors

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mongo_dart/mongo_dart.dart' as mongo;
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
  String _userPhoto = '';
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  int _selectedIndex = 0;

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

    _controller.forward();
  }

  Future<Map<String, dynamic>> _fetchUserData() async {
    Map<String, dynamic> userData =
        await MongoDatabase.getUserByEmail(widget.userEmail);
    _userPhoto = userData['photo'] ?? '';
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
            icon: Icon(Icons.account_circle, color: Colors.white, size: 30.0),
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
                          Hero(
                            tag: 'userPhoto',
                            child: CircleAvatar(
                              backgroundImage: _userPhoto.isNotEmpty
                                  ? FileImage(File(_userPhoto))
                                  : AssetImage('images/person_icon.png'),
                              radius: 40,
                            ),
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: GestureDetector(
                              onTap: _pickImage,
                              child: CircleAvatar(
                                backgroundColor: Colors.white,
                                radius: 15,
                                child: Icon(Icons.camera_alt,
                                    size: 15, color: Colors.deepPurple[700]),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    ListTile(
                      leading: Icon(Icons.logout, color: Colors.red),
                      title: Text('تسجيل الخروج',
                          style: TextStyle(color: Colors.red)),
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
                if (widget.userType == 'client') {
                  return _buildClientView(user['ID_Client'] ?? 0);
                } else if (widget.userType == 'proprietaire') {
                  return _buildProprietaireView(user['ID_Proprietaire'] ?? 0);
                } else {
                  return Center(child: Text('Type d\'utilisateur inconnu.'));
                }
              }
            },
          ),
        ),
      ),
      bottomNavigationBar: widget.userType == 'proprietaire'
          ? BottomNavigationBar(
              items: const <BottomNavigationBarItem>[
                BottomNavigationBarItem(
                  icon: Icon(Icons.cancel),
                  label: 'مرفوضة',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.check_circle),
                  label: 'مقبولة',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.pending),
                  label: 'قيد الانتظار',
                ),
              ],
              currentIndex: _selectedIndex,
              selectedItemColor: Colors.deepPurple[700],
              onTap: _onItemTapped,
            )
          : null,
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

  Widget _buildProprietaireView(int ownerId) {
    String status;
    if (_selectedIndex == 0) {
      status = 'refusée';
    } else if (_selectedIndex == 1) {
      status = 'acceptée';
    } else {
      status = 'attendant';
    }

    return FutureBuilder<List<Map<String, dynamic>>>(
      future: MongoDatabase.getRequestsByOwnerAndStatus(ownerId, status),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(child: Text('Erreur: ${snapshot.error}'));
        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Center(child: Text('Aucune demande trouvée.'));
        } else {
          final requests = snapshot.data!;
          return ListView.builder(
            itemCount: requests.length,
            itemBuilder: (context, index) {
              final request = requests[index];
              return FutureBuilder<Map<String, dynamic>>(
                future: MongoDatabase.getUserById(request['ID_Client']),
                builder: (context, clientSnapshot) {
                  if (clientSnapshot.connectionState ==
                      ConnectionState.waiting) {
                    return Center(child: CircularProgressIndicator());
                  } else if (clientSnapshot.hasError) {
                    return Center(
                        child: Text('Erreur: ${clientSnapshot.error}'));
                  } else if (!clientSnapshot.hasData) {
                    return Center(child: Text('Aucun client trouvé.'));
                  } else {
                    final client = clientSnapshot.data!;
                    return SlideTransition(
                      position: _slideAnimation,
                      child: FadeTransition(
                        opacity: _animation,
                        child: Card(
                          margin: EdgeInsets.symmetric(
                              vertical: 8.0, horizontal: 10.0),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15.0),
                          ),
                          elevation: 5,
                          child: ListTile(
                            title: Text('الكمية: ${request['quantite']} كغ',
                                style: TextStyle(fontWeight: FontWeight.bold)),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                    'الحالة: ${_translateStatus(request['etat'])}'),
                                Text(
                                    'العميل: ${client['nom']} ${client['prenom']}'),
                              ],
                            ),
                            trailing: _buildRequestActions(request, ownerId),
                          ),
                        ),
                      ),
                    );
                  }
                },
              );
            },
          );
        }
      },
    );
  }

  Widget _buildRequestActions(Map<String, dynamic> request, int ownerId) {
    if (request['etat'] == 'attendant') {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: Icon(Icons.check_circle, color: Colors.green),
            onPressed: () {
              _updateRequestStatus(request, 'acceptée', ownerId);
            },
          ),
          IconButton(
            icon: Icon(Icons.cancel, color: Colors.red),
            onPressed: () {
              _updateRequestStatus(request, 'refusée', ownerId);
            },
          ),
        ],
      );
    } else if (request['etat'] == 'acceptée') {
      return Icon(Icons.check_circle, color: Colors.green);
    } else if (request['etat'] == 'refusée') {
      return Icon(Icons.cancel, color: Colors.red);
    } else {
      return Container();
    }
  }

  Future<void> _updateRequestStatus(
      Map<String, dynamic> request, String status, int ownerId) async {
    final requestId = request['_id'] as mongo.ObjectId; // Ensure proper cast
    final quantite = request['quantite'] as int;
    await MongoDatabase.updateRequestStatus(
        requestId, status, quantite, ownerId);
    setState(() {
      _userFuture = _fetchUserData(); // Refresh user data
    });
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  String _translateStatus(String status) {
    switch (status) {
      case 'attendant':
        return 'قيد الانتظار';
      case 'acceptée':
        return 'مقبولة';
      case 'refusée':
        return 'مرفوضة';
      default:
        return status;
    }
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
      child: FadeTransition(
        opacity: animation,
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
      ),
    );
  }
}
