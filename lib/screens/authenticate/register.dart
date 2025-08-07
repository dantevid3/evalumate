// lib/screens/authenticate/register.dart

import 'package:evalumate/shared/constants.dart';
import 'package:evalumate/shared/loading.dart';
import 'package:flutter/material.dart';
import 'package:evalumate/services/auth.dart';
import 'package:evalumate/screens/authenticate/profile_setup_screen.dart'; // Import the ProfileSetupScreen

class Register extends StatefulWidget {
  final Function toggleView;

  const Register({super.key, required this.toggleView});

  @override
  State<Register> createState() => _RegisterState();
}

class _RegisterState extends State<Register> {
  final AuthService _auth = AuthService();
  final _formKey = GlobalKey<FormState>();
  bool loading = false;

  // Text field state
  String email = '';
  String password = '';
  String error = '';

  @override
  Widget build(BuildContext context) {
    return loading
        ? const Loading()
        : Scaffold(
      backgroundColor: Colors.green[100],
      appBar: AppBar(
        backgroundColor: Colors.green[300],
        elevation: 0.0,
        title: const Text('Sign up for App'),
        actions: <Widget>[
          TextButton(
            onPressed: () {
              widget.toggleView();
            },
            style: TextButton.styleFrom(
              backgroundColor: Colors.green[300],
              foregroundColor: Colors.black,
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.person_2),
                SizedBox(width: 8),
                Text('Sign In'),
              ],
            ),
          ),
        ],
      ),
      body: Container(
        padding: const EdgeInsets.symmetric(vertical: 20.0, horizontal: 50.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: <Widget>[
              const SizedBox(height: 70),
              TextFormField(
                  decoration: textInputDecoration.copyWith(hintText: 'Email'),
                  validator: (val) => val!.isEmpty ? 'Enter a valid Email' : null,
                  onChanged: (val) {
                    setState(() => email = val);
                  }),
              const SizedBox(height: 20),
              TextFormField(
                  decoration: textInputDecoration.copyWith(hintText: 'Password'),
                  obscureText: true,
                  validator: (val) =>
                  val!.length < 6 ? 'Enter a password 6+ chars long' : null,
                  onChanged: (val) {
                    setState(() => password = val);
                  }),
              const SizedBox(height: 30),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey[400],
                  foregroundColor: Colors.white,
                ),
                onPressed: () async {
                  if (_formKey.currentState!.validate()) {
                    setState(() => loading = true);

                    dynamic result = await _auth.registerWithEmailAndPassword(email, password);

                    if (!mounted) {
                      return;
                    }

                    if (result == null) {
                      setState(() {
                        error = 'Please supply a valid email or check credentials';
                        loading = false;
                      });
                    } else {
                      // Registration successful, navigate to ProfileSetupScreen
                      // Pass the UID to the ProfileSetupScreen
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ProfileSetupScreen(uid: result.uid),
                        ),
                      );
                    }
                  }
                },
                child: const Text(
                  'Register',
                ),
              ),
              const SizedBox(height: 12),
              Text(
                error,
                style: const TextStyle(color: Colors.red, fontSize: 14),
              )
            ],
          ),
        ),
      ),
    );
  }
}