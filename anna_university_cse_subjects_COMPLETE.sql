
-- COMPLETE Anna University R2021 B.E CSE Subjects (Core + PEC + OEC)

CREATE TABLE subjects (
    id INT AUTO_INCREMENT PRIMARY KEY,
    semester VARCHAR(10),
    subject_code VARCHAR(15),
    subject_title VARCHAR(200),
    category VARCHAR(10),
    credits FLOAT
);

-- CORE SUBJECTS (SEM I - VIII)
INSERT INTO subjects VALUES
(NULL,'I','IP3151','Induction Programme','CORE',0),
(NULL,'I','HS3152','Professional English - I','CORE',3),
(NULL,'I','MA3151','Matrices and Calculus','CORE',4),
(NULL,'I','PH3151','Engineering Physics','CORE',3),
(NULL,'I','CY3151','Engineering Chemistry','CORE',3),
(NULL,'I','GE3151','Problem Solving and Python Programming','CORE',3),
(NULL,'I','GE3152','Heritage of Tamils','CORE',1),
(NULL,'I','GE3171','Problem Solving and Python Programming Laboratory','LAB',2),
(NULL,'I','BS3171','Physics and Chemistry Laboratory','LAB',2),
(NULL,'I','GE3172','English Laboratory','LAB',1),

(NULL,'II','HS3252','Professional English - II','CORE',2),
(NULL,'II','MA3251','Statistics and Numerical Methods','CORE',4),
(NULL,'II','PH3256','Physics for Information Science','CORE',3),
(NULL,'II','BE3251','Basic Electrical and Electronics Engineering','CORE',3),
(NULL,'II','GE3251','Engineering Graphics','CORE',4),
(NULL,'II','CS3251','Programming in C','CORE',3),
(NULL,'II','GE3252','Tamils and Technology','CORE',1),
(NULL,'II','GE3271','Engineering Practices Laboratory','LAB',2),
(NULL,'II','CS3271','Programming in C Laboratory','LAB',2),
(NULL,'II','GE3272','Communication Laboratory','LAB',2),

(NULL,'III','MA3354','Discrete Mathematics','CORE',4),
(NULL,'III','CS3351','Digital Principles and Computer Organization','CORE',4),
(NULL,'III','CS3352','Foundations of Data Science','CORE',3),
(NULL,'III','CS3301','Data Structures','CORE',3),
(NULL,'III','CS3391','Object Oriented Programming','CORE',3),
(NULL,'III','CS3311','Data Structures Laboratory','LAB',1.5),
(NULL,'III','CS3381','Object Oriented Programming Laboratory','LAB',1.5),
(NULL,'III','CS3361','Data Science Laboratory','LAB',2),
(NULL,'III','GE3361','Professional Development','EEC',1),

(NULL,'IV','CS3452','Theory of Computation','CORE',3),
(NULL,'IV','CS3491','Artificial Intelligence and Machine Learning','CORE',4),
(NULL,'IV','CS3492','Database Management Systems','CORE',3),
(NULL,'IV','CS3401','Algorithms','CORE',4),
(NULL,'IV','CS3451','Introduction to Operating Systems','CORE',3),
(NULL,'IV','GE3451','Environmental Sciences and Sustainability','CORE',2),
(NULL,'IV','CS3461','Operating Systems Laboratory','LAB',1.5),
(NULL,'IV','CS3481','Database Management Systems Laboratory','LAB',1.5),

(NULL,'V','CS3591','Computer Networks','CORE',4),
(NULL,'V','CS3501','Compiler Design','CORE',4),
(NULL,'V','CB3491','Cryptography and Cyber Security','CORE',3),
(NULL,'V','CS3551','Distributed Computing','CORE',3),

(NULL,'VI','CCS356','Object Oriented Software Engineering','CORE',4),
(NULL,'VI','CS3691','Embedded Systems and IoT','CORE',4),

(NULL,'VII','GE3791','Human Values and Ethics','CORE',2),
(NULL,'VII','CS3711','Summer Internship','EEC',2),

(NULL,'VIII','CS3811','Project Work / Internship','EEC',10);

-- PROFESSIONAL ELECTIVES (PEC)
INSERT INTO subjects VALUES
(NULL,'PEC','CCS346','Exploratory Data Analysis','PEC',3),
(NULL,'PEC','CCS360','Recommender Systems','PEC',3),
(NULL,'PEC','CCS355','Neural Networks and Deep Learning','PEC',3),
(NULL,'PEC','CCS369','Text and Speech Analysis','PEC',3),
(NULL,'PEC','CCS349','Image and Video Analytics','PEC',3),
(NULL,'PEC','CCS338','Computer Vision','PEC',3),
(NULL,'PEC','CCS334','Big Data Analytics','PEC',3),
(NULL,'PEC','CCS375','Web Technologies','PEC',3),
(NULL,'PEC','CCS332','App Development','PEC',3),
(NULL,'PEC','CCS370','UI and UX Design','PEC',3),
(NULL,'PEC','CCS366','Software Testing and Automation','PEC',3),
(NULL,'PEC','CCS342','DevOps','PEC',3),
(NULL,'PEC','CCS335','Cloud Computing','PEC',3),
(NULL,'PEC','CCS344','Ethical Hacking','PEC',3),
(NULL,'PEC','CCS351','Modern Cryptography','PEC',3);

-- OPEN ELECTIVES (OEC)
INSERT INTO subjects VALUES
(NULL,'OEC','OAS351','Space Science','OEC',3),
(NULL,'OEC','OIE351','Introduction to Industrial Engineering','OEC',3),
(NULL,'OEC','OBT351','Food, Nutrition and Health','OEC',3),
(NULL,'OEC','OCE351','Environmental and Social Impact Assessment','OEC',3),
(NULL,'OEC','OEE351','Renewable Energy Systems','OEC',3),
(NULL,'OEC','OMA351','Graph Theory','OEC',3),
(NULL,'OEC','OHS351','English for Competitive Examinations','OEC',3),
(NULL,'OEC','OMG352','NGOs and Sustainable Development','OEC',3),
(NULL,'OEC','AU3791','Electric and Hybrid Vehicles','OEC',3),
(NULL,'OEC','CRA332','Drone Technologies','OEC',3);
