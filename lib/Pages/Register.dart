import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:flutter_snackbar_content/flutter_snackbar_content.dart';
import 'package:image_picker/image_picker.dart';
import 'package:easingles/Components/AppButton.dart';
import 'package:easingles/Components/Text_input.dart';
import 'package:easingles/Components/Toolbar.dart';
import 'package:easingles/Provider/LoginProvider.dart';
import 'package:easingles/Provider/RegisterProvider.dart';
import 'package:easingles/assets/app.colors.dart';
import 'package:easingles/styles/app.text.dart';
import 'package:otp_text_field/otp_field.dart';
import 'package:otp_text_field/otp_text_field.dart';
import 'package:otp_text_field/style.dart';
import 'package:provider/provider.dart';
import 'package:scroll_date_picker/scroll_date_picker.dart';
import 'package:step_progress_indicator/step_progress_indicator.dart';
import 'package:http/http.dart' as http;

class Register extends StatefulWidget {
  @override
  State<Register> createState() => _RegisterState();
}

enum Gender {
  Male,
  Female,
  Other,
}

enum RegistrationType {
  Phone,
  Email,
}

class _RegisterState extends State<Register> {
  final String pagename = "Account Registration";

  final _pageController = PageController();

  @override
  void initState() {
    super.initState();
  }

  late int _currentPage = 1;

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
  RegistrationType _registrationType = RegistrationType.Phone;

  final phonecontroller = TextEditingController();
  final emailcontroller = TextEditingController();
  final firstnamecontroller = TextEditingController();
  final lastnamecontroller = TextEditingController();
  final password = TextEditingController();
  final confirmpassword = TextEditingController();
  DateTime _selectedDate = DateTime.now();
  Gender? _selectedGender;

  List<File?> _selectedImages = [];

  // Email validation
  bool _isValidEmail(String email) {
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );
    return emailRegex.hasMatch(email);
  }


  void showImageNoticeDialog(BuildContext context, Color accentGreen) {
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (BuildContext dialogContext) {
      return AlertDialog(
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

                // ADD THIS setState() TO UPDATE THE UI
                setState(() {
                  _selectedImages = tempImages;
                });

                print('Selected ${tempImages.length} images.');
              }
            },
            child: Text(
              "PICK IMAGES",
              style: TextStyle(color: accentGreen),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
            },
            child: Text(
              "CONTINUE",
              style: TextStyle(color: accentGreen, fontWeight: FontWeight.bold),
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
                  Icon(
                    _registrationType == RegistrationType.Phone
                        ? Icons.phone_android
                        : Icons.email,
                    color: _primaryOrange,
                    size: 28,
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _registrationType == RegistrationType.Phone
                          ? 'Enter your phone number'
                          : 'Enter your email address',
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
            // Registration type toggle
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
              child: Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          _registrationType = RegistrationType.Phone;
                        });
                      },
                      child: Container(
                        padding: EdgeInsets.symmetric(vertical: 16),
                        decoration: BoxDecoration(
                          color: _registrationType == RegistrationType.Phone
                              ? _primaryOrange
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.phone,
                              color: _registrationType == RegistrationType.Phone
                                  ? Colors.white
                                  : _deepBrown.withOpacity(0.5),
                              size: 20,
                            ),
                            SizedBox(width: 8),
                            Text(
                              'Phone',
                              style: TextStyle(
                                color: _registrationType == RegistrationType.Phone
                                    ? Colors.white
                                    : _deepBrown.withOpacity(0.5),
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
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
                          _registrationType = RegistrationType.Email;
                        });
                      },
                      child: Container(
                        padding: EdgeInsets.symmetric(vertical: 16),
                        decoration: BoxDecoration(
                          color: _registrationType == RegistrationType.Email
                              ? _primaryOrange
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.email,
                              color: _registrationType == RegistrationType.Email
                                  ? Colors.white
                                  : _deepBrown.withOpacity(0.5),
                              size: 20,
                            ),
                            SizedBox(width: 8),
                            Text(
                              'Email',
                              style: TextStyle(
                                color: _registrationType == RegistrationType.Email
                                    ? Colors.white
                                    : _deepBrown.withOpacity(0.5),
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 32),
            // Input field based on selected type
            if (_registrationType == RegistrationType.Phone)
              TextFormField(
                controller: phonecontroller,
                keyboardType: TextInputType.phone,
                style: TextStyle(fontSize: 16, color: _deepBrown),
                decoration: InputDecoration(
                  labelText: "Phone Number",
                  hintText: "078... or 075...",
                  prefixIcon: Icon(Icons.phone, color: _primaryOrange),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(color: _primaryOrange.withOpacity(0.2)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(color: _primaryOrange, width: 2),
                  ),
                  labelStyle: TextStyle(color: _deepBrown.withOpacity(0.7)),
                ),
              )
            else
              TextFormField(
                controller: emailcontroller,
                keyboardType: TextInputType.emailAddress,
                style: TextStyle(fontSize: 16, color: _deepBrown),
                decoration: InputDecoration(
                  labelText: "Email Address",
                  hintText: "example@mail.com",
                  prefixIcon: Icon(Icons.email, color: _primaryOrange),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(color: _primaryOrange.withOpacity(0.2)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(color: _primaryOrange, width: 2),
                  ),
                  labelStyle: TextStyle(color: _deepBrown.withOpacity(0.7)),
                ),
              ),
            SizedBox(height: 32),
            _buildModernButton(
              text: 'Send OTP',
              isLoading: _isLoadingSendOtp,
              onTap: () async {
                // Validate input based on registration type
                if (_registrationType == RegistrationType.Phone) {
                  if (phonecontroller.text.isEmpty) {
                    _showSnackBar('Phone Number cannot be empty', ContentType.warning);
                    return;
                  }
                } else {
                  if (emailcontroller.text.isEmpty) {
                    _showSnackBar('Email Address cannot be empty', ContentType.warning);
                    return;
                  }
                  if (!_isValidEmail(emailcontroller.text)) {
                    _showSnackBar('Please enter a valid email address', ContentType.warning);
                    return;
                  }
                }

                setState(() => _isLoadingSendOtp = true);

                bool response;
                if (_registrationType == RegistrationType.Phone) {
                  response = await context
                      .read<RegisterProvider>()
                      .sendotp(phonecontroller.text, context);
                } else {
         
                  response = await context
                      .read<RegisterProvider>()
                      .sendEmailOtp(emailcontroller.text, context);
                }

                setState(() => _isLoadingSendOtp = false);

                if (response) {
                  setState(() => _currentPage = _currentPage + 1);
                  _pageController.nextPage(
                    duration: Duration(milliseconds: 500),
                    curve: Curves.easeInOut,
                  );
                }
              },
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
              "Verify Your ${_registrationType == RegistrationType.Phone ? 'Number' : 'Email'}",
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: _deepBrown,
              ),
            ),
            SizedBox(height: 12),
            Text(
              _registrationType == RegistrationType.Phone
                  ? "Enter the 5-digit code sent to your phone"
                  : "Enter the 5-digit code sent to your email",
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
                setState(() => _isLoadingVerifyOtp = true);

                bool response = await context
                    .read<RegisterProvider>()
                    .verifyotp(pin, context);

                setState(() => _isLoadingVerifyOtp = false);

                if (response) {
                  setState(() => _currentPage = _currentPage + 1);
                  _pageController.nextPage(
                    duration: Duration(milliseconds: 500),
                    curve: Curves.easeInOut,
                  );
                } else {
                  _showSnackBar(
                    'Wrong OTP code provided',
                    ContentType.failure,
                  );
                }
              },
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
              onTap: () async {
                setState(() => _isLoadingUserDetails = true);

                bool response = context.read<RegisterProvider>().phonenumberinput(
                      firstnamecontroller.text,
                      lastnamecontroller.text,
                      context,
                    );

                setState(() => _isLoadingUserDetails = false);

                if (response) {
                  setState(() => _currentPage = _currentPage + 1);
                  _pageController.nextPage(
                    duration: Duration(milliseconds: 500),
                    curve: Curves.easeInOut,
                  );
                }
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
                  borderSide: BorderSide(color: _warmTerracotta.withOpacity(0.2)),
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
                  borderSide: BorderSide(color: _warmTerracotta.withOpacity(0.2)),
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
              onTap: () async {
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

                setState(() => _isLoadingPassword = true);

                bool response = context.read<RegisterProvider>().passwordInput(
                      password.text,
                      confirmpassword.text,
                      context,
                    );

                setState(() => _isLoadingPassword = false);

                if (response) {
                  setState(() => _currentPage = _currentPage + 1);
                  _pageController.nextPage(
                    duration: Duration(milliseconds: 500),
                    curve: Curves.easeInOut,
                  );
                }
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
                    selectedDate: _selectedDate,
                    options: DatePickerOptions(
                      backgroundColor: Colors.white,
                      itemExtent: 50,
                    ),
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
                bool res = context.read<RegisterProvider>().gender_age(
                      _selectedGender.toString(),
                      _selectedDate,
                      context,
                    );

                if (res) {
                  setState(() => _currentPage = _currentPage + 1);
                  _pageController.nextPage(
                    duration: Duration(milliseconds: 500),
                    curve: Curves.easeInOut,
                  );
                }
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
                        style: TextStyle(color: _richRed, fontWeight: FontWeight.w600),
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
                    style: BorderStyle.solid,
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
              onTap: () async {
                if (_selectedImages.isEmpty) {
                  _showSnackBar(
                    'Please add at least one photo to continue',
                    ContentType.failure,
                  );
                  return;
                }

                setState(() => _isLoadingRegister = true);

                bool response = await context
                    .read<RegisterProvider>()
                    .registration(_selectedImages);

                setState(() => _isLoadingRegister = false);

                if (response) {
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
                              Navigator.of(dialogContext).pop();
                              Navigator.of(context).pop();
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
                }
              },
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