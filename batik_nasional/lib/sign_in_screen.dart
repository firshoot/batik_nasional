import 'package:batik_nasional/home_screen.dart';
import 'package:batik_nasional/sign_up_screen.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:firebase_auth/firebase_auth.dart';

final googleSignIn = GoogleSignIn(
  scopes: [
    'email',
  ],
  clientId:
      '113708571782-ohj54p14lntapaid7cs9sipm844mr4q8.apps.googleusercontent.com',
);

class SignInScreen extends StatefulWidget {
  const SignInScreen({Key? key}) : super(key: key);
  @override
  SignInScreenState createState() => SignInScreenState();
}

class SignInScreenState extends State<SignInScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  String _errorMessage = '';

  Future<void> _signInWIthGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();
      if (googleUser != null) {
        final GoogleSignInAuthentication googleAuth =
            await googleUser.authentication;
        final credential = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );
        await FirebaseAuth.instance.signInWithCredential(credential);
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const HomeScreen()),
        );
      }
    } catch (error) {
      setState(() {
        _errorMessage = error.toString();
      });
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(_errorMessage),
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('Login'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            children: [
              const SizedBox(height: 32.0),
              TextField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16.0),
              TextField(
                controller: _passwordController,
                decoration: const InputDecoration(
                  labelText: 'Password',
                  border: OutlineInputBorder(),
                ),
                obscureText: true,
              ),
              const SizedBox(height: 16.0),
              ElevatedButton(
                onPressed: () async {
                  try {
                    await FirebaseAuth.instance.signInWithEmailAndPassword(
                      email: _emailController.text,
                      password: _passwordController.text,
                    );
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute(
                          builder: (context) => const HomeScreen()),
                    );
                  } catch (error) {
                    setState(() {
                      _errorMessage = error.toString();
                    });
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(_errorMessage),
                      ),
                    );
                  }
                },
                child: const Text('Login'),
              ),
              const SizedBox(height: 16.0),
              ElevatedButton.icon(
                onPressed: _signInWIthGoogle,
                icon: Image.asset('assets/images/logo_google.png'),
                label: const Text('Sign In with Google'),
              ),
              const SizedBox(height: 32.0),
              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const SignUpScreen(),
                    ),
                  );
                },
                child: const Text('Belum Punya Akun? Daftar'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
