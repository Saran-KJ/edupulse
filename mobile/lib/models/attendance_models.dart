class Attendance {
  final int id;
  final String regNo;
  final String studentName;
  final String date;
  final int period;
  final String? subjectCode;
  final String status;
  final int year;
  final String section;
  final String? reason;

  Attendance({
    required this.id,
    required this.regNo,
    required this.studentName,
    required this.date,
    required this.period,
    this.subjectCode,
    required this.status,
    required this.year,
    required this.section,
    this.reason,
  });

  factory Attendance.fromJson(Map<String, dynamic> json) {
    return Attendance(
      id: json['id'],
      regNo: json['reg_no'],
      studentName: json['student_name'],
      date: json['date'],
      period: json['period'] ?? 1,
      subjectCode: json['subject_code'],
      status: json['status'],
      year: json['year'],
      section: json['section'],
      reason: json['reason'],
    );
  }
}

class AttendanceInput {
  final String regNo;
  final String studentName;
  final String status;
  final String? reason;

  AttendanceInput({
    required this.regNo,
    required this.studentName,
    required this.status,
    this.reason,
  });

  Map<String, dynamic> toJson() {
    return {
      'reg_no': regNo,
      'student_name': studentName,
      'status': status,
      'reason': reason,
    };
  }
}
