import 'package:flutter/material.dart';
import 'package:flutter_snackbar_content/flutter_snackbar_content.dart';
import 'package:easingles/Components/Toolbar.dart';
import 'package:easingles/assets/app.colors.dart';
import 'package:easingles/assets/urlconfig.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class Purchase extends StatefulWidget {
  const Purchase({super.key});

  @override
  State<Purchase> createState() => _PurchaseState();
}

class _PurchaseState extends State<Purchase> {
  String selectedPlan = "";
  TextEditingController phoneNumberController = TextEditingController();
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: Toolbar(
        title: "Plans",
        background: AppColors.lighter,
        leading: IconButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          icon: Icon(Icons.arrow_back),
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.amber,
            ),
            onPressed: () async {},
            child: _isLoading
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('confirm payment', style: TextStyle(color: Colors.black)),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(
                  "Select a Plan",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ),
              SizedBox(height: 16),
              buildPlanOption(
                  "1 week Plan", "Full features access", "UGX 2500", "1 week"),
              SizedBox(height: 10),
              buildPlanOption(
                  "2 weeks plan",
                  "Full features access, with a suprise gift(UGX.10000 limit that you can gift in your chats)",
                  "UGX 5000",
                  "2 weeks"),
              SizedBox(height: 10),
              buildPlanOption(
                  "1 month plan",
                  "All features plus a suprise gift you can give to anyone redeemable as mobile money(gift limit is UGX.50,000)",
                  "UGX 10000",
                  "1 month"),
              SizedBox(height: 10),
              Text(
                "MTN or Airtel money",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              TextFormField(
                controller: phoneNumberController,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  labelText: "Phone Number ie 078... or 075...",
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  // Check if the phone number has exactly 10 digits
                  if (value?.trim().length != 10) {
                    return 'Enter a valid 10-digit phone number';
                  }
                  return null; // Return null if the validation is successful
                },
              ),
              SizedBox(height: 24),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.amber,
                ),
                onPressed: _isLoading ? null : () async {
                  setState(() {
                    _isLoading = true;
                  });
                  SharedPreferences pref = await SharedPreferences.getInstance();
                  String? id = pref.getString("id");
                  String? token = pref.getString("token");
                  if (phoneNumberController.text.isNotEmpty &&
                      selectedPlan.isNotEmpty) {
                    if (phoneNumberController.text?.trim().length != 10) {
                      setState(() {
                        _isLoading = false;
                      });
                      const snackBar = SnackBar(
                        elevation: 0,
                        behavior: SnackBarBehavior.floating,
                        backgroundColor: Colors.transparent,
                        content: FlutterSnackbarContent(
                          message: 'Enter a valid 10-digit phone number',
                          contentType: ContentType.failure,
                        ),
                      );
                      ScaffoldMessenger.of(context)
                        ..hideCurrentSnackBar()
                        ..showSnackBar(snackBar);
                      return;
                    } else {
                      var body = {
                        "phone": phoneNumberController.text,
                        "plan": selectedPlan,
                        "reason":
                            "${selectedPlan}+plan purchase at ${DateTime.now()} on phone number ${phoneNumberController.text}",
                        "transactionId":
                            "${DateTime.now()}+${phoneNumberController.text}+${selectedPlan}+plan purchase",
                        "id":id
                      };
                      print(body);
                      var response = await http.post(
                          Uri.parse('${AppUrls.production}/api/payments'),
                          headers: {'Authorization': 'Bearer $token'},
                          body: body);
                      setState(() {
                        _isLoading = false;
                      });
                      switch (response.statusCode) {
                        case 200:
                          var snackBar = SnackBar(
                            elevation: 0,
                            behavior: SnackBarBehavior.floating,
                            backgroundColor: Colors.transparent,
                            content: FlutterSnackbarContent(
                              message:
                                  "You have successfully subscribed to ${selectedPlan} plan",
                              contentType: ContentType.success,
                            ),
                          );
                          ScaffoldMessenger.of(context)
                            ..hideCurrentSnackBar()
                            ..showSnackBar(snackBar);
                          break;
                        case 400:
                          const snackBar = SnackBar(
                            elevation: 0,
                            behavior: SnackBarBehavior.floating,
                            backgroundColor: Colors.transparent,
                            content: FlutterSnackbarContent(
                              message:
                                  "Something went wrong, please try again.",
                              contentType: ContentType.failure,
                            ),
                          );
                          ScaffoldMessenger.of(context)
                            ..hideCurrentSnackBar()
                            ..showSnackBar(snackBar);
                          break;
                        case 500:
                          const snackBar = SnackBar(
                            elevation: 0,
                            behavior: SnackBarBehavior.floating,
                            backgroundColor: Colors.transparent,
                            content: FlutterSnackbarContent(
                              message:
                                  "Something went wrong, please try again.",
                              contentType: ContentType.failure,
                            ),
                          );
                          ScaffoldMessenger.of(context)
                            ..hideCurrentSnackBar()
                            ..showSnackBar(snackBar);
                          break;
                        default:
                      }
                    }
                  } else {
                    setState(() {
                      _isLoading = false;
                    });
                    const snackBar = SnackBar(
                      elevation: 0,
                      behavior: SnackBarBehavior.floating,
                      backgroundColor: Colors.transparent,
                      content: FlutterSnackbarContent(
                        message:
                            'Either missing phone number or no plan selected',
                        contentType: ContentType.failure,
                      ),
                    );
                    ScaffoldMessenger.of(context)
                      ..hideCurrentSnackBar()
                      ..showSnackBar(snackBar);
                  }
                },
                child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Pay', style: TextStyle(color: Colors.black)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget buildPlanOption(
      String title, String description, String price, String plan) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(15),
        color: selectedPlan == plan ? Colors.amber : AppColors.lighter,
      ),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: ListTile(
          title: Text(
            title,
            style: TextStyle(
                color: selectedPlan == plan ? Colors.black : Colors.white),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                description,
                style: TextStyle(
                    color: selectedPlan == plan ? Colors.black : Colors.white),
              ),
              SizedBox(height: 8),
              Text(
                "Price: $price",
                style: TextStyle(
                    color: selectedPlan == plan ? Colors.black : Colors.white),
              ),
            ],
          ),
          tileColor:
              selectedPlan == plan ? AppColors.lighter : Colors.grey[800],
          onTap: () {
            setState(() {
              selectedPlan = plan;
              print(plan);
            });
          },
        ),
      ),
    );
  }
}
