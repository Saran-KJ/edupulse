import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/app_config.dart';
import '../models/models.dart';
import '../models/mark_models.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../models/attendance_models.dart';

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
    // Parent-specific fields
    String? childName,
    String? childPhone,
    String? childRegNo,
    String? occupation,
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
        'child_name': childName,
        'child_phone': childPhone,
        'child_reg_no': childRegNo,
        'occupation': occupation,
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
  Future<List<Student>> getStudents({String? search, String? dept, int? year, String? section}) async {
    var uri = Uri.parse('${AppConfig.baseUrl}${AppConfig.studentsEndpoint}');
    
    final queryParams = <String, String>{};
    if (search != null && search.isNotEmpty) queryParams['search'] = search;
    if (dept != null) queryParams['dept'] = dept;
    if (year != null) queryParams['year'] = year.toString();
    if (section != null && section.isNotEmpty) queryParams['section'] = section;
    
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

  Future<Map<String, dynamic>> getStudentProfile360(String regNo, {String? dept}) async {
    var uri = Uri.parse('${AppConfig.baseUrl}${AppConfig.studentsEndpoint}/$regNo/profile');
    if (dept != null) {
      uri = uri.replace(queryParameters: {'dept': dept});
    }

    final response = await http.get(
      uri,
      headers: _getHeaders(),
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to load student profile');
    }
  }

  // Marks
  Future<List<Mark>> getStudentMarks(String regNo, {int? semester}) async {
    var uri = Uri.parse('${AppConfig.baseUrl}${AppConfig.marksEndpoint}/student/$regNo');
    
    if (semester != null) {
      uri = uri.replace(queryParameters: {'semester': semester.toString()});
    }

    final response = await http.get(uri, headers: _getHeaders());

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.map((json) => Mark.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load marks');
    }
  }




  Future<List<Map<String, dynamic>>> getClassMarks({
    required String dept,
    required int year,
    required String section,
    int? semester,
    String? subjectCode,
  }) async {
    var uri = Uri.parse('${AppConfig.baseUrl}${AppConfig.marksEndpoint}/class/$dept/$year/$section');
    
    final queryParams = <String, String>{};
    if (semester != null) queryParams['semester'] = semester.toString();
    if (subjectCode != null) queryParams['subject_code'] = subjectCode;

    if (queryParams.isNotEmpty) {
      uri = uri.replace(queryParameters: queryParams);
    }

    final response = await http.get(uri, headers: _getHeaders());

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.cast<Map<String, dynamic>>();
    } else {
      throw Exception('Failed to load class marks');
    }
  }

  // New Bulk Marks Entry
  Future<List<dynamic>> submitBulkMarksNew(List<Map<String, dynamic>> marks) async {
    final response = await http.post(
      Uri.parse('${AppConfig.baseUrl}${AppConfig.marksEndpoint}/bulk'),
      headers: _getHeaders(),
      body: json.encode({'marks': marks}),
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to submit marks: ${response.body}');
    }
  }


  // Attendance
  Future<List<Attendance>> getClassAttendance(String dept, int year, String section, String date) async {
    final response = await http.get(
      Uri.parse('${AppConfig.baseUrl}${AppConfig.attendanceEndpoint}/class/$dept/$year/$section/$date'),
      headers: _getHeaders(),
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.map((json) => Attendance.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load class attendance');
    }
  }

  Future<List<Attendance>> submitBulkAttendance({
    required String date,
    required int year,
    required String section,
    required String dept,
    required List<AttendanceInput> attendanceList,
  }) async {
    final response = await http.post(
      Uri.parse('${AppConfig.baseUrl}${AppConfig.attendanceEndpoint}/bulk'),
      headers: _getHeaders(),
      body: json.encode({
        'date': date,
        'year': year,
        'section': section,
        'dept': dept,
        'attendance_list': attendanceList.map((a) => a.toJson()).toList(),
      }),
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.map((json) => Attendance.fromJson(json)).toList();
    } else {
      throw Exception('Failed to submit attendance: ${response.body}');
    }
  }

  Future<List<Attendance>> getStudentAttendance(String regNo) async {
    final response = await http.get(
      Uri.parse('${AppConfig.baseUrl}${AppConfig.attendanceEndpoint}/student/$regNo'),
      headers: _getHeaders(),
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.map((json) => Attendance.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load student attendance');
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

  Future<Activity> updateActivity(int activityId, Map<String, dynamic> data) async {
    final response = await http.put(
      Uri.parse('${AppConfig.baseUrl}${AppConfig.activitiesEndpoint}/$activityId'),
      headers: _getHeaders(),
      body: json.encode(data),
    );

    if (response.statusCode == 200) {
      return Activity.fromJson(json.decode(response.body));
    } else {
      throw Exception('Failed to update activity: ${response.body}');
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

  Future<void> deleteParticipation(int participationId) async {
    final response = await http.delete(
      Uri.parse('${AppConfig.baseUrl}${AppConfig.activitiesEndpoint}/participation/$participationId'),
      headers: _getHeaders(),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to delete participation: ${response.body}');
    }
  }

  Future<void> updateParticipation(int participationId, Map<String, dynamic> data) async {
    final response = await http.put(
      Uri.parse('${AppConfig.baseUrl}${AppConfig.activitiesEndpoint}/participation/$participationId'),
      headers: _getHeaders(),
      body: json.encode(data),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to update participation: ${response.body}');
    }
  }

  Future<List<Map<String, dynamic>>> getClassActivities({
    required String dept,
    required int year,
    required String section,
  }) async {
    final response = await http.get(
      Uri.parse('${AppConfig.baseUrl}${AppConfig.activitiesEndpoint}/class/$dept/$year/$section'),
      headers: _getHeaders(),
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.cast<Map<String, dynamic>>();
    } else {
      throw Exception('Failed to load class activities');
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

  Future<Map<String, dynamic>> getStudentDashboardStats() async {
    final response = await http.get(
      Uri.parse('${AppConfig.baseUrl}${AppConfig.studentsEndpoint}/me/dashboard-stats'),
      headers: _getHeaders(),
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to load student dashboard stats');
    }
  }

  Future<Map<String, dynamic>> getParentDashboardStats() async {
    final response = await http.get(
      Uri.parse('${AppConfig.baseUrl}${AppConfig.studentsEndpoint}/parent/dashboard-stats'),
      headers: _getHeaders(),
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to load parent dashboard stats');
    }
  }

  Future<Map<String, dynamic>> updateStudentProfile(Map<String, dynamic> profileData) async {
    final response = await http.put(
      Uri.parse('${AppConfig.baseUrl}${AppConfig.studentsEndpoint}/me/profile'),
      headers: _getHeaders(),
      body: json.encode(profileData),
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to update profile: ${response.body}');
    }
  }

  Future<void> updateStudentByRegNo(String regNo, Map<String, dynamic> data) async {
    final response = await http.put(
      Uri.parse('${AppConfig.baseUrl}${AppConfig.studentsEndpoint}/$regNo'),
      headers: _getHeaders(),
      body: json.encode(data),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to update student: ${response.body}');
    }
  }

  // Risk Prediction
  Future<RiskPrediction> predictRisk(String regNo) async {
    final response = await http.post(
      Uri.parse('${AppConfig.baseUrl}${AppConfig.predictEndpoint}/risk'),
      headers: _getHeaders(),
      body: json.encode({'reg_no': regNo}),
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

  // Report Generation
  Future<void> downloadClassReport() async {
    final token = await getToken();
    if (token == null) throw Exception('Not authenticated');

    // Append token to URL for query param auth
    final uri = Uri.parse('${AppConfig.baseUrl}/api/reports/class-report?token=$token');
    
    if (await canLaunchUrl(uri)) {
      await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
        // No headers needed as token is in URL
      );
    } else {
      throw Exception('Could not launch report URL');
    }
  }

  Future<void> exportAttendance() async {
    final token = await getToken();
    if (token == null) throw Exception('Not authenticated');

    // Append token to URL for query param auth
    final uri = Uri.parse('${AppConfig.baseUrl}/api/reports/attendance-export?token=$token');
    
    if (await canLaunchUrl(uri)) {
      await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
        // No headers needed as token is in URL
      );
    } else {
      throw Exception('Could not launch report URL');
    }
  }

  Future<void> exportClassMarks({int? semester}) async {
    final token = await getToken();
    if (token == null) throw Exception('Not authenticated');

    var uri = Uri.parse('${AppConfig.baseUrl}/api/reports/marks-export-excel');
    final queryParams = {'token': token};
    if (semester != null) {
      queryParams['semester'] = semester.toString();
    }
    uri = uri.replace(queryParameters: queryParams);
    
    if (await canLaunchUrl(uri)) {
      await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
    } else {
      throw Exception('Could not launch report URL');
    }
  }








  // Faculty Methods
  Future<List<Map<String, dynamic>>> getFacultyClasses() async {
    final response = await http.get(
      Uri.parse('${AppConfig.baseUrl}/api/faculty/my-classes'),
      headers: _getHeaders(),
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.cast<Map<String, dynamic>>();
    } else {
      throw Exception('Failed to load faculty classes: ${response.body}');
    }
  }

  Future<Map<String, dynamic>> getFacultyDashboardStats() async {
    final response = await http.get(
      Uri.parse('${AppConfig.baseUrl}/api/faculty/dashboard-stats'),
      headers: _getHeaders(),
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to load faculty dashboard stats: ${response.body}');
    }
  }

  // Helper to get token for external use
  Future<String?> getToken() async {
    if (_token == null) {
      await loadToken();
    }
    return _token;
  }

  // Student Activity Submissions
  Future<StudentActivitySubmission> submitActivity(Map<String, dynamic> data) async {
    final response = await http.post(
      Uri.parse('${AppConfig.baseUrl}${AppConfig.activitiesEndpoint}/submit'),
      headers: _getHeaders(),
      body: json.encode(data),
    );

    if (response.statusCode == 200) {
      return StudentActivitySubmission.fromJson(json.decode(response.body));
    } else {
      throw Exception('Failed to submit activity: ${response.body}');
    }
  }

  Future<List<StudentActivitySubmission>> getMySubmissions() async {
    final response = await http.get(
      Uri.parse('${AppConfig.baseUrl}${AppConfig.activitiesEndpoint}/my-submissions'),
      headers: _getHeaders(),
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.map((json) => StudentActivitySubmission.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load submissions: ${response.body}');
    }
  }

  Future<List<StudentActivitySubmission>> getStudentActivities(String regNo) async {
    final response = await http.get(
      Uri.parse('${AppConfig.baseUrl}${AppConfig.activitiesEndpoint}/student/$regNo'),
      headers: _getHeaders(),
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.map((json) => StudentActivitySubmission.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load student activities: ${response.body}');
    }
  }

  Future<List<StudentActivitySubmission>> getPendingSubmissions(String dept, int year, String section, {String? status}) async {
    var uri = Uri.parse('${AppConfig.baseUrl}${AppConfig.activitiesEndpoint}/pending-submissions/$dept/$year/$section');
    if (status != null) {
      uri = uri.replace(queryParameters: {'status': status});
    }

    final response = await http.get(uri, headers: _getHeaders());

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.map((json) => StudentActivitySubmission.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load pending submissions: ${response.body}');
    }
  }

  // Personalized Learning
  Future<Map<String, dynamic>> getLearningRecommendations({String? subjectCode, String language = "English"}) async {
    Uri uri = Uri.parse('${AppConfig.baseUrl}/api/learning/recommendations');
    Map<String, String> queryParameters = {};
    if (subjectCode != null) {
      queryParameters['subject_code'] = subjectCode;
    }
    if (language != "English") {
      queryParameters['language'] = language;
    }
    if (queryParameters.isNotEmpty) {
      uri = uri.replace(queryParameters: queryParameters);
    }

    final response = await http.get(
      uri,
      headers: _getHeaders(),
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to load learning recommendations');
    }
  }

  Future<void> updateResourceProgress(int resourceId, bool isCompleted) async {
    final response = await http.post(
      Uri.parse('${AppConfig.baseUrl}/api/learning/progress'),
      headers: _getHeaders(),
      body: json.encode({
        'resource_id': resourceId,
        'completed': isCompleted,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to update progress: ${response.body}');
    }
  }

  Future<StudentActivitySubmission> reviewSubmission(int submissionId, String status, {String? comment}) async {
    final response = await http.put(
      Uri.parse('${AppConfig.baseUrl}${AppConfig.activitiesEndpoint}/submissions/$submissionId/review'),
      headers: _getHeaders(),
      body: json.encode({'status': status, 'review_comment': comment}),
    );

    if (response.statusCode == 200) {
      return StudentActivitySubmission.fromJson(json.decode(response.body));
    } else {
      throw Exception('Failed to review submission: ${response.body}');
    }
  }

  // HOD Faculty Allocation Methods
  Future<Map<String, dynamic>> createAllocation(Map<String, dynamic> data) async {
    final response = await http.post(
      Uri.parse('${AppConfig.baseUrl}/api/hod/allocations'),
      headers: _getHeaders(),
      body: json.encode(data),
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to create allocation: ${response.body}');
    }
  }

  Future<List<Map<String, dynamic>>> getAllocations(String dept, int year, String section) async {
    final response = await http.get(
      Uri.parse('${AppConfig.baseUrl}/api/hod/allocations/$dept/$year/$section'),
      headers: _getHeaders(),
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.cast<Map<String, dynamic>>();
    } else {
      throw Exception('Failed to load allocations: ${response.body}');
    }
  }

  Future<void> deleteAllocation(int id) async {
    final response = await http.delete(
      Uri.parse('${AppConfig.baseUrl}/api/hod/allocations/$id'),
      headers: _getHeaders(),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to delete allocation: ${response.body}');
    }
  }

  Future<List<User>> getDepartmentFaculty(String dept) async {
    final response = await http.get(
      Uri.parse('${AppConfig.baseUrl}/api/hod/faculty/$dept'),
      headers: _getHeaders(),
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.map((json) => User.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load faculty: ${response.body}');
    }
  }

  Future<List<Map<String, dynamic>>> getDepartmentSubjects(String dept, int semester) async {
    final response = await http.get(
      Uri.parse('${AppConfig.baseUrl}/api/hod/subjects/$dept/$semester'),
      headers: _getHeaders(),
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.cast<Map<String, dynamic>>();
    } else {
      throw Exception('Failed to load subjects: ${response.body}');
    }
  }



  Future<List<FacultyAllocation>> getFacultyAllocations() async {
    final response = await http.get(
      Uri.parse('${AppConfig.baseUrl}/api/faculty/allocations'),
      headers: _getHeaders(),
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.map((json) => FacultyAllocation.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load faculty allocations: ${response.body}');
    }
  }
}
