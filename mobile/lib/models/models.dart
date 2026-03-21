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
  // Parent-specific fields
  final String? childName;
  final String? childPhone;
  final String? occupation;

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
    this.childName,
    this.childPhone,
    this.occupation,
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
      childName: json['child_name'],
      childPhone: json['child_phone'],
      occupation: json['occupation'],
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
      'child_name': childName,
      'child_phone': childPhone,
      'occupation': occupation,
    };
  }
}

class Student {
  final int studentId;
  final String regNo;
  final String name;
  final String? email;
  final String? phone;
  final String dept; // Changed from deptId
  final int year;
  final int semester;
  final String? section;
  final String? dob;
  final String? address;

  Student({
    required this.studentId,
    required this.regNo,
    required this.name,
    this.email,
    this.phone,
    required this.dept,
    required this.year,
    required this.semester,
    this.section,
    this.dob,
    this.address,
  });

  factory Student.fromJson(Map<String, dynamic> json) {
    return Student(
      studentId: json['student_id'] ?? 0, // Handle potential missing ID if not returned
      regNo: json['reg_no'],
      name: json['name'],
      email: json['email'],
      phone: json['phone'],
      dept: json['dept'], // Changed from dept_id
      year: json['year'],
      semester: json['semester'],
      section: json['section'],
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
      'dept': dept,
      'year': year,
      'semester': semester,
      'section': section,
      'dob': dob,
      'address': address,
    };
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
  final String regNo; // Changed from studentId
  final String? role;
  final String? achievement;
  final Activity? activity;

  ActivityParticipation({
    required this.participationId,
    required this.activityId,
    required this.regNo,
    this.role,
    this.achievement,
    this.activity,
  });

  factory ActivityParticipation.fromJson(Map<String, dynamic> json) {
    return ActivityParticipation(
      participationId: json['participation_id'],
      activityId: json['activity_id'],
      regNo: json['reg_no'], // Changed from student_id
      role: json['role'],
      achievement: json['achievement'],
      activity: json['activity'] != null ? Activity.fromJson(json['activity']) : null,
    );
  }
}

class RiskPrediction {
  final int predictionId;
  final String regNo; // Changed from studentId
  final String riskLevel;
  final double riskScore;
  final double? attendancePercentage;
  final double? internalAvg;
  final double? externalGpa;
  final int? activityCount;
  final int? backlogCount;
  final String? learningPathPreference;
  final String? reasons;
  final String predictionDate;

  RiskPrediction({
    required this.predictionId,
    required this.regNo,
    required this.riskLevel,
    required this.riskScore,
    this.attendancePercentage,
    this.internalAvg,
    this.externalGpa,
    this.activityCount,
    this.backlogCount,
    this.learningPathPreference,
    this.reasons,
    required this.predictionDate,
  });

  factory RiskPrediction.fromJson(Map<String, dynamic> json) {
    return RiskPrediction(
      predictionId: json['prediction_id'],
      regNo: json['reg_no'],
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
      learningPathPreference: json['learning_path_preference'],
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

// Mark Entry Models

class StudentActivitySubmission {
  final int id;
  final String regNo;
  final String activityName;
  final String activityType;
  final String? level;
  final String activityDate;
  final String? description;
  final String? role;
  final String? achievement;
  final String dept;
  final int year;
  final String section;
  final String status;
  final String? reviewComment;
  final String createdAt;
  final String updatedAt;

  StudentActivitySubmission({
    required this.id,
    required this.regNo,
    required this.activityName,
    required this.activityType,
    this.level,
    required this.activityDate,
    this.description,
    this.role,
    this.achievement,
    required this.dept,
    required this.year,
    required this.section,
    required this.status,
    this.reviewComment,
    required this.createdAt,
    required this.updatedAt,
  });

  factory StudentActivitySubmission.fromJson(Map<String, dynamic> json) {
    return StudentActivitySubmission(
      id: json['id'],
      regNo: json['reg_no'],
      activityName: json['activity_name'],
      activityType: json['activity_type'],
      level: json['level'],
      activityDate: json['activity_date'],
      description: json['description'],
      role: json['role'],
      achievement: json['achievement'],
      dept: json['dept'],
      year: json['year'],
      section: json['section'],
      status: json['status'],
      reviewComment: json['review_comment'],
      createdAt: json['created_at'],
      updatedAt: json['updated_at'],
    );
  }
}

class FacultyAllocation {
  final int id;
  final String dept;
  final int year;
  final String section;
  final String subjectCode;
  final String subjectTitle;
  final int facultyId;
  final String facultyName;

  FacultyAllocation({
    required this.id,
    required this.dept,
    required this.year,
    required this.section,
    required this.subjectCode,
    required this.subjectTitle,
    required this.facultyId,
    required this.facultyName,
  });

  factory FacultyAllocation.fromJson(Map<String, dynamic> json) {
    return FacultyAllocation(
      id: json['id'],
      dept: json['dept'],
      year: json['year'],
      section: json['section'],
      subjectCode: json['subject_code'],
      subjectTitle: json['subject_title'],
      facultyId: json['faculty_id'],
      facultyName: json['faculty_name'],
    );
  }
}

class LearningResource {
  final int resourceId;
  final String title;
  final String? description;
  final String url;
  final String type;
  final String? tags;
  final String? dept;
  final String? minRiskLevel;
  final String? unit;
  final String? resourceLevel;
  final String? skillCategory;
  final String? language;
  final String? content;  // self-written in-app content (JSON)
  final bool isPreferredType;
  bool isCompleted;

  LearningResource({
    required this.resourceId,
    required this.title,
    this.description,
    required this.url,
    required this.type,
    this.tags,
    this.dept,
    this.minRiskLevel,
    this.unit,
    this.resourceLevel,
    this.skillCategory,
    this.language,
    this.content,
    this.isPreferredType = false,
    this.isCompleted = false,
  });

  factory LearningResource.fromJson(Map<String, dynamic> json) {
    return LearningResource(
      resourceId: json['resource_id'],
      title: json['title'],
      description: json['description'],
      url: json['url'],
      type: json['type'],
      tags: json['tags'],
      dept: json['dept'],
      minRiskLevel: json['min_risk_level'],
      unit: json['unit'],
      resourceLevel: json['resource_level'],
      skillCategory: json['skill_category'],
      language: json['language'],
      content: json['content'],
      isPreferredType: json['is_preferred_type'] ?? false,
      isCompleted: json['is_completed'] ?? false,
    );
  }
}

class PersonalizedLearningPlan {
  final int? id;
  final String? regNo;
  final String subjectCode;
  final String riskLevel;
  final String focusType;
  final String? units;
  final String? skillCategory;
  final String? resourceLevel;
  final String? latestAssessment;
  final Map<String, dynamic>? practiceSchedule;
  final Map<String, dynamic>? weeklyGoals;
  final bool pendingChoice;
  final List<String>? availableSkills;

  PersonalizedLearningPlan({
    this.id,
    this.regNo,
    required this.subjectCode,
    required this.riskLevel,
    required this.focusType,
    this.units,
    this.skillCategory,
    this.resourceLevel,
    this.latestAssessment,
    this.practiceSchedule,
    this.weeklyGoals,
    this.pendingChoice = false,
    this.availableSkills,
  });

  factory PersonalizedLearningPlan.fromJson(Map<String, dynamic> json) {
    return PersonalizedLearningPlan(
      id: json['id'],
      regNo: json['reg_no'],
      subjectCode: json['subject_code'] ?? '',
      riskLevel: json['risk_level'] ?? 'Low',
      focusType: json['focus_type'] ?? '',
      units: json['units'],
      skillCategory: json['skill_category'],
      resourceLevel: json['resource_level'],
      latestAssessment: json['latest_assessment'],
      practiceSchedule: json['practice_schedule'] is Map ? json['practice_schedule'] : null,
      weeklyGoals: json['weekly_goals'] is Map ? json['weekly_goals'] : null,
      pendingChoice: json['pending_choice'] ?? false,
      availableSkills: json['available_skills'] != null
          ? List<String>.from(json['available_skills'])
          : null,
    );
  }
}

class SubjectLearningStatus {
  final String subjectCode;
  final String subjectTitle;
  final String riskLevel;
  final String focusType;
  final double progressPercentage;
  final Map<String, dynamic>? practiceSchedule;
  final Map<String, dynamic>? weeklyGoals;

  SubjectLearningStatus({
    required this.subjectCode,
    required this.subjectTitle,
    required this.riskLevel,
    required this.focusType,
    this.progressPercentage = 0.0,
    this.practiceSchedule,
    this.weeklyGoals,
  });

  factory SubjectLearningStatus.fromJson(Map<String, dynamic> json) {
    return SubjectLearningStatus(
      subjectCode: json['subject_code'] ?? '',
      subjectTitle: json['subject_title'] ?? '',
      riskLevel: json['risk_level'] ?? 'Low',
      focusType: json['focus_type'] ?? '',
      progressPercentage: (json['progress_percentage'] as num?)?.toDouble() ?? 0.0,
      practiceSchedule: json['practice_schedule'] is Map ? json['practice_schedule'] : null,
      weeklyGoals: json['weekly_goals'] is Map ? json['weekly_goals'] : null,
    );
  }
}

class OverallLearningView {
  final String overallRisk;
  final List<SubjectLearningStatus> prioritySubjects;
  final Map<String, dynamic> studyStrategy;
  final double totalProgress;
  final String preferredLearningType;

  OverallLearningView({
    required this.overallRisk,
    required this.prioritySubjects,
    required this.studyStrategy,
    required this.totalProgress,
    required this.preferredLearningType,
  });

  factory OverallLearningView.fromJson(Map<String, dynamic> json) {
    return OverallLearningView(
      overallRisk: json['overall_risk'] ?? 'Unknown',
      prioritySubjects: (json['priority_subjects'] as List? ?? [])
          .map((s) => SubjectLearningStatus.fromJson(s))
          .toList(),
      studyStrategy: json['study_strategy'] is Map<String, dynamic> ? json['study_strategy'] : {},
      totalProgress: (json['total_progress'] as num?)?.toDouble() ?? 0.0,
      preferredLearningType: json['preferred_learning_type'] ?? 'text',
    );
  }
}

class StudentLearningStatusItem {
  final String regNo;
  final String studentName;
  final String overallRisk;
  final int highRiskCount;
  final int mediumRiskCount;
  final int lowRiskCount;
  final double overallProgress;
  final List<SubjectLearningStatus> subjects;

  StudentLearningStatusItem({
    required this.regNo,
    required this.studentName,
    required this.overallRisk,
    required this.highRiskCount,
    required this.mediumRiskCount,
    required this.lowRiskCount,
    required this.overallProgress,
    required this.subjects,
  });

  factory StudentLearningStatusItem.fromJson(Map<String, dynamic> json) {
    return StudentLearningStatusItem(
      regNo: json['reg_no'] ?? '',
      studentName: json['student_name'] ?? '',
      overallRisk: json['overall_risk'] ?? 'Low',
      highRiskCount: json['high_risk_count'] ?? 0,
      mediumRiskCount: json['medium_risk_count'] ?? 0,
      lowRiskCount: json['low_risk_count'] ?? 0,
      overallProgress: (json['overall_progress'] as num?)?.toDouble() ?? 0.0,
      subjects: (json['subjects'] as List? ?? [])
          .map((s) => SubjectLearningStatus.fromJson(s))
          .toList(),
    );
  }
}

class HighRiskAlert {
  final String regNo;
  final String studentName;
  final String dept;
  final int year;
  final String section;
  final List<String> highRiskSubjects;
  final String alertSeverity;
  final List<String> recommendedActions;

  HighRiskAlert({
    required this.regNo,
    required this.studentName,
    required this.dept,
    required this.year,
    required this.section,
    required this.highRiskSubjects,
    required this.alertSeverity,
    required this.recommendedActions,
  });

  factory HighRiskAlert.fromJson(Map<String, dynamic> json) {
    return HighRiskAlert(
      regNo: json['reg_no'] ?? '',
      studentName: json['student_name'] ?? '',
      dept: json['dept'] ?? '',
      year: json['year'] ?? 0,
      section: json['section'] ?? '',
      highRiskSubjects: List<String>.from(json['high_risk_subjects'] ?? []),
      alertSeverity: json['alert_severity'] ?? 'warning',
      recommendedActions: List<String>.from(json['recommended_actions'] ?? []),
    );
  }
}

class QuizQuestion {
  final int id;
  final String question;
  final String optionA;
  final String optionB;
  final String optionC;
  final String optionD;
  final String correctAnswer;
  final String difficultyLevel;

  QuizQuestion({
    required this.id,
    required this.question,
    required this.optionA,
    required this.optionB,
    required this.optionC,
    required this.optionD,
    required this.correctAnswer,
    required this.difficultyLevel,
  });

  factory QuizQuestion.fromJson(Map<String, dynamic> json) {
    return QuizQuestion(
      id: json['id'],
      question: json['question'],
      optionA: json['option_a'],
      optionB: json['option_b'],
      optionC: json['option_c'],
      optionD: json['option_d'],
      correctAnswer: json['correct_answer'],
      difficultyLevel: json['difficulty_level'],
    );
  }
}

class QuizAttemptSubmission {
  final String subject;
  final int unit;
  final String riskLevel;
  final Map<String, String> answers; // question_id -> selected_option

  final int? scheduledQuizId;

  QuizAttemptSubmission({
    required this.subject,
    required this.unit,
    required this.riskLevel,
    required this.answers,
    this.scheduledQuizId,
  });

  Map<String, dynamic> toJson() {
    return {
      'subject': subject,
      'unit': unit,
      'risk_level': riskLevel,
      'answers': answers,
      'scheduled_quiz_id': scheduledQuizId,
    };
  }
}
