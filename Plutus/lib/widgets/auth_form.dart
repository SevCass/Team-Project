// Imported Flutter packages
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';

// Imported Plutus files
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
  AuthMode _authMode = AuthMode.Signup;
  final _auth = FirebaseAuth.instance;
  String email;
  String password;
  var _isLoading = false;
  final _passwordController = TextEditingController();
  final _emailController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  var _iserror = false;

  // Displays a popup informing the user that an issue occurred
  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        content: Text(message),
        actions: <Widget>[
          TextButton(
            child: Text('Okay', style: TextStyle(fontWeight: FontWeight.bold)),
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
      setState(() {
        _iserror = true;
      });
      // Invalid!
      return;
    }
    setState(() {
      _iserror = false;
    });
    _formKey.currentState.save();
    FocusScope.of(context).unfocus();
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
        errorMessage = 'This is not a valid email address.';
      } else if (error.code == 'user-not-found') {
        errorMessage = 'This user is not found.';
      } else if (error.code == 'wrong-password') {
        errorMessage = 'Incorrect password.';
      } else if (error.code == 'email-already-in-use') {
        errorMessage = 'This email address is already in use.';
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
  void dispose() {
    _passwordController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Adjusts based on the size of the device
    final deviceSize = MediaQuery.of(context).size;

    return Card(
      color: Colors
          .white, // Needs to be white; will be otherwise black if Light mode is on
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10.0),
      ),
      elevation: 8.0,
      child: SingleChildScrollView(
        child: Container(
          // Signup card is bigger due to extra textfield
          height: _iserror
              ? (_authMode == AuthMode.Signup ? 460 : 375)
              : (_authMode == AuthMode.Signup ? 390 : 325),

          width: deviceSize.width * 0.75,
          padding: const EdgeInsets.all(16.0),
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
                    fontFamily: 'Lato',
                    fontWeight: FontWeight.bold,
                  ),
                ),
                // E-mail
                TextFormField(
                  decoration: InputDecoration(
                      labelText: 'E-Mail',
                      // if user is signing up, show an icon indicating whether their email is valid
                      suffixIcon: Icon(_emailController.text.isEmpty ||
                              _authMode == AuthMode.Login
                          ? null
                          : (_emailController.text.trim().contains(RegExp(
                                  r'^[a-zA-Z0-9]+([.]?[a-zA-Z0-9]+){0,2}@[a-zA-Z0-9]+([.][a-zA-Z0-9]{2,}){1,2}$'))
                              ? Icons.check
                              : Icons.error))),
                  keyboardType: TextInputType.emailAddress,
                  onEditingComplete: () => FocusScope.of(context).nextFocus(),
                  onChanged: (val) => setState(() {}),
                  controller: _emailController,
                  validator: (value) {
                    if (value.isEmpty) return 'Please enter an email address.';
                    if (!value.trim().contains(RegExp(
                        r'^[a-zA-Z0-9]+([.]?[a-zA-Z0-9]+){0,2}@[a-zA-Z0-9]+([.][a-zA-Z0-9]{2,}){1,2}$')))
                    // after removing leading/trailing whitespace, regex checks for:
                    // one or more characters followed by
                    // 0-2 (.(1+characters) followed by
                    // @ followed by
                    // one or more characters followed by
                    // 1-2 (.(2+ characters))
                    {
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
                  decoration: InputDecoration(
                      // if user is signing up, show an icon indicating whether their password is long enough
                      suffixIcon: Icon(_passwordController.text.isEmpty ||
                              _authMode == AuthMode.Login
                          ? null
                          : (_passwordController.text.trim().length < 6
                              ? Icons.error
                              : Icons.check)),
                      labelText: 'Password',
                      helperText: _authMode == AuthMode.Signup
                          ? 'At least 6 characters'
                          : ''),
                  onEditingComplete: () => {
                    if (_authMode == AuthMode.Signup)
                      {FocusScope.of(context).nextFocus()}
                    else
                      {FocusScope.of(context).unfocus()}
                  },
                  onChanged: (val) => setState(() {}), //update the suffix icon
                  obscureText: true,
                  controller: _passwordController,
                  // ignore: missing_return
                  validator: (value) {
                    if (value.isEmpty || value.trim().length < 6) {
                      return 'Password must be at least 6 characters!';
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
                    decoration: InputDecoration(
                        labelText: 'Confirm Password',
                        suffixIcon: Icon(_confirmPasswordController.text.isEmpty
                            ? null
                            : (_confirmPasswordController.text.trim() ==
                                    _passwordController.text.trim()
                                ? Icons.check
                                : Icons.error))),
                    onEditingComplete: () => FocusScope.of(context).unfocus(),
                    obscureText: true,
                    onChanged: (val) => setState(() {}),
                    controller: _confirmPasswordController,
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
                const SizedBox(
                  height: 20,
                ),
                if (_isLoading)
                  CircularProgressIndicator(
                    backgroundColor: Theme.of(context).primaryColor,
                  )
                else
                  Column(children: [
                    // LOGIN/SIGNUP UP button
                    ElevatedButton(
                      child: Text(
                        _authMode == AuthMode.Login ? 'LOGIN' : 'SIGN UP',
                        style: Theme.of(context).textTheme.subtitle2,
                      ),
                      onPressed: _submit,
                      style: ElevatedButton.styleFrom(
                        primary: Theme.of(context).primaryColor,
                        textStyle: TextStyle(
                            color: Theme.of(context)
                                .primaryTextTheme
                                .button
                                .color),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 30.0, vertical: 8.0),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                    ),
                    // Button to switch AuthModes
                    TextButton(
                      child: Text(
                          '${_authMode == AuthMode.Login ? 'SIGNUP' : 'LOGIN'} INSTEAD'),
                      onPressed: _switchAuthMode,
                      style: TextButton.styleFrom(
                        padding:
                            EdgeInsets.symmetric(horizontal: 30.0, vertical: 4),
                        primary: Theme.of(context).primaryColor,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                    ),
                  ])
              ],
            ),
          ),
        ),
      ),
    );
  }
}
