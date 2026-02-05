import 'dart:convert';

class DjangoAuthUser {
  final String? id;
  final String? phoneNumber;
  final String? email;
  final String? googleId;
  final String? token;
  final String? refreshToken;
  final String? supabaseId;
  final String? supabaseEmail;

  final String? firstName;
  final String? lastName;
  final String? day;
  final String? month;
  final String? year;
  final String? latitude;
  final String? longitude;
  final String? profilePic;
  final String? gender;
  final String? about;
  final String? hopes;
  final String? religion;

  final String? contact;
  final String? twitter;
  final String? instagram;
  final String? facebook;
  final String? whatsapp;
  final String? referalCode;
  final String? promoterUrl;

  final bool online;
  final bool promoted;
  final bool modified;
  final int modify;
  final int totalShows;

  final dynamic userImages;
  final dynamic userInterests;
  final String? deviceId;

  final double engagementScore;
  final double recommendationBoost;
  final String? activityLevel;

  DjangoAuthUser({
    this.id,
    this.phoneNumber,
    this.email,
    this.googleId,
    this.token,
    this.refreshToken,
    this.supabaseId,
    this.supabaseEmail,
    this.firstName,
    this.lastName,
    this.day,
    this.month,
    this.year,
    this.latitude,
    this.longitude,
    this.profilePic,
    this.gender,
    this.about,
    this.hopes,
    this.religion,
    this.contact,
    this.twitter,
    this.instagram,
    this.facebook,
    this.whatsapp,
    this.referalCode,
    this.promoterUrl,
    this.online = false,
    this.promoted = false,
    this.modified = false,
    this.modify = 0,
    this.totalShows = 0,
    this.userImages,
    this.userInterests,
    this.deviceId,
    this.engagementScore = 0.0,
    this.recommendationBoost = 1.0,
    this.activityLevel,
  });

  factory DjangoAuthUser.fromJson(Map<String, dynamic> json) {
    return DjangoAuthUser(
      id: json['id']?.toString(),
      phoneNumber: json['phone_number'],
      email: json['email'],
      googleId: json['google_id'],
      token: json['token'],
      refreshToken: json['refresh_token'],
      supabaseId: json['supabase_id'],
      supabaseEmail: json['supabase_email'],
      
      firstName: json['first_name'],
      lastName: json['last_name'],
      day: json['day'],
      month: json['month'],
      year: json['year'],
      latitude: json['latitude'],
      longitude: json['longitude'],
      profilePic: json['profile_pic'],
      gender: json['gender'],
      about: json['about'],
      hopes: json['hopes'],
      religion: json['religion'],
      
      contact: json['contact'],
      twitter: json['twitter'],
      instagram: json['instagram'],
      facebook: json['facebook'],
      whatsapp: json['whatsapp'],
      referalCode: json['referal_code'],
      promoterUrl: json['promoter_url'],
      
      online: json['online'] ?? false,
      promoted: json['promoted'] ?? false,
      modified: json['modified'] ?? false,
      modify: json['modify'] ?? 0,
      totalShows: json['total_shows'] ?? 0,
      
      userImages: json['user_images'],
      userInterests: json['user_interests'],
      deviceId: json['device_id'],
      
      engagementScore: (json['engagement_score'] ?? 0.0).toDouble(),
      recommendationBoost: (json['recommendation_boost'] ?? 1.0).toDouble(),
      activityLevel: json['activity_level'],
    );
  }
}