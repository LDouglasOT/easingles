import 'dart:async';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'package:mazale/assets/urlconfig.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PhotoUploadPage extends StatefulWidget {
  final String googleId;
  
  const PhotoUploadPage({Key? key, required this.googleId}) : super(key: key);

  @override
  State<PhotoUploadPage> createState() => _PhotoUploadPageState();
}

class _PhotoUploadPageState extends State<PhotoUploadPage> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  
  String? _selectedGender;
  DateTime? _selectedBirthday;
  final List<File?> _photos = [null, null, null, null];
  final List<bool> _faceDetected = [false, false, false, false];
  bool _isLoading = false;
  
  // Interests selection
  final List<String> _availableInterests = [
    'Travel',
    'Music',
    'Sports',
    'Reading',
    'Cooking',
    'Movies',
    'Art',
    'Dancing',
    'Gaming',
    'Photography',
    'Fitness',
    'Yoga',
    'Hiking',
    'Swimming',
    'Cycling',
    'Fashion',
    'Technology',
    'Food',
    'Coffee',
    'Wine',
    'Pets',
    'Nature',
    'Camping',
    'Beach',
    'Shopping',
    'Writing',
    'Meditation',
    'Netflix',
    'Concerts',
    'Theater',
  ];
  
  final List<String> _selectedInterests = [];
  
  final ImagePicker _picker = ImagePicker();
  late FaceDetector _faceDetector;
  late Position? _currentPosition;

  @override
  void initState() {
    super.initState();
    _faceDetector = FaceDetector(
      options: FaceDetectorOptions(
        enableContours: true,
        enableClassification: true,
      ),
    );

  }

  Future<Position?> getCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      print('Location services are disabled.');
      return null;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        print('Location permissions are denied');
        return null;
      }
    }
    
    if (permission == LocationPermission.deniedForever) {
      print('Location permissions are permanently denied.');
      return null;
    }

    return await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high
    );
    
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _faceDetector.close();
    super.dispose();
  }

  Future<void> _pickImage(int index) async {
    final XFile? image = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1920,
      maxHeight: 1080,
      imageQuality: 85,
    );

    if (image != null) {
      setState(() => _isLoading = true);
      
      final inputImage = InputImage.fromFilePath(image.path);
      final faces = await _faceDetector.processImage(inputImage);
      
      setState(() {
        _photos[index] = File(image.path);
        _faceDetected[index] = faces.isNotEmpty;
        _isLoading = false;
      });

      if (faces.isEmpty) {
        _showSnackBar('No face detected in this photo. Please upload a clear photo with your face.', isError: true);
      }
    }
  }

  Future<void> _submitData() async {
    if (!_formKey.currentState!.validate()) return;

    if (_photos.every((photo) => photo == null)) {
      _showSnackBar('Please upload at least one photo', isError: true);
      return;
    }

    if (_selectedGender == null) {
      _showSnackBar('Please select your gender', isError: true);
      return;
    }

    if (_selectedBirthday == null) {
      _showSnackBar('Please select your birthday', isError: true);
      return;
    }

    if (_selectedInterests.isEmpty) {
      _showSnackBar('Please select at least one interest', isError: true);
      return;
    }
    setState(() => _isLoading = true);
    Position? position = await getCurrentLocation();
    
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('token');
    String? refreshToken = prefs.getString('refresh_token');
    
    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('${AppUrls.production}/api/upload-photos/'),
      );

      request.fields['google_id'] = widget.googleId;
      request.fields['phone_number'] = _phoneController.text;
      request.fields['gender'] = _selectedGender!;
      request.fields['birthday'] = _selectedBirthday!.toIso8601String().split('T')[0];
      request.fields['latitude'] = position?.latitude.toString() ?? '';
      request.fields['longitude'] = position?.longitude.toString() ?? '';
      
      // Send interests as comma-separated string
      request.fields['interests'] = _selectedInterests.join(',');
      request.headers['Authorization'] = 'Bearer $token';
      request.headers['Refresh-Token'] = refreshToken!;
      
      for (int i = 0; i < _photos.length; i++) {
        if (_photos[i] != null) {
          request.files.add(
            await http.MultipartFile.fromPath(
              'photo_${i + 1}',
              _photos[i]!.path,
            ),
          );
        }
      }

      final response = await request.send();
      final responseData = await response.stream.bytesToString();
      if(response.statusCode ==400){
        final error = json.decode(responseData);
        _showSnackBar(error['error'] ?? 'Failed to upload photos, fix some errors and try again', isError: true);
        return;
      }

      if(response.statusCode ==401){
        _showSnackBar('Session expired. Please log in again.', isError: true);
        Timer(Duration(seconds: 2), () {
          Navigator.of(context).pushReplacementNamed('/login');
        });
        return;
      }



      if (response.statusCode == 200 || response.statusCode == 201) {
        _showSnackBar('Profile updated successfully!');
        Timer(Duration(seconds: 2), () {
          Navigator.of(context).pushReplacementNamed('/main');
        });
      } else {
        final error = json.decode(responseData);
        _showSnackBar(error['error'] ?? 'Failed to upload photos, fix some errors and try again', isError: true);
      }
    } catch (e) {
      _showSnackBar('Error: ${e.toString()}', isError: true);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
      ),
    );
  }

  Future<void> _selectBirthday() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime(2000, 1, 1),
      firstDate: DateTime(1924, 1, 1),
      lastDate: DateTime.now().subtract(const Duration(days: 6570)),
      helpText: 'Select your birthday',
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Theme.of(context).primaryColor,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() => _selectedBirthday = picked);
    }
  }

  String _formatDate(DateTime date) {
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 
                    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Complete Your Profile'),
        elevation: 0,
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Add Your Photos',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Upload at least one clear photo with your face visible',
                    style: TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 24),
                  
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                    ),
                    itemCount: 4,
                    itemBuilder: (context, index) => _buildPhotoCard(index),
                  ),
                  
                  const SizedBox(height: 32),
                  
                  DropdownButtonFormField<String>(
                    value: _selectedGender,
                    decoration: const InputDecoration(
                      labelText: 'Gender',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.person),
                    ),
                    items: ['Male', 'Female', 'Other'].map((gender) {
                      return DropdownMenuItem(value: gender, child: Text(gender));
                    }).toList(),
                    onChanged: (value) => setState(() => _selectedGender = value),
                    validator: (value) => value == null ? 'Please select gender' : null,
                  ),
                  
                  const SizedBox(height: 16),
                  
                  GestureDetector(
                    onTap: _selectBirthday,
                    child: AbsorbPointer(
                      child: TextFormField(
                        decoration: InputDecoration(
                          labelText: 'Birthday',
                          border: const OutlineInputBorder(),
                          prefixIcon: const Icon(Icons.cake),
                          hintText: 'Select your birthday',
                          suffixIcon: const Icon(Icons.calendar_today),
                        ),
                        controller: TextEditingController(
                          text: _selectedBirthday != null 
                              ? _formatDate(_selectedBirthday!) 
                              : '',
                        ),
                        validator: (value) {
                          if (_selectedBirthday == null) {
                            return 'Please select your birthday';
                          }
                          final age = DateTime.now().difference(_selectedBirthday!).inDays ~/ 365;
                          if (age < 18) {
                            return 'You must be at least 18 years old';
                          }
                          return null;
                        },
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  TextFormField(
                    controller: _phoneController,
                    decoration: const InputDecoration(
                      labelText: 'Phone/WhatsApp Number',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.phone),
                      hintText: '+256 700 000 000',
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your phone number';
                      }
                      if (value.length < 10) {
                        return 'Please enter a valid phone number';
                      }
                      return null;
                    },
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Interests Section
                  const Text(
                    'Your Interests',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Select at least one interest (${_selectedInterests.length} selected)',
                    style: const TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 16),
                  
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _availableInterests.map((interest) {
                      final isSelected = _selectedInterests.contains(interest);
                      return FilterChip(
                        label: Text(interest),
                        selected: isSelected,
                        onSelected: (selected) {
                          setState(() {
                            if (selected) {
                              _selectedInterests.add(interest);
                            } else {
                              _selectedInterests.remove(interest);
                            }
                          });
                        },
                        selectedColor: Theme.of(context).primaryColor.withOpacity(0.3),
                        checkmarkColor: Theme.of(context).primaryColor,
                      );
                    }).toList(),
                  ),
                  
                  const SizedBox(height: 32),
                  
                  ElevatedButton(
                    onPressed: _isLoading ? null : _submitData,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      'Continue Signup',
                      style: TextStyle(fontSize: 18),
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          if (_isLoading)
            Container(
              color: Colors.black54,
              child: const Center(
                child: CircularProgressIndicator(),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPhotoCard(int index) {
    return GestureDetector(
      onTap: () => _pickImage(index),
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(
            color: _faceDetected[index] ? Colors.green : Colors.grey.shade300,
            width: 2,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: _photos[index] != null
            ? Stack(
                fit: StackFit.expand,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.file(_photos[index]!, fit: BoxFit.cover),
                  ),
                  if (_faceDetected[index])
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Colors.green,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.check, color: Colors.white, size: 16),
                      ),
                    ),
                  Positioned(
                    bottom: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Icon(Icons.edit, color: Colors.white, size: 16),
                    ),
                  ),
                ],
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.add_photo_alternate, size: 48, color: Colors.grey.shade400),
                  const SizedBox(height: 8),
                  Text(
                    'Photo ${index + 1}',
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                ],
              ),
      ),
    );
  }
}