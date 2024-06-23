// ignore_for_file: prefer_const_constructors, use_build_context_synchronously, deprecated_member_use

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../data/mongo_database.dart';
import '../screens/home_page.dart';

class LoginPage extends StatefulWidget {
  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;
  String? _lastEmail;
  // String? _lastPassword;

  @override
  void initState() {
    super.initState();
    _loadLastInputs();
  }

  Future<void> _loadLastInputs() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _lastEmail = prefs.getString('lastEmail');
      // _lastPassword = prefs.getString('lastPassword');
    });
  }

  Future<void> _login() async {
    final email = _emailController.text;
    final password = _passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      _showSnackBar('يرجى ملء جميع الحقول.');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final user = await MongoDatabase.login(email, password);

      setState(() {
        _isLoading = false;
      });
      if (user != null) {
        final prefs = await SharedPreferences.getInstance();
        prefs.setString('lastEmail', email);
        prefs.setString('lastPassword', password);

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) =>
                HomePage(userType: user['type'], userEmail: user['email']),
          ),
        );
      } else {
        _showSnackBar('البريد الإلكتروني أو كلمة المرور غير صحيحة.');
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showSnackBar('حدث خطأ ما. يرجى المحاولة مرة أخرى.');
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        margin: EdgeInsetsDirectional.symmetric(vertical: 25.0),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blue.shade800,
        elevation: 0,
        automaticallyImplyLeading: false,
      ),
      body: Stack(
        children: [
          AnimatedContainer(
            duration: Duration(seconds: 7),
            onEnd: () {
              setState(() {});
            },
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.blue.shade800, Colors.purple.shade600],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: AnimatedSwitcher(
                duration: Duration(milliseconds: 500),
                child: Card(
                  key: ValueKey<int>(1),
                  elevation: 15,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25.0),
                  ),
                  shadowColor: Colors.grey.withOpacity(0.7),
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'تسجيل الدخول',
                          style: theme.textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          '. يرجى تسجيل الدخول باستخدام البريد الإلكتروني وكلمة المرور الخاصة بك',
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: Colors.black54,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: 20),
                        _buildTextField(
                          controller: _emailController,
                          labelText: 'البريد الإلكتروني',
                          icon: Icons.email,
                        ),
                        if (_lastEmail != null)
                          _buildLastInputButton(
                            label: '$_lastEmail آخر بريد إلكتروني: ',
                            onPressed: () {
                              _emailController.text = _lastEmail!;
                            },
                          ),
                        SizedBox(height: 16),
                        _buildTextField(
                          controller: _passwordController,
                          labelText: 'كلمة المرور',
                          icon: Icons.lock,
                          obscureText: _obscurePassword,
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword
                                  ? Icons.visibility
                                  : Icons.visibility_off,
                              color: Colors.blue,
                            ),
                            onPressed: () {
                              setState(() {
                                _obscurePassword = !_obscurePassword;
                              });
                            },
                          ),
                        ),
                        // if (_lastPassword != null)
                        //   _buildLastInputButton(
                        //     label: 'آخر كلمة مرور: $_lastPassword',
                        //     onPressed: () {
                        //       _passwordController.text = _lastPassword!;
                        //     },
                        //   ),
                        SizedBox(height: 20),
                        AnimatedSwitcher(
                          duration: Duration(milliseconds: 300),
                          child: _isLoading
                              ? CircularProgressIndicator(
                                  key: ValueKey<int>(1),
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.blue),
                                )
                              : _buildLoginButton(),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          if (_isLoading)
            Opacity(
              opacity: 0.8,
              child: ModalBarrier(dismissible: false, color: Colors.black),
            ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String labelText,
    required IconData icon,
    bool obscureText = false,
    Widget? suffixIcon,
  }) {
    return AnimatedContainer(
      duration: Duration(milliseconds: 300),
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          prefixIcon: Icon(icon, color: Colors.blue),
          suffixIcon: suffixIcon,
          labelText: labelText,
          labelStyle: TextStyle(color: Colors.blue),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15.0),
          ),
          focusedBorder: OutlineInputBorder(
            borderSide: BorderSide(color: Colors.blue, width: 2.0),
            borderRadius: BorderRadius.circular(15.0),
          ),
        ),
        obscureText: obscureText,
      ),
    );
  }

  Widget _buildLoginButton() {
    return ElevatedButton(
      key: ValueKey<int>(2),
      style: ElevatedButton.styleFrom(
        foregroundColor: Colors.white,
        backgroundColor: Colors.blue,
        padding: EdgeInsets.symmetric(vertical: 16.0, horizontal: 32.0),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(25.0),
        ),
        textStyle: TextStyle(fontSize: 18.0, fontWeight: FontWeight.bold),
        elevation: 10,
        shadowColor: Colors.blueAccent,
      ).copyWith(
        elevation: MaterialStateProperty.resolveWith<double>(
          (Set<MaterialState> states) {
            if (states.contains(MaterialState.pressed)) {
              return 15;
            }
            return 10; // Default elevation
          },
        ),
      ),
      onPressed: _login,
      child: Text('تسجيل الدخول'),
    );
  }

  Widget _buildLastInputButton({
    required String label,
    required VoidCallback onPressed,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          foregroundColor: Colors.white,
          backgroundColor: Colors.grey,
          padding: EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15.0),
          ),
          textStyle: TextStyle(fontSize: 14.0),
        ),
        onPressed: onPressed,
        child: Text(label, textAlign: TextAlign.center),
      ),
    );
  }
}
