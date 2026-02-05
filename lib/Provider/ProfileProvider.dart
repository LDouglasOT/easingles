import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:mazale/Models/Authmodel.dart';
import 'package:mazale/assets/urlconfig.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ProfileProvider extends ChangeNotifier {
  List<DjangoAuthUser> _profiles = [];
  bool _isLoading = false;
  bool _hasError = false;
  bool _isInitialized = false;
  int _viewedProfilesCount = 0;
  static const int FREE_PROFILE_LIMIT = 20;

  List<DjangoAuthUser> get profiles => _profiles;
  bool get isLoading => _isLoading;
  bool get hasError => _hasError;
  bool get isInitialized => _isInitialized;
  int get viewedProfilesCount => _viewedProfilesCount;
  bool get hasReachedFreeLimit => _viewedProfilesCount >= FREE_PROFILE_LIMIT;

  /// Fetches profiles only if not already loaded
  /// Returns true if profiles are available, false otherwise
  Future<bool> fetchProfilesIfNeeded() async {
    // If already initialized and has profiles, don't fetch again
    if (_isInitialized && _profiles.isNotEmpty) {
      return true;
    }

    return await _fetchProfiles();
  }

  /// Force fetch new profiles (used when all profiles are swiped)
  Future<bool> fetchNewProfiles() async {
    return await _fetchProfiles();
  }

  Future<bool> _fetchProfiles() async {
    _isLoading = true;
    _hasError = false;
    notifyListeners();

    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString("token");
      
      var response = await http.get(
        Uri.parse('${AppUrls.production}/api/users/'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonResponse = jsonDecode(response.body);

        if (jsonResponse.containsKey('results') && jsonResponse['results'] is List) {
          final List<dynamic> profilesList = jsonResponse['results'];
          _profiles = profilesList
              .map((profile) => DjangoAuthUser.fromJson(profile))
              .toList();
          _isInitialized = true;
          _isLoading = false;
          _hasError = false;
          notifyListeners();
          return true;
        }
      } else if (response.statusCode == 201) {
        // Server indicates subscription required
        _isLoading = false;
        _hasError = false;
        _isInitialized = true;
        notifyListeners();
        return false;
      }

      _isLoading = false;
      _hasError = true;
      notifyListeners();
      return false;
    } catch (e) {
      debugPrint('Error fetching profiles: $e');
      _isLoading = false;
      _hasError = true;
      notifyListeners();
      return false;
    }
  }

  /// Called when a profile is swiped (liked or noped)
  void onProfileSwiped() {
    _viewedProfilesCount++;
    notifyListeners();
  }

  /// Remove a profile from the list (after swiping)
  void removeProfile(DjangoAuthUser profile) {
    _profiles.remove(profile);
    notifyListeners();
  }

  /// Check if all profiles have been viewed
  bool get allProfilesViewed => _profiles.isEmpty && _isInitialized;

  /// Reset the viewed count (e.g., after subscription)
  void resetViewedCount() {
    _viewedProfilesCount = 0;
    notifyListeners();
  }

  /// Clear all data (e.g., on logout)
  void clear() {
    _profiles = [];
    _isLoading = false;
    _hasError = false;
    _isInitialized = false;
    _viewedProfilesCount = 0;
    notifyListeners();
  }
}
