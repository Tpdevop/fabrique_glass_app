// home_page.dart
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:myapp/auth/login.dart';
import 'package:myapp/data/mongo_database.dart';
import 'package:myapp/screens/client_view.dart';
import 'package:myapp/screens/proprietaire_view.dart';
import 'package:myapp/screens/drawer_content.dart';

class HomePage extends StatefulWidget {
  final String userType;
  final String userEmail;

  HomePage({required this.userType, required this.userEmail});

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with SingleTickerProviderStateMixin {
  late Future<Map<String, dynamic>> _userFuture;
  late AnimationController _controller;
  late Animation<double> _animation;
  late Animation<Offset> _slideAnimation;
  String _userPhoto = '';
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  int _selectedIndex = 2;

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
    Map<String, dynamic> userData = await MongoDatabase.getUserByEmail(widget.userEmail);
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

  void _showEditQuantityDialog(BuildContext context, int currentQuantity) {
    TextEditingController quantityController = TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Changer la quantité'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Quantité actuelle: $currentQuantity'),
              TextField(
                controller: quantityController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(hintText: "Entrez la nouvelle quantité"),
              ),
            ],
          ),
          actions: <Widget>[
            TextButton(
              child: Text('Annuler'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text('Confirmer'),
              onPressed: () {
                int? newQuantity = int.tryParse(quantityController.text);
                if (newQuantity != null) {
                  _updateQuantity(newQuantity);
                  Navigator.of(context).pop();
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text('Veuillez entrer une quantité valide'),
                  ));
                }
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _updateQuantity(int newQuantity) async {
    try {
      await MongoDatabase.updateOwnerQuantity(widget.userEmail, newQuantity);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Quantité mise à jour avec succès'),
      ));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Erreur lors de la mise à jour de la quantité : $e'),
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        title: Text('الرئيسية', style: TextStyle(color: Colors.white, fontSize: 27.0)),
        backgroundColor: Colors.deepPurple[700],
        actions: [
          if (widget.userType == 'proprietaire')
            IconButton(
              icon: Icon(Icons.edit, color: Colors.white, size: 30.0),
              onPressed: () async {
                final userData = await _userFuture;
                final currentQuantity = userData['quantite'] ?? 0;
                _showEditQuantityDialog(context, currentQuantity);
              },
            ),
          IconButton(
            icon: Icon(Icons.account_circle, color: Colors.white, size: 30.0),
            onPressed: _openDrawer,
          ),
        ],
        automaticallyImplyLeading: false,
      ),
      endDrawer: DrawerContent(userFuture: _userFuture, userEmail: widget.userEmail, userPhoto: _userPhoto, pickImage: _pickImage, logout: _logout),
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
                  return ClientView(clientId: user['ID_Client'] ?? 0, animation: _animation, slideAnimation: _slideAnimation);
                } else if (widget.userType == 'proprietaire') {
                  int currentQuantity = user['quantity'] ?? 0; // Assurez-vous que le champ 'quantity' existe dans les données utilisateur
                  return ProprietaireView(ownerId: user['ID_Proprietaire'] ?? 0, animation: _animation, slideAnimation: _slideAnimation, selectedIndex: _selectedIndex, onItemTapped: _onItemTapped, onEditQuantity: () => _showEditQuantityDialog(context, currentQuantity));
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
                BottomNavigationBarItem(icon: Icon(Icons.cancel), label: 'مرفوضة'),
                BottomNavigationBarItem(icon: Icon(Icons.check_circle), label: 'مقبولة'),
                BottomNavigationBarItem(icon: Icon(Icons.pending), label: 'قيد الانتظار'),
              ],
              currentIndex: _selectedIndex,
              selectedItemColor: Colors.deepPurple[700],
              onTap: _onItemTapped,
            )
          : null,
    );
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }
}
