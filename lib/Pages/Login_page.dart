import 'dart:async';
import 'dart:ffi';

import 'package:flutter/material.dart';
import 'package:easingles/Pages/home_page.dart';
import 'package:easingles/Provider/LoginProvider.dart';
import 'package:easingles/assets/app.colors.dart';
import 'package:provider/provider.dart';
import 'package:google_sign_in/google_sign_in.dart';

class Login_page extends StatefulWidget {
  Login_page({super.key});

  @override
  State<Login_page> createState() => _Login_pageState();
}

class _Login_pageState extends State<Login_page> {
  bool _isLoginLoading = false;
  bool _isRegisterLoading = false;
  bool _isGoogleLoading = false;

  final _phonecontroller = TextEditingController();
  final _passwordcontroller = TextEditingController();
  // final GoogleSignIn _googleSignIn = GoogleSignIn.standard();

  void dispose() {
    _phonecontroller.dispose();
    _passwordcontroller.dispose();
    super.dispose();
  }

  String? get _errorText {
    final text = _phonecontroller.value.text;
    if (text.isEmpty) {
      return null;
    }
    if (text.length < 10) {
      return 'Ten digits eg.07821.....';
    }
    if (text.length > 10) {
      return 'Number too long';
    }
    return null;
  }

  Future<void> _handleGoogleSignIn() async {
    setState(() {
      _isGoogleLoading = true;
    });

    try {
      // final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      
      // if (googleUser != null) {
      //   final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
        
        
      //   print('Google Sign-In successful');
      //   print('User: ${googleUser.displayName}');
      //   print('Email: ${googleUser.email}');
      //   print('ID Token: ${googleAuth.idToken}');

      //   Navigator.of(context).pushReplacementNamed("/main");
      // }
    } catch (error) {
      print('Google Sign-In Error: $error');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Google Sign-In failed: $error')),
      );
    } finally {
      setState(() {
        _isGoogleLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: SingleChildScrollView(
          child: SizedBox(
            height: MediaQuery.of(context).size.height,
            child: Column(
              children: [
                const SizedBox(height: 68),
                const Text(
                  "Login or Register to continue",
                  style: TextStyle(
                      fontSize: 22,
                      color: Colors.white,
                      fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 45),
                Column(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(5),
                        color: AppColors.lighter,
                      ),
                      child: TextFormField(
                        controller: _phonecontroller,
                        keyboardType: TextInputType.phone,
                        decoration: const InputDecoration(
                          icon: Padding(
                            padding: EdgeInsets.all(8.0),
                            child: Icon(Icons.phone),
                          ),
                          filled: true,
                          fillColor: AppColors.lighter,
                          labelText: "Phone Number ie 078... or 075...",
                        ),
                      ),
                    ),
                    const SizedBox(
                      height: 25,
                    ),
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(5),
                        color: AppColors.lighter,
                      ),
                      child: TextFormField(
                        obscureText: true,
                        controller: _passwordcontroller,
                        decoration: InputDecoration(
                          icon: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: const Icon(Icons.lock),
                          ),
                          labelText: "Password",
                          filled: true,
                          fillColor: AppColors.lighter,
                        ),
                        validator: (value) {
                          if (value?.trim().length != 10) {
                            return 'Enter a valid 10-digit phone number';
                          }
                          return null;
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(
                  height: 25,
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.white,
                    ),
                    onPressed: () => {
                      Navigator.of(context).pushNamed('/forgot')
                    },
                    child: const Text(
                      "Forgot Password?  Reset",
                      style: TextStyle(
                        color: Colors.amber,
                      ),
                    ),
                  ),
                ),
                const SizedBox(
                  height: 25,
                ),
                SizedBox(
                  width: double.infinity,
                  height: 40,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.lighter,
                    ),
                    onPressed: _isLoginLoading ? null : () async {
                      setState(() {
                        _isLoginLoading = true;
                      });
                      bool response = await context.read<LoginProvider>().login(
                          _phonecontroller.text,
                          _passwordcontroller.text,
                          context);
                      setState(() {
                        _isLoginLoading = false;
                      });
                      if (response) {
                        Navigator.of(context).pushReplacementNamed("/main");
                      }
                    },
                    child: _isLoginLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Text('Login', style: TextStyle(color: Colors.white)),
                  ),
                ),
                const SizedBox(
                  height: 20,
                ),
                
                Row(
                  children: const [
                    Expanded(child: Divider(color: Colors.white54, thickness: 1)),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        "OR",
                        style: TextStyle(color: Colors.white54, fontWeight: FontWeight.bold),
                      ),
                    ),
                    Expanded(child: Divider(color: Colors.white54, thickness: 1)),
                  ],
                ),
                
                const SizedBox(
                  height: 20,
                ),
                
                SizedBox(
                  width: double.infinity,
                  height: 40,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.black87,
                    ),
                    onPressed: _isGoogleLoading ? null : _handleGoogleSignIn,
                    icon: _isGoogleLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
                          ),
                        )
                      : Image.asset(
                          'assets/google_logo.png',
                          height: 24,
                        ),
                    label: const Text(
                      'Sign in with Google',
                      style: TextStyle(fontSize: 16),
                    ),
                  ),
                ),
                
                const SizedBox(
                  height: 40,
                ),
                
                SizedBox(
                  height: 40,
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.lighter,
                    ),
                    onPressed: _isRegisterLoading ? null : () async {
                      setState(() {
                        _isRegisterLoading = true;
                      });
                      Navigator.of(context).pushNamed('/register');
                      setState(() {
                        _isRegisterLoading = false;
                      });
                    },
                    child: _isRegisterLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Text('Register', style: TextStyle(color: Colors.white)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}