import 'package:flutter/material.dart';
import 'package:mazale/Components/ModernButton.dart';

class NameInputStep extends StatelessWidget {
  final TextEditingController firstNameController;
  final TextEditingController lastNameController;
  final bool isLoading;
  final VoidCallback onContinue;

  const NameInputStep({
    Key? key,
    required this.firstNameController,
    required this.lastNameController,
    required this.onContinue,
    this.isLoading = false,
  }) : super(key: key);

  // Colors aligned with your brand
  static const Color _accentGreen = Color(0xFF388E3C);
  static const Color _deepBrown = Color(0xFF4B3A21);

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),
            
            // Info Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _accentGreen.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: _accentGreen.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.person, color: _accentGreen, size: 28),
                  const SizedBox(width: 12),
                  const Expanded(
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
            
            const SizedBox(height: 32),

            // First Name Field
            _buildNameField(
              controller: firstNameController,
              label: "First Name",
            ),

            const SizedBox(height: 20),

            // Last Name Field
            _buildNameField(
              controller: lastNameController,
              label: "Last Name",
            ),

            const SizedBox(height: 32),

            // Continue Button (Using the ModernButton class we created earlier)
            ModernButton(
              text: 'Continue',
              isLoading: isLoading,
              backgroundColor: _accentGreen,
              onTap: onContinue,
            ),
          ],
        ),
      ),
    );
  }

  // Reusable TextField helper for this page
  Widget _buildNameField({
    required TextEditingController controller,
    required String label,
  }) {
    return TextFormField(
      controller: controller,
      style: const TextStyle(fontSize: 16, color: _deepBrown),
      textCapitalization: TextCapitalization.words,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: const Icon(Icons.person_outline, color: _accentGreen),
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
          borderSide: const BorderSide(color: _accentGreen, width: 2),
        ),
        labelStyle: TextStyle(color: _deepBrown.withOpacity(0.7)),
      ),
    );
  }
}