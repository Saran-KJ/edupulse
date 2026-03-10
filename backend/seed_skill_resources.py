"""
Seed skill development resources with full self-written in-app content.
No external URLs — content is built into the app.
Each resource has: sections (learning content) + quiz questions + progress tracking.
"""
import json
from sqlalchemy.orm import Session
from database import SessionLocal, engine
from models import LearningResource, StudentLearningProgress, Base

# ─── Helper to build a resource content blob ─────────────────────────────────

def make_content(sections: list, quiz: list) -> str:
    """
    sections: [{"title": str, "body": str}, ...]
    quiz: [{"question": str, "options": [str,str,str,str], "answer": int (0-indexed)}, ...]
    """
    return json.dumps({"sections": sections, "quiz": quiz}, ensure_ascii=False)

# ═════════════════════════════════════════════════════════════════════════════
#  COMMUNICATION  (3 topics, each with quiz)
# ═════════════════════════════════════════════════════════════════════════════

comm_verbal = make_content(
    sections=[
        {"title": "What is Verbal Communication?",
         "body": "Verbal communication is the use of spoken words to share information, ideas, and feelings. It is one of the most powerful tools in both academic and professional environments.\n\n✅ Key elements:\n• Clarity — Speak clearly so the listener can understand easily.\n• Tone — Adjust your tone to suit the situation (formal vs informal).\n• Pace — Speak at a moderate speed; too fast causes confusion.\n• Volume — Be audible — not too loud, not too soft.\n• Vocabulary — Use words appropriate to your audience."},
        {"title": "Tips for Effective Speaking",
         "body": "1. Think before you speak — organise your thoughts.\n2. Use simple, direct sentences.\n3. Make eye contact to show confidence.\n4. Pause between ideas to let the listener absorb.\n5. Avoid filler words like 'um', 'uh', 'like'.\n6. Summarise key points at the end."},
        {"title": "Common Mistakes to Avoid",
         "body": "❌ Speaking too fast — listeners miss key information.\n❌ Mumbling — reduces clarity.\n❌ Using jargon in mixed audiences — confuses non-experts.\n❌ Interrupting the listener — shows disrespect.\n❌ Lack of structure — jumping between topics randomly."},
        {"title": "Practice Exercise",
         "body": "📝 Exercise: Stand in front of a mirror and speak about your daily routine for 2 minutes. Focus on:\n• Keeping a steady pace.\n• Looking at yourself (as if making eye contact).\n• Using complete sentences.\n\nRepeat until you feel confident and natural."},
    ],
    quiz=[
        {"question": "Which of the following is NOT a key element of verbal communication?",
         "options": ["Clarity", "Tone", "Font Size", "Pace"],
         "answer": 2},
        {"question": "Filler words like 'um' and 'uh' should be:",
         "options": ["Used frequently to sound natural", "Avoided as much as possible", "Only used in formal settings", "Used at the beginning of sentences"],
         "answer": 1},
        {"question": "What does 'pace' refer to in verbal communication?",
         "options": ["The loudness of your voice", "The speed at which you speak", "The vocabulary you choose", "The tone of your message"],
         "answer": 1},
        {"question": "Why is eye contact important when speaking?",
         "options": ["It makes the listener uncomfortable", "It shows confidence and engagement", "It is only needed in interviews", "It replaces verbal content"],
         "answer": 1},
        {"question": "What is the best way to handle a complex topic verbally?",
         "options": ["Rush through it quickly", "Use as many technical words as possible", "Break it into simple, structured points", "Avoid discussing it"],
         "answer": 2},
    ]
)

comm_body_language = make_content(
    sections=[
        {"title": "Understanding Body Language",
         "body": "Body language refers to non-verbal signals — gestures, posture, facial expressions, and eye contact — that communicate your attitude and emotions without words.\n\n🔑 Studies show that up to 55% of communication is non-verbal. This means how you stand, look, and gesture matters as much as what you say."},
        {"title": "Positive Body Language Signals",
         "body": "✅ Open posture — face the person squarely, uncross arms.\n✅ Nodding — shows you are listening and agreeing.\n✅ Eye contact — shows confidence and interest.\n✅ Genuine smile — builds rapport and trust.\n✅ Leaning slightly forward — signals engagement.\n✅ Firm handshake — conveys confidence in professional settings."},
        {"title": "Negative Body Language to Avoid",
         "body": "❌ Crossed arms — appears defensive or closed-off.\n❌ Avoiding eye contact — seems untrustworthy or disinterested.\n❌ Slouching — signals low confidence.\n❌ Fidgeting — distracts the listener and shows nervousness.\n❌ Checking phone while someone speaks — disrespectful.\n❌ Invading personal space — makes others uncomfortable."},
        {"title": "Applying Body Language in Interviews",
         "body": "In job or college interviews:\n1. Sit upright with feet flat on the ground.\n2. Maintain natural, steady eye contact.\n3. Smile when appropriate (at introduction, after answering well).\n4. Keep hands visible and relaxed on the table.\n5. Avoid touching your face — can signal anxiety.\n6. Mirror the interviewer's body language subtly — builds rapport."},
    ],
    quiz=[
        {"question": "Approximately what percentage of communication is non-verbal?",
         "options": ["10%", "25%", "55%", "80%"],
         "answer": 2},
        {"question": "Crossing your arms during a conversation usually signals:",
         "options": ["Openness", "Confidence", "Defensiveness", "Excitement"],
         "answer": 2},
        {"question": "Which of these is a POSITIVE body language signal?",
         "options": ["Fidgeting", "Slouching", "Nodding while listening", "Checking your phone"],
         "answer": 2},
        {"question": "In an interview, where should your hands ideally be?",
         "options": ["In your pockets", "Visible and relaxed on the table", "Behind your back", "Constantly gesturing"],
         "answer": 1},
        {"question": "Mirroring the interviewer's body language subtly helps to:",
         "options": ["Copy them exactly", "Build rapport", "Show dominance", "Avoid conversation"],
         "answer": 1},
    ]
)

comm_writing = make_content(
    sections=[
        {"title": "Email Writing Fundamentals",
         "body": "Professional emails must be clear, concise, and courteous.\n\n📧 Structure of a good email:\n1. Subject Line — Short and specific. E.g., 'Request for Leave – 4 March'\n2. Greeting — 'Dear Sir/Madam,' or 'Dear [Name],'\n3. Opening — State your purpose in the first line.\n4. Body — Explain the details in 2–3 short paragraphs.\n5. Closing — 'Regards,' / 'Yours sincerely,' / 'Thank you,'\n6. Signature — Your full name, department, roll number."},
        {"title": "Technical Report Writing",
         "body": "A technical report communicates findings or project results clearly.\n\n📄 Structure:\n1. Title Page — Title, author, date.\n2. Abstract — 100–150 word summary of what was done and found.\n3. Introduction — Background and objective.\n4. Methodology — How was it done? Steps taken.\n5. Results — Findings with data/diagrams.\n6. Conclusion — What the results mean.\n7. References — Sources cited.\n\n✅ Tips:\n• Use numbered headings.\n• Write in passive voice for formal tone: 'The experiment was conducted…'\n• Avoid contractions (don't → do not).\n• Keep sentences short (under 20 words each)."},
        {"title": "Common Writing Mistakes",
         "body": "❌ Spelling and grammar errors — always proofread.\n❌ Vague subjects: 'This shows that…' — Specify what 'this' is.\n❌ Overly long sentences — break them into shorter ones.\n❌ Informal language in professional emails — avoid slang.\n❌ Missing subject line in emails — always include one.\n❌ Burying the main point — state your purpose early."},
        {"title": "Practice Task",
         "body": "📝 Write a short email (80–100 words) to your class advisor requesting a one-day leave for a family function. Include:\n• Proper subject line\n• Formal greeting\n• Clear reason for leave\n• Mention of completing missed work\n• Polite closing\n\nExample subject: 'Request for One-Day Leave – 5 March 2026'"},
    ],
    quiz=[
        {"question": "What should a professional email subject line be?",
         "options": ["Long and descriptive", "Short and specific", "Optional — can be left blank", "Written in all capitals"],
         "answer": 1},
        {"question": "In a technical report, the Abstract should be:",
         "options": ["500 words or more", "A detailed methodology", "A 100–150 word summary", "The same as the Introduction"],
         "answer": 2},
        {"question": "Which closing is appropriate for a formal email?",
         "options": ["Cheers!", "Later!", "Regards,", "TTYL,"],
         "answer": 2},
        {"question": "Which writing style is preferred in technical reports?",
         "options": ["First person active voice", "Second person voice", "Passive voice for formal tone", "Casual conversational tone"],
         "answer": 2},
        {"question": "What is the FIRST thing your email body should do?",
         "options": ["Explain the full story from the beginning", "State your purpose clearly", "Write a long greeting", "List all attachments"],
         "answer": 1},
    ]
)

# ═════════════════════════════════════════════════════════════════════════════
# PROGRAMMING — Python track (Basic / Intermediate / Advanced)
# ═════════════════════════════════════════════════════════════════════════════

prog_basic = make_content(
    sections=[
        {"title": "Why Learn Programming?",
         "body": "Programming is the skill of instructing a computer to perform tasks. It is at the heart of software, websites, apps, AI, and data science.\n\n🎯 Why Python?\n• Simple English-like syntax — easy to learn.\n• Widely used in AI, data science, web dev, automation.\n• Huge community and free resources.\n• Used in placement exams (AMCAT, CoCubes, etc.)."},
        {"title": "Python Basics — Variables and Data Types",
         "body": "A variable stores a value. In Python, you do not declare types.\n\n```python\nname = \"Arun\"       # String\nage = 21            # Integer\ncgpa = 8.5          # Float\nis_student = True   # Boolean\n```\n\n🔑 Rules for variable names:\n• No spaces (use underscore: my_name)\n• Cannot start with a number\n• Case-sensitive (Age ≠ age)"},
        {"title": "Input, Output and Operators",
         "body": "```python\n# Output\nprint(\"Hello, World!\")\n\n# Input\nname = input(\"Enter your name: \")\nprint(\"Hello,\", name)\n\n# Arithmetic Operators\nprint(10 + 3)   # Addition → 13\nprint(10 - 3)   # Subtraction → 7\nprint(10 * 3)   # Multiplication → 30\nprint(10 / 3)   # Division → 3.33\nprint(10 // 3)  # Floor division → 3\nprint(10 % 3)   # Modulus (remainder) → 1\nprint(10 ** 2)  # Power → 100\n```"},
        {"title": "Conditional Statements",
         "body": "```python\nmarks = int(input(\"Enter your marks: \"))\n\nif marks >= 90:\n    print(\"Grade: O\")\nelif marks >= 80:\n    print(\"Grade: A+\")\nelif marks >= 70:\n    print(\"Grade: A\")\nelif marks >= 60:\n    print(\"Grade: B+\")\nelse:\n    print(\"Grade: B\")\n```"},
        {"title": "Mini Task 1 — Simple Calculator",
         "body": "📝 Task: Write a Python program that:\n1. Asks the user for two numbers.\n2. Asks which operation to perform (+, -, *, /).\n3. Prints the result.\n\nExample output:\n```\nEnter first number: 10\nEnter second number: 5\nOperation (+/-/*/÷): *\nResult: 50\n```\n\nTip: Use if-elif-else to check the operation."},
    ],
    quiz=[
        {"question": "What is the output of: print(10 % 3)?",
         "options": ["3", "1", "0", "3.33"],
         "answer": 1},
        {"question": "Which of these is a valid Python variable name?",
         "options": ["2name", "my-name", "my_name", "my name"],
         "answer": 2},
        {"question": "What does input() do in Python?",
         "options": ["Prints a value", "Takes input from the user as a string", "Performs a calculation", "Converts data types"],
         "answer": 1},
        {"question": "What is the result of 10 // 3 in Python?",
         "options": ["3.33", "3", "1", "0"],
         "answer": 1},
        {"question": "Which keyword is used for alternative conditions in Python?",
         "options": ["else if", "elif", "elseif", "or"],
         "answer": 1},
    ]
)

prog_intermediate = make_content(
    sections=[
        {"title": "Loops — for and while",
         "body": "```python\n# for loop — iterate over a sequence\nfor i in range(1, 6):\n    print(i)  # prints 1 to 5\n\n# while loop — repeat while condition is true\ncount = 1\nwhile count <= 5:\n    print(count)\n    count += 1\n\n# Loop over a list\nfruits = [\"apple\", \"banana\", \"mango\"]\nfor fruit in fruits:\n    print(fruit)\n```"},
        {"title": "Functions",
         "body": "Functions avoid repetition and make code reusable.\n\n```python\ndef greet(name):\n    print(\"Hello,\", name)\n\ngreet(\"Arun\")  # → Hello, Arun\ngreet(\"Priya\") # → Hello, Priya\n\n# Function with return value\ndef add(a, b):\n    return a + b\n\nresult = add(5, 3)\nprint(result)  # → 8\n```"},
        {"title": "Lists and Dictionaries",
         "body": "```python\n# List — ordered, mutable\nstudents = [\"Alice\", \"Bob\", \"Charlie\"]\nstudents.append(\"Diana\")   # Add\nstudents.remove(\"Bob\")     # Remove\nprint(students[0])          # → Alice (indexing)\n\n# Dictionary — key-value pairs\nmark = {\"Alice\": 88, \"Charlie\": 75, \"Diana\": 92}\nprint(mark[\"Alice\"])        # → 88\nmark[\"Eve\"] = 80            # Add new entry\n\n# Loop through dictionary\nfor name, score in mark.items():\n    print(name, \":\", score)\n```"},
        {"title": "Mini Project — Student Grade Calculator",
         "body": "📝 Mini Project: Build a Student Grade Calculator\n\nRequirements:\n1. Accept names and marks for 5 students.\n2. Store in a dictionary.\n3. Calculate:\n   a. Class average\n   b. Highest scorer\n   c. Grade of each student (O/A+/A/B+/B)\n4. Print a formatted result table.\n\nExpected output:\n```\nName      Mark  Grade\n-----     ----  -----\nAlice     92    O\nBob       78    A\n...\nClass Average: 83.0\nTop Scorer: Alice (92)\n```"},
    ],
    quiz=[
        {"question": "What is the output of range(1, 5)?",
         "options": ["1, 2, 3, 4, 5", "1, 2, 3, 4", "0, 1, 2, 3, 4", "0, 1, 2, 3"],
         "answer": 1},
        {"question": "Which method adds an item to a Python list?",
         "options": ["insert()", "add()", "append()", "push()"],
         "answer": 2},
        {"question": "In a dictionary, values are accessed using:",
         "options": ["Index numbers only", "Keys", "A loop only", "The find() method"],
         "answer": 1},
        {"question": "What does the 'return' statement do in a function?",
         "options": ["Prints the result to screen", "Ends the program", "Sends a value back to the caller", "Calls another function"],
         "answer": 2},
        {"question": "Which loop is best when the number of iterations is unknown?",
         "options": ["for loop", "while loop", "do-while loop", "foreach loop"],
         "answer": 1},
    ]
)

prog_advanced = make_content(
    sections=[
        {"title": "Object-Oriented Programming (OOP)",
         "body": "OOP organises code into objects (instances of classes).\n\n```python\nclass Student:\n    def __init__(self, name, marks):\n        self.name = name\n        self.marks = marks\n\n    def get_grade(self):\n        if self.marks >= 90: return \"O\"\n        elif self.marks >= 80: return \"A+\"\n        elif self.marks >= 70: return \"A\"\n        else: return \"B+\"\n\n    def display(self):\n        print(f\"{self.name}: {self.marks} — {self.get_grade()}\")\n\ns1 = Student(\"Arun\", 87)\ns1.display()  # → Arun: 87 — A+\n```"},
        {"title": "File Handling",
         "body": "```python\n# Writing to a file\nwith open(\"marks.txt\", \"w\") as f:\n    f.write(\"Arun,87\\n\")\n    f.write(\"Priya,92\\n\")\n\n# Reading from a file\nwith open(\"marks.txt\", \"r\") as f:\n    for line in f:\n        name, score = line.strip().split(\",\")\n        print(f\"Student: {name}, Marks: {score}\")\n```\n\n✅ Always use 'with open()' — it automatically closes the file."},
        {"title": "Exception Handling",
         "body": "Prevents the program from crashing on errors.\n\n```python\ntry:\n    num = int(input(\"Enter a number: \"))\n    result = 100 / num\n    print(\"Result:\", result)\nexcept ValueError:\n    print(\"Error: Please enter a valid integer.\")\nexcept ZeroDivisionError:\n    print(\"Error: Cannot divide by zero.\")\nfinally:\n    print(\"Program complete.\")\n```"},
        {"title": "Capstone Project — Library Management System",
         "body": "📝 Capstone Project: Library Management System\n\nBuild a simple CLI library system with:\n1. Add a book (title, author, availability)\n2. Search for a book by title\n3. Issue a book (mark as unavailable)\n4. Return a book (mark as available)\n5. Display all books\n6. Save/load book data from a file\n\nFeatures to implement:\n• Use a `Book` class with OOP\n• Store all books in a list of Book objects\n• Use file handling to persist data between runs\n• Wrap all operations in try/except for safety\n\nThis project demonstrates OOP, file I/O, exception handling, and list manipulation — core concepts tested in campus placements."},
    ],
    quiz=[
        {"question": "What does '__init__' do in a Python class?",
         "options": ["Destroys the object", "Initialises the object when created", "Prints object data", "Connects to a database"],
         "answer": 1},
        {"question": "The 'with open()' statement is preferred because:",
         "options": ["It is faster", "It automatically closes the file", "It only works for reading", "It avoids loops"],
         "answer": 1},
        {"question": "Which exception handles division by zero?",
         "options": ["ValueError", "TypeError", "ZeroDivisionError", "AttributeError"],
         "answer": 2},
        {"question": "In OOP, 'self' refers to:",
         "options": ["The class itself", "The current object instance", "A global variable", "The parent class"],
         "answer": 1},
        {"question": "The 'finally' block in exception handling:",
         "options": ["Runs only when no exception occurs", "Runs only on exception", "Always runs regardless of exception", "Optional and rarely used"],
         "answer": 2},
    ]
)

# ═════════════════════════════════════════════════════════════════════════════
# APTITUDE — Basic / Intermediate / Advanced
# ═════════════════════════════════════════════════════════════════════════════

apt_basic = make_content(
    sections=[
        {"title": "Number Systems",
         "body": "A number system is a way to represent numbers.\n\n📌 Types:\n• Natural Numbers: 1, 2, 3, 4, … (positive counting numbers)\n• Whole Numbers: 0, 1, 2, 3, … (includes zero)\n• Integers: …−2, −1, 0, 1, 2, … (includes negatives)\n• Rational Numbers: can be written as p/q (e.g., 3/4, 0.5)\n• Prime Numbers: divisible only by 1 and itself (2, 3, 5, 7, 11…)\n\n🔑 Divisibility Rules:\n• ÷2: ends in 0, 2, 4, 6, 8\n• ÷3: sum of digits divisible by 3\n• ÷5: ends in 0 or 5\n• ÷9: sum of digits divisible by 9"},
        {"title": "Fractions, Decimals and Percentages",
         "body": "🔄 Converting between them:\n• Fraction → Decimal: divide numerator by denominator\n  3/4 = 3 ÷ 4 = 0.75\n• Decimal → Percentage: multiply by 100\n  0.75 × 100 = 75%\n• Percentage → Fraction: divide by 100\n  75% = 75/100 = 3/4\n\n📝 Key formulas:\n• % of a number: (percent/100) × number\n  25% of 200 = (25/100) × 200 = 50\n• % increase: [(New − Old)/Old] × 100\n• % decrease: [(Old − New)/Old] × 100"},
        {"title": "HCF and LCM",
         "body": "🔑 HCF (Highest Common Factor) — the largest number that divides both.\nMethod: Prime factorisation\n  HCF of 12 and 18:\n  12 = 2² × 3  |  18 = 2 × 3²\n  HCF = 2 × 3 = 6\n\n🔑 LCM (Lowest Common Multiple) — the smallest number divisible by both.\n  LCM = (12 × 18) / HCF = 216 / 6 = 36\n\n✅ Shortcut: HCF × LCM = Product of two numbers"},
        {"title": "Practice Questions",
         "body": "Solve these:\n1. What is 15% of 400?\n2. A number is divisible by both 4 and 6. Is it always divisible by 24? (Hint: Check LCM)\n3. Find HCF of 24 and 36.\n4. Convert 3/8 to a percentage.\n5. If a price increased from ₹500 to ₹600, what is the % increase?\n\nAnswers:\n1. 60\n2. No — LCM of 4 and 6 is 12, not 24.\n3. 12\n4. 37.5%\n5. 20%"},
    ],
    quiz=[
        {"question": "Which number is a Prime?",
         "options": ["9", "15", "17", "21"],
         "answer": 2},
        {"question": "25% of 320 is:",
         "options": ["70", "80", "110", "65"],
         "answer": 1},
        {"question": "HCF of 12 and 18 is:",
         "options": ["2", "3", "6", "9"],
         "answer": 2},
        {"question": "A number ends in 5. It is definitely divisible by:",
         "options": ["2", "3", "5", "9"],
         "answer": 2},
        {"question": "If price increases from ₹200 to ₹250, the % increase is:",
         "options": ["20%", "25%", "30%", "50%"],
         "answer": 1},
    ]
)

apt_intermediate = make_content(
    sections=[
        {"title": "Ratio and Proportion",
         "body": "Ratio compares two quantities of the same kind.\n\n📐 If A:B = 3:5 and total = 160:\n   A = (3/8) × 160 = 60\n   B = (5/8) × 160 = 100\n\n🔁 Proportion: two ratios are equal\n   a/b = c/d  →  ad = bc (cross multiplication)\n\n📝 Direct Proportion: as one increases, other increases.\n   5 workers → 20 days. 10 workers → 10 days.\n\n📝 Inverse Proportion: as one increases, other decreases.\n   Formula: x₁y₁ = x₂y₂"},
        {"title": "Time and Work",
         "body": "🔑 Formula:\nIf A can do a work in 'n' days, A's 1 day work = 1/n\n\n📝 Example 1:\nA can do work in 10 days. B in 15 days.\nTogether: 1/10 + 1/15 = 3/30 + 2/30 = 5/30 = 1/6\n→ Together they finish in 6 days.\n\n📝 Example 2 (Pipes and Cisterns):\nInlet pipe fills tank in 8 hrs. Outlet drains in 12 hrs.\nNet rate = 1/8 − 1/12 = 3/24 − 2/24 = 1/24\n→ Tank fills in 24 hrs."},
        {"title": "Time, Speed and Distance",
         "body": "📐 Formulas:\n• Distance = Speed × Time\n• Speed = Distance / Time\n• Time = Distance / Speed\n\nUnit conversions:\n• km/hr → m/s: multiply by 5/18\n• m/s → km/hr: multiply by 18/5\n\n📝 Example:\nA train 200m long crosses a platform 300m long at 60 km/hr.\nTotal distance = 200 + 300 = 500m\nSpeed = 60 × 5/18 = 50/3 m/s\nTime = 500 / (50/3) = 30 seconds"},
        {"title": "Practice Set",
         "body": "Solve these:\n1. A and B can do a job in 12 and 18 days. How many days together?\n2. A train moves at 90 km/hr. Convert to m/s.\n3. A can do 1/4 of work in 4 days. How long for full work?\n4. In what time will ₹5000 double at 10% simple interest?\n5. Ratio of A:B:C = 2:3:5; total = ₹1000. Find B's share.\n\nAnswers:\n1. 7.2 days  2. 25 m/s  3. 16 days  4. 10 years  5. ₹300"},
    ],
    quiz=[
        {"question": "A can finish work in 12 days, B in 24 days. Together in how many days?",
         "options": ["6 days", "8 days", "9 days", "10 days"],
         "answer": 1},
        {"question": "60 km/hr in m/s is:",
         "options": ["10 m/s", "16.67 m/s", "20 m/s", "25 m/s"],
         "answer": 1},
        {"question": "If A:B = 3:7 and total is 500, find B's share:",
         "options": ["₹100", "₹150", "₹300", "₹350"],
         "answer": 3},
        {"question": "Simple Interest formula is:",
         "options": ["SI = P×R×T/100", "SI = P+R+T", "SI = P×R/T×100", "SI = (P+T)/R"],
         "answer": 0},
        {"question": "Two pipes fill a tank in 10 and 15 hours. Together in how many hours?",
         "options": ["5 hrs", "6 hrs", "7 hrs", "8 hrs"],
         "answer": 1},
    ]
)

apt_advanced = make_content(
    sections=[
        {"title": "Permutations and Combinations",
         "body": "📐 Permutation P(n,r) — Order matters\n   P(n,r) = n! / (n−r)!\n   Arranging 3 books out of 5: P(5,3) = 5!/2! = 60\n\n📐 Combination C(n,r) — Order does NOT matter\n   C(n,r) = n! / (r! × (n−r)!)\n   Choosing 3 from 5: C(5,3) = 10\n\n📝 Key:\n• Password problems (order matters) → Permutation\n• Team selection (order doesn't matter) → Combination"},
        {"title": "Probability",
         "body": "📐 Formula: P(event) = Favourable outcomes / Total outcomes\n\n📝 Examples:\n1. Rolling a die, P(even) = 3/6 = 1/2\n2. Drawing a red card from a deck: P = 26/52 = 1/2\n3. Getting 2 heads in 2 coin tosses: P = 1/4\n\n🔁 Rules:\n• P(A or B) = P(A) + P(B) − P(A and B)  [for any events]\n• P(A and B) = P(A) × P(B)  [for independent events]\n• P(not A) = 1 − P(A)"},
        {"title": "Data Interpretation — Reading Charts",
         "body": "In placement aptitude tests, Data Interpretation (DI) questions are common. You will be given a table, bar chart, pie chart, or line graph and must answer questions.\n\n📊 Steps to solve DI quickly:\n1. Skim the title, axes, and units FIRST.\n2. Identify what each category/column represents.\n3. Use approximate values (don't compute exact decimals unless necessary).\n4. For % questions: use the formula directly.\n5. Check the scale — 'in thousands' or 'in lakhs' changes everything!\n\n✅ Always verify your answer against the chart before marking."},
        {"title": "Advanced Practice Problems",
         "body": "1. In how many ways can 5 people sit in a row? [Ans: 120]\n2. A committee of 4 is chosen from 6 men and 4 women. How many ways if exactly 2 must be women? [Ans: C(4,2)×C(6,2) = 6×15 = 90]\n3. P(drawing an ace from a deck) = ?\n   [Ans: 4/52 = 1/13]\n4. Two dice are thrown. P(sum = 7) = ?\n   [Favourable: (1,6),(2,5),(3,4),(4,3),(5,2),(6,1) = 6 outcomes; Ans: 6/36 = 1/6]\n5. From 8 books, 3 are selected. How many combinations?\n   [Ans: C(8,3) = 56]"},
    ],
    quiz=[
        {"question": "How many ways can 4 people be arranged in a line?",
         "options": ["12", "16", "24", "32"],
         "answer": 2},
        {"question": "C(6,2) equals:",
         "options": ["12", "15", "30", "36"],
         "answer": 1},
        {"question": "P(rolling a number > 4 on a die) =",
         "options": ["1/6", "1/3", "1/2", "2/3"],
         "answer": 1},
        {"question": "If P(A) = 0.4, then P(not A) =",
         "options": ["0.4", "0.6", "0.64", "1.4"],
         "answer": 1},
        {"question": "Which formula is used for arrangements where ORDER matters?",
         "options": ["Combination C(n,r)", "Permutation P(n,r)", "Probability P(A)", "None of the above"],
         "answer": 1},
    ]
)

# ═════════════════════════════════════════════════════════════════════════════
# CRITICAL THINKING (single level, full course)
# ═════════════════════════════════════════════════════════════════════════════

critical_thinking = make_content(
    sections=[
        {"title": "What is Critical Thinking?",
         "body": "Critical thinking is the ability to analyse information objectively and make a reasoned judgement. It involves:\n• Identifying problems clearly\n• Gathering relevant information\n• Evaluating evidence\n• Considering different perspectives\n• Drawing well-reasoned conclusions\n\n🎯 Why it matters:\nEmployers consistently rank critical thinking among the top skills they seek. It helps in exams, group discussions, interviews, and real-world problem-solving."},
        {"title": "Root Cause Analysis (5 Whys Technique)",
         "body": "The 5 Whys method finds the root cause of a problem by asking 'Why?' five times.\n\n📝 Example:\nProblem: The project was submitted late.\n1. Why? → Team members were not coordinated.\n2. Why? → There was no project plan.\n3. Why? → The team leader did not create one.\n4. Why? → The team leader lacked planning skills.\n5. Why? → No training was provided.\n\n✅ Root Cause: Lack of project management training.\nSolution: Provide training + create a structured project plan for future projects."},
        {"title": "SWOT Analysis",
         "body": "SWOT helps analyse a situation by identifying:\n• S — Strengths: What advantages do you have?\n• W — Weaknesses: What could be improved?\n• O — Opportunities: What external chances can you use?\n• T — Threats: What external challenges could harm you?\n\n📝 Example — Student analysing their career path:\nS: Strong coding skills, good attendance\nW: Poor presentation skills, low CGPA in one subject\nO: Campus placement at leading IT firms, internship openings\nT: Tough competition, changing technology trends\n\n✅ Use SWOT to make better decisions about studies, career paths, and project choices."},
        {"title": "Decision Trees",
         "body": "A decision tree maps out all possible decisions and their outcomes.\n\n📝 Example: Should you apply for a competitive exam?\n\nApply?\n├── YES\n│   ├── Prepare well → HIGH chance of selection ✅\n│   └── Don't prepare → LOW chance of selection ❌\n└── NO\n    → Miss the opportunity entirely ❌\n\n✅ Steps to build a decision tree:\n1. Write the decision at the root.\n2. Branch off each possible choice.\n3. For each branch, write the outcome or next decision.\n4. Evaluate each outcome's probability/impact.\n5. Choose the path with the best outcome."},
        {"title": "Practice Scenario",
         "body": "📝 Scenario: Your college team's app project is not working 2 days before submission. Half the team wants to submit a simpler version; the other half wants to fix the original.\n\nApply critical thinking:\n1. What is the root cause of the issue?\n2. Do a SWOT of each option.\n3. Build a decision tree with both choices.\n4. What is the best decision? Why?\n\nDiscuss with a classmate and compare reasoning."},
    ],
    quiz=[
        {"question": "The 5 Whys technique is used to find:",
         "options": ["The best employee", "The root cause of a problem", "A percentage calculation", "Project timeline"],
         "answer": 1},
        {"question": "In SWOT, 'O' stands for:",
         "options": ["Obstacles", "Outcomes", "Opportunities", "Objectives"],
         "answer": 2},
        {"question": "A decision tree helps you to:",
         "options": ["Store data", "Map all possible decisions and outcomes", "Calculate probabilities only", "Design a website"],
         "answer": 1},
        {"question": "Which is NOT a step in critical thinking?",
         "options": ["Gather relevant information", "Evaluate evidence", "Guess the answer without analysis", "Consider different perspectives"],
         "answer": 2},
        {"question": "After using 5 Whys, what should you do with the root cause?",
         "options": ["Ignore it", "Blame the person responsible", "Address it with a targeted solution", "Report it to higher authorities only"],
         "answer": 2},
    ]
)

# ═════════════════════════════════════════════════════════════════════════════
# LEADERSHIP (single level, full course)
# ═════════════════════════════════════════════════════════════════════════════

leadership = make_content(
    sections=[
        {"title": "What Makes a Good Leader?",
         "body": "Leadership is the ability to guide, inspire, and influence a group towards achieving a common goal.\n\n🌟 Core qualities of a leader:\n• Vision — Knows where the team is going.\n• Communication — Clearly expresses ideas and listens well.\n• Empathy — Understands team members' feelings and needs.\n• Integrity — Honest, ethical, and trustworthy.\n• Decision-making — Makes sound decisions under pressure.\n• Accountability — Takes responsibility for outcomes.\n\n📌 Leaders are not always managers. Anyone can demonstrate leadership — in a college project, a sports team, or classroom activities."},
        {"title": "Team Dynamics and Roles",
         "body": "A team works best when every member's role is clear.\n\n👥 Common team roles:\n• Leader/Facilitator — Guides the group and coordinates.\n• Idea Generator — Comes up with creative solutions.\n• Analyst — Evaluates ideas critically.\n• Implementer — Turns plans into action.\n• Timekeeper — Monitors deadlines.\n\n📝 Tuckman's Stages of Team Development:\n1. Forming — Members meet and are polite.\n2. Storming — Conflicts arise as personalities clash.\n3. Norming — Team establishes ground rules.\n4. Performing — Team works efficiently.\n5. Adjourning — Project ends, team disbands.\n\n✅ A leader's job is to guide the team through all stages."},
        {"title": "Conflict Resolution",
         "body": "Conflict is normal in teams. How you resolve it defines your leadership.\n\n🔑 Steps to resolve conflict:\n1. Listen actively to both sides without interrupting.\n2. Identify the real issue (not just the symptoms).\n3. Find common ground — what does each party want at its core?\n4. Explore solutions together.\n5. Agree on an action plan and follow up.\n\n📌 Conflict styles:\n• Avoiding — ignoring conflict (not effective long-term).\n• Competing — one side wins; other loses (damages relationships).\n• Compromising — both give up something.\n• Collaborating — find a solution that satisfies both. ✅ (Best approach)"},
        {"title": "Motivating Your Team",
         "body": "Motivated teams perform better, think more creatively, and persist through challenges.\n\n🌱 Maslow's Hierarchy of Needs (applied to teams):\n1. Basic needs — ensure fair workload distribution.\n2. Safety — create a non-threatening environment.\n3. Social needs — foster friendship and belonging.\n4. Esteem — recognise and praise achievements.\n5. Self-actualisation — challenge members with meaningful tasks.\n\n📝 Practical motivation tips for student projects:\n• Celebrate small wins.\n• Give specific praise (e.g., Your UI design was very clean) instead of just saying Good job.\n• Involve everyone in decisions.\n• Set achievable targets with clear deadlines.\n• Rotate leadership opportunities."},
        {"title": "Leadership Practice Task",
         "body": "📝 Task: You are the team leader for a 4-person final-year project. Two members are always late to meetings and one has not completed their assigned module.\n\n1. Identify which leadership quality is most needed here.\n2. Using conflict resolution steps, plan how you will address this.\n3. List 3 specific motivation strategies you would use.\n4. What team stage (Tuckman's model) is your team currently in?\n5. Write a short (5-sentence) team message to re-motivate the group.\n\nShare your response with a classmate for feedback."},
    ],
    quiz=[
        {"question": "Which leadership quality involves understanding team members' emotions?",
         "options": ["Integrity", "Vision", "Empathy", "Decision-making"],
         "answer": 2},
        {"question": "In Tuckman's model, what stage comes after 'Storming'?",
         "options": ["Forming", "Performing", "Norming", "Adjourning"],
         "answer": 2},
        {"question": "The best conflict resolution style is:",
         "options": ["Avoiding", "Competing", "Compromising", "Collaborating"],
         "answer": 3},
        {"question": "Maslow's highest need in his hierarchy is:",
         "options": ["Safety", "Esteem", "Social belonging", "Self-actualisation"],
         "answer": 3},
        {"question": "Specific praise is better than general praise because:",
         "options": ["It takes less time", "It feels more sincere and meaningful", "It avoids conflict", "It is easier to say"],
         "answer": 1},
    ]
)

# ═════════════════════════════════════════════════════════════════════════════
# Build resource list
# ═════════════════════════════════════════════════════════════════════════════

SKILL_RESOURCES = [
    # ── COMMUNICATION ──────────────────────────────────────────────────────
    LearningResource(
        title="Verbal Communication Skills",
        description="Master spoken communication: clarity, tone, pace, and structured delivery.",
        url="internal",
        type="course",
        tags="skill,communication,verbal",
        dept=None,
        skill_category="Communication",
        resource_level="Basic",
        language="English",
        content=comm_verbal,
    ),
    LearningResource(
        title="Body Language & Non-Verbal Communication",
        description="Understand and use positive body language in academic and professional settings.",
        url="internal",
        type="course",
        tags="skill,communication,body-language",
        dept=None,
        skill_category="Communication",
        resource_level="Intermediate",
        language="English",
        content=comm_body_language,
    ),
    LearningResource(
        title="Professional Email & Report Writing",
        description="Write clear professional emails and structured technical reports.",
        url="internal",
        type="article",
        tags="skill,communication,writing",
        dept=None,
        skill_category="Communication",
        resource_level="Advanced",
        language="English",
        content=comm_writing,
    ),

    # ── PROGRAMMING — Python ────────────────────────────────────────────────
    LearningResource(
        title="Python Programming — Basics",
        description="Variables, data types, input/output, operators, and conditional statements with mini task.",
        url="internal",
        type="course",
        tags="skill,programming,python,basic",
        dept=None,
        skill_category="Programming",
        resource_level="Basic",
        language="English",
        content=prog_basic,
    ),
    LearningResource(
        title="Python Programming — Intermediate",
        description="Loops, functions, lists, and dictionaries. Includes a Student Grade Calculator mini project.",
        url="internal",
        type="course",
        tags="skill,programming,python,intermediate",
        dept=None,
        skill_category="Programming",
        resource_level="Intermediate",
        language="English",
        content=prog_intermediate,
    ),
    LearningResource(
        title="Python Programming — Advanced",
        description="OOP, file handling, exception handling, and a Library Management System capstone project.",
        url="internal",
        type="course",
        tags="skill,programming,python,advanced",
        dept=None,
        skill_category="Programming",
        resource_level="Advanced",
        language="English",
        content=prog_advanced,
    ),

    # ── APTITUDE ────────────────────────────────────────────────────────────
    LearningResource(
        title="Aptitude — Basic Level",
        description="Number systems, fractions, percentages, HCF/LCM with worked examples and quiz.",
        url="internal",
        type="course",
        tags="skill,aptitude,basic",
        dept=None,
        skill_category="Aptitude",
        resource_level="Basic",
        language="English",
        content=apt_basic,
    ),
    LearningResource(
        title="Aptitude — Intermediate Level",
        description="Ratio & proportion, time & work, speed & distance with step-by-step solutions.",
        url="internal",
        type="course",
        tags="skill,aptitude,intermediate",
        dept=None,
        skill_category="Aptitude",
        resource_level="Intermediate",
        language="English",
        content=apt_intermediate,
    ),
    LearningResource(
        title="Aptitude — Advanced Level",
        description="Permutations, combinations, probability, and data interpretation for competitive exams.",
        url="internal",
        type="course",
        tags="skill,aptitude,advanced",
        dept=None,
        skill_category="Aptitude",
        resource_level="Advanced",
        language="English",
        content=apt_advanced,
    ),

    # ── CRITICAL THINKING ───────────────────────────────────────────────────
    LearningResource(
        title="Critical Thinking & Problem Solving",
        description="Root cause analysis (5 Whys), SWOT, and decision trees for structured problem solving.",
        url="internal",
        type="course",
        tags="skill,critical-thinking",
        dept=None,
        skill_category="Critical Thinking",
        resource_level="Intermediate",
        language="English",
        content=critical_thinking,
    ),

    # ── LEADERSHIP ──────────────────────────────────────────────────────────
    LearningResource(
        title="Student Leadership Development",
        description="Team dynamics, conflict resolution, and motivation strategies for college leaders.",
        url="internal",
        type="course",
        tags="skill,leadership",
        dept=None,
        skill_category="Leadership",
        resource_level="Intermediate",
        language="English",
        content=leadership,
    ),
]


def seed_skill_resources():
    db: Session = SessionLocal()
    try:
        Base.metadata.create_all(bind=engine)

        # Remove old skill-dev resources (url=="internal" or skill_category is not null)
        old = db.query(LearningResource).filter(
            LearningResource.skill_category != None
        ).all()
        if old:
            old_ids = [r.resource_id for r in old]
            db.query(StudentLearningProgress).filter(
                StudentLearningProgress.resource_id.in_(old_ids)
            ).delete(synchronize_session=False)
            db.query(LearningResource).filter(
                LearningResource.skill_category != None
            ).delete(synchronize_session=False)
            db.commit()
            print(f"Removed {len(old)} old skill resources.")

        db.add_all(SKILL_RESOURCES)
        db.commit()
        print(f"✅ Seeded {len(SKILL_RESOURCES)} self-written skill development resources.")
    except Exception as e:
        db.rollback()
        print(f"❌ Error: {e}")
        raise
    finally:
        db.close()


if __name__ == "__main__":
    seed_skill_resources()
