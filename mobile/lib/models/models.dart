class User {
  final int userId;
  final String name;
  final String email;
  final String role;
  final int isActive;
  final String? regNo;
  final String? phone;
  final String? dept;
  final String? year;
  final String? section;

  User({
    required this.userId,
    required this.name,
    required this.email,
    required this.role,
    this.isActive = 1,
    this.regNo,
    this.phone,
    this.dept,
    this.year,
    this.section,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      userId: json['user_id'],
      name: json['name'],
      email: json['email'],
      role: json['role'],
      isActive: json['is_active'] ?? 1,
      regNo: json['reg_no'],
      phone: json['phone'],
      dept: json['dept'],
      year: json['year'],
      section: json['section'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'name': name,
      'email': email,
      'role': role,
      'is_active': isActive,
      'reg_no': regNo,
      'phone': phone,
      'dept': dept,
      'year': year,
      'section': section,
    };
  }
}

class Student {
  final int studentId;
  final String regNo;
  final String name;
  final String? email;
  final String? phone;
  final int deptId;
  final int year;
  final int semester;
  final String? dob;
  final String? address;

  Student({
    required this.studentId,
    required this.regNo,
    required this.name,
    this.email,
    this.phone,
    required this.deptId,
    required this.year,
    required this.semester,
    this.dob,
    this.address,
  });

  factory Student.fromJson(Map<String, dynamic> json) {
    return Student(
      studentId: json['student_id'],
      regNo: json['reg_no'],
      name: json['name'],
      email: json['email'],
      phone: json['phone'],
      deptId: json['dept_id'],
      year: json['year'],
      semester: json['semester'],
      dob: json['dob'],
      address: json['address'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'reg_no': regNo,
      'name': name,
      'email': email,
      'phone': phone,
      'dept_id': deptId,
      'year': year,
      'semester': semester,
      'dob': dob,
      'address': address,
    };
  }
}

class Mark {
  final int markId;
  final int studentId;
  final int subjectId;
  final int semester;
  final double internalMarks;
  final double? externalMarks;
  final double? totalMarks;
  final String? grade;

  Mark({
    required this.markId,
    required this.studentId,
    required this.subjectId,
    required this.semester,
    required this.internalMarks,
    this.externalMarks,
    this.totalMarks,
    this.grade,
  });

  factory Mark.fromJson(Map<String, dynamic> json) {
    return Mark(
      markId: json['mark_id'],
      studentId: json['student_id'],
      subjectId: json['subject_id'],
      semester: json['semester'],
      internalMarks: (json['internal_marks'] as num).toDouble(),
      externalMarks: json['external_marks'] != null 
          ? (json['external_marks'] as num).toDouble() 
          : null,
      totalMarks: json['total_marks'] != null 
          ? (json['total_marks'] as num).toDouble() 
          : null,
      grade: json['grade'],
    );
  }
}

class Attendance {
  final int attendanceId;
  final int studentId;
  final int subjectId;
  final String month;
  final int year;
  final int totalClasses;
  final int attendedClasses;
  final double? attendancePercentage;

  Attendance({
    required this.attendanceId,
    required this.studentId,
    required this.subjectId,
    required this.month,
    required this.year,
    required this.totalClasses,
    required this.attendedClasses,
    this.attendancePercentage,
  });

  factory Attendance.fromJson(Map<String, dynamic> json) {
    return Attendance(
      attendanceId: json['attendance_id'],
      studentId: json['student_id'],
      subjectId: json['subject_id'],
      month: json['month'],
      year: json['year'],
      totalClasses: json['total_classes'],
      attendedClasses: json['attended_classes'],
      attendancePercentage: json['attendance_percentage'] != null
          ? (json['attendance_percentage'] as num).toDouble()
          : null,
    );
  }
}

class Activity {
  final int activityId;
  final String activityName;
  final String activityType;
  final String? level;
  final String activityDate;
  final String? description;

  Activity({
    required this.activityId,
    required this.activityName,
    required this.activityType,
    this.level,
    required this.activityDate,
    this.description,
  });

  factory Activity.fromJson(Map<String, dynamic> json) {
    return Activity(
      activityId: json['activity_id'],
      activityName: json['activity_name'],
      activityType: json['activity_type'],
      level: json['level'],
      activityDate: json['activity_date'],
      description: json['description'],
    );
  }
}

class ActivityParticipation {
  final int participationId;
  final int activityId;
  final int studentId;
  final String? role;
  final String? achievement;

  ActivityParticipation({
    required this.participationId,
    required this.activityId,
    required this.studentId,
    this.role,
    this.achievement,
  });

  factory ActivityParticipation.fromJson(Map<String, dynamic> json) {
    return ActivityParticipation(
      participationId: json['participation_id'],
      activityId: json['activity_id'],
      studentId: json['student_id'],
      role: json['role'],
      achievement: json['achievement'],
    );
  }
}

class RiskPrediction {
  final int predictionId;
  final int studentId;
  final String riskLevel;
  final double riskScore;
  final double? attendancePercentage;
  final double? internalAvg;
  final double? externalGpa;
  final int? activityCount;
  final int? backlogCount;
  final String? reasons;
  final String predictionDate;

  RiskPrediction({
    required this.predictionId,
    required this.studentId,
    required this.riskLevel,
    required this.riskScore,
    this.attendancePercentage,
    this.internalAvg,
    this.externalGpa,
    this.activityCount,
    this.backlogCount,
    this.reasons,
    required this.predictionDate,
  });

  factory RiskPrediction.fromJson(Map<String, dynamic> json) {
    return RiskPrediction(
      predictionId: json['prediction_id'],
      studentId: json['student_id'],
      riskLevel: json['risk_level'],
      riskScore: (json['risk_score'] as num).toDouble(),
      attendancePercentage: json['attendance_percentage'] != null
          ? (json['attendance_percentage'] as num).toDouble()
          : null,
      internalAvg: json['internal_avg'] != null
          ? (json['internal_avg'] as num).toDouble()
          : null,
      externalGpa: json['external_gpa'] != null
          ? (json['external_gpa'] as num).toDouble()
          : null,
      activityCount: json['activity_count'],
      backlogCount: json['backlog_count'],
      reasons: json['reasons'],
      predictionDate: json['prediction_date'],
    );
  }
}

class DashboardStats {
  final int totalStudents;
  final int totalActivities;
  final double avgAttendance;
  final int atRiskCount;
  final int highPerformers;

  DashboardStats({
    required this.totalStudents,
    required this.totalActivities,
    required this.avgAttendance,
    required this.atRiskCount,
    required this.highPerformers,
  });

  factory DashboardStats.fromJson(Map<String, dynamic> json) {
    return DashboardStats(
      totalStudents: json['total_students'],
      totalActivities: json['total_activities'],
      avgAttendance: (json['avg_attendance'] as num).toDouble(),
      atRiskCount: json['at_risk_count'],
      highPerformers: json['high_performers'],
    );
  }
}
