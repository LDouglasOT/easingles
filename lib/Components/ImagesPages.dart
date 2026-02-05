import 'package:flutter/material.dart';
import 'dart:io';

import 'package:mazale/Components/ModernButton.dart';

class ImageUploadPage extends StatelessWidget {
  // Pass these in from the parent
  final List<File?> selectedImages;
  final VoidCallback onPickImages;
  final VoidCallback onClearImages;
  final Function(int) onRemoveImage;
  final VoidCallback onComplete;
  final bool isLoading;

  const ImageUploadPage({
    Key? key,
    required this.selectedImages,
    required this.onPickImages,
    required this.onClearImages,
    required this.onRemoveImage,
    required this.onComplete,
    this.isLoading = false,
  }) : super(key: key);

  // Theme Colors
  static const Color _richRed = Color(0xFFD32F2F);
  static const Color _deepBrown = Color(0xFF4B3A21);
  static const Color _accentGreen = Color(0xFF388E3C);

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),
            
            // 1. Header Section
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _richRed.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: _richRed.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.photo_camera, color: _richRed, size: 28),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Add your photos',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: _deepBrown),
                        ),
                        Text(
                          '${selectedImages.length}/4 selected',
                          style: TextStyle(fontSize: 14, color: _deepBrown.withOpacity(0.6)),
                        ),
                      ],
                    ),
                  ),
                  if (selectedImages.isNotEmpty)
                    TextButton(
                      onPressed: onClearImages,
                      child: const Text('Clear', style: TextStyle(color: _richRed, fontWeight: FontWeight.w600)),
                    ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // 2. Upload Box
            GestureDetector(
              onTap: onPickImages,
              child: Container(
                height: 160,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: _richRed.withOpacity(0.3), width: 2),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(color: _richRed.withOpacity(0.1), shape: BoxShape.circle),
                      child: const Icon(Icons.add_photo_alternate, color: _richRed, size: 48),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      selectedImages.isEmpty ? "Tap to select photos" : "Tap to add more photos",
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: _deepBrown),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // 3. Grid of Images
            if (selectedImages.isNotEmpty)
              GridView.builder(
                physics: const NeverScrollableScrollPhysics(),
                shrinkWrap: true,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                ),
                itemCount: selectedImages.length,
                itemBuilder: (context, index) {
                  return Stack(
                    children: [
                      Positioned.fill(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: Image.file(selectedImages[index]!, fit: BoxFit.cover),
                        ),
                      ),
                      Positioned(
                        top: 8,
                        right: 8,
                        child: GestureDetector(
                          onTap: () => onRemoveImage(index),
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(color: Colors.black.withOpacity(0.6), shape: BoxShape.circle),
                            child: const Icon(Icons.close, color: Colors.white, size: 18),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),

            const SizedBox(height: 32),

            // 4. Submit Button
            ModernButton(
              text: 'Complete Registration',
              isLoading: isLoading,
              backgroundColor: _accentGreen,
              onTap: onComplete,
            ),
          ],
        ),
      ),
    );
  }
}