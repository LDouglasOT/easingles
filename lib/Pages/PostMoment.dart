import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:mazale/assets/app.colors.dart';
import 'package:mazale/assets/urlconfig.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Toolbar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final Color background;
  final List<Widget>? actions;
  final Widget? leading;
  const Toolbar({
    required this.title,
    required this.background,
    this.actions,
    this.leading,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.bold,
          color: AppColors.primary,
        ),
      ),
      backgroundColor: AppColors.background,
      elevation: 0,
      leading: leading,
      actions: actions,
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

class PostMoment extends StatefulWidget {
  const PostMoment({super.key});

  @override
  State<PostMoment> createState() => _PostMomentState();
}

class _PostMomentState extends State<PostMoment> {
  final List<File> _selectedImages = [];
  final TextEditingController momentController = TextEditingController();
  bool isUploading = false;
  final ImagePicker _picker = ImagePicker();

  @override
  void dispose() {
    momentController.dispose();
    super.dispose();
  }

void postMoment() async {
    if (_selectedImages.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least one image')),
      );
      return;
    }

    try {
      setState(() {
        isUploading = true;
      });

      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('token');

      // 1. Initialize Multipart Request
      // Borrowing from your backend's parser_classes([MultiPartParser, FormParser])
      var request = http.MultipartRequest(
        'POST',
        Uri.parse("${AppUrls.production}/api/moments/"),
      );

      // 2. Add Authorization Header
      request.headers.addAll({
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      });

      // 3. Add Text Fields
      // Based on your backend 'data = request.data.copy()', it expects 'tagline'
      request.fields['tagline'] = momentController.text.trim();

      // 4. Add Image Files
      // Borrowing the logic from your photo_key loop (photo_1, photo_2...)
      // NOTE: If your MomentSerializer expects a list, use the key 'images' for all.
      // If it works like your upload_photos function, use 'image_1', 'image_2' etc.
      for (int i = 0; i < _selectedImages.length; i++) {
        File imageFile = _selectedImages[i];
        
        request.files.add(
          await http.MultipartFile.fromPath(
            'images', // Change to 'photo_${i + 1}' if it matches upload_photos logic
            imageFile.path,
            filename: imageFile.path.split('/').last,
          ),
        );
      }

      // 5. Send Request
      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200 || response.statusCode == 201) {
        if (mounted) {
          setState(() {
            isUploading = false;
          });
          // Show success and go back
          Navigator.of(context).pop();
        }
      } else {
        // Handle Validation errors from Serializer (status 400)
        final errorData = jsonDecode(response.body);
        throw Exception(errorData.toString());
      }
    } catch (err) {
      debugPrint('Error: $err');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Upload failed: $err')),
        );
        setState(() {
          isUploading = false;
        });
      }
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
        _selectedImages.addAll(images.map((image) => File(image.path)));
      });
    }
  }

  // UI Helper methods remain largely the same, but simplified for the new list type
  Widget _buildImagePickerArea() {
    return GestureDetector(
      onTap: _pickImage,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
        width: double.infinity,
        height: _selectedImages.isEmpty ? 200 : 300,
        decoration: BoxDecoration(
          color: AppColors.lighter.withOpacity(_selectedImages.isEmpty ? 1 : 0.8),
          borderRadius: BorderRadius.circular(20),
          border: _selectedImages.isEmpty
              ? Border.all(color: AppColors.primary, width: 2.5)
              : null,
        ),
        child: _selectedImages.isEmpty
            ? const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.add_a_photo_outlined, color: AppColors.primary, size: 60),
                    SizedBox(height: 12),
                    Text('Tap to add your moment\'s photo!',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                  ],
                ),
              )
            : Stack(
                fit: StackFit.expand,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: Image.file(_selectedImages[0], fit: BoxFit.cover),
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
                              color: AppColors.background.withOpacity(0.7),
                              borderRadius: BorderRadius.circular(15),
                            ),
                            child: Text('+${_selectedImages.length - 1} more',
                                style: const TextStyle(fontWeight: FontWeight.bold)),
                          ),
                        const SizedBox(width: 10),
                        CircleAvatar(
                          backgroundColor: AppColors.lighter.withOpacity(0.9),
                          child: IconButton(
                            icon: const Icon(Icons.refresh, color: AppColors.primary),
                            onPressed: _pickImage,
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
        color: AppColors.lighter.withOpacity(0.8),
        borderRadius: BorderRadius.circular(15),
      ),
      child: TextField(
        controller: momentController,
        maxLines: 6,
        minLines: 3,
        decoration: const InputDecoration(
          hintText: 'Share your story...',
          border: InputBorder.none,
          contentPadding: EdgeInsets.all(10),
        ),
      ),
    );
  }

  Widget _buildPostButton() {
    return ElevatedButton(
      onPressed: isUploading ? null : postMoment,
      style: ElevatedButton.styleFrom(
        minimumSize: const Size(double.infinity, 60),
        backgroundColor: AppColors.primary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      ),
      child: isUploading
          ? const CircularProgressIndicator(color: Colors.black)
          : const Text("Post Moment", 
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: Toolbar(
        title: "Create New Moment",
        background: AppColors.background,
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.arrow_back_ios, color: AppColors.fontColor),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            _buildImagePickerArea(),
            const SizedBox(height: 25),
            _buildCaptionInputField(),
            const SizedBox(height: 35),
            _buildPostButton(),
          ],
        ),
      ),
    );
  }
}