import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mazale/assets/app.colors.dart';
import 'package:mazale/assets/urlconfig.dart';
import 'package:mazale/styles/app.text.dart';
import 'package:mazale/Models/Authmodel.dart';

class PeopleAroundMapPage extends StatefulWidget {
  const PeopleAroundMapPage({super.key});

  @override
  State<PeopleAroundMapPage> createState() => _PeopleAroundMapPageState();
}

class _PeopleAroundMapPageState extends State<PeopleAroundMapPage> {
  final MapController _mapController = MapController();
  LatLng? _currentLocation;
  List<NearbyPerson> _nearbyPeople = [];
  bool _isLoading = true;
  bool _isLoadingPeople = false;
  String? _error;
  double _radiusKm = 10.0;
  NearbyPerson? _selectedPerson;

  @override
  void initState() {
    super.initState();
    _initializeMap();
  }

  Future<void> _initializeMap() async {
    await _getCurrentLocation();
    if (_currentLocation != null) {
      await _fetchNearbyPeople();
    }
  }

  Future<void> _getCurrentLocation() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw Exception('Location services are disabled');
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw Exception('Location permissions are denied');
        }
      }

      if (permission == LocationPermission.deniedForever) {
        throw Exception('Location permissions are permanently denied');
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      setState(() {
        _currentLocation = LatLng(position.latitude, position.longitude);
        _isLoading = false;
      });

      _mapController.move(_currentLocation!, 13.0);
      
      // Update location on backend
      await _updateLocationOnBackend(position.latitude, position.longitude);
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
        // Default to Kampala if permission denied
        _currentLocation = LatLng(0.3476, 32.5825);
      });
    }
  }

  Future<void> _updateLocationOnBackend(double lat, double lon) async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString("token");

      await http.post(
        Uri.parse('${AppUrls.production}/api/update-location'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'latitude': lat,
          'longitude': lon,
        }),
      );
    } catch (e) {
      debugPrint('Failed to update location: $e');
    }
  }

  Future<void> _fetchNearbyPeople() async {
    if (_currentLocation == null) return;

    setState(() {
      _isLoadingPeople = true;
    });

    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString("token");

      final response = await http.post(
        Uri.parse('${AppUrls.production}/api/nearme/'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'latitude': _currentLocation!.latitude,
          'longitude': _currentLocation!.longitude,
          'radius': _radiusKm,
          'limit': 100,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        if (data['success'] == true) {
          List<NearbyPerson> people = [];
          
          for (var person in data['people']) {
            people.add(NearbyPerson.fromJson(person));
          }

          setState(() {
            _nearbyPeople = people;
            _isLoadingPeople = false;
          });
          
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Found ${people.length} people nearby'),
                backgroundColor: Colors.green,
                duration: const Duration(seconds: 2),
              ),
            );
          }
        } else {
          throw Exception(data['error'] ?? 'Failed to fetch nearby people');
        }
      } else {
        throw Exception('Server error: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error fetching nearby people: $e');
      setState(() {
        _isLoadingPeople = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load nearby people: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  void _onMarkerTap(NearbyPerson person) {
    setState(() {
      _selectedPerson = person;
    });
    _mapController.move(
      LatLng(person.latitude, person.longitude),
      15.0,
    );
  }

  String _calculateAge(String? year, String? month, String? day) {
    if (year == null || month == null || day == null) return '?';
    try {
      DateTime birthDate = DateTime(
        int.parse(year),
        int.parse(month),
        int.parse(day),
      );
      DateTime now = DateTime.now();
      int age = now.year - birthDate.year;
      if (now.month < birthDate.month ||
          (now.month == birthDate.month && now.day < birthDate.day)) {
        age--;
      }
      return age.toString();
    } catch (e) {
      return '?';
    }
  }

  Widget _buildPersonCard(NearbyPerson person) {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.lighter.withOpacity(0.95),
            AppColors.background.withOpacity(0.95),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Hero(
                  tag: 'person_${person.id}',
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: person.online ? Colors.green : Colors.amber,
                        width: 3,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: person.online
                              ? Colors.green.withOpacity(0.3)
                              : Colors.amber.withOpacity(0.3),
                          blurRadius: 10,
                        ),
                      ],
                    ),
                    child: Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(40),
                          child: Image.network(
                            person.profilePic ?? '',
                            width: 80,
                            height: 80,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                Container(
                              width: 80,
                              height: 80,
                              color: Colors.grey[800],
                              child: Icon(
                                person.gender == 'male'
                                    ? Icons.man
                                    : person.gender == 'female'
                                        ? Icons.woman
                                        : Icons.person,
                                size: 40,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                        if (person.online)
                          Positioned(
                            right: 0,
                            bottom: 0,
                            child: Container(
                              width: 20,
                              height: 20,
                              decoration: BoxDecoration(
                                color: Colors.green,
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white, width: 2),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              person.name,
                              style: AppText.subtitle1.copyWith(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (person.promoted)
                            Container(
                              margin: const EdgeInsets.only(left: 8),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [Colors.amber, Colors.orange],
                                ),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Text(
                                '⭐ VIP',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      if (person.age != null)
                        Text(
                          '${person.age} years old',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.7),
                            fontSize: 14,
                          ),
                        ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(
                            Icons.location_on,
                            size: 16,
                            color: Colors.amber,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${person.distance.toStringAsFixed(1)} km away',
                            style: const TextStyle(
                              color: Colors.amber,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (person.activityLevel != null) ...[
                            const SizedBox(width: 12),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: _getActivityColor(person.activityLevel!),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                person.activityLevel!.toUpperCase(),
                                style: const TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  onPressed: () {
                    setState(() {
                      _selectedPerson = null;
                    });
                  },
                ),
              ],
            ),
          ),
          if (person.bio.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text(
                person.bio,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.8),
                  fontSize: 14,
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          if (person.interests.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Wrap(
                spacing: 8,
                runSpacing: 4,
                children: person.interests.split(',').take(5).map((interest) {
                  return Chip(
                    label: Text(
                      interest.trim(),
                      style: const TextStyle(fontSize: 11),
                    ),
                    backgroundColor: Colors.amber.withOpacity(0.2),
                    padding: const EdgeInsets.all(4),
                  );
                }).toList(),
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pushNamed(
                        context,
                        '/userprofile',
                        arguments: person.id.toString(),
                      );
                    },
                    icon: const Icon(Icons.person),
                    label: const Text('View Profile'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.amber,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      // Navigate to messages
                      Navigator.pushNamed(
                        context,
                        '/chat',
                        arguments: person.id.toString(),
                      );
                    },
                    icon: const Icon(Icons.message),
                    label: const Text('Message'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
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

  Color _getActivityColor(String activityLevel) {
    switch (activityLevel.toLowerCase()) {
      case 'very_high':
        return Colors.green;
      case 'high':
        return Colors.lightGreen;
      case 'medium':
        return Colors.orange;
      case 'low':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'People Around',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: AppColors.lighter,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.my_location),
            onPressed: () async {
              await _getCurrentLocation();
              if (_currentLocation != null) {
                _mapController.move(_currentLocation!, 13.0);
                await _fetchNearbyPeople();
              }
            },
            tooltip: 'Center on my location',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchNearbyPeople,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: Stack(
        children: [
          if (_isLoading)
            Container(
              color: AppColors.background,
              child: const Center(
                child: CircularProgressIndicator(color: Colors.amber),
              ),
            )
          else if (_currentLocation != null)
            FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: _currentLocation!,
                initialZoom: 13.0,
                minZoom: 5.0,
                maxZoom: 18.0,
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.mazale.app',
                ),
                // Current location marker
                MarkerLayer(
                  markers: [
                    Marker(
                      point: _currentLocation!,
                      width: 60,
                      height: 60,
                      child: Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.blue.withOpacity(0.3),
                          border: Border.all(color: Colors.blue, width: 3),
                        ),
                        child: const Icon(
                          Icons.person_pin_circle,
                          color: Colors.blue,
                          size: 30,
                        ),
                      ),
                    ),
                  ],
                ),
                // Nearby people markers
                MarkerLayer(
                  markers: _nearbyPeople.map((person) {
                    bool isSelected = _selectedPerson?.id == person.id;
                    return Marker(
                      point: LatLng(person.latitude, person.longitude),
                      width: isSelected ? 100 : 80,
                      height: isSelected ? 100 : 80,
                      child: GestureDetector(
                        onTap: () => _onMarkerTap(person),
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            Container(
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: person.online
                                    ? Colors.green.withOpacity(0.3)
                                    : Colors.amber.withOpacity(0.3),
                                border: Border.all(
                                  color: isSelected
                                      ? (person.online ? Colors.green : Colors.amber)
                                      : (person.online
                                              ? Colors.green
                                              : Colors.amber)
                                          .withOpacity(0.5),
                                  width: isSelected ? 4 : 2,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: (person.online
                                            ? Colors.green
                                            : Colors.amber)
                                        .withOpacity(0.5),
                                    blurRadius: isSelected ? 15 : 10,
                                  ),
                                ],
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(40),
                                child: Image.network(
                                  person.profilePic ?? '',
                                  width: isSelected ? 90 : 70,
                                  height: isSelected ? 90 : 70,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) =>
                                      Container(
                                    width: isSelected ? 90 : 70,
                                    height: isSelected ? 90 : 70,
                                    color: Colors.grey[800],
                                    child: Icon(
                                      person.gender == 'male'
                                          ? Icons.man
                                          : person.gender == 'female'
                                              ? Icons.woman
                                              : Icons.person,
                                      size: isSelected ? 45 : 35,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            if (isSelected)
                              Positioned(
                                bottom: 0,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: person.online ? Colors.green : Colors.amber,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(
                                    person.name.split(' ')[0],
                                    style: const TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
                // Radius circle
                CircleLayer(
                  circles: [
                    CircleMarker(
                      point: _currentLocation!,
                      radius: _radiusKm * 1000,
                      useRadiusInMeter: true,
                      color: Colors.blue.withOpacity(0.1),
                      borderColor: Colors.blue.withOpacity(0.3),
                      borderStrokeWidth: 2,
                    ),
                  ],
                ),
              ],
            ),
          // Selected person card
          if (_selectedPerson != null)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: _buildPersonCard(_selectedPerson!),
            ),
          // Radius slider
          Positioned(
            top: 16,
            left: 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(15),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 10,
                  ),
                ],
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      const Icon(Icons.radar, color: Colors.amber),
                      const SizedBox(width: 8),
                      Text(
                        'Search Radius: ${_radiusKm.toStringAsFixed(1)} km',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Colors.amber, Colors.orange],
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${_nearbyPeople.length} 👥',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  Slider(
                    value: _radiusKm,
                    min: 1.0,
                    max: 100.0,
                    divisions: 99,
                    activeColor: Colors.amber,
                    onChanged: (value) {
                      setState(() {
                        _radiusKm = value;
                      });
                    },
                    onChangeEnd: (value) {
                      _fetchNearbyPeople();
                    },
                  ),
                ],
              ),
            ),
          ),
          // Loading indicator for people
          if (_isLoadingPeople)
            Positioned(
              top: 100,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(15),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 10,
                      ),
                    ],
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(
                        color: Colors.amber,
                        strokeWidth: 2,
                      ),
                      SizedBox(width: 16),
                      Text('Finding people nearby...'),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class NearbyPerson {
  final int id;
  final String name;
  final int? age;
  final String? profilePic;
  final double latitude;
  final double longitude;
  final double distance;
  final String bio;
  final String interests;
  final String? gender;
  final bool online;
  final bool promoted;
  final double engagementScore;
  final String? activityLevel;

  NearbyPerson({
    required this.id,
    required this.name,
    this.age,
    this.profilePic,
    required this.latitude,
    required this.longitude,
    required this.distance,
    required this.bio,
    required this.interests,
    this.gender,
    required this.online,
    required this.promoted,
    required this.engagementScore,
    this.activityLevel,
  });

  factory NearbyPerson.fromJson(Map<String, dynamic> json) {
    return NearbyPerson(
      id: json['id'],
      name: json['name'] ?? 'User',
      age: json['age'],
      profilePic: json['profile_pic'],
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      distance: (json['distance'] as num).toDouble(),
      bio: json['bio'] ?? '',
      interests: json['interests'] ?? '',
      gender: json['gender'],
      online: json['online'] ?? false,
      promoted: json['promoted'] ?? false,
      engagementScore: (json['engagement_score'] ?? 0.0).toDouble(),
      activityLevel: json['activity_level'],
    );
  }
}