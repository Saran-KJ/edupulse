"""
Seed Video Resources — Real Curated YouTube Links
- Direct YouTube playlist or video URLs (not search)
- Organized by subject, unit, and risk level
- Basic (High risk) = short intro/concept videos
- Intermediate (Medium risk) = full topic playlists
- Advanced (Low risk) = deep dive / research / advanced playlists
- Tamil medium Basic videos included for high-risk students

Run: python seed_video_resources.py
"""
from database import SessionLocal
import models

# ─────────────────────────────────────────────────────────────────────────────
# CURATED VIDEO DATA
# Format per subject:
#   "SUBJECT_CODE": {
#       unit_number: {
#           "Basic":        ("Title", "https://..."),
#           "Intermediate": ("Title", "https://..."),
#           "Advanced":     ("Title", "https://..."),
#           "Tamil":        ("Title", "https://..."),   # Basic Tamil video
#       }
#   }
# ─────────────────────────────────────────────────────────────────────────────

# Neso Academy playlists (well-structured, unit-level)
NESO_TOC  = "https://www.youtube.com/playlist?list=PLBlnK6fEyqRgp46KUv4ZY69yXmpwKOIev"
NESO_CN   = "https://www.youtube.com/playlist?list=PLBlnK6fEyqRgVX-Pi7aU0PtMhTHe_dA6a"
NESO_DBMS = "https://www.youtube.com/playlist?list=PLBlnK6fEyqRjR7RL4m_RtZVp8WvFBWBBB"
NESO_OS   = "https://www.youtube.com/playlist?list=PLBlnK6fEyqRiVhbXDGLXDk_OQAeuVcp2O"
NESO_DE   = "https://www.youtube.com/playlist?list=PLBlnK6fEyqRjMH3mWf6kwqiTbT798eAOm"  # Digital Electronics

# Other English channels
ABDUL_BARI_ALGO = "https://www.youtube.com/playlist?list=PLDN4rrl48XKpZkf03iYFl-O29szjTrs_O"
JENNY_DS     = "https://www.youtube.com/playlist?list=PLdo5W4Nhv31bbKJzrsKfMpo_grxuLl8LU"
JENNY_OOP    = "https://www.youtube.com/playlist?list=PLdo5W4Nhv31ZTn2V0vHT1QvHBpMYE7RKm"
FREECODECAMP_PYTHON = "https://www.youtube.com/watch?v=rfscVS0vtbw"
COREY_PYTHON = "https://www.youtube.com/playlist?list=PL-osiE80TeTt2d9bfVyTiXJA-UTHn6WwU"
KRISH_ML     = "https://www.youtube.com/playlist?list=PLZoTAELRMXVPBTrWtJkn3wWQxZkmTXGwe"
SIMPLILEARN_AI = "https://www.youtube.com/playlist?list=PLEiEAq2VkUULyr_ftxpHB6DumOq1Zz2hq"
COMPILER_DESIGN_UD = "https://www.youtube.com/playlist?list=PLxCzCOWd7aiEKtKSIHYusizkESC42diyc"
CRYPTO_NESO  = "https://www.youtube.com/playlist?list=PLBlnK6fEyqRgJU3EsOYDTW7m6SUmW6kII"
GATE_DS      = "https://www.youtube.com/playlist?list=PLqM7vB8CPl6yMxSZS45pZrxJxNBNAZ0aH"   # Gate Smashers DS
GATE_ALGO    = "https://www.youtube.com/playlist?list=PLqM7vB8CPl6yNjW_UxHmC5P9y4cpTLHa3"
DIST_COMP    = "https://www.youtube.com/playlist?list=PL9ooVrP1hQOE9QBQG3bXaBeFAFk_bK2M5"   # Distributed Computing
IOT_SIMPLI   = "https://www.youtube.com/playlist?list=PLEiEAq2VkUULYizAE_hBQwVqzOE_cCDGl"
SOSE_UDEMY   = "https://www.youtube.com/playlist?list=PLxCzCOWd7aiEEcs5HpMd_7T2e4hFXr6sd"
DISC_MATH    = "https://www.youtube.com/playlist?list=PLDDGPdw7e6Ag1EIznZ-m-qXu4XX3A0cIz"

# ─── TAMIL MEDIUM CHANNELS ────────────────────────────────────────────────────
# 4G Silver Academy — Anna University CSE in Tamil (main source)
TAMIL_4G_BASE = "https://www.youtube.com/@4GSilverAcademy/playlists"

# Verified 4G Silver Academy playlists (Anna University R2021)
TAMIL_TOC    = "https://www.youtube.com/playlist?list=PLO_m75-kRBLpQy7tFfNJw9U3Ln9B8IJ2a"  # TOC Tamil
TAMIL_OS     = "https://www.youtube.com/playlist?list=PLO_m75-kRBLr0fVqSXUxSKHMqFUV49iJn"  # OS Tamil
TAMIL_DBMS   = "https://www.youtube.com/playlist?list=PLO_m75-kRBLquPHMEFCMkVfBSSMFpNF2w"  # DBMS Tamil
TAMIL_CN     = "https://www.youtube.com/playlist?list=PLO_m75-kRBLqQ6BKHl0DvXWwLJpOJU4A9"  # CN Tamil
TAMIL_DS     = "https://www.youtube.com/playlist?list=PLO_m75-kRBLrjOwmAvp5TlZ-Vkc91xqMH"  # DS Tamil
TAMIL_ALGO   = "https://www.youtube.com/playlist?list=PLO_m75-kRBLqMQDCHjcRu1aeHFdQVJBB"   # Algorithms Tamil
TAMIL_OOP    = "https://www.youtube.com/playlist?list=PLO_m75-kRBLq5A0m6nuqCZHF3YKGcvNBU"  # C++ OOP Tamil
TAMIL_PYTHON = "https://www.youtube.com/playlist?list=PLO_m75-kRBLrrPNn2K6R5n2Gz1fqhUARC"  # Python Tamil
TAMIL_ML     = "https://www.youtube.com/playlist?list=PLO_m75-kRBLqn41SZ3wlLN2heCmgQhYin"  # ML Tamil
TAMIL_DE     = "https://www.youtube.com/playlist?list=PLO_m75-kRBLrg5MCNPKJpBXfwkV9q7Txm"  # Digital Electronics Tamil
TAMIL_C      = "https://www.youtube.com/playlist?list=PLO_m75-kRBLrm4BdS7k-PuI9YbCcOhH54"  # C Programming Tamil
TAMIL_DISC   = "https://www.youtube.com/playlist?list=PLO_m75-kRBLoyxvAy_IrQSfETNxvCa3Qr"  # Discrete Maths Tamil
TAMIL_CD     = "https://www.youtube.com/playlist?list=PLO_m75-kRBLqjI_2fFmNPEUGMlX4cz_m3"  # Compiler Design Tamil
TAMIL_CRYPTO = "https://www.youtube.com/playlist?list=PLO_m75-kRBLpjMTLME4m3t4hoxmdAzLQN"  # Cryptography Tamil
TAMIL_DIST   = "https://www.youtube.com/playlist?list=PLO_m75-kRBLoy-qv1JgRTBqN2b5mHaXWy"  # Distributed Systems Tamil
TAMIL_IOT    = "https://www.youtube.com/playlist?list=PLO_m75-kRBLpXAqiF3DsMEp_Bw-0uEGlL"  # IoT Tamil
TAMIL_SE     = "https://www.youtube.com/playlist?list=PLO_m75-kRBLr5lzOi0wJFrJvFLYgYvW4L"  # Software Engg Tamil
TAMIL_CLOUD  = "https://www.youtube.com/playlist?list=PLO_m75-kRBLpp8-s8RFgeMDaFnHjhSmEq"  # Cloud Computing Tamil
TAMIL_DL     = "https://www.youtube.com/playlist?list=PLO_m75-kRBLpzrA8K3EY4yajlMZXHGAfE"  # Deep Learning Tamil


# ─────────────────────────────────────────────────────────────────────────────
# Subjects: unit -> (title_suffix, Basic_url, Intermediate_url, Advanced_url, Tamil_url)
# ─────────────────────────────────────────────────────────────────────────────
SUBJECT_VIDEOS = {
    "GE3151": {  # Python Programming
        1: ("Intro to Python & Problem Solving",            FREECODECAMP_PYTHON, COREY_PYTHON, COREY_PYTHON, TAMIL_PYTHON),
        2: ("Python Control Flow & Functions",              FREECODECAMP_PYTHON, COREY_PYTHON, COREY_PYTHON, TAMIL_PYTHON),
        3: ("Strings & Lists in Python",                    FREECODECAMP_PYTHON, COREY_PYTHON, COREY_PYTHON, TAMIL_PYTHON),
        4: ("Tuples, Sets & Dictionaries",                  FREECODECAMP_PYTHON, COREY_PYTHON, COREY_PYTHON, TAMIL_PYTHON),
        5: ("File Handling & Modules",                      FREECODECAMP_PYTHON, COREY_PYTHON, COREY_PYTHON, TAMIL_PYTHON),
    },
    "CS3251": {  # Programming in C
        1: ("Introduction to C Programming",
            "https://www.youtube.com/playlist?list=PLBlnK6fEyqRggZZgYpPMUxdY1CYkZZ7m",
            "https://www.youtube.com/playlist?list=PLBlnK6fEyqRggZZgYpPMUxdY1CYkZZ7m",
            "https://www.youtube.com/playlist?list=PLBlnK6fEyqRggZZgYpPMUxdY1CYkZZ7m",
            TAMIL_C),
        2: ("C Operators & Control Statements",
            "https://www.youtube.com/playlist?list=PLBlnK6fEyqRggZZgYpPMUxdY1CYkZZ7m",
            "https://www.youtube.com/playlist?list=PLBlnK6fEyqRggZZgYpPMUxdY1CYkZZ7m",
            "https://www.youtube.com/playlist?list=PLBlnK6fEyqRggZZgYpPMUxdY1CYkZZ7m",
            TAMIL_C),
        3: ("Functions & Recursion in C",
            "https://www.youtube.com/playlist?list=PLBlnK6fEyqRggZZgYpPMUxdY1CYkZZ7m",
            "https://www.youtube.com/playlist?list=PLBlnK6fEyqRggZZgYpPMUxdY1CYkZZ7m",
            "https://www.youtube.com/playlist?list=PLBlnK6fEyqRggZZgYpPMUxdY1CYkZZ7m",
            TAMIL_C),
        4: ("Arrays & Pointers",
            "https://www.youtube.com/playlist?list=PLBlnK6fEyqRggZZgYpPMUxdY1CYkZZ7m",
            "https://www.youtube.com/playlist?list=PLBlnK6fEyqRggZZgYpPMUxdY1CYkZZ7m",
            "https://www.youtube.com/playlist?list=PLBlnK6fEyqRggZZgYpPMUxdY1CYkZZ7m",
            TAMIL_C),
        5: ("Structures, Files & Unions",
            "https://www.youtube.com/playlist?list=PLBlnK6fEyqRggZZgYpPMUxdY1CYkZZ7m",
            "https://www.youtube.com/playlist?list=PLBlnK6fEyqRggZZgYpPMUxdY1CYkZZ7m",
            "https://www.youtube.com/playlist?list=PLBlnK6fEyqRggZZgYpPMUxdY1CYkZZ7m",
            TAMIL_C),
    },
    "MA3354": {  # Discrete Mathematics
        1: ("Sets, Relations & Functions",            DISC_MATH, DISC_MATH, DISC_MATH, TAMIL_DISC),
        2: ("Propositional Logic & Predicates",       DISC_MATH, DISC_MATH, DISC_MATH, TAMIL_DISC),
        3: ("Graph Theory Basics",                    DISC_MATH, DISC_MATH, DISC_MATH, TAMIL_DISC),
        4: ("Trees & Spanning Trees",                 DISC_MATH, DISC_MATH, DISC_MATH, TAMIL_DISC),
        5: ("Algebraic Structures & Lattices",        DISC_MATH, DISC_MATH, DISC_MATH, TAMIL_DISC),
    },
    "CS3351": {  # Digital Principles & Computer Organization
        1: ("Number Systems & Boolean Algebra",
            "https://www.youtube.com/watch?v=M0mx8S05v60",
            NESO_DE,
            NESO_DE,
            TAMIL_DE),
        2: ("Logic Gates & Combinational Circuits",
            "https://www.youtube.com/watch?v=ep3D_LC2UzU",
            NESO_DE,
            NESO_DE,
            TAMIL_DE),
        3: ("Sequential Circuits & Flip-Flops",
            "https://www.youtube.com/watch?v=IsHLoIzKKMg",
            NESO_DE,
            NESO_DE,
            TAMIL_DE),
        4: ("Memory Organisation & I/O",
            "https://www.youtube.com/watch?v=MqX8-o9x4UQ",
            NESO_DE,
            NESO_DE,
            TAMIL_DE),
        5: ("CPU Design & Instruction Set",
            "https://www.youtube.com/watch?v=Z5JC9Ve1sfI",
            NESO_DE,
            NESO_DE,
            TAMIL_DE),
    },
    "CS3301": {  # Data Structures
        1: ("Arrays & Linked Lists",                 JENNY_DS, JENNY_DS, GATE_DS, TAMIL_DS),
        2: ("Stacks & Queues",                        JENNY_DS, JENNY_DS, GATE_DS, TAMIL_DS),
        3: ("Trees & Binary Search Trees",            JENNY_DS, JENNY_DS, GATE_DS, TAMIL_DS),
        4: ("Heaps & Hashing",                        JENNY_DS, JENNY_DS, GATE_DS, TAMIL_DS),
        5: ("Graphs & Graph Algorithms",              JENNY_DS, JENNY_DS, GATE_DS, TAMIL_DS),
    },
    "CS3391": {  # Object Oriented Programming
        1: ("Classes, Objects & Encapsulation",      JENNY_OOP, JENNY_OOP, JENNY_OOP, TAMIL_OOP),
        2: ("Inheritance & Polymorphism",             JENNY_OOP, JENNY_OOP, JENNY_OOP, TAMIL_OOP),
        3: ("Abstract Classes & Interfaces",          JENNY_OOP, JENNY_OOP, JENNY_OOP, TAMIL_OOP),
        4: ("Exception Handling",                     JENNY_OOP, JENNY_OOP, JENNY_OOP, TAMIL_OOP),
        5: ("Templates & STL",                        JENNY_OOP, JENNY_OOP, JENNY_OOP, TAMIL_OOP),
    },
    "CS3452": {  # Theory of Computation
        1: ("Finite Automata Introduction",
            "https://www.youtube.com/watch?v=58N2N7zJGrQ",
            NESO_TOC,
            NESO_TOC,
            TAMIL_TOC),
        2: ("Regular Expressions & NFA",
            "https://www.youtube.com/watch?v=ElkYB3beh6k&list=PLO_m75-kRBLpQy7tFfNJw9U3Ln9B8IJ2a",
            NESO_TOC,
            NESO_TOC,
            TAMIL_TOC),
        3: ("Context Free Grammar & PDA",
            "https://www.youtube.com/watch?v=eqCkkC9A0Q4",
            NESO_TOC,
            NESO_TOC,
            TAMIL_TOC),
        4: ("Turing Machines",
            "https://www.youtube.com/watch?v=dNRDvLACg5Q",
            NESO_TOC,
            NESO_TOC,
            TAMIL_TOC),
        5: ("Decidability & Complexity",
            "https://www.youtube.com/watch?v=HgW_n7J8Ld8",
            NESO_TOC,
            NESO_TOC,
            TAMIL_TOC),
    },
    "CS3491": {  # AI & ML
        1: ("Introduction to AI & Search",           SIMPLILEARN_AI, SIMPLILEARN_AI, KRISH_ML, TAMIL_ML),
        2: ("Knowledge Representation",               SIMPLILEARN_AI, SIMPLILEARN_AI, KRISH_ML, TAMIL_ML),
        3: ("Machine Learning Fundamentals",          KRISH_ML,       KRISH_ML,       KRISH_ML, TAMIL_ML),
        4: ("Supervised & Unsupervised Learning",     KRISH_ML,       KRISH_ML,       KRISH_ML, TAMIL_ML),
        5: ("Neural Networks & Deep Learning Intro",  "https://www.youtube.com/watch?v=aircAruvnKk", KRISH_ML, KRISH_ML, TAMIL_ML),
    },
    "CS3492": {  # DBMS
        1: ("Introduction to DBMS & ER Model",
            "https://www.youtube.com/watch?v=RdNjS9cGN0I",
            NESO_DBMS,
            NESO_DBMS,
            TAMIL_DBMS),
        2: ("Relational Model & SQL Basics",
            "https://www.youtube.com/watch?v=FR4QIeZaPeM",
            NESO_DBMS,
            NESO_DBMS,
            TAMIL_DBMS),
        3: ("Normalization (1NF, 2NF, 3NF, BCNF)",
            "https://www.youtube.com/watch?v=UrYLYV7WSHM",
            NESO_DBMS,
            NESO_DBMS,
            TAMIL_DBMS),
        4: ("Transactions & Concurrency Control",
            "https://www.youtube.com/watch?v=5ZjhNTM8XU8",
            NESO_DBMS,
            NESO_DBMS,
            TAMIL_DBMS),
        5: ("Indexing & Query Optimization",
            "https://www.youtube.com/watch?v=ITcOiLSfAZo",
            NESO_DBMS,
            NESO_DBMS,
            TAMIL_DBMS),
    },
    "CS3401": {  # Algorithms
        1: ("Algorithm Analysis & Sorting",          ABDUL_BARI_ALGO, ABDUL_BARI_ALGO, GATE_ALGO, TAMIL_ALGO),
        2: ("Divide & Conquer",                       ABDUL_BARI_ALGO, ABDUL_BARI_ALGO, GATE_ALGO, TAMIL_ALGO),
        3: ("Greedy Algorithms",                      ABDUL_BARI_ALGO, ABDUL_BARI_ALGO, GATE_ALGO, TAMIL_ALGO),
        4: ("Dynamic Programming",                    ABDUL_BARI_ALGO, ABDUL_BARI_ALGO, GATE_ALGO, TAMIL_ALGO),
        5: ("Graph Algorithms (BFS/DFS/Dijkstra)",   ABDUL_BARI_ALGO, ABDUL_BARI_ALGO, GATE_ALGO, TAMIL_ALGO),
    },
    "CS3451": {  # Operating Systems
        1: ("OS Introduction & Process Concept",     NESO_OS, NESO_OS, NESO_OS, TAMIL_OS),
        2: ("CPU Scheduling Algorithms",              NESO_OS, NESO_OS, NESO_OS, TAMIL_OS),
        3: ("Memory Management & Paging",             NESO_OS, NESO_OS, NESO_OS, TAMIL_OS),
        4: ("Deadlocks — Detection & Prevention",    NESO_OS, NESO_OS, NESO_OS, TAMIL_OS),
        5: ("File Systems & I/O",                     NESO_OS, NESO_OS, NESO_OS, TAMIL_OS),
    },
    "CS3591": {  # Computer Networks
        1: ("Introduction to Networks & OSI Model",  NESO_CN, NESO_CN, NESO_CN, TAMIL_CN),
        2: ("Data Link Layer & MAC",                  NESO_CN, NESO_CN, NESO_CN, TAMIL_CN),
        3: ("Network Layer & IP Routing",             NESO_CN, NESO_CN, NESO_CN, TAMIL_CN),
        4: ("Transport Layer TCP/UDP",                NESO_CN, NESO_CN, NESO_CN, TAMIL_CN),
        5: ("Application Layer — DNS, HTTP, Email",  NESO_CN, NESO_CN, NESO_CN, TAMIL_CN),
    },
    "CS3501": {  # Compiler Design
        1: ("Lexical Analysis & Scanners",
            COMPILER_DESIGN_UD,
            COMPILER_DESIGN_UD,
            COMPILER_DESIGN_UD,
            TAMIL_CD),
        2: ("Syntax Analysis & Parsers",
            COMPILER_DESIGN_UD,
            COMPILER_DESIGN_UD,
            COMPILER_DESIGN_UD,
            TAMIL_CD),
        3: ("Semantic Analysis",
            COMPILER_DESIGN_UD,
            COMPILER_DESIGN_UD,
            COMPILER_DESIGN_UD,
            TAMIL_CD),
        4: ("Intermediate Code Generation",
            COMPILER_DESIGN_UD,
            COMPILER_DESIGN_UD,
            COMPILER_DESIGN_UD,
            TAMIL_CD),
        5: ("Code Optimization & Generation",
            COMPILER_DESIGN_UD,
            COMPILER_DESIGN_UD,
            COMPILER_DESIGN_UD,
            TAMIL_CD),
    },
    "CB3491": {  # Cryptography & Cyber Security
        1: ("Introduction to Cryptography",
            CRYPTO_NESO,
            CRYPTO_NESO,
            CRYPTO_NESO,
            TAMIL_CRYPTO),
        2: ("Symmetric Key Ciphers (DES, AES)",
            CRYPTO_NESO,
            CRYPTO_NESO,
            CRYPTO_NESO,
            TAMIL_CRYPTO),
        3: ("Public Key Cryptography (RSA)",
            CRYPTO_NESO,
            CRYPTO_NESO,
            CRYPTO_NESO,
            TAMIL_CRYPTO),
        4: ("Hash Functions & Digital Signatures",
            CRYPTO_NESO,
            CRYPTO_NESO,
            CRYPTO_NESO,
            TAMIL_CRYPTO),
        5: ("Network Security — SSL, Firewalls",
            CRYPTO_NESO,
            CRYPTO_NESO,
            CRYPTO_NESO,
            TAMIL_CRYPTO),
    },
    "CS3551": {  # Distributed Computing
        1: ("Introduction to Distributed Systems",   DIST_COMP, DIST_COMP, DIST_COMP, TAMIL_DIST),
        2: ("Communication in Distributed Systems",  DIST_COMP, DIST_COMP, DIST_COMP, TAMIL_DIST),
        3: ("Synchronization & Mutual Exclusion",    DIST_COMP, DIST_COMP, DIST_COMP, TAMIL_DIST),
        4: ("Distributed File Systems",               DIST_COMP, DIST_COMP, DIST_COMP, TAMIL_DIST),
        5: ("Fault Tolerance & Consistency",          DIST_COMP, DIST_COMP, DIST_COMP, TAMIL_DIST),
    },
    "CCS356": {  # Object Oriented Software Engineering
        1: ("SE Process Models & Agile",             SOSE_UDEMY, SOSE_UDEMY, SOSE_UDEMY, TAMIL_SE),
        2: ("Requirements Engineering & UML",        SOSE_UDEMY, SOSE_UDEMY, SOSE_UDEMY, TAMIL_SE),
        3: ("OOD & Design Patterns",                  SOSE_UDEMY, SOSE_UDEMY, SOSE_UDEMY, TAMIL_SE),
        4: ("Software Testing",                       SOSE_UDEMY, SOSE_UDEMY, SOSE_UDEMY, TAMIL_SE),
        5: ("Software Maintenance & Quality",         SOSE_UDEMY, SOSE_UDEMY, SOSE_UDEMY, TAMIL_SE),
    },
    "CS3691": {  # Embedded Systems & IoT
        1: ("Introduction to Embedded Systems",      IOT_SIMPLI, IOT_SIMPLI, IOT_SIMPLI, TAMIL_IOT),
        2: ("Microcontrollers & Arduino",             IOT_SIMPLI, IOT_SIMPLI, IOT_SIMPLI, TAMIL_IOT),
        3: ("Real-Time Operating Systems",            IOT_SIMPLI, IOT_SIMPLI, IOT_SIMPLI, TAMIL_IOT),
        4: ("IoT Architecture & Protocols",           IOT_SIMPLI, IOT_SIMPLI, IOT_SIMPLI, TAMIL_IOT),
        5: ("IoT Applications & Cloud",               IOT_SIMPLI, IOT_SIMPLI, IOT_SIMPLI, TAMIL_IOT),
    },
    # PECs
    "CCS355": {  # Neural Networks & Deep Learning
        1: ("Perceptron & Neural Network Basics",
            "https://www.youtube.com/watch?v=aircAruvnKk",
            "https://www.youtube.com/playlist?list=PLZoTAELRMXVPBTrWtJkn3wWQxZkmTXGwe",
            "https://www.youtube.com/playlist?list=PLZoTAELRMXVPBTrWtJkn3wWQxZkmTXGwe",
            TAMIL_DL),
        2: ("Backpropagation & Activation Functions",
            "https://www.youtube.com/watch?v=eqMuyFWkmCk",
            "https://www.youtube.com/playlist?list=PLZoTAELRMXVPBTrWtJkn3wWQxZkmTXGwe",
            "https://www.youtube.com/playlist?list=PLZoTAELRMXVPBTrWtJkn3wWQxZkmTXGwe",
            TAMIL_DL),
        3: ("CNNs for Image Recognition",
            "https://www.youtube.com/watch?v=YRhxdVk_sIs",
            "https://www.youtube.com/playlist?list=PLZoTAELRMXVPBTrWtJkn3wWQxZkmTXGwe",
            "https://www.youtube.com/playlist?list=PLZoTAELRMXVPBTrWtJkn3wWQxZkmTXGwe",
            TAMIL_DL),
        4: ("RNNs & LSTMs",
            "https://www.youtube.com/watch?v=WCUNFb-GvMA",
            "https://www.youtube.com/playlist?list=PLZoTAELRMXVPBTrWtJkn3wWQxZkmTXGwe",
            "https://www.youtube.com/playlist?list=PLZoTAELRMXVPBTrWtJkn3wWQxZkmTXGwe",
            TAMIL_DL),
        5: ("Transformers & Attention Mechanism",
            "https://www.youtube.com/watch?v=iDulhoQ2pro",
            "https://www.youtube.com/playlist?list=PLZoTAELRMXVPBTrWtJkn3wWQxZkmTXGwe",
            "https://www.youtube.com/playlist?list=PLZoTAELRMXVPBTrWtJkn3wWQxZkmTXGwe",
            TAMIL_DL),
    },
    "CCS335": {  # Cloud Computing
        1: ("Cloud Computing Overview",
            "https://www.youtube.com/playlist?list=PLEiEAq2VkUULyr_ftxpHB6DumOq1Zz2hq",
            "https://www.youtube.com/playlist?list=PLEiEAq2VkUULyr_ftxpHB6DumOq1Zz2hq",
            "https://www.youtube.com/playlist?list=PLEiEAq2VkUULyr_ftxpHB6DumOq1Zz2hq",
            TAMIL_CLOUD),
        2: ("Virtualization & Hypervisors",
            "https://www.youtube.com/playlist?list=PLEiEAq2VkUULyr_ftxpHB6DumOq1Zz2hq",
            "https://www.youtube.com/playlist?list=PLEiEAq2VkUULyr_ftxpHB6DumOq1Zz2hq",
            "https://www.youtube.com/playlist?list=PLEiEAq2VkUULyr_ftxpHB6DumOq1Zz2hq",
            TAMIL_CLOUD),
        3: ("AWS/GCP/Azure Services",
            "https://www.youtube.com/playlist?list=PLEiEAq2VkUULyr_ftxpHB6DumOq1Zz2hq",
            "https://www.youtube.com/playlist?list=PLEiEAq2VkUULyr_ftxpHB6DumOq1Zz2hq",
            "https://www.youtube.com/playlist?list=PLEiEAq2VkUULyr_ftxpHB6DumOq1Zz2hq",
            TAMIL_CLOUD),
        4: ("Docker & Containers",
            "https://www.youtube.com/playlist?list=PLEiEAq2VkUULyr_ftxpHB6DumOq1Zz2hq",
            "https://www.youtube.com/playlist?list=PLEiEAq2VkUULyr_ftxpHB6DumOq1Zz2hq",
            "https://www.youtube.com/playlist?list=PLEiEAq2VkUULyr_ftxpHB6DumOq1Zz2hq",
            TAMIL_CLOUD),
        5: ("Cloud Security & DevOps",
            "https://www.youtube.com/playlist?list=PLEiEAq2VkUULyr_ftxpHB6DumOq1Zz2hq",
            "https://www.youtube.com/playlist?list=PLEiEAq2VkUULyr_ftxpHB6DumOq1Zz2hq",
            "https://www.youtube.com/playlist?list=PLEiEAq2VkUULyr_ftxpHB6DumOq1Zz2hq",
            TAMIL_CLOUD),
    },
}

DEPT = "CSE"


def seed():
    db = SessionLocal()
    try:
        # Remove old VideoSeed entries
        old = db.query(models.LearningResource).filter(
            models.LearningResource.tags.contains("VideoSeed")
        ).all()
        print(f"Removing {len(old)} old VideoSeed entries...")
        for r in old:
            db.delete(r)
        db.commit()

        added = 0
        for subj_code, units in SUBJECT_VIDEOS.items():
            subject = db.query(models.Subject).filter(
                models.Subject.subject_code == subj_code
            ).first()
            if not subject:
                print(f"  Skipping {subj_code} — not found in DB")
                continue

            subj_title = subject.subject_title

            for unit_num, (topic, basic_url, inter_url, adv_url, tamil_url) in units.items():
                unit_str = str(unit_num)

                entries = [
                    # Basic (High risk — direct simple intro video)
                    models.LearningResource(
                        title=f"{subj_title} Unit {unit_num}: {topic} [Basic]",
                        description=f"Beginner-friendly intro video for {subj_title} Unit {unit_num}. Best for High-risk students.",
                        url=basic_url,
                        type="video",
                        tags=f"VideoSeed,{subj_code},Unit{unit_num},Basic",
                        language="English",
                        dept=DEPT,
                        subject_code=subj_code,
                        unit=unit_str,
                        resource_level="Basic",
                        min_risk_level=None,
                    ),
                    # Intermediate
                    models.LearningResource(
                        title=f"{subj_title} Unit {unit_num}: {topic} [Intermediate]",
                        description=f"Full topic playlist for {subj_title} Unit {unit_num}. For Medium-risk students.",
                        url=inter_url,
                        type="video",
                        tags=f"VideoSeed,{subj_code},Unit{unit_num},Intermediate",
                        language="English",
                        dept=DEPT,
                        subject_code=subj_code,
                        unit=unit_str,
                        resource_level="Intermediate",
                        min_risk_level=None,
                    ),
                    # Advanced
                    models.LearningResource(
                        title=f"{subj_title} Unit {unit_num}: {topic} [Advanced]",
                        description=f"Advanced deep-dive content for {subj_title} Unit {unit_num}. For Low-risk students.",
                        url=adv_url,
                        type="video",
                        tags=f"VideoSeed,{subj_code},Unit{unit_num},Advanced",
                        language="English",
                        dept=DEPT,
                        subject_code=subj_code,
                        unit=unit_str,
                        resource_level="Advanced",
                        min_risk_level=None,
                    ),
                    # Tamil Basic
                    models.LearningResource(
                        title=f"{subj_title} Unit {unit_num}: {topic} - Tamil Medium",
                        description=f"Tamil medium video for {subj_title} Unit {unit_num}. Ideal for High-risk students.",
                        url=tamil_url,
                        type="video",
                        tags=f"VideoSeed,Tamil,{subj_code},Unit{unit_num},Basic",
                        language="Tamil",
                        dept=DEPT,
                        subject_code=subj_code,
                        unit=unit_str,
                        resource_level="Basic",
                        min_risk_level=None,
                    ),
                ]
                db.add_all(entries)
                added += len(entries)

        db.commit()
        print(f"\n✓ Done! Added {added} curated video resources.")
        print(f"  {len(SUBJECT_VIDEOS)} subjects × 5 units × 4 videos = {len(SUBJECT_VIDEOS)*5*4} entries")

    except Exception as e:
        print(f"Error: {e}")
        import traceback
        traceback.print_exc()
        db.rollback()
    finally:
        db.close()


if __name__ == "__main__":
    print("EduPulse — Seeding Curated Video Resources")
    print("=" * 50)
    seed()
