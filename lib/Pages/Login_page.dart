import 'dart:async';
import 'dart:ffi';

import 'package:flutter/material.dart';
import 'package:easingles/Pages/home_page.dart';
import 'package:easingles/Provider/LoginProvider.dart';
import 'package:easingles/assets/app.colors.dart';
import 'package:http/http.dart' as http;
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
  
  // Authentication method selector
  String _authMethod = 'phone'; // 'phone', 'email'
  
  final GoogleSignIn signIn = GoogleSignIn.instance;
  
  // Controllers for phone authentication
  final _phonecontroller = TextEditingController();
  final _phonePasswordController = TextEditingController();
  
  // Controllers for email authentication
  final _emailController = TextEditingController();
  final _emailPasswordController = TextEditingController();

  void initState() {
    super.initState();
    check();
  }
  void check()async{
    print('Api call made');
    final response = await http.get(
        Uri.parse('http://192.168.100.61:3001'),
        headers: {'Content-Type': 'application/json'},
      );
      print('api call failed finally');
  }


  @override
  void dispose() {
    _phonecontroller.dispose();
    _phonePasswordController.dispose();
    _emailController.dispose();
    _emailPasswordController.dispose();
    super.dispose();
  }

  String? get _phoneErrorText {
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

  String? get _emailErrorText {
    final text = _emailController.value.text;
    if (text.isEmpty) {
      return null;
    }
    // Basic email validation
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(text)) {
      return 'Enter a valid email address';
    }
    return null;
  }

  Future<void> _handleGoogleSignIn() async {
    setState(() {
      _isGoogleLoading = true;
    });

    try {
      signIn.initialize(
        clientId: 'clientId', 
        serverClientId: 'serverClientId'
      ).then((
        _,
      ) {
        signIn.authenticationEvents
            .listen((GoogleSignInAuthenticationEvent event) {
           
              print('Google Sign-In Event: $event');
            }, onError: (Object error) {
              print('Google Sign-In Stream Error: $error');
            });

        signIn.attemptLightweightAuthentication();
      });
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

  Future<void> _handleLogin() async {
    setState(() {
      _isLoginLoading = true;
    });

    bool response = false;
    
    if (_authMethod == 'phone') {
      response = await context.read<LoginProvider>().login(
          _phonecontroller.text,
          _phonePasswordController.text,
          context);
    } else if (_authMethod == 'email') {
      // You'll need to add an email login method to your LoginProvider
      response = await context.read<LoginProvider>().loginWithEmail(
          _emailController.text,
          _emailPasswordController.text,
          context);
    }
    
    setState(() {
      _isLoginLoading = false;
    });
    
    if (response) {
      Navigator.of(context).pushReplacementNamed("/main");
    }
  }

  Widget _buildAuthMethodSelector() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.lighter.withOpacity(0.3),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _authMethod = 'phone';
                });
              },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: _authMethod == 'phone' 
                      ? AppColors.lighter 
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.phone,
                      color: _authMethod == 'phone' 
                          ? Colors.white 
                          : Colors.white54,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Phone',
                      style: TextStyle(
                        color: _authMethod == 'phone' 
                            ? Colors.white 
                            : Colors.white54,
                        fontWeight: _authMethod == 'phone' 
                            ? FontWeight.bold 
                            : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _authMethod = 'email';
                });
              },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: _authMethod == 'email' 
                      ? AppColors.lighter 
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.email,
                      color: _authMethod == 'email' 
                          ? Colors.white 
                          : Colors.white54,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Email',
                      style: TextStyle(
                        color: _authMethod == 'email' 
                            ? Colors.white 
                            : Colors.white54,
                        fontWeight: _authMethod == 'email' 
                            ? FontWeight.bold 
                            : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPhoneAuthForm() {
    return Column(
      children: [
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(5),
            color: AppColors.lighter,
          ),
          child: TextFormField(
            controller: _phonecontroller,
            keyboardType: TextInputType.phone,
            decoration: InputDecoration(
              icon: const Padding(
                padding: EdgeInsets.all(8.0),
                child: Icon(Icons.phone),
              ),
              filled: true,
              fillColor: AppColors.lighter,
              labelText: "Phone Number ie 078... or 075...",
              errorText: _phoneErrorText,
            ),
          ),
        ),
        const SizedBox(height: 25),
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(5),
            color: AppColors.lighter,
          ),
          child: TextFormField(
            obscureText: true,
            controller: _phonePasswordController,
            decoration: const InputDecoration(
              icon: Padding(
                padding: EdgeInsets.all(8.0),
                child: Icon(Icons.lock),
              ),
              labelText: "Password",
              filled: true,
              fillColor: AppColors.lighter,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEmailAuthForm() {
    return Column(
      children: [
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(5),
            color: AppColors.lighter,
          ),
          child: TextFormField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            decoration: InputDecoration(
              icon: const Padding(
                padding: EdgeInsets.all(8.0),
                child: Icon(Icons.email),
              ),
              filled: true,
              fillColor: AppColors.lighter,
              labelText: "Email Address",
              errorText: _emailErrorText,
            ),
          ),
        ),
        const SizedBox(height: 25),
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(5),
            color: AppColors.lighter,
          ),
          child: TextFormField(
            obscureText: true,
            controller: _emailPasswordController,
            decoration: const InputDecoration(
              icon: Padding(
                padding: EdgeInsets.all(8.0),
                child: Icon(Icons.lock),
              ),
              labelText: "Password",
              filled: true,
              fillColor: AppColors.lighter,
            ),
          ),
        ),
      ],
    );
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
                GestureDetector(
                  onTap: check,
                  child: const Text(
                    "Login or Register to continue",
                    style: TextStyle(
                        fontSize: 22,
                        color: Colors.white,
                        fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(height: 45),
                
                // Authentication method selector
                _buildAuthMethodSelector(),
                
                const SizedBox(height: 25),
                
                // Dynamic form based on selected auth method
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: _authMethod == 'phone' 
                      ? _buildPhoneAuthForm() 
                      : _buildEmailAuthForm(),
                ),
                
                const SizedBox(height: 25),
                
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
                
                const SizedBox(height: 25),
                
                // Login Button
                SizedBox(
                  width: double.infinity,
                  height: 40,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.lighter,
                    ),
                    onPressed: _isLoginLoading ? null : _handleLogin,
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
                
                const SizedBox(height: 20),
                
                // Divider
                const Row(
                  children: [
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
                
                const SizedBox(height: 20),
                
                // Google Sign-In Button
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
                          'lib/assets/images/google.png',
                          height: 24,
                        ),
                    label: const Text(
                      'Sign in with Google',
                      style: TextStyle(fontSize: 16),
                    ),
                  ),
                ),
                
                const SizedBox(height: 40),
                
                // Register Button
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