import 'package:flutter/material.dart';
import 'package:flutter_neumorphic_plus/flutter_neumorphic.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'signup_screen.dart';

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _auth = FirebaseAuth.instance;
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  Future<void> _signIn() async {
    setState(() => _isLoading = true);
    try {
      await _auth.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );
      // CORRECTED: This ensures we pop all the way back to the main screen.
      if (mounted) Navigator.of(context).popUntil((route) => route.isFirst);
    } on FirebaseAuthException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message ?? 'Login failed.'), backgroundColor: Colors.red),
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
        title: Text('Sign In'),
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
                onPressed: _isLoading ? null : _signIn,
                style: NeumorphicStyle(color: Colors.blueAccent),
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: _isLoading
                    ? SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : Text('SIGN IN', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
              SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text("Don't have an account?"),
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).push(MaterialPageRoute(builder: (_) => SignupScreen()));
                    },
                    child: Text('Sign Up'),
                  )
                ],
              )
            ],
          ),
        ),
      ),
    );
  }
}
