import 'dart:async';
import 'dart:convert';
import 'dart:ffi';

import 'package:flutter/material.dart';
import 'package:mazale/Models/Authmodel.dart';
import 'package:mazale/Pages/PhotoUploadPage.dart';
import 'package:mazale/Pages/home_page.dart';
import 'package:mazale/Provider/LoginProvider.dart';
import 'package:mazale/assets/app.colors.dart';
import 'package:http/http.dart' as http;
import 'package:mazale/assets/urlconfig.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:scroll_date_picker/scroll_date_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Login_page extends StatefulWidget {
  Login_page({super.key});

  @override
  State<Login_page> createState() => _Login_pageState();
}

class _Login_pageState extends State<Login_page> with SingleTickerProviderStateMixin {
  bool _isLoginLoading = false;
  bool _isRegisterLoading = false;
  bool _isGoogleLoading = false;
  bool _obscurePassword = true;

  String _selectedCountryCode = '+256';

  final GoogleSignIn signIn = GoogleSignIn.instance;

  final _phonecontroller = TextEditingController();
  final _phonePasswordController = TextEditingController();

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  final List<Map<String, String>> _countryCodes = [
    {'code': '+256', 'country': 'Uganda', 'flag': '🇺🇬'},
    {'code': '+254', 'country': 'Kenya', 'flag': '🇰🇪'},
    {'code': '+255', 'country': 'Tanzania', 'flag': '🇹🇿'},
    {'code': '+250', 'country': 'Rwanda', 'flag': '🇷🇼'},
    {'code': '+1', 'country': 'USA/Canada', 'flag': '🇺🇸'},
    {'code': '+44', 'country': 'UK', 'flag': '🇬🇧'},
    {'code': '+91', 'country': 'India', 'flag': '🇮🇳'},
    {'code': '+86', 'country': 'China', 'flag': '🇨🇳'},
    {'code': '+234', 'country': 'Nigeria', 'flag': '🇳🇬'},
    {'code': '+27', 'country': 'South Africa', 'flag': '🇿🇦'},
  ];

  @override
  void initState() {
    super.initState();
    check();
    
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
      ),
    );
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.2, 1.0, curve: Curves.easeOutCubic),
      ),
    );
    
    _animationController.forward();
  }

  void check() async {
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
    _animationController.dispose();
    super.dispose();
  }

  String? get _phoneErrorText {
    final text = _phonecontroller.value.text;
    if (text.isEmpty) {
      return null;
    }
    if (text.length != 9) {
      return 'Phone number must be 9 digits';
    }
    return null;
  }

  // TODO: Implement Google Sign-In logic here
  Future<void> _handleGoogleLogin() async {
     setState(() => _isGoogleLoading = true);

    try {
      signIn.initialize();
      signIn.initialize(
        serverClientId:
            '1048511336383-oc57lcet02qh49kn751r5g8vu8hn74bs.apps.googleusercontent.com',
      );
      final GoogleSignInAccount? googleUser = await signIn.authenticate();
      if (googleUser == null) return;

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;
      final AuthCredential credential = GoogleAuthProvider.credential(
        idToken: googleAuth.idToken,
      );
      final UserCredential userCredential =
          await FirebaseAuth.instance.signInWithCredential(credential);

      String? idToken = await userCredential.user?.getIdToken();
      print(idToken);
      var response = await http.post(
        Uri.parse("${AppUrls.production}/api/auth/google/"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"idToken": idToken}),
      );
      print('//////////////////////////////////');
       print('//////////////////////////////////');
        print('//////////////////////////////////');
      print(response.body);
      print(response);
       print('//////////////////////////////////');
        print('//////////////////////////////////');
         print('//////////////////////////////////');
          print('//////////////////////////////////');

      if (response.statusCode == 200) {
        var data = jsonDecode(response.body);
        final DjangoAuthUser finalData = DjangoAuthUser.fromJson(data['user']);

        final SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.setString('token', data['token']);
        await prefs.setString('refresh_token', data['refresh_token']);
        await prefs.setString('id', finalData.id!);
        await prefs.setString('firstname', finalData.firstName!);
        await prefs.setString('lastname', finalData.lastName!);
        
        if (data['is_new_user']) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => PhotoUploadPage(googleId: data['google_id']),
            ),
          );
        } else {
          Navigator.of(context).pushReplacementNamed("/main");
        }
      } else {
        const snackBar = SnackBar(
          elevation: 0,
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.red,
          content: Text(
            'Google Sign-In failed: Please register an account first.',
            style: TextStyle(color: Colors.white),
          ),
        );
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(snackBar);
      }
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $error')),
      );
    } finally {
      setState(() => _isGoogleLoading = false);
    }
  }

  // Helper function to format phone number
  // Removes leading 0 and + from dial code
  // Input: "+256" + "0740733532" -> Output: "256740733532"
  String _formatPhoneNumber(String dialCode, String phone) {
    // Remove leading 0 from phone number if present
    String cleanPhone = phone.trim();
    if (cleanPhone.startsWith('0')) {
      cleanPhone = cleanPhone.substring(1);
    }
    // Remove + from dial code and concatenate
    String cleanDialCode = dialCode.replaceAll('+', '');
    return cleanDialCode + cleanPhone;
  }

  Future<void> _handleLogin() async {
    setState(() {
      _isLoginLoading = true;
    });

    bool response = false;

    // Format phone number correctly: remove leading 0, no + in country code
    String formattedPhone = _formatPhoneNumber(_selectedCountryCode, _phonecontroller.text);
    
    response = await context.read<LoginProvider>().login(
      formattedPhone,
      _phonePasswordController.text,
      context,
    );

    setState(() {
      _isLoginLoading = false;
    });

    if (response) {
      Navigator.of(context).pushReplacementNamed("/main");
    }
  }

  Widget _buildPhoneAuthForm() {
    return Column(
      children: [
        // Country Code Dropdown
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: AppColors.lighter,
            boxShadow: [
              BoxShadow(
                color: AppColors.gradientEnd.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _selectedCountryCode,
              dropdownColor: AppColors.lighter,
              icon: const Icon(Icons.arrow_drop_down, color: Colors.white70),
              style: const TextStyle(color: Colors.white, fontSize: 16),
              isExpanded: true,
              items: _countryCodes.map((country) {
                return DropdownMenuItem<String>(
                  value: country['code'],
                  child: Row(
                    children: [
                      Text(
                        country['flag']!,
                        style: const TextStyle(fontSize: 24),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        '${country['code']} ${country['country']}',
                        style: const TextStyle(color: Colors.white),
                      ),
                    ],
                  ),
                );
              }).toList(),
              onChanged: (String? newValue) {
                setState(() {
                  _selectedCountryCode = newValue!;
                });
              },
            ),
          ),
        ),
        const SizedBox(height: 16),
        
        // Phone Number Field
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: AppColors.lighter,
            boxShadow: [
              BoxShadow(
                color: AppColors.gradientEnd.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: TextFormField(
            controller: _phonecontroller,
            keyboardType: TextInputType.number,
            style: const TextStyle(color: Colors.white, fontSize: 16),
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.phone, color: Colors.white70),
              filled: true,
              fillColor: Colors.transparent,
              labelText: "Phone Number",
              labelStyle: const TextStyle(color: Colors.white60),
              hintText: "740123456",
              hintStyle: const TextStyle(color: Colors.white38),
              errorText: _phoneErrorText,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Colors.amber, width: 2),
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        
        // Password Field
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: AppColors.lighter,
            boxShadow: [
              BoxShadow(
                color: AppColors.gradientEnd.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: TextFormField(
            obscureText: _obscurePassword,
            controller: _phonePasswordController,
            style: const TextStyle(color: Colors.white, fontSize: 16),
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.lock, color: Colors.white70),
              suffixIcon: IconButton(
                icon: Icon(
                  _obscurePassword ? Icons.visibility_off : Icons.visibility,
                  color: Colors.white70,
                ),
                onPressed: () {
                  setState(() {
                    _obscurePassword = !_obscurePassword;
                  });
                },
              ),
              labelText: "Password",
              labelStyle: const TextStyle(color: Colors.white60),
              filled: true,
              fillColor: Colors.transparent,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Colors.amber, width: 2),
              ),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.lighter.withOpacity(0.8),
              AppColors.gradientEnd,
              AppColors.background,
            ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: SingleChildScrollView(
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: SlideTransition(
                  position: _slideAnimation,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 40),
                      
                      // Header
                      const Text(
                        "Welcome",
                        style: TextStyle(
                          fontSize: 36,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.2,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        "Sign in to continue your journey",
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.white60,
                          fontWeight: FontWeight.w300,
                        ),
                      ),
                      const SizedBox(height: 50),

                      // Auth Form
                      _buildPhoneAuthForm(),

                      const SizedBox(height: 16),

                      // Forgot Password
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.amber,
                            padding: EdgeInsets.zero,
                          ),
                          onPressed: () => Navigator.of(context).pushNamed('/forgot'),
                          child: const Text(
                            "Forgot Password?",
                            style: TextStyle(
                              color: Colors.amber,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Login Button
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.amber,
                            foregroundColor: Colors.white,
                            elevation: 8,
                            shadowColor: Colors.amber.withOpacity(0.5),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onPressed: _isLoginLoading ? null : _handleLogin,
                          child: _isLoginLoading
                              ? const SizedBox(
                                  height: 24,
                                  width: 24,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.5,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white,
                                    ),
                                  ),
                                )
                              : const Text(
                                  'Login',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Divider
                      Row(
                        children: [
                          Expanded(
                            child: Divider(
                              color: Colors.white24,
                              thickness: 1,
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Text(
                              "OR",
                              style: TextStyle(
                                color: Colors.white60,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          Expanded(
                            child: Divider(
                              color: Colors.white24,
                              thickness: 1,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 24),

                      // Google Sign In Button
                      SizedBox(
                        height: 56,
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.white,
                            side: const BorderSide(color: Colors.white24, width: 1.5),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onPressed: _isGoogleLoading ? null : _handleGoogleLogin,
                          icon: _isGoogleLoading
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white,
                                    ),
                                  ),
                                )
                              : Image.asset(
                                  'lib/assets/images/google.png',
                                  height: 24,
                                  width: 24,
                                ),
                          label: const Text(
                            'Continue with Google',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 32),

                      // Register Section
                      Center(
                        child: Column(
                          children: [
                            const Text(
                              "Don't have an account?",
                              style: TextStyle(
                                color: Colors.white60,
                                fontSize: 15,
                              ),
                            ),
                            const SizedBox(height: 12),
                            TextButton(
                              style: TextButton.styleFrom(
                                foregroundColor: Colors.amber,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 32,
                                  vertical: 12,
                                ),
                              ),
                              onPressed: _isRegisterLoading
                                  ? null
                                  : () async {
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
                                        valueColor: AlwaysStoppedAnimation<Color>(
                                          Colors.amber,
                                        ),
                                      ),
                                    )
                                  : const Text(
                                      'Create Account',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}