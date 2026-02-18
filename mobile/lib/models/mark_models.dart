// New Mark model for the updated structure
class Mark {
  final int id;
  final String regNo;
  final String studentName;
  final int year;
  final String section;
  final int semester;
  final String subjectCode;
  final String subjectTitle;
  final double assignment1;
  final double assignment2;
  final double assignment3;
  final double assignment4;
  final double assignment5;
  final double slipTest1;
  final double slipTest2;
  final double slipTest3;
  final double slipTest4;
  final double cia1;
  final double cia2;
  final double model;
  final String? universityResultGrade;

  Mark({
    required this.id,
    required this.regNo,
    required this.studentName,
    required this.year,
    required this.section,
    required this.semester,
    required this.subjectCode,
    required this.subjectTitle,
    this.assignment1 = 0.0,
    this.assignment2 = 0.0,
    this.assignment3 = 0.0,
    this.assignment4 = 0.0,
    this.assignment5 = 0.0,
    this.slipTest1 = 0.0,
    this.slipTest2 = 0.0,
    this.slipTest3 = 0.0,
    this.slipTest4 = 0.0,
    this.cia1 = 0.0,
    this.cia2 = 0.0,
    this.model = 0.0,
    this.universityResultGrade,
  });

  factory Mark.fromJson(Map<String, dynamic> json) {
    return Mark(
      id: json['id'],
      regNo: json['reg_no'],
      studentName: json['student_name'],
      year: json['year'],
      section: json['section'],
      semester: json['semester'],
      subjectCode: json['subject_code'],
      subjectTitle: json['subject_title'],
      assignment1: (json['assignment_1'] as num?)?.toDouble() ?? 0.0,
      assignment2: (json['assignment_2'] as num?)?.toDouble() ?? 0.0,
      assignment3: (json['assignment_3'] as num?)?.toDouble() ?? 0.0,
      assignment4: (json['assignment_4'] as num?)?.toDouble() ?? 0.0,
      assignment5: (json['assignment_5'] as num?)?.toDouble() ?? 0.0,
      slipTest1: (json['slip_test_1'] as num?)?.toDouble() ?? 0.0,
      slipTest2: (json['slip_test_2'] as num?)?.toDouble() ?? 0.0,
      slipTest3: (json['slip_test_3'] as num?)?.toDouble() ?? 0.0,
      slipTest4: (json['slip_test_4'] as num?)?.toDouble() ?? 0.0,
      cia1: (json['cia_1'] as num?)?.toDouble() ?? 0.0,
      cia2: (json['cia_2'] as num?)?.toDouble() ?? 0.0,
      model: (json['model'] as num?)?.toDouble() ?? 0.0,
      universityResultGrade: json['university_result_grade'],
    );
  }
}

class MarkCreate {
  final String regNo;
  final String studentName;
  final String dept; // Added dept
  final int year;
  final String section;
  final int semester;
  final String subjectCode;
  final String subjectTitle;
  final double assignment1;
  final double assignment2;
  final double assignment3;
  final double assignment4;
  final double assignment5;
  final double slipTest1;
  final double slipTest2;
  final double slipTest3;
  final double slipTest4;
  final double cia1;
  final double cia2;
  final double model;
  final String? universityResultGrade;

  MarkCreate({
    required this.regNo,
    required this.studentName,
    required this.dept, // Added dept
    required this.year,
    required this.section,
    required this.semester,
    required this.subjectCode,
    required this.subjectTitle,
    this.assignment1 = 0.0,
    this.assignment2 = 0.0,
    this.assignment3 = 0.0,
    this.assignment4 = 0.0,
    this.assignment5 = 0.0,
    this.slipTest1 = 0.0,
    this.slipTest2 = 0.0,
    this.slipTest3 = 0.0,
    this.slipTest4 = 0.0,
    this.cia1 = 0.0,
    this.cia2 = 0.0,
    this.model = 0.0,
    this.universityResultGrade,
  });

  Map<String, dynamic> toJson() {
    return {
      'reg_no': regNo,
      'student_name': studentName,
      'dept': dept, // Added dept
      'year': year,
      'section': section,
      'semester': semester,
      'subject_code': subjectCode,
      'subject_title': subjectTitle,
      'assignment_1': assignment1,
      'assignment_2': assignment2,
      'assignment_3': assignment3,
      'assignment_4': assignment4,
      'assignment_5': assignment5,
      'slip_test_1': slipTest1,
      'slip_test_2': slipTest2,
      'slip_test_3': slipTest3,
      'slip_test_4': slipTest4,
      'cia_1': cia1,
      'cia_2': cia2,
      'model': model,
      'university_result_grade': universityResultGrade,
    };
  }
}

// Subject Input for subject selection
class SubjectInput {
  final String subjectCode;
  final String subjectTitle;

  SubjectInput({
    required this.subjectCode,
    required this.subjectTitle,
  });

  Map<String, dynamic> toJson() {
    return {
      'subject_code': subjectCode,
      'subject_title': subjectTitle,
    };
  }
}
