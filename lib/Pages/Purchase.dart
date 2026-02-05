import 'package:flutter/material.dart';
import 'package:flutter_snackbar_content/flutter_snackbar_content.dart';
import 'package:mazale/Components/Toolbar.dart';
import 'package:mazale/assets/app.colors.dart';
import 'package:mazale/assets/urlconfig.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class Purchase extends StatefulWidget {
  const Purchase({super.key});

  @override
  State<Purchase> createState() => _PurchaseState();
}

class _PurchaseState extends State<Purchase> {
  String selectedPlan = "1 month"; // Pre-select best value plan
  TextEditingController phoneNumberController = TextEditingController();
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: Toolbar(
        title: "Unlock Premium",
        background: AppColors.lighter,
        leading: IconButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          icon: Icon(Icons.arrow_back),
        ),
        actions: [],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Hero Section
              Container(
                padding: EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.amber.shade400, Colors.amber.shade600],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  children: [
                    Icon(Icons.star_rounded, size: 50, color: Colors.white),
                    SizedBox(height: 12),
                    Text(
                      "Get Unlimited Connections",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      "Join 10,000+ members finding meaningful connections",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white.withOpacity(0.9),
                      ),
                    ),
                  ],
                ),
              ),
              
              SizedBox(height: 24),
              
              // Benefits Section
              Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.lighter.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Premium Benefits",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(height: 12),
                    _buildBenefit("Unlimited swipes and matches"),
                    _buildBenefit("See who likes you first"),
                    _buildBenefit("Priority profile visibility"),
                    _buildBenefit("Advanced filters and preferences"),
                  ],
                ),
              ),
              
              SizedBox(height: 24),
              
              Text(
                "Choose Your Plan",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              SizedBox(height: 4),
              Text(
                "Start connecting today, cancel anytime",
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[400],
                ),
              ),
              SizedBox(height: 16),
              
              // Plans
              buildPlanOption(
                title: "1 Month",
                subtitle: "Most Popular",
                price: "UGX 15,000",
                pricePerDay: "~500/day",
                plan: "1 month",
                savings: null,
                isBestValue: true,
              ),
              SizedBox(height: 12),
              buildPlanOption(
                title: "1 Week",
                subtitle: "Try Premium",
                price: "UGX 6,000",
                pricePerDay: "~857/day",
                plan: "1 week",
                savings: null,
                isBestValue: false,
              ),
              SizedBox(height: 12),
              buildPlanOption(
                title: "3 Days",
                subtitle: "Weekend Special",
                price: "UGX 3,500",
                pricePerDay: "~1,167/day",
                plan: "3 days",
                savings: null,
                isBestValue: false,
              ),
              SizedBox(height: 12),
              buildPlanOption(
                title: "1 Day",
                subtitle: "Quick Trial",
                price: "UGX 1,500",
                pricePerDay: "1,500/day",
                plan: "1 day",
                savings: null,
                isBestValue: false,
              ),
              
              SizedBox(height: 24),
              
              // Payment Section
              Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.lighter.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(color: Colors.amber.withOpacity(0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.payment, color: Colors.amber, size: 20),
                        SizedBox(width: 8),
                        Text(
                          "Payment Details",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 12),
                    Text(
                      "MTN or Airtel Money",
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[300],
                      ),
                    ),
                    SizedBox(height: 8),
                    TextFormField(
                      controller: phoneNumberController,
                      keyboardType: TextInputType.number,
                      style: TextStyle(color: Colors.white, fontSize: 16),
                      decoration: InputDecoration(
                        labelText: "Phone Number",
                        hintText: "078XXXXXXX or 075XXXXXXX",
                        hintStyle: TextStyle(color: Colors.grey[600]),
                        labelStyle: TextStyle(color: Colors.grey[400]),
                        prefixIcon: Icon(Icons.phone, color: Colors.amber),
                        filled: true,
                        fillColor: Colors.black.withOpacity(0.3),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey[700]!),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey[700]!),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.amber, width: 2),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              
              SizedBox(height: 24),
              
              // CTA Button
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.amber,
                  foregroundColor: Colors.black,
                  padding: EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 4,
                ),
                onPressed: _isLoading ? null : _handlePayment,
                child: _isLoading
                    ? const SizedBox(
                        height: 24,
                        width: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
                        ),
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.lock_open, size: 20),
                          SizedBox(width: 8),
                          Text(
                            'Start Premium Now',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
              ),
              
              SizedBox(height: 16),
              
              // Trust Signals
              Text(
                "🔒 Secure payment • Cancel anytime • Instant activation",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[500],
                ),
              ),
              
              SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBenefit(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        children: [
          Icon(Icons.check_circle, color: Colors.amber, size: 20),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 14,
                color: Colors.white.withOpacity(0.9),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget buildPlanOption({
    required String title,
    required String subtitle,
    required String price,
    required String pricePerDay,
    required String plan,
    String? savings,
    required bool isBestValue,
  }) {
    bool isSelected = selectedPlan == plan;
    
    return GestureDetector(
      onTap: () {
        setState(() {
          selectedPlan = plan;
        });
      },
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: isSelected ? Colors.amber : AppColors.lighter.withOpacity(0.5),
          border: Border.all(
            color: isSelected ? Colors.amber : Colors.grey[700]!,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.amber.withOpacity(0.3),
                    blurRadius: 12,
                    spreadRadius: 2,
                  )
                ]
              : [],
        ),
        child: Stack(
          children: [
            if (isBestValue)
              Positioned(
                top: 0,
                right: 0,
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.green,
                    borderRadius: BorderRadius.only(
                      topRight: Radius.circular(16),
                      bottomLeft: Radius.circular(12),
                    ),
                  ),
                  child: Text(
                    "BEST VALUE",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isSelected ? Colors.black : Colors.grey[600]!,
                        width: 2,
                      ),
                      color: isSelected ? Colors.black : Colors.transparent,
                    ),
                    child: isSelected
                        ? Icon(Icons.check, size: 16, color: Colors.amber)
                        : null,
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              title,
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: isSelected ? Colors.black : Colors.white,
                              ),
                            ),
                            SizedBox(width: 8),
                            if (isBestValue && !isSelected)
                              Container(
                                padding: EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.green,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  "SAVE 67%",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        SizedBox(height: 4),
                        Text(
                          subtitle,
                          style: TextStyle(
                            fontSize: 13,
                            color: isSelected
                                ? Colors.black.withOpacity(0.7)
                                : Colors.grey[400],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        price,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: isSelected ? Colors.black : Colors.white,
                        ),
                      ),
                      Text(
                        pricePerDay,
                        style: TextStyle(
                          fontSize: 11,
                          color: isSelected
                              ? Colors.black.withOpacity(0.6)
                              : Colors.grey[500],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handlePayment() async {
    if (phoneNumberController.text.trim().isEmpty) {
      _showError('Please enter your phone number');
      return;
    }

    if (phoneNumberController.text.trim().length != 10) {
      _showError('Please enter a valid 10-digit phone number');
      return;
    }

    if (selectedPlan.isEmpty) {
      _showError('Please select a plan');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      SharedPreferences pref = await SharedPreferences.getInstance();
      String? id = pref.getString("id");
      String? token = pref.getString("token");

      var body = {
        "phone": phoneNumberController.text.trim(),
        "plan": selectedPlan,
        "reason":
            "$selectedPlan plan purchase at ${DateTime.now()} on phone number ${phoneNumberController.text.trim()}",
        "transactionId":
            "${DateTime.now()}+${phoneNumberController.text.trim()}+$selectedPlan+plan purchase",
        "id": id
      };

      var response = await http.post(
        Uri.parse('${AppUrls.production}/api/payments'),
        headers: {'Authorization': 'Bearer $token'},
        body: body,
      );

      setState(() {
        _isLoading = false;
      });

      switch (response.statusCode) {
        case 200:
          _showSuccess(
              "🎉 Welcome to Premium! Your $selectedPlan subscription is now active.");
          Future.delayed(Duration(seconds: 2), () {
            Navigator.of(context).pop();
          });
          break;
        case 400:
          _showError(
              "Payment failed. Please check your details and try again.");
          break;
        case 500:
          _showError("Server error. Please try again in a moment.");
          break;
        default:
          _showError("Something went wrong. Please try again.");
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showError("Connection error. Please check your internet and try again.");
    }
  }

  void _showError(String message) {
    final snackBar = SnackBar(
      elevation: 0,
      behavior: SnackBarBehavior.floating,
      backgroundColor: Colors.transparent,
      content: FlutterSnackbarContent(
        message: message,
        contentType: ContentType.failure,
      ),
    );
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(snackBar);
  }

  void _showSuccess(String message) {
    final snackBar = SnackBar(
      elevation: 0,
      behavior: SnackBarBehavior.floating,
      backgroundColor: Colors.transparent,
      content: FlutterSnackbarContent(
        message: message,
        contentType: ContentType.success,
      ),
    );
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(snackBar);
  }
}