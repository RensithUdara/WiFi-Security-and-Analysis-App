import 'package:flutter/material.dart';
import 'package:flutter_neumorphic_plus/flutter_neumorphic.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SignupScreen extends StatefulWidget {
  @override
  _SignupScreenState createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _auth = FirebaseAuth.instance;
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _displayNameController = TextEditingController();
  bool _isLoading = false;

  Future<void> _signUp() async {
    setState(() => _isLoading = true);
    try {
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );
      await userCredential.user?.updateDisplayName(_displayNameController.text.trim());
      await userCredential.user?.reload();

      if (mounted) Navigator.of(context).popUntil((route) => route.isFirst);
    } on FirebaseAuthException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message ?? 'Sign up failed.'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: NeumorphicTheme.baseColor(context),
      appBar: NeumorphicAppBar(
        title: Text('Sign Up'),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Neumorphic(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                style: NeumorphicStyle(depth: -4, boxShape: NeumorphicBoxShape.stadium()),
                child: TextField(
                  controller: _displayNameController,
                  decoration: InputDecoration(labelText: 'Display Name', border: InputBorder.none),
                ),
              ),
              SizedBox(height: 20),
              Neumorphic(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                style: NeumorphicStyle(depth: -4, boxShape: NeumorphicBoxShape.stadium()),
                child: TextField(
                  controller: _emailController,
                  decoration: InputDecoration(labelText: 'Email', border: InputBorder.none),
                  keyboardType: TextInputType.emailAddress,
                ),
              ),
              SizedBox(height: 20),
              Neumorphic(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                style: NeumorphicStyle(depth: -4, boxShape: NeumorphicBoxShape.stadium()),
                child: TextField(
                  controller: _passwordController,
                  decoration: InputDecoration(labelText: 'Password', border: InputBorder.none),
                  obscureText: true,
                ),
              ),
              SizedBox(height: 30),
              NeumorphicButton(
                onPressed: _isLoading ? null : _signUp,
                style: NeumorphicStyle(color: Colors.green),
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: _isLoading
                    ? SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : Text('CREATE ACCOUNT', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
