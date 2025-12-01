import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/app_config.dart';
import '../models/models.dart';

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  String? _token;

  Future<void> loadToken() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString(AppConfig.tokenKey);
  }

  Future<void> saveToken(String token) async {
    _token = token;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AppConfig.tokenKey, token);
  }

  Future<void> clearToken() async {
    _token = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(AppConfig.tokenKey);
    await prefs.remove(AppConfig.userKey);
  }

  Map<String, String> _getHeaders() {
    final headers = {
      'Content-Type': 'application/json',
    };
    if (_token != null) {
      headers['Authorization'] = 'Bearer $_token';
    }
    return headers;
  }

  // Authentication
  Future<Map<String, dynamic>> login(String email, String password) async {
    final response = await http.post(
      Uri.parse('${AppConfig.baseUrl}${AppConfig.loginEndpoint}'),
      headers: {'Content-Type': 'application/x-www-form-urlencoded'},
      body: {
        'username': email,
        'password': password,
      },
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      await saveToken(data['access_token']);
      return data;
    } else {
      throw Exception('Login failed: ${response.body}');
    }

  }

  Future<User> register(
    String name,
    String email,
    String password,
    String role,
    String secretPin, {
    String? regNo,
    String? phone,
    String? dept,
    String? year,
    String? section,
  }) async {
    final response = await http.post(
      Uri.parse('${AppConfig.baseUrl}${AppConfig.registerEndpoint}'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'name': name,
        'email': email,
        'password': password,
        'role': role,
        'secret_pin': secretPin,
        'reg_no': regNo,
        'phone': phone,
        'dept': dept,
        'year': year,
        'section': section,
      }),
    );

    if (response.statusCode == 200) {
      return User.fromJson(json.decode(response.body));
    } else {
      throw Exception('Registration failed: ${response.body}');
    }
  }

  Future<void> forgotPassword(String email, String secretPin, String newPassword) async {
    final response = await http.post(
      Uri.parse('${AppConfig.baseUrl}${AppConfig.apiVersion}/auth/forgot-password'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'email': email,
        'secret_pin': secretPin,
        'new_password': newPassword,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('Password reset failed: ${response.body}');
    }
  }

  Future<User> getCurrentUser() async {
    final response = await http.get(
      Uri.parse('${AppConfig.baseUrl}${AppConfig.meEndpoint}'),
      headers: _getHeaders(),
    );

    if (response.statusCode == 200) {
      return User.fromJson(json.decode(response.body));
    } else {
      throw Exception('Failed to get user: ${response.body}');
    }
  }

  // Students
  Future<List<Student>> getStudents({String? search, int? deptId, int? year}) async {
    var uri = Uri.parse('${AppConfig.baseUrl}${AppConfig.studentsEndpoint}');
    
    final queryParams = <String, String>{};
    if (search != null && search.isNotEmpty) queryParams['search'] = search;
    if (deptId != null) queryParams['dept_id'] = deptId.toString();
    if (year != null) queryParams['year'] = year.toString();
    
    if (queryParams.isNotEmpty) {
      uri = uri.replace(queryParameters: queryParams);
    }

    final response = await http.get(uri, headers: _getHeaders());

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.map((json) => Student.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load students');
    }
  }

  Future<Student> createStudent(Map<String, dynamic> studentData) async {
    final response = await http.post(
      Uri.parse('${AppConfig.baseUrl}${AppConfig.studentsEndpoint}'),
      headers: _getHeaders(),
      body: json.encode(studentData),
    );

    if (response.statusCode == 200) {
      return Student.fromJson(json.decode(response.body));
    } else {
      throw Exception('Failed to create student: ${response.body}');
    }
  }

  Future<Map<String, dynamic>> getStudentProfile360(int studentId) async {
    final response = await http.get(
      Uri.parse('${AppConfig.baseUrl}${AppConfig.studentsEndpoint}/$studentId/profile'),
      headers: _getHeaders(),
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to load student profile');
    }
  }

  // Marks
  Future<List<Mark>> getStudentMarks(int studentId) async {
    final response = await http.get(
      Uri.parse('${AppConfig.baseUrl}${AppConfig.marksEndpoint}/student/$studentId'),
      headers: _getHeaders(),
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.map((json) => Mark.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load marks');
    }
  }

  Future<Mark> createMark(Map<String, dynamic> markData) async {
    final response = await http.post(
      Uri.parse('${AppConfig.baseUrl}${AppConfig.marksEndpoint}'),
      headers: _getHeaders(),
      body: json.encode(markData),
    );

    if (response.statusCode == 200) {
      return Mark.fromJson(json.decode(response.body));
    } else {
      throw Exception('Failed to create mark: ${response.body}');
    }
  }

  // Attendance
  Future<List<Attendance>> getStudentAttendance(int studentId) async {
    final response = await http.get(
      Uri.parse('${AppConfig.baseUrl}${AppConfig.attendanceEndpoint}/student/$studentId'),
      headers: _getHeaders(),
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.map((json) => Attendance.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load attendance');
    }
  }

  Future<Attendance> createAttendance(Map<String, dynamic> attendanceData) async {
    final response = await http.post(
      Uri.parse('${AppConfig.baseUrl}${AppConfig.attendanceEndpoint}'),
      headers: _getHeaders(),
      body: json.encode(attendanceData),
    );

    if (response.statusCode == 200) {
      return Attendance.fromJson(json.decode(response.body));
    } else {
      throw Exception('Failed to create attendance: ${response.body}');
    }
  }

  // Activities
  Future<List<Activity>> getActivities() async {
    final response = await http.get(
      Uri.parse('${AppConfig.baseUrl}${AppConfig.activitiesEndpoint}'),
      headers: _getHeaders(),
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.map((json) => Activity.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load activities');
    }
  }

  Future<Activity> createActivity(Map<String, dynamic> activityData) async {
    final response = await http.post(
      Uri.parse('${AppConfig.baseUrl}${AppConfig.activitiesEndpoint}'),
      headers: _getHeaders(),
      body: json.encode(activityData),
    );

    if (response.statusCode == 200) {
      return Activity.fromJson(json.decode(response.body));
    } else {
      throw Exception('Failed to create activity: ${response.body}');
    }
  }

  Future<ActivityParticipation> createParticipation(Map<String, dynamic> participationData) async {
    final response = await http.post(
      Uri.parse('${AppConfig.baseUrl}${AppConfig.activitiesEndpoint}/participation'),
      headers: _getHeaders(),
      body: json.encode(participationData),
    );

    if (response.statusCode == 200) {
      return ActivityParticipation.fromJson(json.decode(response.body));
    } else {
      throw Exception('Failed to create participation: ${response.body}');
    }
  }

  // Analytics
  Future<DashboardStats> getDashboardStats() async {
    final response = await http.get(
      Uri.parse('${AppConfig.baseUrl}${AppConfig.analyticsEndpoint}/dashboard'),
      headers: _getHeaders(),
    );

    if (response.statusCode == 200) {
      return DashboardStats.fromJson(json.decode(response.body));
    } else {
      throw Exception('Failed to load dashboard stats');
    }
  }

  // Risk Prediction
  Future<RiskPrediction> predictRisk(int studentId) async {
    final response = await http.post(
      Uri.parse('${AppConfig.baseUrl}${AppConfig.predictEndpoint}/risk'),
      headers: _getHeaders(),
      body: json.encode({'student_id': studentId}),
    );

    if (response.statusCode == 200) {
      return RiskPrediction.fromJson(json.decode(response.body));
    } else {
      throw Exception('Failed to predict risk: ${response.body}');
    }
  }

  Future<List<RiskPrediction>> getAtRiskStudents() async {
    final response = await http.get(
      Uri.parse('${AppConfig.baseUrl}${AppConfig.predictEndpoint}/at-risk-students'),
      headers: _getHeaders(),
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.map((json) => RiskPrediction.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load at-risk students');
    }
  }

  // Admin Methods
  Future<User> createUser(Map<String, dynamic> userData) async {
    final response = await http.post(
      Uri.parse('${AppConfig.baseUrl}${AppConfig.adminEndpoint}/users'),
      headers: _getHeaders(),
      body: json.encode(userData),
    );

    if (response.statusCode == 200) {
      return User.fromJson(json.decode(response.body));
    } else {
      throw Exception('Failed to create user: ${response.body}');
    }
  }

  Future<List<dynamic>> getPendingUsers() async {
    final response = await http.get(
      Uri.parse('${AppConfig.baseUrl}${AppConfig.adminEndpoint}/pending-users'),
      headers: _getHeaders(),
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to load pending users');
    }
  }

  Future<void> approveUser(int userId) async {
    final response = await http.post(
      Uri.parse('${AppConfig.baseUrl}${AppConfig.adminEndpoint}/approve-user/$userId'),
      headers: _getHeaders(),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to approve user: ${response.body}');
    }
  }

  Future<void> rejectUser(int userId) async {
    final response = await http.post(
      Uri.parse('${AppConfig.baseUrl}${AppConfig.adminEndpoint}/reject-user/$userId'),
      headers: _getHeaders(),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to reject user: ${response.body}');
    }
  }

  Future<List<User>> getUsers({String? role}) async {
    var uri = Uri.parse('${AppConfig.baseUrl}${AppConfig.adminEndpoint}/users');
    if (role != null) {
      uri = uri.replace(queryParameters: {'role': role});
    }

    final response = await http.get(uri, headers: _getHeaders());

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.map((json) => User.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load users');
    }
  }

  Future<User> updateUser(int userId, Map<String, dynamic> userData) async {
    final response = await http.put(
      Uri.parse('${AppConfig.baseUrl}${AppConfig.adminEndpoint}/users/$userId'),
      headers: _getHeaders(),
      body: json.encode(userData),
    );

    if (response.statusCode == 200) {
      return User.fromJson(json.decode(response.body));
    } else {
      throw Exception('Failed to update user: ${response.body}');
    }
  }

  Future<void> toggleUserStatus(int userId) async {
    final response = await http.post(
      Uri.parse('${AppConfig.baseUrl}${AppConfig.adminEndpoint}/users/$userId/toggle-status'),
      headers: _getHeaders(),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to toggle user status: ${response.body}');
    }
  }

  Future<void> resetUserPassword(int userId, String newPassword) async {
    final uri = Uri.parse('${AppConfig.baseUrl}${AppConfig.adminEndpoint}/users/$userId/reset-password')
        .replace(queryParameters: {'new_password': newPassword});

    final response = await http.post(
      uri,
      headers: _getHeaders(),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to reset password: ${response.body}');
    }
  }

  Future<List<dynamic>> getLoginLogs({bool? successOnly}) async {
    var uri = Uri.parse('${AppConfig.baseUrl}${AppConfig.adminEndpoint}/login-logs');
    if (successOnly != null) {
      uri = uri.replace(queryParameters: {'success_only': successOnly.toString()});
    }

    final response = await http.get(uri, headers: _getHeaders());

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to load login logs');
    }
  }

  Future<void> deleteUser(int userId) async {
    final response = await http.delete(
      Uri.parse('${AppConfig.baseUrl}${AppConfig.adminEndpoint}/users/$userId'),
      headers: _getHeaders(),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to delete user: ${response.body}');
    }
  }
}
