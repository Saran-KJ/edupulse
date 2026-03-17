
-- Anna University R2021 B.E CSE Subjects

CREATE TABLE subjects (
    id INT AUTO_INCREMENT PRIMARY KEY,
    semester VARCHAR(10),
    subject_code VARCHAR(15),
    subject_title VARCHAR(200),
    credits FLOAT
);

-- SEMESTER I
INSERT INTO subjects (semester, subject_code, subject_title, credits) VALUES
('I','IP3151','Induction Programme',0),
('I','HS3152','Professional English - I',3),
('I','MA3151','Matrices and Calculus',4),
('I','PH3151','Engineering Physics',3),
('I','CY3151','Engineering Chemistry',3),
('I','GE3151','Problem Solving and Python Programming',3),
('I','GE3152','Heritage of Tamils',1),
('I','GE3171','Problem Solving and Python Programming Laboratory',2),
('I','BS3171','Physics and Chemistry Laboratory',2),
('I','GE3172','English Laboratory',1);

-- SEMESTER II
INSERT INTO subjects VALUES
(NULL,'II','HS3252','Professional English - II',2),
(NULL,'II','MA3251','Statistics and Numerical Methods',4),
(NULL,'II','PH3256','Physics for Information Science',3),
(NULL,'II','BE3251','Basic Electrical and Electronics Engineering',3),
(NULL,'II','GE3251','Engineering Graphics',4),
(NULL,'II','CS3251','Programming in C',3),
(NULL,'II','GE3252','Tamils and Technology',1),
(NULL,'II','GE3271','Engineering Practices Laboratory',2),
(NULL,'II','CS3271','Programming in C Laboratory',2),
(NULL,'II','GE3272','Communication Laboratory',2);

-- SEMESTER III
INSERT INTO subjects VALUES
(NULL,'III','MA3354','Discrete Mathematics',4),
(NULL,'III','CS3351','Digital Principles and Computer Organization',4),
(NULL,'III','CS3352','Foundations of Data Science',3),
(NULL,'III','CS3301','Data Structures',3),
(NULL,'III','CS3391','Object Oriented Programming',3),
(NULL,'III','CS3311','Data Structures Laboratory',1.5),
(NULL,'III','CS3381','Object Oriented Programming Laboratory',1.5),
(NULL,'III','CS3361','Data Science Laboratory',2),
(NULL,'III','GE3361','Professional Development',1);

-- SEMESTER IV
INSERT INTO subjects VALUES
(NULL,'IV','CS3452','Theory of Computation',3),
(NULL,'IV','CS3491','Artificial Intelligence and Machine Learning',4),
(NULL,'IV','CS3492','Database Management Systems',3),
(NULL,'IV','CS3401','Algorithms',4),
(NULL,'IV','CS3451','Introduction to Operating Systems',3),
(NULL,'IV','GE3451','Environmental Sciences and Sustainability',2),
(NULL,'IV','CS3461','Operating Systems Laboratory',1.5),
(NULL,'IV','CS3481','Database Management Systems Laboratory',1.5);

-- SEMESTER V
INSERT INTO subjects VALUES
(NULL,'V','CS3591','Computer Networks',4),
(NULL,'V','CS3501','Compiler Design',4),
(NULL,'V','CB3491','Cryptography and Cyber Security',3),
(NULL,'V','CS3551','Distributed Computing',3),
(NULL,'V','PEC','Professional Elective I',3),
(NULL,'V','PEC','Professional Elective II',3);

-- SEMESTER VI
INSERT INTO subjects VALUES
(NULL,'VI','CCS356','Object Oriented Software Engineering',4),
(NULL,'VI','CS3691','Embedded Systems and IoT',4),
(NULL,'VI','OEC','Open Elective - I',3),
(NULL,'VI','PEC','Professional Elective III',3),
(NULL,'VI','PEC','Professional Elective IV',3);

-- SEMESTER VII
INSERT INTO subjects VALUES
(NULL,'VII','GE3791','Human Values and Ethics',2),
(NULL,'VII','OEC','Open Elective - II',3),
(NULL,'VII','OEC','Open Elective - III',3),
(NULL,'VII','OEC','Open Elective - IV',3),
(NULL,'VII','CS3711','Summer Internship',2);

-- SEMESTER VIII
INSERT INTO subjects VALUES
(NULL,'VIII','CS3811','Project Work / Internship',10);
