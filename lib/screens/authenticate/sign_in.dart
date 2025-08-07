import 'package:evalumate/services/auth.dart';
import 'package:evalumate/shared/constants.dart';
import 'package:evalumate/shared/loading.dart';
import'package:flutter/material.dart';


class SignIn extends StatefulWidget {
  final Function toggleView;

  const SignIn({super.key, required this.toggleView});

  @override
  State<SignIn> createState() => _SignInState();
}

class _SignInState extends State<SignIn> {

  final AuthService _auth = AuthService();
  final _formKey = GlobalKey<FormState>();
  bool loading = false;
  //text field state
  String email = '';
  String password = '';
  String error = '';


  @override
  Widget build(BuildContext context) {
    return loading ? Loading() : Scaffold(
      backgroundColor: Colors.green[100],
      appBar: AppBar(
        backgroundColor: Colors.green[300],
        elevation: 0.0,
        title: Text('Sign Into App'),
        actions: <Widget>[
          TextButton(
            onPressed: () {
              widget.toggleView();
            },
            style: TextButton.styleFrom(
              backgroundColor: Colors.green[300],  // Background
              foregroundColor: Colors.black, // Text/icon color
            ),
            child: Row(
                mainAxisSize: MainAxisSize.min, // Prevents extra width
                children: [
                  Icon(Icons.person_2),
                  SizedBox(width: 8),          // Spacing between icon and text
                  Text('Register'),
                ],
            ),
          ),
        ],
      ),
      body: Container(
        padding: EdgeInsets.symmetric(vertical:20.0, horizontal: 50.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: <Widget>[
              SizedBox(height:70),
              TextFormField(
                  decoration: textInputDecoration.copyWith(hintText: 'Email'),
                  validator: (val) => val!.isEmpty ? 'Enter an Email' : null,
                  onChanged: (val) {
                    setState(() => email = val);
                  }
              ),
              SizedBox(height:20),
              TextFormField(
                  decoration: textInputDecoration.copyWith(hintText: 'Password'),
                  obscureText: true,
                  validator: (val) => val!.length < 6 ? 'Enter a valid password' : null,
                  onChanged: (val) {
                    setState(() => password = val);
                 }
              ),
              SizedBox(height:30),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey[400], // Background color
                  foregroundColor: Colors.white, // Text/icon color
                ),
                onPressed: () async{
                  if (_formKey.currentState!.validate()){
                    setState(() => loading = true);
                    dynamic result = await _auth.signInWithEmailAndPassword(email, password);
                    if(result == null) {
                      setState(() {
                        error = 'could not sign in with those credentials';
                        loading = false;
                      });
                    }
                  }
                },
                child: Text(
                  'Sign in',
                ),
              ),
              SizedBox(height: 12),
              Text(error, style: TextStyle(color: Colors.red, fontSize: 14),)
            ],
          ),
        ),
      ),
    );
  }
}
