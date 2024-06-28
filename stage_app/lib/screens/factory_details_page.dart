// ignore_for_file: prefer_const_constructors, sort_child_properties_last

import 'package:flutter/material.dart';
import 'package:myapp/data/mongo_database.dart';
import 'package:google_fonts/google_fonts.dart';

class FactoryDetailsPage extends StatefulWidget {
  final int factoryId;
  final int clientId;

  FactoryDetailsPage({required this.factoryId, required this.clientId});

  @override
  _FactoryDetailsPageState createState() => _FactoryDetailsPageState();
}

class _FactoryDetailsPageState extends State<FactoryDetailsPage>
    with SingleTickerProviderStateMixin {
  late Future<Map<String, dynamic>> _factoryFuture;
  final _quantityController = TextEditingController();
  bool _isHovering = false;
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _factoryFuture = MongoDatabase.getFactoryById(widget.factoryId);
    _animationController = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _quantityController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _sendRequest(int quantity, Map<String, dynamic> factory) async {
    if (quantity > 0 && quantity <= (factory['quantite'] ?? 0)) {
      await MongoDatabase.sendRequest(
        widget.clientId,
        factory['ID_Proprietaire'] ?? 0, // Ensure it's an int
        quantity,
      );
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.check, color: Colors.green),
              SizedBox(width: 10),
              Text('تم إرسال الطلب بنجاح!'),
            ],
          ),
          backgroundColor: Colors.green[100],
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10.0),
          ),
        ),
      );
      _quantityController.clear();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.error, color: Colors.red),
              SizedBox(width: 10),
              Text('الرجاء إدخال كمية صالحة.'),
            ],
          ),
          backgroundColor: Colors.red[100],
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10.0),
          ),
        ),
      );
    }
  }

  Widget _buildFactoryDetails(Map<String, dynamic> factory) {
    return Card(
      margin: EdgeInsets.all(16.0),
      elevation: 10.0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20.0),
      ),
      child: AnimatedContainer(
        duration: Duration(milliseconds: 300),
        padding: EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.white, Colors.blue[50]!],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.5),
              spreadRadius: 5,
              blurRadius: 7,
              offset: Offset(0, 3), // changes position of shadow
            ),
          ],
        ),
        child: Directionality(
          textDirection: TextDirection.rtl,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: 10),
              Row(
                children: [
                  Icon(Icons.factory, color: Colors.blueAccent, size: 28),
                  SizedBox(width: 10),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      'اسم المالك: ${factory['nom']}',
                      style: GoogleFonts.cairo(
                        textStyle: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue[900],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 10),
              Row(
                children: [
                  Icon(Icons.location_on, color: Colors.redAccent, size: 22),
                  SizedBox(width: 10),
                  Text(
                    'الموقع: ${factory['location']}',
                    style: GoogleFonts.tajawal(
                      textStyle: TextStyle(
                        fontSize: 18,
                        color: Colors.grey[700],
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 10),
              Row(
                children: [
                  Icon(Icons.description, color: Colors.green, size: 22),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'الوصف: ${factory['description']}',
                      style: GoogleFonts.amiri(
                        textStyle: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[600],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 20),
              TextField(
                controller: _quantityController,
                decoration: InputDecoration(
                  labelText: 'كمية الجليد',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                  prefixIcon: Icon(Icons.numbers),
                ),
                keyboardType: TextInputType.number,
              ),
              SizedBox(height: 20),
              MouseRegion(
                onEnter: (_) => setState(() => _isHovering = true),
                onExit: (_) => setState(() => _isHovering = false),
                child: OutlinedButton(
                  onPressed: () {
                    int quantity = int.tryParse(_quantityController.text) ?? 0;
                    _sendRequest(quantity, factory);
                  },
                  child: Text('إرسال الطلب'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    backgroundColor:
                        _isHovering ? Colors.orange[700] : Colors.orange,
                    textStyle: GoogleFonts.lateef(
                      textStyle: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                      ),
                    ),
                    padding: EdgeInsets.symmetric(vertical: 12, horizontal: 24),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20.0),
                    ),
                    side: BorderSide(
                      color: Colors.orange,
                      width: 2.0,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildErrorWidget(String error) {
    return Center(
      child: Text(
        'خطأ: $error',
        style: GoogleFonts.tajawal(
          textStyle: TextStyle(
            fontSize: 18,
            color: Colors.red[800],
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingWidget() {
    return Center(
      child: CircularProgressIndicator(
        color: Colors.deepPurple[700],
      ),
    );
  }

  Widget _buildNoDataWidget() {
    return Center(
      child: Text(
        'لم يتم العثور على بيانات.',
        style: GoogleFonts.tajawal(
          textStyle: TextStyle(
            fontSize: 18,
            color: Colors.grey[700],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'تفاصيل المصنع',
          style: GoogleFonts.cairo(
            textStyle: TextStyle(
              color: Colors.white,
              fontSize: 27.0,
            ),
          ),
        ),
        backgroundColor: Colors.deepPurple[700],
        iconTheme: IconThemeData(
          color: Colors.white,
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage('images/background.png'),
            fit: BoxFit.cover,
          ),
        ),
        child: FutureBuilder<Map<String, dynamic>>(
          future: _factoryFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return _buildLoadingWidget();
            } else if (snapshot.hasError) {
              return _buildErrorWidget(snapshot.error.toString());
            } else if (!snapshot.hasData) {
              return _buildNoDataWidget();
            } else {
              final factory = snapshot.data!;
              return SingleChildScrollView(
                child: FadeTransition(
                  opacity: _animationController..forward(),
                  child: _buildFactoryDetails(factory),
                ),
              );
            }
          },
        ),
      ),
    );
  }
}
