import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_snackbar_content/flutter_snackbar_content.dart';
import 'package:easingles/Pages/Login_page.dart';
import 'package:easingles/Provider/RegisterProvider.dart';
import 'package:easingles/assets/app.colors.dart';
import 'package:easingles/styles/app.text.dart';
import 'package:otp_text_field/otp_field.dart';
import 'package:otp_text_field/otp_field_style.dart';
import 'package:otp_text_field/style.dart';
import 'package:provider/provider.dart';
import 'package:step_progress_indicator/step_progress_indicator.dart';




class Text_input extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  const Text_input({required this.label, required this.controller});
  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      obscureText: label.toLowerCase().contains('password'),
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
        ),
      ),
    );
  }
}

class Toolbar extends StatelessWidget implements PreferredSizeWidget {
  final Widget leading;
  final String title;
  final Color background;
  const Toolbar({required this.leading, required this.title, required this.background});

  @override
  Widget build(BuildContext context) {
    return AppBar(
      leading: leading,
      title: Text(title),
      backgroundColor: background,
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}


class ForgotPass extends StatefulWidget {
  @override
  State<ForgotPass> createState() => _ForgotPassState();
}

class _ForgotPassState extends State<ForgotPass> {
  final String pagename = "Account Recovery";

  final _pageController = PageController();

  late int _currentPage = 1;

  bool _isLoading = false;
  bool _isOtpLoading = false;
  bool _isFinalSubmitLoading = false; 

  
  final phonecontroller = TextEditingController();

  final passwordcontroller = TextEditingController();
  final confirmpasswordcontroller = TextEditingController();

  String _enteredOtp = '';


  void _showSnackbar(BuildContext context, String message, ContentType type) {
    final snackBar = SnackBar(
      elevation: 0,
      behavior: SnackBarBehavior.floating,
      backgroundColor: Colors.transparent,
      content: FlutterSnackbarContent(
        message: message,
        contentType: type,
      ),
    );
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(snackBar);
  }

  Future<void> _handlePasswordReset() async {
    setState(() {
      _isFinalSubmitLoading = true;
    });

    if (passwordcontroller.text.length < 6) {
      _showSnackbar(context, 'Password should at least be 6 characters', ContentType.failure);
      setState(() {
        _isFinalSubmitLoading = false;
      });
      return;
    }
    if (!(passwordcontroller.text == confirmpasswordcontroller.text)) {
      _showSnackbar(context, 'Passwords do not match', ContentType.failure);
      setState(() {
        _isFinalSubmitLoading = false;
      });
      return;
    }
    if (passwordcontroller.text.contains(' ')) {
      _showSnackbar(context, 'Passwords should not contain spaces, usually the last character is inserted', ContentType.warning);
      setState(() {
        _isFinalSubmitLoading = false;
      });
      return;
    }


    bool response = await context
        .read<RegisterProvider>()
        .verifyconfirmationotp(
            passwordcontroller.text,
            context,
            phonecontroller.text,
            
        );

    setState(() {
      _isFinalSubmitLoading = false;
    });

    Timer(Duration(seconds: 3), () {
      if (response) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
              builder: (context) => Login_page()),
        );
      }
    });
  }
  
  Future<void> _handleOtpVerification(String pin) async {
    setState(() {
      _isOtpLoading = true;
    });
    

    bool response = await context
        .read<RegisterProvider>()
        .verifyotp(pin, context);

    setState(() {
      _isOtpLoading = false;
    });

    switch (response) {
      case true:
        if (_pageController.page != 2) {
          
          setState(() {
            _currentPage = _currentPage + 1;
          });
          _pageController.nextPage(
            duration: Duration(milliseconds: 500),
            curve: Curves.easeInOut,
          );
        }
        break;
      default:
        _showSnackbar(context, 'Wrong OTP code provided, please enter the received pin', ContentType.failure);
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: Toolbar(
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
            icon: Icon(Icons.arrow_back)),
        title: pagename,
        background: AppColors.lighter),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(15, 25, 15, 0),
            child: StepProgressIndicator(
              totalSteps: 3,
              currentStep: _currentPage,
              selectedColor: Colors.yellow,
              unselectedColor: Colors.white,
            ),
          ),
          Expanded(
            child: PageView(
              controller: _pageController,
              scrollDirection: Axis.horizontal,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                Container(
                  color: AppColors.background,
                  child: Padding(
                    padding: const EdgeInsets.only(top: 30),
                    child: Column(children: [
                      const SizedBox(height: 15),
                      Padding(
                        padding: EdgeInsets.fromLTRB(10, 5, 10, 0),
                        child: TextFormField(
                          obscureText: false,
                          controller: phonecontroller,
                          keyboardType: TextInputType.phone,
                          decoration: InputDecoration(
                            labelText: "Phone Number i.e. 078... or 075...",
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.all(
                                Radius.circular(12),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 30),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        child: SizedBox(
                          width: double.infinity,
                          height: 40,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.lighter,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12), 
                              ),
                            ),
                            onPressed: _isLoading ? null : () async {
                              if (phonecontroller.text.isEmpty) {
                                _showSnackbar(context, 'Phone Number cannot be empty', ContentType.warning);
                                return;
                              }

                              if (phonecontroller.text.length != 10) {
                                _showSnackbar(context, 'Phone Number must have 10 digits', ContentType.warning);
                                return;
                              }

                              setState(() {
                                _isLoading = true;
                              });

                              bool response = await context
                                  .read<RegisterProvider>()
                                  .sendconfirmationotp(phonecontroller.text, context);

                              setState(() {
                                _isLoading = false;
                              });

                              if (response) {
                                if (_pageController.page != 2) {
                                  setState(() {
                                    _currentPage = _currentPage + 1;
                                  });
                                  _pageController.nextPage(
                                    duration: Duration(milliseconds: 500),
                                    curve: Curves.easeInOut,
                                  );
                                }
                              }
                            },
                            child: _isLoading
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                    ),
                                  )
                                : const Text('Send OTP', style: TextStyle(color: Colors.white)),
                          ),
                        ),
                      ),
                    ]),
                  ),
                ),

                Container(
                  color: AppColors.background,
                  child: Column(
                    children: [
                      const SizedBox(height: 20),
                      Text(
                        "Enter OTP",
                        style: AppText.header1,
                      ),
                      const SizedBox(height: 20),
                      Padding(
                        padding: const EdgeInsets.all(15.0),
                        child: OTPTextField(
                          length: 5,
                          width: MediaQuery.of(context).size.width,
                          fieldWidth: 50,
                          style: const TextStyle(fontSize: 17),
                          otpFieldStyle: OtpFieldStyle(
                            enabledBorderColor: Colors.white,
                            errorBorderColor: Colors.white,
                          ),
                          textFieldAlignment: MainAxisAlignment.spaceAround,
                          fieldStyle: FieldStyle.box,
                          onChanged: (pin) {
                            _enteredOtp = pin;
                          },
                          onCompleted: (pin) async {
                            await _handleOtpVerification(pin);
                          },
                        ),
                      ),
                      

                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        child: SizedBox(
                          width: double.infinity,
                          height: 40,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.lighter,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            onPressed: _isOtpLoading ? null : () async {
                              if (_enteredOtp.length == 5) {
                                await _handleOtpVerification(_enteredOtp);
                              } else {
                                _showSnackbar(context, 'Please enter the 5-digit OTP', ContentType.warning);
                              }
                            },
                            child: _isOtpLoading
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                    ),
                                  )
                                : const Text('Verify', style: TextStyle(color: Colors.white)),
                          ),
                        ),
                      ),

                    ],
                  ),
                ),

                SingleChildScrollView(
                  child: Container(
                    color: AppColors.background,
                    child: Padding(
                      padding: const EdgeInsets.only(top: 30),
                      child: Column(children: [
                        const SizedBox(height: 15),
                        Padding(
                          padding: EdgeInsets.fromLTRB(10, 5, 10, 0),
                          child: Text_input(
                            label: 'New Password',
                            controller: passwordcontroller,
                          ),
                        ),
                        const SizedBox(height: 30),
                        Padding(
                          padding: EdgeInsets.fromLTRB(10, 5, 10, 0),
                          child: Text_input(
                            label: 'Confirm Password',
                            controller: confirmpasswordcontroller,
                          ),
                        ),
                        const SizedBox(height: 15),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          child: SizedBox(
                            width: double.infinity,
                            height: 50,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.lighter,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              onPressed: _isFinalSubmitLoading ? null : _handlePasswordReset,
                              child: _isFinalSubmitLoading
                                  ? const SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                      ),
                                    )
                                  : const Text('Continue',
                                      style: TextStyle(color: Colors.white)),
                            ),
                          ),
                        ),
                      ]),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}