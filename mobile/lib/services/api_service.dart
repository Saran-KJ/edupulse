import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/app_config.dart';
import '../models/models.dart';
import '../models/mark_models.dart';
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
    String role, {
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

  Future<void> requestPasswordResetOtp(String email) async {
    final response = await http.post(
      Uri.parse('${AppConfig.baseUrl}${AppConfig.apiVersion}/auth/forgot-password/request-otp'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'email': email}),
    );

    if (response.statusCode != 200) {
      final error = json.decode(response.body)['detail'] ?? 'Failed to request OTP';
      throw Exception(error);
    }
  }

  Future<void> verifyPasswordResetOtp(String email, String otp) async {
    final response = await http.post(
      Uri.parse('${AppConfig.baseUrl}${AppConfig.apiVersion}/auth/forgot-password/verify-otp'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'email': email,
        'otp': otp,
      }),
    );

    if (response.statusCode != 200) {
      final error = json.decode(response.body)['detail'] ?? 'Invalid or expired OTP';
      throw Exception(error);
    }
  }

  Future<void> confirmPasswordReset(String email, String otp, String newPassword) async {
    final response = await http.post(
      Uri.parse('${AppConfig.baseUrl}${AppConfig.apiVersion}/auth/forgot-password/confirm'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'email': email,
        'otp': otp,
        'new_password': newPassword,
      }),
    );

    if (response.statusCode != 200) {
      final error = json.decode(response.body)['detail'] ?? 'Password reset failed';
      throw Exception(error);
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
  Future<List<Mark>> getStudentMarks(String regNo, {int? semester, bool? excludeLabs}) async {
    var uri = Uri.parse('${AppConfig.baseUrl}${AppConfig.marksEndpoint}/student/$regNo');
    
    final queryParams = <String, String>{};
    if (semester != null) {
      queryParams['semester'] = semester.toString();
    }
    if (excludeLabs == true) {
      queryParams['exclude_labs'] = 'true';
    }

    if (queryParams.isNotEmpty) {
      uri = uri.replace(queryParameters: queryParams);
    }

    final response = await http.get(uri, headers: _getHeaders());

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.map((json) => Mark.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load marks');
    }
  }

  Future<Map<String, dynamic>> getCgpa(String regNo) async {
    final response = await http.get(
      Uri.parse('${AppConfig.baseUrl}${AppConfig.marksEndpoint}/cgpa/$regNo'),
      headers: _getHeaders(),
    );
    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to load CGPA: ${response.body}');
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

  // Academic Alerts
  Future<List<dynamic>> getStudentAlerts() async {
    final response = await http.get(
      Uri.parse('${AppConfig.baseUrl}${AppConfig.studentsEndpoint}/me/alerts'),
      headers: _getHeaders(),
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to load student alerts: ${response.body}');
    }
  }

  Future<void> markAlertRead(int alertId) async {
    final response = await http.put(
      Uri.parse('${AppConfig.baseUrl}${AppConfig.studentsEndpoint}/me/alerts/$alertId/read'),
      headers: _getHeaders(),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to mark alert as read: ${response.body}');
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
      final responseData = json.decode(response.body);
      
      // If the email was changed, the backend issues a new token. Save it!
      if (responseData.containsKey('access_token')) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('token', responseData['access_token']);
      }
      
      return responseData;
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

  // Personalized Learning Plan APIs
  Future<Map<String, dynamic>> getPersonalizedPlan(String subjectCode) async {
    final response = await http.get(
      Uri.parse('${AppConfig.baseUrl}/api/learning/plan/$subjectCode'),
      headers: _getHeaders(),
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to load personalized plan');
    }
  }

  Future<Map<String, dynamic>> submitLowRiskChoice(String subjectCode, String choice) async {
    final response = await http.post(
      Uri.parse('${AppConfig.baseUrl}/api/learning/low-risk-choice'),
      headers: _getHeaders(),
      body: json.encode({
        'subject_code': subjectCode,
        'choice': choice,
      }),
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to submit choice: ${response.body}');
    }
  }

  Future<Map<String, dynamic>> submitSkillSelection(String subjectCode, String skill) async {
    final response = await http.post(
      Uri.parse('${AppConfig.baseUrl}/api/learning/skill-selection'),
      headers: _getHeaders(),
      body: json.encode({
        'subject_code': subjectCode,
        'skill': skill,
      }),
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to submit skill: ${response.body}');
    }
  }

  Future<Map<String, dynamic>> submitGlobalPathPreference(String choice, {String? subChoice}) async {
    final response = await http.post(
      Uri.parse('${AppConfig.baseUrl}/api/learning/global-path'),
      headers: _getHeaders(),
      body: json.encode({
        'choice': choice,
        'sub_choice': subChoice,
      }),
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to submit global path: ${response.body}');
    }
  }

  Future<Map<String, dynamic>> getPlanResources(String subjectCode, {String language = "English"}) async {
    Uri uri = Uri.parse('${AppConfig.baseUrl}/api/learning/plan/resources/$subjectCode');
    if (language != "English") {
      uri = uri.replace(queryParameters: {'language': language});
    }

    final response = await http.get(uri, headers: _getHeaders());

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to load plan resources');
    }
  }

  Future<Map<String, dynamic>> getAllSubjectResources(String subjectCode, {String language = "All", String? riskLevel}) async {
    Uri uri = Uri.parse('${AppConfig.baseUrl}/api/learning/subject-resources/$subjectCode');
    final queryParams = <String, String>{};
    if (language != "All") queryParams['language'] = language;
    if (riskLevel != null) queryParams['risk_level'] = riskLevel;
    if (queryParams.isNotEmpty) {
      uri = uri.replace(queryParameters: queryParams);
    }

    final response = await http.get(uri, headers: _getHeaders());

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to load subject resources');
    }
  }

  // Overall Learning View
  Future<Map<String, dynamic>> getOverallLearningView() async {
    final response = await http.get(
      Uri.parse('${AppConfig.baseUrl}/api/learning/overall-view'),
      headers: _getHeaders(),
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to load overall learning view');
    }
  }

  // Set Preferred Learning Type
  Future<Map<String, dynamic>> setPreferredLearningType(String learningType) async {
    final response = await http.patch(
      Uri.parse('${AppConfig.baseUrl}/api/learning/preferred-type'),
      headers: _getHeaders(),
      body: json.encode({'learning_type': learningType}),
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to set learning type: ${response.body}');
    }
  }

  // Advisor Student Progress Monitoring
  Future<Map<String, dynamic>> getAdvisorStudentProgress(String dept, int year, String section) async {
    final response = await http.get(
      Uri.parse('${AppConfig.baseUrl}/api/learning/advisor/students/$dept/$year/$section'),
      headers: _getHeaders(),
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to load advisor student progress');
    }
  }

  // High Risk Alerts
  Future<Map<String, dynamic>> getHighRiskAlerts({String? dept, int? year, String? section}) async {
    Uri uri = Uri.parse('${AppConfig.baseUrl}/api/learning/alerts');
    Map<String, String> queryParams = {};
    if (dept != null) queryParams['dept'] = dept;
    if (year != null) queryParams['year'] = year.toString();
    if (section != null) queryParams['section'] = section;
    if (queryParams.isNotEmpty) {
      uri = uri.replace(queryParameters: queryParams);
    }

    final response = await http.get(uri, headers: _getHeaders());

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to load high risk alerts');
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

  Future<List<Map<String, dynamic>>> getSubjects({String? semester, String? category}) async {
    final params = <String, String>{};
    if (semester != null) params['semester'] = semester;
    if (category != null) params['category'] = category;

    final uri = Uri.parse('${AppConfig.baseUrl}/api/subjects').replace(queryParameters: params.isNotEmpty ? params : null);

    final response = await http.get(
      uri,
      headers: _getHeaders(),
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.cast<Map<String, dynamic>>();
    } else {
      throw Exception('Failed to load subjects: ${response.body}');
    }
  }

  Future<List<Map<String, dynamic>>> saveSubjectSelections(List<Map<String, dynamic>> selections) async {
    final response = await http.post(
      Uri.parse('${AppConfig.baseUrl}/api/hod/subject-selection'),
      headers: _getHeaders(),
      body: json.encode(selections),
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.cast<Map<String, dynamic>>();
    } else {
      throw Exception('Failed to save subject selections: ${response.body}');
    }
  }

  Future<List<Map<String, dynamic>>> getSubjectSelections(String dept, int year, String section, String semester) async {
    final response = await http.get(
      Uri.parse('${AppConfig.baseUrl}/api/hod/subject-selection/$dept/$year/$section/$semester'),
      headers: _getHeaders(),
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.cast<Map<String, dynamic>>();
    } else {
      throw Exception('Failed to load subject selections: ${response.body}');
    }
  }



  // --- HOD Project Batch Endpoints ---
  
  Future<Map<String, dynamic>> createProjectBatch({
    required int guideId,
    required String dept,
    required int year,
    required String section,
    required List<String> studentRegNos,
  }) async {
    final response = await http.post(
      Uri.parse('${AppConfig.baseUrl}/api/hod/batches/create'),
      headers: _getHeaders(),
      body: json.encode({
        'guide_id': guideId,
        'dept': dept,
        'year': year,
        'section': section,
        'student_reg_nos': studentRegNos,
      }),
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to create batch: ${response.body}');
    }
  }

  Future<List<Map<String, dynamic>>> getProjectBatches({
    String? dept,
    int? year,
    String? section,
  }) async {
    final queryParams = <String, String>{};
    if (dept != null) queryParams['dept'] = dept;
    if (year != null) queryParams['year'] = year.toString();
    if (section != null) queryParams['section'] = section;

    final uri = Uri.parse('${AppConfig.baseUrl}/api/hod/batches').replace(queryParameters: queryParams);

    final response = await http.get(
      uri,
      headers: _getHeaders(),
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.cast<Map<String, dynamic>>();
    } else {
      throw Exception('Failed to load project batches: ${response.body}');
    }
  }

  // Coordinator Assignment
  Future<Map<String, dynamic>> assignProjectCoordinator({
    required int facultyId,
    required String dept,
    required int year,
  }) async {
    final response = await http.post(
      Uri.parse('${AppConfig.baseUrl}/api/hod/coordinator'),
      headers: _getHeaders(),
      body: json.encode({
        'faculty_id': facultyId,
        'dept': dept,
        'year': year,
      }),
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to assign coordinator: ${response.body}');
    }
  }

  Future<List<Map<String, dynamic>>> getProjectCoordinators(String dept) async {
    final response = await http.get(
      Uri.parse('${AppConfig.baseUrl}/api/hod/coordinators/$dept'),
      headers: _getHeaders(),
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.cast<Map<String, dynamic>>();
    } else {
      throw Exception('Failed to load coordinators: ${response.body}');
    }
  }


  // --- Project Management Endpoints ---
  Future<Map<String, dynamic>?> getMyProjectBatch() async {
    final response = await http.get(
      Uri.parse('${AppConfig.baseUrl}/api/projects/my-batch'),
      headers: _getHeaders(),
    );

    if (response.statusCode == 200) {
      final decoded = json.decode(response.body);
      return decoded;
    } else if (response.statusCode == 404 || response.statusCode == 400) {
      return null;
    } else {
      throw Exception('Failed to load my project batch: ${response.body}');
    }
  }

  Future<void> updateProjectTask(int taskId, int isCompleted) async {
    final response = await http.put(
      Uri.parse('${AppConfig.baseUrl}/api/projects/tasks/$taskId'),
      headers: _getHeaders(),
      body: json.encode({'is_completed': isCompleted}),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to update project task: ${response.body}');
    }
  }

  Future<Map<String, dynamic>> recordProjectReview({
    required int batchId,
    required int reviewNumber,
    required double marks,
    String? feedback,
  }) async {
    final response = await http.post(
      Uri.parse('${AppConfig.baseUrl}/api/projects/reviews'),
      headers: _getHeaders(),
      body: json.encode({
        'batch_id': batchId,
        'review_number': reviewNumber,
        'marks': marks,
        'feedback': feedback,
      }),
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to record project review: ${response.body}');
    }
  }


  Future<List<Map<String, dynamic>>> getGuideBatches() async {
    final response = await http.get(
      Uri.parse('${AppConfig.baseUrl}/api/projects/guide-batches'),
      headers: _getHeaders(),
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.cast<Map<String, dynamic>>();
    } else {
      throw Exception('Failed to load guide batches: ${response.body}');
    }
  }

  Future<Map<String, dynamic>> assignBatchReviewer(int batchId, int reviewerId) async {
    final response = await http.put(
      Uri.parse('${AppConfig.baseUrl}/api/projects/batches/$batchId/reviewer'),
      headers: _getHeaders(),
      body: json.encode({'reviewer_id': reviewerId}),
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to assign reviewer: ${response.body}');
    }
  }

  Future<List<Map<String, dynamic>>> getCoordinatorBatches({String? section}) async {
    final queryParams = <String, String>{};
    if (section != null) queryParams['section'] = section;

    final uri = Uri.parse('${AppConfig.baseUrl}/api/projects/coordinator-batches').replace(queryParameters: queryParams);

    final response = await http.get(
      uri,
      headers: _getHeaders(),
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.cast<Map<String, dynamic>>();
    } else {
      throw Exception('Failed to load coordinator batches: ${response.body}');
    }
  }

  Future<List<Map<String, dynamic>>> getReviewerBatches() async {
    final response = await http.get(
      Uri.parse('${AppConfig.baseUrl}/api/projects/reviewer-batches'),
      headers: _getHeaders(),
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.cast<Map<String, dynamic>>();
    } else {
      throw Exception('Failed to load reviewer batches: ${response.body}');
    }
  }


  // --- Helper Methods ---
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

  // Quiz Methods
  Future<Map<String, dynamic>> getQuiz({
    required String subjectName,
    required int unitNumber,
    required String riskLevel,
  }) async {
    final response = await http.get(
      Uri.parse('${AppConfig.baseUrl}/api/quiz/generate')
          .replace(queryParameters: {
        'subject_name': subjectName,
        'unit_number': unitNumber.toString(),
        'risk_level': riskLevel,
      }),
      headers: _getHeaders(),
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to load quiz: ${response.body}');
    }
  }

  Future<Map<String, dynamic>> submitQuiz(QuizAttemptSubmission submission) async {
    final response = await http.post(
      Uri.parse('${AppConfig.baseUrl}/api/quiz/submit'),
      headers: _getHeaders(),
      body: json.encode(submission.toJson()),
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to submit quiz: ${response.body}');
    }
  }

  /// Fetch Gemini-generated content + YouTube videos + AI quiz for a skill category.
  Future<Map<String, dynamic>> getSkillContent(
    String skillCategory, {
    String language = 'English',
    String? subCategory,
    String? level,
  }) async {
    final queryParams = {
      'skill': skillCategory,
      'language': language,
    };
    if (subCategory != null) queryParams['sub_category'] = subCategory;
    if (level != null) queryParams['level'] = level;

    final uri = Uri.parse('${AppConfig.baseUrl}/api/learning/skill-content')
        .replace(queryParameters: queryParams);

    final response = await http.get(uri, headers: _getHeaders());

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to load skill content: ${response.body}');
    }
  }

  // --- Faculty Quiz Scheduling ---

  Future<Map<String, dynamic>> scheduleQuiz(Map<String, dynamic> data) async {
    final response = await http.post(
      Uri.parse('${AppConfig.baseUrl}/api/faculty/schedule-quiz'),
      headers: _getHeaders(),
      body: json.encode(data),
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to schedule quiz: ${response.body}');
    }
  }

  Future<List<Map<String, dynamic>>> getScheduledQuizzes() async {
    final response = await http.get(
      Uri.parse('${AppConfig.baseUrl}/api/faculty/scheduled-quizzes'),
      headers: _getHeaders(),
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.cast<Map<String, dynamic>>();
    } else {
      throw Exception('Failed to load scheduled quizzes: ${response.body}');
    }
  }

  Future<void> closeScheduledQuiz(int quizId) async {
    final response = await http.put(
      Uri.parse('${AppConfig.baseUrl}/api/faculty/scheduled-quizzes/$quizId/close'),
      headers: _getHeaders(),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to close quiz: ${response.body}');
    }
  }

  Future<List<Map<String, dynamic>>> getPendingQuizzes() async {
    final response = await http.get(
      Uri.parse('${AppConfig.baseUrl}/api/students/me/pending-quizzes'),
      headers: _getHeaders(),
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.cast<Map<String, dynamic>>();
    } else {
      throw Exception('Failed to load pending quizzes: ${response.body}');
    }
  }

  Future<void> deleteProjectCoordinator(int coordId) async {
    final response = await http.delete(
      Uri.parse('${AppConfig.baseUrl}/api/hod/coordinator/$coordId'),
      headers: _getHeaders(),
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to delete project coordinator: ${response.body}');
    }
  }

  Future<void> updateProjectCoordinator(int coordId, {required int facultyId, required String dept, required int year}) async {
    final response = await http.put(
      Uri.parse('${AppConfig.baseUrl}/api/hod/coordinator/$coordId'),
      headers: _getHeaders(),
      body: json.encode({
        'faculty_id': facultyId,
        'dept': dept,
        'year': year,
      }),
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to update project coordinator: ${response.body}');
    }
  }
}


// 
