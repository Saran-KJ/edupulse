import 'dart:io';
import 'package:flutter/foundation.dart';

class AppConfig {
  static String get baseUrl {
    if (kIsWeb) return 'http://localhost:8000';
    if (Platform.isAndroid) return 'http://localhost:8000';
    return 'http://localhost:8000';
  }
  static const String apiVersion = '/api';
  
  // Endpoints
  static const String loginEndpoint = '$apiVersion/auth/login';
  static const String registerEndpoint = '$apiVersion/auth/register';
  static const String meEndpoint = '$apiVersion/auth/me';
  static const String studentsEndpoint = '$apiVersion/students';
  static const String marksEndpoint = '$apiVersion/marks';
  static const String attendanceEndpoint = '$apiVersion/attendance';
  static const String activitiesEndpoint = '$apiVersion/activities';
  static const String analyticsEndpoint = '$apiVersion/analytics';

  static const String predictEndpoint = '$apiVersion/predict';
  static const String adminEndpoint = '$apiVersion/admin';
  
  // Storage Keys
  static const String tokenKey = 'auth_token';
  static const String userKey = 'user_data';
  
  // App Info
  static const String appName = 'EduPulse';
  static const String appVersion = '1.0.0';
}
