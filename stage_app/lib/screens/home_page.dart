// home_page.dart
// ignore_for_file: prefer_const_constructors, use_build_context_synchronously, prefer_const_literals_to_create_immutables

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

class _HomePageState extends State<HomePage>
    with SingleTickerProviderStateMixin {
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

  void _showEditQuantityDialog(BuildContext context, int currentQuantity,
      Function(int) onQuantityUpdated) {
    TextEditingController quantityController = TextEditingController();
    String? errorMessage;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              title: Row(
                children: [
                  Icon(Icons.edit, color: Colors.deepPurple[700]),
                  SizedBox(width: 10),
                  Text(
                    'تغيير كمية الثلج',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
                  ),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'الكمية الحالية: $currentQuantity',
                    style: TextStyle(fontSize: 16),
                  ),
                  SizedBox(height: 10),
                  TextField(
                    controller: quantityController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      prefixIcon:
                          Icon(Icons.numbers, color: Colors.deepPurple[700]),
                      hintText: "أدخل الكمية الجديدة",
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(10)),
                      ),
                    ),
                  ),
                  if (errorMessage != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 10.0),
                      child: Text(
                        errorMessage!,
                        style: TextStyle(color: Colors.red),
                      ),
                    ),
                ],
              ),
              actions: <Widget>[
                ElevatedButton.icon(
                  icon: Icon(Icons.cancel, color: Colors.white),
                  label: Text('إلغاء'),
                  style: ElevatedButton.styleFrom(
                    foregroundColor: Colors.white,
                    backgroundColor: Colors.red,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  ),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
                ElevatedButton.icon(
                  icon: Icon(Icons.check, color: Colors.white),
                  label: Text('تأكيد'),
                  style: ElevatedButton.styleFrom(
                    foregroundColor: Colors.white,
                    backgroundColor: Colors.green,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  ),
                  onPressed: () {
                    int? newQuantity = int.tryParse(quantityController.text);
                    if (newQuantity != null) {
                      _updateQuantity(newQuantity, onQuantityUpdated);
                      Navigator.of(context).pop();
                    } else {
                      setState(() {
                        errorMessage = 'الرجاء إدخال كمية صالحة';
                      });
                    }
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _updateQuantity(
      int newQuantity, Function(int) onQuantityUpdated) async {
    try {
      await MongoDatabase.updateOwnerQuantity(widget.userEmail, newQuantity);
      onQuantityUpdated(newQuantity);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('تم تحديث الكمية بنجاح'),
      ));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('خطأ في تحديث الكمية: $e'),
      ));
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
          if (widget.userType == 'proprietaire')
            IconButton(
              icon: Icon(Icons.edit, color: Colors.white, size: 30.0),
              onPressed: () async {
                final userData = await _userFuture;
                final currentQuantity = userData['quantite'] ?? 0;
                _showEditQuantityDialog(context, currentQuantity,
                    (newQuantity) {
                  setState(() {
                    _userFuture = Future.value({
                      ...userData,
                      'quantite': newQuantity,
                    });
                  });
                });
              },
            ),
          IconButton(
            icon: Icon(Icons.account_circle, color: Colors.white, size: 30.0),
            onPressed: _openDrawer,
          ),
        ],
        automaticallyImplyLeading: false,
      ),
      endDrawer: DrawerContent(
          userFuture: _userFuture,
          userEmail: widget.userEmail,
          userPhoto: _userPhoto,
          pickImage: _pickImage,
          logout: _logout),
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
                  return ClientView(
                      clientId: user['ID_Client'] ?? 0,
                      animation: _animation,
                      slideAnimation: _slideAnimation);
                } else if (widget.userType == 'proprietaire') {
                  int currentQuantity = user['quantite'] ??
                      0; // Assurez-vous que le champ 'quantite' existe dans les données utilisateur
                  return ProprietaireView(
                      ownerId: user['ID_Proprietaire'] ?? 0,
                      animation: _animation,
                      slideAnimation: _slideAnimation,
                      selectedIndex: _selectedIndex,
                      onItemTapped: _onItemTapped,
                      onEditQuantity: () => _showEditQuantityDialog(
                              context, currentQuantity, (newQuantity) {
                            setState(() {
                              user['quantite'] = newQuantity;
                            });
                          }));
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
              currentIndex: _selectedIndex,
              onTap: _onItemTapped,
              backgroundColor: Colors.white,
              selectedItemColor: Colors.deepPurple[700],
              unselectedItemColor: Colors.grey,
              selectedFontSize: 14,
              unselectedFontSize: 12,
              iconSize: 30,
              items: [
                BottomNavigationBarItem(
                  icon: Icon(Icons.cancel),
                  label: 'الطلبات المرفوضة',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.check_circle),
                  label: 'الطلبات المقبولة',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.pending),
                  label: 'قيد الانتظار',
                ),
              ],
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
