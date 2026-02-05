import 'dart:convert';
import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:flutter_snackbar_content/flutter_snackbar_content.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mazale/Components/AppButton.dart';
import 'package:mazale/Components/Text_input.dart';
import 'package:mazale/Components/Toolbar.dart';
import 'package:mazale/Models/Authmodel.dart';
import 'package:mazale/Pages/PhotoUploadPage.dart';
import 'package:mazale/Provider/LoginProvider.dart';
import 'package:mazale/Provider/RegisterProvider.dart';
import 'package:mazale/assets/app.colors.dart';
import 'package:mazale/assets/urlconfig.dart';
import 'package:mazale/styles/app.text.dart';
import 'package:otp_text_field/otp_field.dart';
import 'package:otp_text_field/otp_text_field.dart';
import 'package:otp_text_field/style.dart';
import 'package:provider/provider.dart';
import 'package:scroll_date_picker/scroll_date_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:step_progress_indicator/step_progress_indicator.dart';
import 'package:http/http.dart' as http;

class Register extends StatefulWidget {
  @override
  State<Register> createState() => _RegisterState();
}

enum Gender { Male, Female, Other }

enum RegistrationType { Phone }

class Country {
  final String name;
  final String code;
  final String dialCode;
  final String flag;

  Country({
    required this.name,
    required this.code,
    required this.dialCode,
    required this.flag,
  });
}

class _RegisterState extends State<Register> {
  final String pagename = "Account Registration";
  final GoogleSignIn signIn = GoogleSignIn.instance;
  final _pageController = PageController();
  bool _isGoogleLoading = false;

  @override
  void initState() {
    super.initState();
  }

  late int _currentPage = 1;

  String _enteredOtp = '';
  String? _verifiedPhoneNumber; // Store verified phone number

  // Country code selection
  Country _selectedCountry = Country(
    name: 'Uganda',
    code: 'UG',
    dialCode: '+256',
    flag: '🇺🇬',
  );

  final List<Country> _countries = [
    Country(name: 'Uganda', code: 'UG', dialCode: '+256', flag: '🇺🇬'),
    Country(name: 'Kenya', code: 'KE', dialCode: '+254', flag: '🇰🇪'),
    Country(name: 'Tanzania', code: 'TZ', dialCode: '+255', flag: '🇹🇿'),
    Country(name: 'Rwanda', code: 'RW', dialCode: '+250', flag: '🇷🇼'),
    Country(name: 'South Africa', code: 'ZA', dialCode: '+27', flag: '🇿🇦'),
    Country(name: 'Nigeria', code: 'NG', dialCode: '+234', flag: '🇳🇬'),
    Country(name: 'Ghana', code: 'GH', dialCode: '+233', flag: '🇬🇭'),
    Country(name: 'United States', code: 'US', dialCode: '+1', flag: '🇺🇸'),
    Country(name: 'United Kingdom', code: 'GB', dialCode: '+44', flag: '🇬🇧'),
    Country(name: 'India', code: 'IN', dialCode: '+91', flag: '🇮🇳'),
  ];

  bool _isLoadingSendOtp = false;
  bool _isLoadingVerifyOtp = false;
  bool _isLoadingUserDetails = false;
  bool _isLoadingPassword = false;
  bool _isLoadingGender = false;
  bool _isLoadingRegister = false;

  final Color _primaryOrange = AppColors.lighter;
  final Color _secondaryYellow = AppColors.lighter;
  final Color _accentGreen = AppColors.lighter;
  final Color _deepBrown = AppColors.lighter;
  final Color _warmTerracotta = AppColors.lighter;
  final Color _richRed = AppColors.lighter;
  final Color _earthyBeige = Color(0xFFF4F1DE);

  // Registration type selection
  final RegistrationType _registrationType = RegistrationType.Phone;

  final phonecontroller = TextEditingController();
  final emailcontroller = TextEditingController();
  final firstnamecontroller = TextEditingController();
  final lastnamecontroller = TextEditingController();
  final password = TextEditingController();
  final confirmpassword = TextEditingController();
  DateTime _selectedDate = DateTime.now();
  Gender? _selectedGender;

  List<File?> _selectedImages = [];

  Future<void> _handleGoogleSignIn() async {
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

      var response = await http.post(
        Uri.parse("${AppUrls.production}/api/auth/google/"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"idToken": idToken}),
      );

      if (response.statusCode == 200) {
        var data = jsonDecode(response.body);
        final DjangoAuthUser finalData = DjangoAuthUser.fromJson(data['user']);
        print(response.body.toString());

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

  // Send OTP via Django Backend
  Future<void> _sendPhoneOtp() async {
    String formattedPhone = _formatPhoneNumber(
      _selectedCountry.dialCode, 
      phonecontroller.text.trim()
    );

    if (phonecontroller.text.isEmpty) {
      _showSnackBar('Please enter your phone number', ContentType.warning);
      return;
    }

    setState(() => _isLoadingSendOtp = true);

    try {
      var response = await http.post(
        Uri.parse("${AppUrls.production}/api/auth/request-otp/"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"phone_number": formattedPhone}),
      );

      setState(() => _isLoadingSendOtp = false);

      if (response.statusCode == 200) {
        var data = jsonDecode(response.body);
        _showSnackBar(
          data['message'] ?? 'OTP sent successfully!',
          ContentType.success,
        );

        // Move to OTP page
        setState(() => _currentPage = _currentPage + 1);
        _pageController.nextPage(
          duration: Duration(milliseconds: 500),
          curve: Curves.easeInOut,
        );
      } else {
        var errorData = jsonDecode(response.body);
        _showSnackBar(
          errorData['error'] ?? 'Failed to send OTP',
          ContentType.failure,
        );
      }
    } catch (e) {
      setState(() => _isLoadingSendOtp = false);
      print("Error sending OTP: $e");
      _showSnackBar(
        'Failed to send OTP. Please try again',
        ContentType.failure,
      );
    }
  }

  // Verify OTP via Django Backend
  Future<void> _verifyPhoneOtp(String otp) async {
    String formattedPhone = _formatPhoneNumber(
      _selectedCountry.dialCode, 
      phonecontroller.text.trim()
    );

    if (otp.length != 5) {
      _showSnackBar('Please enter the complete OTP', ContentType.warning);
      return;
    }

    setState(() => _isLoadingVerifyOtp = true);

    try {
      var response = await http.post(
        Uri.parse("${AppUrls.production}/api/auth/verify-otp/"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "phone_number": formattedPhone,
          "otp_code": otp,
        }),
      );

      setState(() => _isLoadingVerifyOtp = false);

      if (response.statusCode == 200) {
        var data = jsonDecode(response.body);
        _verifiedPhoneNumber = data['phone_number'];
        
        _showSnackBar('Phone verified successfully!', ContentType.success);

        // Move to next page
        setState(() => _currentPage = _currentPage + 1);
        _pageController.nextPage(
          duration: Duration(milliseconds: 500),
          curve: Curves.easeInOut,
        );
      } else {
        var errorData = jsonDecode(response.body);
        _showSnackBar(
          errorData['error'] ?? 'Invalid OTP',
          ContentType.failure,
        );
      }
    } catch (e) {
      setState(() => _isLoadingVerifyOtp = false);
      _showSnackBar('Verification failed. Please try again', ContentType.failure);
    }
  }

  // Resend OTP
  Future<void> _resendOtp() async {
    await _sendPhoneOtp();
  }

  // Complete Registration
  Future<void> _completeRegistration() async {
    if (_selectedImages.isEmpty) {
      _showSnackBar(
        'Please add at least one photo to continue',
        ContentType.failure,
      );
      return;
    }

    if (_verifiedPhoneNumber == null) {
      _showSnackBar('Phone number not verified', ContentType.failure);
      return;
    }

    setState(() => _isLoadingRegister = true);

    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse("${AppUrls.production}/api/auth/register/"),
      );

      // Add phone number and other fields
      request.fields['phone_number'] = _verifiedPhoneNumber!;
      request.fields['first_name'] = firstnamecontroller.text;
      request.fields['last_name'] = lastnamecontroller.text;
      request.fields['password'] = password.text;
      request.fields['gender'] = _selectedGender.toString().split('.').last;
      request.fields['day'] = _selectedDate.day.toString();
      request.fields['month'] = _selectedDate.month.toString();
      request.fields['year'] = _selectedDate.year.toString();
      request.fields['otp_code'] = _enteredOtp;

      // Add images
      for (var i = 0; i < _selectedImages.length; i++) {
        if (_selectedImages[i] != null) {
          var file = await http.MultipartFile.fromPath(
            'user_images',
            _selectedImages[i]!.path,
          );
          request.files.add(file);
        }
      }

      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      setState(() => _isLoadingRegister = false);

      if (response.statusCode == 201) {
        var data = jsonDecode(response.body);
        
        // Save tokens
        final SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.setString('token', data['token']);
        await prefs.setString('refresh_token', data['refresh_token']);
        await prefs.setString('id', data['user']['id'].toString());
        await prefs.setString('firstname', data['user']['first_name']);
        await prefs.setString('lastname', data['user']['last_name']);

        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (BuildContext dialogContext) {
            return AlertDialog(
              title: Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Icon(Icons.check_circle, color: Colors.green),
                  SizedBox(width: 10),
                  Text('Welcome! 🎉'),
                ],
              ),
              content: const Text(
                "Your account has been created successfully! We have a surprise gift for you. Login to redeem it from the gifts section.",
              ),
              actions: <Widget>[
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pushReplacementNamed('/main');
                  },
                  child: Text(
                    "GET STARTED",
                    style: TextStyle(
                      color: _accentGreen,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            );
          },
        );
      } else {
        var errorData = jsonDecode(response.body);
        _showSnackBar(
          errorData['error'] ?? 'Registration failed',
          ContentType.failure,
        );
      }
    } catch (e) {
      setState(() => _isLoadingRegister = false);
      print("Registration error: $e");
      _showSnackBar('Registration failed. Please try again', ContentType.failure);
    }
  }

  // Country picker bottom sheet
  void _showCountryPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: EdgeInsets.symmetric(vertical: 20),
          height: 400,
          child: Column(
            children: [
              Text(
                'Select Country',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: _deepBrown,
                ),
              ),
              SizedBox(height: 20),
              Expanded(
                child: ListView.builder(
                  itemCount: _countries.length,
                  itemBuilder: (context, index) {
                    final country = _countries[index];
                    final isSelected = _selectedCountry.code == country.code;

                    return ListTile(
                      leading: Text(
                        country.flag,
                        style: TextStyle(fontSize: 32),
                      ),
                      title: Text(
                        country.name,
                        style: TextStyle(
                          fontWeight: isSelected
                              ? FontWeight.bold
                              : FontWeight.normal,
                          color: isSelected ? _primaryOrange : _deepBrown,
                        ),
                      ),
                      trailing: Text(
                        country.dialCode,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: isSelected
                              ? _primaryOrange
                              : _deepBrown.withOpacity(0.6),
                        ),
                      ),
                      selected: isSelected,
                      selectedTileColor: _primaryOrange.withOpacity(0.1),
                      onTap: () {
                        setState(() {
                          _selectedCountry = country;
                        });
                        Navigator.pop(context);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void showImageNoticeDialog(BuildContext context, Color accentGreen) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          backgroundColor: AppColors.lighter,
          title: Row(
            children: [
              Icon(Icons.info, color: Colors.blueAccent),
              SizedBox(width: 10),
              Text('Notice !'),
            ],
          ),
          content: Text(
            "All account with fake images that donot contain people will be banned permanently to protect our users from scammers. All earned virtual gifts will be revoked. You can always change your selection by clicking on 'pick images' or 'continue' if you are confident with your selection. Thanks.",
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () async {
                Navigator.of(dialogContext).pop();

                List<XFile>? images = await ImagePicker().pickMultiImage(
                  imageQuality: 85,
                  maxWidth: 500,
                );

                if (images != null) {
                  List<File?> tempImages = [];
                  for (XFile image in images) {
                    if (tempImages.length == 4) break;
                    tempImages.add(File(image.path));
                  }

                  setState(() {
                    _selectedImages = tempImages;
                  });

                  print('Selected ${tempImages.length} images.');
                }
              },
              child: Text("PICK IMAGES", style: TextStyle(color: Colors.white)),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
              child: Text(
                "CONTINUE",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _pickImages() async {
    if (_selectedImages.isEmpty) {
      showImageNoticeDialog(context, _accentGreen);
    } else {
      List<XFile>? images = await ImagePicker().pickMultiImage(
        imageQuality: 85,
      );

      if (images != null) {
        List<File?> _tempImages = [];
        _tempImages.addAll(_selectedImages);
        for (XFile image in images) {
          if (_tempImages.length == 4) break;
          _tempImages.add(File(image.path));
        }
        setState(() {
          _selectedImages = _tempImages;
        });
      }
    }
  }

  Widget _buildModernButton({
    required String text,
    required VoidCallback? onTap,
    required bool isLoading,
    Color? backgroundColor,
  }) {
    return Container(
      width: double.infinity,
      height: 56,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            backgroundColor ?? _primaryOrange,
            backgroundColor?.withOpacity(0.8) ?? _secondaryYellow,
          ],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: (backgroundColor ?? _primaryOrange).withOpacity(0.3),
            blurRadius: 12,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isLoading ? null : onTap,
          borderRadius: BorderRadius.circular(16),
          child: Center(
            child: isLoading
                ? SizedBox(
                    height: 24,
                    width: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : Text(
                    text,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                    ),
                  ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _earthyBeige,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: _primaryOrange,
        leading: IconButton(
          onPressed: () {
            if (_pageController.page != 0) {
              _pageController.previousPage(
                duration: Duration(milliseconds: 500),
                curve: Curves.easeInOut,
              );
              setState(() {
                _currentPage = _currentPage - 1;
              });
            } else {
              Navigator.of(context).pop();
            }
          },
          icon: Icon(Icons.arrow_back_ios_new, color: Colors.white),
        ),
        title: Text(
          pagename,
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [_primaryOrange, _secondaryYellow],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 25),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: List.generate(6, (index) {
                      return Expanded(
                        child: Container(
                          margin: EdgeInsets.symmetric(horizontal: 3),
                          height: 6,
                          decoration: BoxDecoration(
                            color: index < _currentPage
                                ? Colors.white
                                : Colors.white.withOpacity(0.3),
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                      );
                    }),
                  ),
                  SizedBox(height: 12),
                  Text(
                    'Step $_currentPage of 6',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: PageView(
              controller: _pageController,
              scrollDirection: Axis.horizontal,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _buildPhoneEmailPage(),
                _buildOtpPage(),
                _buildNamePage(),
                _buildPasswordPage(),
                _buildGenderDobPage(),
                _buildImagesPage(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPhoneEmailPage() {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 20),
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _primaryOrange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: _primaryOrange.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Icon(Icons.phone_android, color: _primaryOrange, size: 28),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Enter your phone number',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: _deepBrown,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 24),
            Row(
              children: [
                GestureDetector(
                  onTap: _showCountryPicker,
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: _primaryOrange.withOpacity(0.2),
                      ),
                    ),
                    child: Row(
                      children: [
                        Text(_selectedCountry.flag, style: TextStyle(fontSize: 24)),
                        SizedBox(width: 8),
                        Text(
                          _selectedCountry.dialCode,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: _deepBrown,
                          ),
                        ),
                        SizedBox(width: 4),
                        Icon(Icons.arrow_drop_down, color: _primaryOrange),
                      ],
                    ),
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: phonecontroller,
                    keyboardType: TextInputType.number,
                    style: TextStyle(fontSize: 16, color: _deepBrown),
                    decoration: InputDecoration(
                      labelText: "Phone Number",
                      hintText: "712345678",
                      prefixIcon: Icon(Icons.phone, color: _primaryOrange),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(
                          color: _primaryOrange.withOpacity(0.2),
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(color: _primaryOrange, width: 2),
                      ),
                      labelStyle: TextStyle(color: _deepBrown.withOpacity(0.7)),
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 32),
            _buildModernButton(
              text: 'Send OTP',
              isLoading: _isLoadingSendOtp,
              onTap: _sendPhoneOtp,
            ),
            SizedBox(height: 20),
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
                    : Image.asset('lib/assets/images/google.png', height: 24),
                label: const Text('Sign in with Google', style: TextStyle(fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOtpPage() {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            SizedBox(height: 20),
            Container(
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [_primaryOrange, _secondaryYellow],
                ),
              ),
              child: Icon(Icons.message, color: Colors.white, size: 48),
            ),
            SizedBox(height: 24),
            Text(
              "Verify Your Number",
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: _deepBrown,
              ),
            ),
            SizedBox(height: 12),
            Text(
              "Enter the 5-digit code sent to your phone",
              style: TextStyle(
                fontSize: 14,
                color: _deepBrown.withOpacity(0.6),
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 40),
            OTPTextField(
              length: 5,
              width: MediaQuery.of(context).size.width - 48,
              fieldWidth: 50,
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              otpFieldStyle: OtpFieldStyle(
                backgroundColor: Colors.white,
                borderColor: _primaryOrange.withOpacity(0.3),
                enabledBorderColor: _primaryOrange.withOpacity(0.3),
                focusBorderColor: _primaryOrange,
                errorBorderColor: _richRed,
              ),
              textFieldAlignment: MainAxisAlignment.spaceAround,
              fieldStyle: FieldStyle.box,
              onCompleted: (pin) async {
                setState(() => _enteredOtp = pin);
                await _verifyPhoneOtp(pin);
              },
            ),
            SizedBox(height: 20),
            TextButton(
              onPressed: _resendOtp,
              child: Text(
                'Resend OTP',
                style: TextStyle(
                  color: _primaryOrange,
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
            ),
            SizedBox(height: 32),
            if (_isLoadingVerifyOtp)
              CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(_primaryOrange),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildNamePage() {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 20),
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _accentGreen.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: _accentGreen.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Icon(Icons.person, color: _accentGreen, size: 28),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Tell us your name',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: _deepBrown,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 32),
            TextFormField(
              controller: firstnamecontroller,
              style: TextStyle(fontSize: 16, color: _deepBrown),
              decoration: InputDecoration(
                labelText: "First Name",
                prefixIcon: Icon(Icons.person_outline, color: _accentGreen),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: _accentGreen.withOpacity(0.2)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: _accentGreen, width: 2),
                ),
                labelStyle: TextStyle(color: _deepBrown.withOpacity(0.7)),
              ),
            ),
            SizedBox(height: 20),
            TextFormField(
              controller: lastnamecontroller,
              style: TextStyle(fontSize: 16, color: _deepBrown),
              decoration: InputDecoration(
                labelText: "Last Name",
                prefixIcon: Icon(Icons.person_outline, color: _accentGreen),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: _accentGreen.withOpacity(0.2)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: _accentGreen, width: 2),
                ),
                labelStyle: TextStyle(color: _deepBrown.withOpacity(0.7)),
              ),
            ),
            SizedBox(height: 32),
            _buildModernButton(
              text: 'Continue',
              isLoading: _isLoadingUserDetails,
              backgroundColor: _accentGreen,
              onTap: () {
                if (firstnamecontroller.text.isEmpty ||
                    lastnamecontroller.text.isEmpty) {
                  _showSnackBar('Please enter your name', ContentType.warning);
                  return;
                }
                setState(() => _currentPage = _currentPage + 1);
                _pageController.nextPage(
                  duration: Duration(milliseconds: 500),
                  curve: Curves.easeInOut,
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPasswordPage() {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 20),
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _warmTerracotta.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: _warmTerracotta.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Icon(Icons.lock, color: _warmTerracotta, size: 28),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Secure your account',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: _deepBrown,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 32),
            TextFormField(
              controller: password,
              obscureText: true,
              style: TextStyle(fontSize: 16, color: _deepBrown),
              decoration: InputDecoration(
                labelText: "Password",
                hintText: "At least 6 characters",
                prefixIcon: Icon(Icons.lock_outline, color: _warmTerracotta),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(
                    color: _warmTerracotta.withOpacity(0.2),
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: _warmTerracotta, width: 2),
                ),
                labelStyle: TextStyle(color: _deepBrown.withOpacity(0.7)),
              ),
            ),
            SizedBox(height: 20),
            TextFormField(
              controller: confirmpassword,
              obscureText: true,
              style: TextStyle(fontSize: 16, color: _deepBrown),
              decoration: InputDecoration(
                labelText: "Confirm Password",
                prefixIcon: Icon(Icons.lock_outline, color: _warmTerracotta),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(
                    color: _warmTerracotta.withOpacity(0.2),
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: _warmTerracotta, width: 2),
                ),
                labelStyle: TextStyle(color: _deepBrown.withOpacity(0.7)),
              ),
            ),
            SizedBox(height: 32),
            _buildModernButton(
              text: 'Continue',
              isLoading: _isLoadingPassword,
              backgroundColor: _warmTerracotta,
              onTap: () {
                if (password.text.isEmpty || confirmpassword.text.isEmpty) {
                  _showSnackBar('Fill all password fields', ContentType.failure);
                  return;
                }
                if (password.text != confirmpassword.text) {
                  _showSnackBar('Passwords do not match', ContentType.failure);
                  return;
                }
                if (password.text.length < 6) {
                  _showSnackBar(
                    'Password too short (minimum 6 characters)',
                    ContentType.failure,
                  );
                  return;
                }
                setState(() => _currentPage = _currentPage + 1);
                _pageController.nextPage(
                  duration: Duration(milliseconds: 500),
                  curve: Curves.easeInOut,
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGenderDobPage() {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 20),
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _secondaryYellow.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: _secondaryYellow.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Icon(Icons.calendar_today, color: _secondaryYellow, size: 28),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'About you',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: _deepBrown,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 24),
            Text(
              'Date of Birth',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: _deepBrown,
              ),
            ),
            SizedBox(height: 16),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: SizedBox(
                  height: 200,
                  child: ScrollDatePicker(
                    viewType: [
                      DatePickerViewType.day,
                      DatePickerViewType.month,
                      DatePickerViewType.year,
                    ],
                    selectedDate: _selectedDate,
                    scrollViewOptions: DatePickerScrollViewOptions(
                      year: ScrollViewDetailOptions(
                        selectedTextStyle: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: _secondaryYellow,
                        ),
                        textStyle: TextStyle(fontSize: 16, color: Colors.black87),
                      ),
                      month: ScrollViewDetailOptions(
                        margin: EdgeInsets.symmetric(horizontal: 6),
                        selectedTextStyle: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: _secondaryYellow,
                        ),
                        textStyle: TextStyle(fontSize: 16, color: Colors.black87),
                      ),
                      day: ScrollViewDetailOptions(
                        selectedTextStyle: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: _secondaryYellow,
                        ),
                        textStyle: TextStyle(fontSize: 16, color: Colors.black87),
                      ),
                    ),
                    options: DatePickerOptions(itemExtent: 50),
                    locale: Locale('en'),
                    onDateTimeChanged: (DateTime value) {
                      setState(() => _selectedDate = value);
                    },
                  ),
                ),
              ),
            ),
            SizedBox(height: 24),
            Text(
              'Gender',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: _deepBrown,
              ),
            ),
            SizedBox(height: 16),
            Row(
              children: [
                _buildGenderCard(Gender.Male, Icons.male, "Male"),
                SizedBox(width: 12),
                _buildGenderCard(Gender.Female, Icons.female, "Female"),
                SizedBox(width: 12),
                _buildGenderCard(Gender.Other, Icons.transgender, "Other"),
              ],
            ),
            SizedBox(height: 32),
            _buildModernButton(
              text: 'Continue',
              isLoading: _isLoadingGender,
              backgroundColor: _secondaryYellow,
              onTap: () {
                if (_selectedGender == null) {
                  _showSnackBar('Please select your gender', ContentType.warning);
                  return;
                }
                setState(() => _currentPage = _currentPage + 1);
                _pageController.nextPage(
                  duration: Duration(milliseconds: 500),
                  curve: Curves.easeInOut,
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGenderCard(Gender gender, IconData icon, String label) {
    bool isSelected = _selectedGender == gender;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() => _selectedGender = gender);
        },
        child: Container(
          padding: EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: isSelected ? _secondaryYellow : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected
                  ? _secondaryYellow
                  : _secondaryYellow.withOpacity(0.2),
              width: 2,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: _secondaryYellow.withOpacity(0.3),
                      blurRadius: 8,
                      offset: Offset(0, 4),
                    ),
                  ]
                : [],
          ),
          child: Column(
            children: [
              Icon(
                icon,
                color: isSelected ? Colors.white : _deepBrown,
                size: 32,
              ),
              SizedBox(height: 8),
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? Colors.white : _deepBrown,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImagesPage() {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 20),
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _richRed.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: _richRed.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Icon(Icons.photo_camera, color: _richRed, size: 28),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Add your photos',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: _deepBrown,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          '${_selectedImages.length}/4 selected',
                          style: TextStyle(
                            fontSize: 14,
                            color: _deepBrown.withOpacity(0.6),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (_selectedImages.isNotEmpty)
                    TextButton(
                      onPressed: () {
                        setState(() => _selectedImages.clear());
                      },
                      child: Text(
                        'Clear',
                        style: TextStyle(
                          color: _richRed,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            SizedBox(height: 24),
            GestureDetector(
              onTap: _pickImages,
              child: Container(
                height: 160,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: _richRed.withOpacity(0.3),
                    width: 2,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: _richRed.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.add_photo_alternate,
                        color: _richRed,
                        size: 48,
                      ),
                    ),
                    SizedBox(height: 16),
                    Text(
                      _selectedImages.isEmpty
                          ? "Tap to select photos"
                          : "Tap to add more photos",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: _deepBrown,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      "Choose up to 4 images",
                      style: TextStyle(
                        fontSize: 12,
                        color: _deepBrown.withOpacity(0.5),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 24),
            if (_selectedImages.isNotEmpty)
              GridView.builder(
                physics: NeverScrollableScrollPhysics(),
                shrinkWrap: true,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                ),
                itemCount: _selectedImages.length,
                itemBuilder: (context, index) {
                  return Stack(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 8,
                              offset: Offset(0, 4),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: Image.file(
                            _selectedImages[index]!,
                            fit: BoxFit.cover,
                            width: double.infinity,
                            height: double.infinity,
                          ),
                        ),
                      ),
                      Positioned(
                        top: 8,
                        right: 8,
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              _selectedImages.removeAt(index);
                            });
                          },
                          child: Container(
                            padding: EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.6),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.close,
                              color: Colors.white,
                              size: 18,
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: 8,
                        left: 8,
                        child: Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: _richRed,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '${index + 1}',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            SizedBox(height: 32),
            _buildModernButton(
              text: 'Complete Registration',
              isLoading: _isLoadingRegister,
              backgroundColor: _accentGreen,
              onTap: _completeRegistration,
            ),
            SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  void _showSnackBar(String message, ContentType contentType) {
    final snackBar = SnackBar(
      elevation: 0,
      behavior: SnackBarBehavior.floating,
      backgroundColor: Colors.transparent,
      content: FlutterSnackbarContent(
        message: message,
        contentType: contentType,
      ),
    );
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(snackBar);
  }
}