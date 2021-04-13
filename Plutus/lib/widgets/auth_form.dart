import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';

import '../screens/tab_screen.dart';
import '../providers/auth.dart';

// Form to login a user
class AuthForm extends StatefulWidget {
  @override
  _AuthFormState createState() => _AuthFormState();
}

enum AuthMode { Signup, Login }

class _AuthFormState extends State<AuthForm> {
  final GlobalKey<FormState> _formKey = GlobalKey();
  AuthMode _authMode = AuthMode.Login;
  final _auth = FirebaseAuth.instance;
  String email;
  String password;
  var _isLoading = false;
  final _passwordController = TextEditingController();
  final _emailController = TextEditingController();

  // Displays a popup informing the user that an issue occurred
  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(message),
        content: Text(message),
        actions: <Widget>[
          FlatButton(
            child: Text('Okay'),
            onPressed: () => Navigator.pop(context),
          )
        ],
      ),
    );
  }

  // Submits the entered credentials and awaits for authentication
  Future<void> _submit() async {
    UserCredential credentialResult;
    if (!_formKey.currentState.validate()) {
      // Invalid!
      return;
    }
    _formKey.currentState.save();
    setState(() {
      _isLoading = true;
    });
    try {
      if (_authMode == AuthMode.Login) {
        // Log user in
        credentialResult = await _auth.signInWithEmailAndPassword(
            email: email, password: password);
      } else {
        credentialResult = await _auth.createUserWithEmailAndPassword(
            email: email, password: password);
        await FirebaseFirestore.instance
            .collection('users')
            .doc(credentialResult.user.uid)
            .set({
          'email': email,
          'password': password,
        });
      }
      Provider.of<Auth>(context, listen: false).setEmail(email);
      Provider.of<Auth>(context, listen: false)
          .setUserId(credentialResult.user.uid);
      Provider.of<Auth>(context, listen: false).setPassword(password);
      if (credentialResult != null) {
        Navigator.pushNamed(context, TabScreen.routeName);
      }
      // Error messages
    } on FirebaseAuthException catch (error) {
      var errorMessage = 'Authentication failed';
      if (error.code == 'invalid-email') {
        errorMessage = 'This is not a valid email address';
      } else if (error.code == 'user-not-found') {
        errorMessage = 'This user is not found.';
      } else if (error.code == 'wrong-password') {
        errorMessage = 'Incorrect password';
      } else if (error.code == 'email-already-in-use') {
        errorMessage = 'This email address is already in use.';
      } else if (error.code == 'invalid-email') {
        errorMessage = 'This is not a valid email address';
      } else if (error.code == 'weak-password') {
        errorMessage = 'This password is too weak.';
      }
      _showErrorDialog(errorMessage);
    }
    setState(() {
      _isLoading = false;
    });
  }

  // Switches between Login and Signup modes
  void _switchAuthMode() {
    if (_authMode == AuthMode.Login) {
      setState(() {
        _authMode = AuthMode.Signup;
      });
    } else {
      setState(() {
        _authMode = AuthMode.Login;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Adjusts based on the size of the device
    final deviceSize = MediaQuery.of(context).size;

    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10.0),
      ),
      elevation: 8.0,
      child: Container(
        // Signup card is bigger due to extra textfield
        height: _authMode == AuthMode.Signup ? 400 : 340,
        constraints:
            BoxConstraints(minHeight: _authMode == AuthMode.Signup ? 320 : 260),
        width: deviceSize.width * 0.75,
        padding: EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: <Widget>[
              // Title
              Text(
                'Plutus',
                style: TextStyle(
                  color: Theme.of(context).primaryColor,
                  fontSize: 25,
                  fontFamily: 'Anton',
                  fontWeight: FontWeight.bold,
                ),
              ),
              // E-mail
              TextFormField(
                decoration: InputDecoration(labelText: 'E-Mail'),
                keyboardType: TextInputType.emailAddress,
                onEditingComplete: () => FocusScope.of(context).nextFocus(),
                controller: _emailController,
                validator: (value) {
                  if (value.isEmpty || !value.contains('@')) {
                    return 'Invalid email!';
                  }
                  return null;
                },
                onSaved: (value) {
                  email = value.trim();
                },
                style: Theme.of(context).textTheme.bodyText2,
              ),
              // Password
              TextFormField(
                decoration: InputDecoration(labelText: 'Password'),
                onEditingComplete: () => {
                  if (_authMode == AuthMode.Signup)
                    {FocusScope.of(context).nextFocus()}
                  else
                    {FocusScope.of(context).unfocus()}
                },
                obscureText: true,
                controller: _passwordController,
                // ignore: missing_return
                validator: (value) {
                  if (value.isEmpty || value.trim().length < 6) {
                    return 'Password is too short!';
                  }
                },
                onSaved: (value) {
                  password = value.trim();
                },
                style: Theme.of(context).textTheme.bodyText2,
              ),
              // Default is Login
              if (_authMode == AuthMode.Signup)
                // Confirm Password
                TextFormField(
                  enabled: _authMode == AuthMode.Signup,
                  decoration: InputDecoration(labelText: 'Confirm Password'),
                  onEditingComplete: () => FocusScope.of(context).unfocus(),
                  obscureText: true,
                  validator: _authMode == AuthMode.Signup
                      // ignore: missing_return
                      ? (value) {
                          if (value != _passwordController.text.trim()) {
                            return 'Passwords do not match!';
                          }
                        }
                      : null,
                  style: Theme.of(context).textTheme.bodyText2,
                ),
              SizedBox(
                height: 20,
              ),
              if (_isLoading)
                CircularProgressIndicator()
              else
                // LOGIN/SIGNUP UP button
                RaisedButton(
                  child: Text(
                    _authMode == AuthMode.Login ? 'LOGIN' : 'SIGN UP',
                    style: Theme.of(context).textTheme.subtitle1,
                  ),
                  onPressed: _submit,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                  padding:
                      EdgeInsets.symmetric(horizontal: 30.0, vertical: 8.0),
                  color: Theme.of(context).primaryColor,
                  textColor: Theme.of(context).primaryTextTheme.button.color,
                ),
              // Button to switch AuthModes
              FlatButton(
                child: Text(
                    '${_authMode == AuthMode.Login ? 'SIGNUP' : 'LOGIN'} INSTEAD'),
                onPressed: _switchAuthMode,
                padding: EdgeInsets.symmetric(horizontal: 30.0, vertical: 4),
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                textColor: Theme.of(context).primaryColor,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
