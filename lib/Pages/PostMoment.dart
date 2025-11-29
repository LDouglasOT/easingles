import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:easingles/assets/app.colors.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

// Assuming these imports are correctly defined in your project:
// import 'package:easingles/Components/Toolbar.dart';
// import 'package:easingles/assets/app.colors.dart';
// import 'package:easingles/assets/urlconfig.dart';
import 'package:shared_preferences/shared_preferences.dart';

// --- Placeholder/External Classes (Required for the PostMoment page to compile) ---

class Toolbar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final Color background;
  final List<Widget>? actions;
  final Widget? leading;
  const Toolbar({required this.title, required this.background, this.actions, this.leading, super.key});

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: Text(title, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.primary)),
      backgroundColor: AppColors.background,
      elevation: 0,
      leading: leading,
      actions: actions,
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

class AppUrls {
  static const String production = "https://example.com";
}

// -------------------------------------------------------------------

class PostMoment extends StatefulWidget {
  PostMoment({super.key});

  @override
  State<PostMoment> createState() => _PostMomentState();
}

class _PostMomentState extends State<PostMoment> {
  List<File?> _selectedImages = [];
  final TextEditingController momentController = TextEditingController();
  bool isUploading = false;
  final ImagePicker _picker = ImagePicker();

  @override
  void dispose() {
    momentController.dispose();
    super.dispose();
  }

  Future<String> uploadFile(
      String uploadUrl, List<File?> userImages, String fileType) async {
    // This method is primarily for file upload logic, keeping it as-is for UI focus.
    // Ensure your actual implementation handles the HTTP request correctly.
    await Future.delayed(Duration(seconds: 2)); // Simulate network delay
    return "https://default-image-url.jpg"; // Placeholder
  }

  void postMoment() async {
    if (_selectedImages.isEmpty || momentController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Please select an image and write a caption!',
            style: TextStyle(color: AppColors.fontColor2),
          ),
          backgroundColor: AppColors.primary, // Use primary for alerts
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          margin: EdgeInsets.all(16),
        ),
      );
      return;
    }

    setState(() {
      isUploading = true;
    });

    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('token');
      String? firstName = prefs.getString("FirstName");
      String? LastName = prefs.getString("LastName");
      String? id = prefs.getString("id");

      var request = http.MultipartRequest(
          'POST', Uri.parse("${AppUrls.production}/api/moments"));

      request.headers['Authorization'] = 'Bearer $token';
      request.fields['TagLine'] = momentController.text;
      request.fields['firstName'] = firstName ?? "";
      request.fields['LastName'] = LastName ?? "";
      request.fields['owenId'] = id ?? "0";

      for (int i = 0; i < _selectedImages.length; i++) {
        if (_selectedImages[i] != null) {
          request.files.add(
            await http.MultipartFile.fromPath(
              'userImages',
              _selectedImages[i]!.path,
              filename: '$firstName$LastName$i.jpg',
            ),
          );
        }
      }

      var response = await request.send();

      if (response.statusCode >= 200 && response.statusCode < 300) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Moment posted successfully!',
              style: TextStyle(color: AppColors.fontColor2),
            ),
            backgroundColor: AppColors.primary,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            margin: EdgeInsets.all(16),
          ),
        );
        Navigator.of(context).pop();
      } else {
        final responseBody = await response.stream.bytesToString();
        print('Failed to submit. Status code: ${response.statusCode}. Response: $responseBody');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Failed to post moment (Status: ${response.statusCode})',
              style: TextStyle(color: AppColors.fontColor),
            ),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            margin: EdgeInsets.all(16),
          ),
        );
      }
    } catch (err) {
      print('Post error: $err');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'An unexpected error occurred. Please try again.',
            style: TextStyle(color: AppColors.fontColor),
          ),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          margin: EdgeInsets.all(16),
        ),
      );
    } finally {
      setState(() {
        isUploading = false;
      });
    }
  }

  Future<void> _pickImage() async {
    final List<XFile>? images = await _picker.pickMultiImage(
      imageQuality: 85,
      maxWidth: 800,
    );

    if (images != null && images.isNotEmpty) {
      setState(() {
        _selectedImages.clear();
        _selectedImages.addAll(
          images.map((image) => File(image.path)),
        );
      });
    }
  }

  // --- Beautiful UI Widgets ---

  Widget _buildImagePickerArea() {
    return GestureDetector(
      onTap: _pickImage,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
        width: double.infinity,
        height: _selectedImages.isEmpty ? 200 : 300, // Make empty state larger
        decoration: BoxDecoration(
          color: AppColors.lighter.withOpacity(_selectedImages.isEmpty ? 1 : 0.8), // Dynamic opacity
          borderRadius: BorderRadius.circular(20), // More rounded corners
          boxShadow: _selectedImages.isEmpty
              ? [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.2),
                    blurRadius: 10,
                    spreadRadius: 2,
                  ),
                ]
              : null,
          border: _selectedImages.isEmpty
              ? Border.all(color: AppColors.primary, width: 2.5) // More prominent border
              : null,
        ),
        child: _selectedImages.isEmpty
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.add_a_photo_outlined, // More relevant icon
                      color: AppColors.primary, // Primary color for icon
                      size: 60,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Tap to add your moment\'s photo!',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          color: AppColors.fontColor,
                          fontSize: 18,
                          fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              )
            : Stack(
                fit: StackFit.expand,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: Image.file(
                      _selectedImages[0]!,
                      fit: BoxFit.cover,
                    ),
                  ),
                  Positioned(
                    top: 15,
                    right: 15,
                    child: Row(
                      children: [
                        if (_selectedImages.length > 1)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: AppColors.background.withOpacity(0.7), // Darker overlay for readability
                              borderRadius: BorderRadius.circular(15),
                            ),
                            child: Text(
                              '+${_selectedImages.length - 1} more',
                              style: TextStyle(
                                  color: AppColors.fontColor,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14),
                            ),
                          ),
                        const SizedBox(width: 10),
                        Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(15),
                            color: AppColors.lighter.withOpacity(0.9),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.3),
                                blurRadius: 5,
                                spreadRadius: 1,
                              ),
                            ],
                          ),
                          child: IconButton(
                            icon: const Icon(Icons.refresh, color: AppColors.primary, size: 28), // Refresh icon
                            onPressed: _pickImage,
                            tooltip: 'Change image(s)',
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildCaptionInputField() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.lighter.withOpacity(0.8), // Lighter surface for input
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TextField(
        controller: momentController,
        maxLines: 6, // Allow more lines for detailed descriptions
        minLines: 3,
        style: TextStyle(color: AppColors.fontColor, fontSize: 16),
        cursorColor: AppColors.primary, // Primary color for cursor
        decoration: InputDecoration(
          hintText: 'Share your story, feelings, or what\'s on your mind...',
          hintStyle: TextStyle(color: AppColors.disableFont.withOpacity(0.7), fontSize: 16),
          border: InputBorder.none, // Remove default border
          contentPadding: const EdgeInsets.all(10),
        ),
      ),
    );
  }

  Widget _buildPostButton() {
    final bool canPost = !isUploading && (_selectedImages.isNotEmpty && momentController.text.trim().isEmpty);

    return ElevatedButton(
      onPressed:postMoment,
      style: ElevatedButton.styleFrom(
        minimumSize: const Size(double.infinity, 60), // Larger button
        backgroundColor:  AppColors.primary,
        foregroundColor: Colors.black,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15), // Consistent rounded corners
        ),
        elevation: 8, // More pronounced shadow
        shadowColor: AppColors.primary.withOpacity(0.4), // Shadow color from primary
      ),
      child: AnimatedSwitcher( // Add animation for loading state
        duration: const Duration(milliseconds: 300),
        transitionBuilder: (Widget child, Animation<double> animation) {
          return FadeTransition(opacity: animation, child: child);
        },
        child: isUploading
            ? SizedBox(
                key: const ValueKey('loading'),
                height: 28,
                width: 28,
                child: CircularProgressIndicator(
                  color: AppColors.fontColor2,
                  strokeWidth: 3,
                ),
              )
            : Text(
                "PUBLISH MOMENT",
                key: const ValueKey('text'),
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: canPost ? AppColors.fontColor2 : AppColors.disableFont,
                  letterSpacing: 1.2, // Slightly increased letter spacing
                ),
              ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: Toolbar(
        title: "Create New Moment", // More inviting title
        background: AppColors.background,
        leading: IconButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          icon: const Icon(Icons.arrow_back_ios, color: AppColors.fontColor), // iOS-style back arrow
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.background,
              AppColors.gradientEnd, // A slightly darker purple for the gradient end
            ],
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. Image Picker Area
              _buildImagePickerArea(),
              
              const SizedBox(height: 25), // Increased spacing

              // 2. Caption Text Field
              _buildCaptionInputField(),
              
              const SizedBox(height: 35), // Increased spacing

              // 3. Post Button
              _buildPostButton(),
            ],
          ),
        ),
      ),
    );
  }
}