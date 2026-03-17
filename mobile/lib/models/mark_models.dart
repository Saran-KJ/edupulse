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
  final int? assignment1;
  final int? assignment2;
  final int? assignment3;
  final int? assignment4;
  final int? assignment5;
  final int? slipTest1;
  final int? slipTest2;
  final int? slipTest3;
  final int? slipTest4;
  final int? cia1;
  final int? cia2;
  final int? model;
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
    this.assignment1,
    this.assignment2,
    this.assignment3,
    this.assignment4,
    this.assignment5,
    this.slipTest1,
    this.slipTest2,
    this.slipTest3,
    this.slipTest4,
    this.cia1,
    this.cia2,
    this.model,
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
      assignment1: (json['assignment_1'] as num?)?.toInt(),
      assignment2: (json['assignment_2'] as num?)?.toInt(),
      assignment3: (json['assignment_3'] as num?)?.toInt(),
      assignment4: (json['assignment_4'] as num?)?.toInt(),
      assignment5: (json['assignment_5'] as num?)?.toInt(),
      slipTest1: (json['slip_test_1'] as num?)?.toInt(),
      slipTest2: (json['slip_test_2'] as num?)?.toInt(),
      slipTest3: (json['slip_test_3'] as num?)?.toInt(),
      slipTest4: (json['slip_test_4'] as num?)?.toInt(),
      cia1: (json['cia_1'] as num?)?.toInt(),
      cia2: (json['cia_2'] as num?)?.toInt(),
      model: (json['model'] as num?)?.toInt(),
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
  final int? assignment1;
  final int? assignment2;
  final int? assignment3;
  final int? assignment4;
  final int? assignment5;
  final int? slipTest1;
  final int? slipTest2;
  final int? slipTest3;
  final int? slipTest4;
  final int? cia1;
  final int? cia2;
  final int? model;
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
    this.assignment1,
    this.assignment2,
    this.assignment3,
    this.assignment4,
    this.assignment5,
    this.slipTest1,
    this.slipTest2,
    this.slipTest3,
    this.slipTest4,
    this.cia1,
    this.cia2,
    this.model,
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
