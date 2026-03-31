"""
Dynamic Quiz Generation Service
Generates quiz questions programmatically without relying on external AI services.
Supports MCQ, MCS, and NAT question types.
"""

import random
from typing import List, Dict, Any

class DynamicQuizGenerator:
    """Generates diverse, high-quality quiz questions dynamically."""
    
    # Knowledge base for different subjects and units
    QUIZ_DATABASE = {
        "Computer Networks": {
            1: {
                "title": "Basics and OSI Model",
                "mcq": [
                    {
                        "question": "Which layer of the OSI model is responsible for end-to-end communication?",
                        "option_a": "Transport Layer",
                        "option_b": "Network Layer",
                        "option_c": "Data Link Layer",
                        "option_d": "Application Layer",
                        "correct_answer": "Option A",
                        "difficulty_level": "Easy"
                    },
                    {
                        "question": "What is the maximum size of an IPv4 address?",
                        "option_a": "16 bits",
                        "option_b": "32 bits",
                        "option_c": "64 bits",
                        "option_d": "128 bits",
                        "correct_answer": "Option B",
                        "difficulty_level": "Easy"
                    },
                    {
                        "question": "Which protocol operates at the Application Layer?",
                        "option_a": "IP",
                        "option_b": "TCP",
                        "option_c": "HTTP",
                        "option_d": "Ethernet",
                        "correct_answer": "Option C",
                        "difficulty_level": "Medium"
                    },
                    {
                        "question": "What does TCP stand for?",
                        "option_a": "Transfer Control Protocol",
                        "option_b": "Transmission Control Protocol",
                        "option_c": "Transport Control Protocol",
                        "option_d": "Telecommunication Control Protocol",
                        "correct_answer": "Option B",
                        "difficulty_level": "Easy"
                    },
                    {
                        "question": "Which layer does the router operate on?",
                        "option_a": "Layer 1",
                        "option_b": "Layer 2",
                        "option_c": "Layer 3",
                        "option_d": "Layer 7",
                        "correct_answer": "Option C",
                        "difficulty_level": "Medium"
                    },
                    {
                        "question": "Which protocol is used to translate domain names to IP addresses?",
                        "option_a": "DHCP",
                        "option_b": "DNS",
                        "option_c": "SNMP",
                        "option_d": "ARP",
                        "correct_answer": "Option B",
                        "difficulty_level": "Easy"
                    },
                    {
                        "question": "What is the primary purpose of the Data Link Layer?",
                        "option_a": "Routing",
                        "option_b": "Framing and error detection",
                        "option_c": "Process-to-process delivery",
                        "option_d": "Bit-level transmission",
                        "correct_answer": "Option B",
                        "difficulty_level": "Medium"
                    },
                    {
                        "question": "Which of these is a Class B IP address?",
                        "option_a": "10.0.0.1",
                        "option_b": "172.16.0.1",
                        "option_c": "192.168.1.1",
                        "option_d": "224.0.0.1",
                        "correct_answer": "Option B",
                        "difficulty_level": "Medium"
                    },
                    {
                        "question": "What is the size of an IPv6 address?",
                        "option_a": "32 bits",
                        "option_b": "64 bits",
                        "option_c": "128 bits",
                        "option_d": "256 bits",
                        "correct_answer": "Option C",
                        "difficulty_level": "Medium"
                    },
                    {
                        "question": "Which device is used to connect different networks?",
                        "option_a": "Hub",
                        "option_b": "Switch",
                        "option_c": "Router",
                        "option_d": "Repeater",
                        "correct_answer": "Option C",
                        "difficulty_level": "Easy"
                    }
                ],
                "mcs": [
                    {
                        "question": "Which of the following are Transport Layer protocols?",
                        "option_a": "TCP",
                        "option_b": "UDP",
                        "option_c": "IP",
                        "option_d": "ICMP",
                        "correct_answer": "Option A, Option B",
                        "difficulty_level": "Medium"
                    },
                    {
                        "question": "Which layers of OSI model deal with hardware?",
                        "option_a": "Physical Layer",
                        "option_b": "Data Link Layer",
                        "option_c": "Network Layer",
                        "option_d": "Transport Layer",
                        "correct_answer": "Option A, Option B",
                        "difficulty_level": "Medium"
                    },
                    {
                        "question": "Which of the following are functions of the Network Layer?",
                        "option_a": "Routing",
                        "option_b": "Logical Addressing",
                        "option_c": "Error Detection",
                        "option_d": "Congestion Control",
                        "correct_answer": "Option A, Option B",
                        "difficulty_level": "Hard"
                    },
                    {
                        "question": "Which protocols are used for email communication?",
                        "option_a": "SMTP",
                        "option_b": "POP3",
                        "option_c": "IMAP",
                        "option_d": "FTP",
                        "correct_answer": "Option A, Option B, Option C",
                        "difficulty_level": "Medium"
                    },
                    {
                        "question": "Which of the following are wireless networking standards?",
                        "option_a": "802.11a",
                        "option_b": "802.11g",
                        "option_c": "802.11n",
                        "option_d": "802.3",
                        "correct_answer": "Option A, Option B, Option C",
                        "difficulty_level": "Medium"
                    },
                    {
                        "question": "Which layers are present in the TCP/IP model?",
                        "option_a": "Application",
                        "option_b": "Transport",
                        "option_c": "Internet",
                        "option_d": "Network Interface",
                        "correct_answer": "Option A, Option B, Option C, Option D",
                        "difficulty_level": "Medium"
                    },
                    {
                        "question": "Which of these are valid MAC addresses?",
                        "option_a": "00:1A:2B:3C:4D:5E",
                        "option_b": "G1:22:33:44:55:66",
                        "option_c": "11-22-33-44-55-66",
                        "option_d": "123.456.789.012",
                        "correct_answer": "Option A, Option C",
                        "difficulty_level": "Hard"
                    }
                ],
                "nat": [
                    {
                        "question": "What is the default port number for HTTP?",
                        "correct_answer": "80",
                        "difficulty_level": "Easy"
                    },
                    {
                        "question": "How many layers does the OSI model have?",
                        "correct_answer": "7",
                        "difficulty_level": "Easy"
                    },
                    {
                        "question": "What is the default port number for HTTPS?",
                        "correct_answer": "443",
                        "difficulty_level": "Easy"
                    },
                    {
                        "question": "How many bits are in a byte?",
                        "correct_answer": "8",
                        "difficulty_level": "Easy"
                    },
                    {
                        "question": "What is the maximum number of hosts in a /24 subnet?",
                        "correct_answer": "254",
                        "difficulty_level": "Hard"
                    },
                    {
                        "question": "What is the port number used by DNS?",
                        "correct_answer": "53",
                        "difficulty_level": "Medium"
                    },
                    {
                        "question": "How many bits are in an IPv4 address?",
                        "correct_answer": "32",
                        "difficulty_level": "Easy"
                    },
                    {
                        "question": "What is the maximum data rate of 10BaseT Ethernet in Mbps?",
                        "correct_answer": "10",
                        "difficulty_level": "Easy"
                    }
                ]
            },
            2: {
                "title": "IP Addressing and Subnetting",
                "mcq": [
                    {
                        "question": "What is the purpose of subnetting?",
                        "option_a": "Divide IP address space into smaller networks",
                        "option_b": "Increase the number of IP addresses",
                        "option_c": "Speed up data transmission",
                        "option_d": "Reduce network congestion",
                        "correct_answer": "Option A",
                        "difficulty_level": "Medium"
                    },
                    {
                        "question": "Which IP address range is reserved for private networks?",
                        "option_a": "10.0.0.0 to 10.255.255.255",
                        "option_b": "172.16.0.0 to 172.31.255.255",
                        "option_c": "192.168.0.0 to 192.168.255.255",
                        "option_d": "All of the above",
                        "correct_answer": "Option D",
                        "difficulty_level": "Medium"
                    },
                    {
                        "question": "What does CIDR stand for?",
                        "option_a": "Class Internet Domain Routing",
                        "option_b": "Classless Inter-Domain Routing",
                        "option_c": "Class Internet Distribution Routing",
                        "option_d": "Classless Inter-Domain Relay",
                        "correct_answer": "Option B",
                        "difficulty_level": "Medium"
                    },
                    {
                        "question": "What is the subnet mask for a /25 network?",
                        "option_a": "255.255.255.0",
                        "option_b": "255.255.255.128",
                        "option_c": "255.255.255.192",
                        "option_d": "255.255.255.224",
                        "correct_answer": "Option B",
                        "difficulty_level": "Hard"
                    },
                ],
                "mcs": [
                    {
                        "question": "Which of the following are valid IPv4 address classes?",
                        "option_a": "Class A",
                        "option_b": "Class B",
                        "option_c": "Class D",
                        "option_d": "Class E",
                        "correct_answer": "Option A, Option B, Option C, Option D",
                        "difficulty_level": "Medium"
                    },
                    {
                        "question": "Which statements about DHCP are true?",
                        "option_a": "Automatically assigns IP addresses",
                        "option_b": "Uses port 67 and 68",
                        "option_c": "Operates at Data Link Layer",
                        "option_d": "Can provide gateway and DNS information",
                        "correct_answer": "Option A, Option B, Option D",
                        "difficulty_level": "Hard"
                    },
                ],
                "nat": [
                    {
                        "question": "How many usable host addresses are in a /28 subnet?",
                        "correct_answer": "14",
                        "difficulty_level": "Hard"
                    },
                    {
                        "question": "What is the broadcast address of 192.168.1.0/25?",
                        "correct_answer": "192.168.1.127",
                        "difficulty_level": "Hard"
                    },
                ]
            }
        },
        "Data Structures": {
            1: {
                "title": "Arrays and Linked Lists",
                "mcq": [
                    {
                        "question": "What is the time complexity of accessing an element in an array by index?",
                        "option_a": "O(n)",
                        "option_b": "O(log n)",
                        "option_c": "O(1)",
                        "option_d": "O(n²)",
                        "correct_answer": "Option C",
                        "difficulty_level": "Easy"
                    },
                    {
                        "question": "Which of the following is a disadvantage of arrays?",
                        "option_a": "Fixed size",
                        "option_b": "O(1) access time",
                        "option_c": "Contiguous memory allocation",
                        "option_d": "Cache friendly",
                        "correct_answer": "Option A",
                        "difficulty_level": "Medium"
                    },
                    {
                        "question": "What is the time complexity of inserting an element at the beginning of a linked list?",
                        "option_a": "O(1)",
                        "option_b": "O(n)",
                        "option_c": "O(log n)",
                        "option_d": "O(n²)",
                        "correct_answer": "Option A",
                        "difficulty_level": "Medium"
                    },
                    {
                        "question": "Which data structure uses LIFO principle?",
                        "option_a": "Queue",
                        "option_b": "Stack",
                        "option_c": "Tree",
                        "option_d": "Graph",
                        "correct_answer": "Option B",
                        "difficulty_level": "Easy"
                    },
                ],
                "mcs": [
                    {
                        "question": "Which of the following are advantages of linked lists?",
                        "option_a": "Dynamic size",
                        "option_b": "Easy insertion and deletion",
                        "option_c": "O(1) access time",
                        "option_d": "Cache friendly",
                        "correct_answer": "Option A, Option B",
                        "difficulty_level": "Medium"
                    },
                    {
                        "question": "Which operations can be performed in O(1) time?",
                        "option_a": "Accessing array element by index",
                        "option_b": "Pushing to a stack",
                        "option_c": "Searching in sorted array",
                        "option_d": "Deleting from beginning of linked list",
                        "correct_answer": "Option A, Option B, Option D",
                        "difficulty_level": "Hard"
                    },
                ],
                "nat": [
                    {
                        "question": "What is the space complexity of storing an array of n elements?",
                        "correct_answer": "O(n)",
                        "difficulty_level": "Easy"
                    },
                    {
                        "question": "How many pointers does a node in a doubly linked list have?",
                        "correct_answer": "2",
                        "difficulty_level": "Easy"
                    },
                ]
            }
        },
        "Database Management": {
            1: {
                "title": "SQL Basics and Queries",
                "mcq": [
                    {
                        "question": "Which SQL keyword is used to retrieve data from a database?",
                        "option_a": "GET",
                        "option_b": "RETRIEVE",
                        "option_c": "SELECT",
                        "option_d": "FETCH",
                        "correct_answer": "Option C",
                        "difficulty_level": "Easy"
                    },
                    {
                        "question": "What does ACID stand for in database transactions?",
                        "option_a": "Atomicity, Consistency, Isolation, Durability",
                        "option_b": "Authentication, Confidentiality, Integrity, Durability",
                        "option_c": "Accuracy, Consistency, Integration, Dispatch",
                        "option_d": "Atomicity, Compliance, Integration, Dispatch",
                        "correct_answer": "Option A",
                        "difficulty_level": "Medium"
                    },
                    {
                        "question": "Which SQL clause is used to filter records?",
                        "option_a": "FILTER",
                        "option_b": "WHERE",
                        "option_c": "SEARCH",
                        "option_d": "FIND",
                        "correct_answer": "Option B",
                        "difficulty_level": "Easy"
                    },
                    {
                        "question": "What is the purpose of normalization?",
                        "option_a": "Speed up queries",
                        "option_b": "Reduce data redundancy",
                        "option_c": "Increase storage space",
                        "option_d": "Improve data security",
                        "correct_answer": "Option B",
                        "difficulty_level": "Medium"
                    },
                ],
                "mcs": [
                    {
                        "question": "Which normal forms are commonly used?",
                        "option_a": "1NF",
                        "option_b": "2NF",
                        "option_c": "3NF",
                        "option_d": "4NF",
                        "correct_answer": "Option A, Option B, Option C",
                        "difficulty_level": "Medium"
                    },
                    {
                        "question": "Which of the following are types of SQL JOINs?",
                        "option_a": "INNER JOIN",
                        "option_b": "LEFT JOIN",
                        "option_c": "OUTER JOIN",
                        "option_d": "CROSS JOIN",
                        "correct_answer": "Option A, Option B, Option C, Option D",
                        "difficulty_level": "Medium"
                    },
                ],
                "nat": [
                    {
                        "question": "How many normal forms are there in relational database design?",
                        "correct_answer": "5",
                        "difficulty_level": "Medium"
                    },
                    {
                        "question": "What is the maximum length of an SQL query in characters (typically)?",
                        "correct_answer": "32768",
                         "difficulty_level": "Hard"
                     },
                 ]
            }
        },
        "Operating Systems": {
            1: {
                "title": "Process Management and Scheduling",
                "mcq": [
                    {
                        "question": "What is a process in an operating system?",
                        "option_a": "A program in memory",
                        "option_b": "A sequence of instructions",
                        "option_c": "An instance of a program in execution",
                        "option_d": "A file on disk",
                        "correct_answer": "Option C",
                        "difficulty_level": "Easy"
                    },
                    {
                        "question": "Which scheduling algorithm is preemptive?",
                        "option_a": "FCFS",
                        "option_b": "SJF",
                        "option_c": "Round Robin",
                        "option_d": "Priority",
                        "correct_answer": "Option C",
                        "difficulty_level": "Medium"
                    },
                    {
                        "question": "What is the time quantum in Round Robin scheduling?",
                        "option_a": "Time slice allocated to each process",
                        "option_b": "Total time to complete",
                        "option_c": "Waiting time",
                        "option_d": "Process priority",
                        "correct_answer": "Option A",
                        "difficulty_level": "Medium"
                    },
                    {
                        "question": "Which state does a process move to when it waits for I/O?",
                        "option_a": "Ready",
                        "option_b": "Running",
                        "option_c": "Waiting",
                        "option_d": "Terminated",
                        "correct_answer": "Option C",
                        "difficulty_level": "Easy"
                    },
                ],
                "mcs": [
                    {
                        "question": "Which of the following are CPU scheduling criteria?",
                        "option_a": "CPU utilization",
                        "option_b": "Turnaround time",
                        "option_c": "Throughput",
                        "option_d": "Memory usage",
                        "correct_answer": "Option A, Option B, Option C",
                        "difficulty_level": "Medium"
                    },
                    {
                        "question": "Which are disadvantages of context switching?",
                        "option_a": "Time overhead",
                        "option_b": "Cache invalidation",
                        "option_c": "Memory fragmentation",
                        "option_d": "Increased CPU usage",
                        "correct_answer": "Option A, Option B, Option D",
                        "difficulty_level": "Hard"
                    },
                ],
                "nat": [
                    {
                        "question": "How many process states exist in a typical OS?",
                        "correct_answer": "5",
                        "difficulty_level": "Easy"
                    },
                    {
                        "question": "What is the typical time quantum in milliseconds for Round Robin?",
                        "correct_answer": "20",
                        "difficulty_level": "Medium"
                    },
                ]
            }
        },
        "Algorithms": {
            1: {
                "title": "Sorting and Searching",
                "mcq": [
                    {
                        "question": "What is the best-case time complexity of Quick Sort?",
                        "option_a": "O(n)",
                        "option_b": "O(n log n)",
                        "option_c": "O(n²)",
                        "option_d": "O(log n)",
                        "correct_answer": "Option B",
                        "difficulty_level": "Medium"
                    },
                    {
                        "question": "Which sorting algorithm is stable?",
                        "option_a": "Quick Sort",
                        "option_b": "Merge Sort",
                        "option_c": "Heap Sort",
                        "option_d": "Shell Sort",
                        "correct_answer": "Option B",
                        "difficulty_level": "Hard"
                    },
                    {
                        "question": "What is the time complexity of Binary Search?",
                        "option_a": "O(n)",
                        "option_b": "O(log n)",
                        "option_c": "O(n log n)",
                        "option_d": "O(1)",
                        "correct_answer": "Option B",
                        "difficulty_level": "Easy"
                    },
                    {
                        "question": "Which sorting algorithm requires O(n²) comparisons in worst case?",
                        "option_a": "Merge Sort",
                        "option_b": "Quick Sort",
                        "option_c": "Bubble Sort",
                        "option_d": "Heap Sort",
                        "correct_answer": "Option C",
                        "difficulty_level": "Medium"
                    },
                ],
                "mcs": [
                    {
                        "question": "Which sorting algorithms are comparison-based?",
                        "option_a": "Bubble Sort",
                        "option_b": "Counting Sort",
                        "option_c": "Merge Sort",
                        "option_d": "Radix Sort",
                        "correct_answer": "Option A, Option C",
                        "difficulty_level": "Hard"
                    },
                ],
                "nat": [
                    {
                        "question": "What is the space complexity of Merge Sort?",
                        "correct_answer": "O(n)",
                        "difficulty_level": "Medium"
                    },
                ]
            }
        },
        "Object-Oriented Programming": {
            1: {
                "title": "Classes, Objects, and Inheritance",
                "mcq": [
                    {
                        "question": "What is encapsulation in OOP?",
                        "option_a": "Bundling data and methods together",
                        "option_b": "Creating objects",
                        "option_c": "Inheriting from parent class",
                        "option_d": "Writing functions",
                        "correct_answer": "Option A",
                        "difficulty_level": "Easy"
                    },
                    {
                        "question": "Which of the following is a characteristic of a class?",
                        "option_a": "It is an instance",
                        "option_b": "It is a blueprint",
                        "option_c": "It is a function",
                        "option_d": "It is a variable",
                        "correct_answer": "Option B",
                        "difficulty_level": "Easy"
                    },
                    {
                        "question": "What is method overriding?",
                        "option_a": "Calling parent method",
                        "option_b": "Redefining parent method in child class",
                        "option_c": "Calling multiple methods",
                        "option_d": "Creating new methods",
                        "correct_answer": "Option B",
                        "difficulty_level": "Medium"
                    },
                ],
                "mcs": [
                    {
                        "question": "Which are pillars of OOP?",
                        "option_a": "Encapsulation",
                        "option_b": "Inheritance",
                        "option_c": "Polymorphism",
                        "option_d": "Compilation",
                        "correct_answer": "Option A, Option B, Option C",
                        "difficulty_level": "Easy"
                    },
                ],
                "nat": [
                    {
                        "question": "How many main pillars does OOP have?",
                        "correct_answer": "4",
                        "difficulty_level": "Easy"
                    },
                ]
            }
        },
        "Web Technologies": {
            1: {
                "title": "HTML, CSS, and JavaScript Basics",
                "mcq": [
                    {
                        "question": "What does HTML stand for?",
                        "option_a": "Hyper Text Markup Language",
                        "option_b": "High Tech Modern Language",
                        "option_c": "Home Tool Markup Language",
                        "option_d": "Hyperlinks and Text Markup Language",
                        "correct_answer": "Option A",
                        "difficulty_level": "Easy"
                    },
                    {
                        "question": "Which CSS property controls text color?",
                        "option_a": "text-color",
                        "option_b": "color",
                        "option_c": "font-color",
                        "option_d": "text-style",
                        "correct_answer": "Option B",
                        "difficulty_level": "Easy"
                    },
                    {
                        "question": "What is the purpose of JavaScript?",
                        "option_a": "Server-side processing",
                        "option_b": "Client-side scripting",
                        "option_c": "Database management",
                        "option_d": "Network configuration",
                        "correct_answer": "Option B",
                        "difficulty_level": "Easy"
                    },
                ],
                "mcs": [
                    {
                        "question": "Which are valid CSS selectors?",
                        "option_a": "Class selector",
                        "option_b": "ID selector",
                        "option_c": "Element selector",
                        "option_d": "Color selector",
                        "correct_answer": "Option A, Option B, Option C",
                        "difficulty_level": "Medium"
                    },
                ],
                "nat": [
                    {
                        "question": "How many semantic elements does HTML5 introduce approximately?",
                        "correct_answer": "28",
                        "difficulty_level": "Hard"
                    },
                ]
            }
        }
    }

    @staticmethod
    def generate_quiz(subject_name: str, unit_number: int, risk_level: str, total_questions: int = 20) -> List[Dict[str, Any]]:
        """
        Generates a dynamic quiz with mixed question types.
        
        Args:
            subject_name: Name of the subject
            unit_number: Unit number
            risk_level: HIGH, MEDIUM, or LOW
            total_questions: Total number of questions to generate
        
        Returns:
            List of quiz questions
        """
        
        # Get subject data or use fallback
        if subject_name not in DynamicQuizGenerator.QUIZ_DATABASE:
            return DynamicQuizGenerator._generate_fallback_quiz(subject_name, unit_number, risk_level, total_questions)
        
        subject_data = DynamicQuizGenerator.QUIZ_DATABASE[subject_name]
        
        if unit_number not in subject_data:
            return DynamicQuizGenerator._generate_fallback_quiz(subject_name, unit_number, risk_level, total_questions)
        
        unit_data = subject_data[unit_number]
        
        # Determine question distribution based on risk level
        if risk_level.upper() == "HIGH":
            mcq_count = 8
            mcs_count = 6
            nat_count = 6
        elif risk_level.upper() == "LOW":
            mcq_count = 12
            mcs_count = 5
            nat_count = 3
        else:  # MEDIUM
            mcq_count = 10
            mcs_count = 6
            nat_count = 4
        
        quiz = []
        
        # Add MCQ questions
        mcq_questions = unit_data.get("mcq", [])
        selected_mcq = random.sample(mcq_questions, min(mcq_count, len(mcq_questions)))
        for q in selected_mcq:
            q["question_type"] = "MCQ"
            q["assessment_type"] = None
            quiz.append(q)
        
        # Add MCS questions
        mcs_questions = unit_data.get("mcs", [])
        selected_mcs = random.sample(mcs_questions, min(mcs_count, len(mcs_questions)))
        for q in selected_mcs:
            q["question_type"] = "MCS"
            q["assessment_type"] = None
            # Set options to None for MCS display
            quiz.append(q)
        
        # Add NAT questions
        nat_questions = unit_data.get("nat", [])
        selected_nat = random.sample(nat_questions, min(nat_count, len(nat_questions)))
        for q in selected_nat:
            q["question_type"] = "NAT"
            q["assessment_type"] = None
            q["option_a"] = None
            q["option_b"] = None
            q["option_c"] = None
            q["option_d"] = None
            quiz.append(q)
        
        # Shuffle and assign IDs
        random.shuffle(quiz)
        for i, q in enumerate(quiz):
            q["id"] = i + 1
        
        return quiz[:total_questions]

    @staticmethod
    def _generate_fallback_quiz(subject_name: str, unit_number: int, risk_level: str, total_questions: int) -> List[Dict[str, Any]]:
        """Generate a fallback generic quiz for unknown subjects."""
        
        quiz = []
        
        # Generic MCQ questions
        generic_mcq = [
            {
                "id": 1,
                "question": f"What is the primary focus of {subject_name} Unit {unit_number}?",
                "option_a": "Foundational concepts",
                "option_b": "Advanced implementations",
                "option_c": "Practical applications",
                "option_d": "Theoretical analysis",
                "correct_answer": "Option A",
                "difficulty_level": "Easy",
                "question_type": "MCQ",
                "assessment_type": None
            },
            {
                "id": 2,
                "question": f"Which principle is central to {subject_name}?",
                "option_a": "Optimization",
                "option_b": "Efficiency",
                "option_c": "Correctness",
                "option_d": "Scalability",
                "correct_answer": "Option C",
                "difficulty_level": "Medium",
                "question_type": "MCQ",
                "assessment_type": None
            },
        ]
        
        # Generic MCS questions
        generic_mcs = [
            {
                "id": 3,
                "question": f"Which concepts are important in {subject_name}?",
                "option_a": "Theory",
                "option_b": "Practice",
                "option_c": "Application",
                "option_d": "Testing",
                "correct_answer": "Option A, Option B, Option C",
                "difficulty_level": "Medium",
                "question_type": "MCS",
                "assessment_type": None
            },
        ]
        
        # Generic NAT questions
        generic_nat = [
            {
                "id": 4,
                "question": f"How many chapters are typically in Unit {unit_number}?",
                "correct_answer": "5",
                "difficulty_level": "Easy",
                "question_type": "NAT",
                "assessment_type": None,
                "option_a": None,
                "option_b": None,
                "option_c": None,
                "option_d": None
            },
        ]
        
        quiz.extend(generic_mcq)
        quiz.extend(generic_mcs)
        quiz.extend(generic_nat)
        
        return quiz


def generate_quiz_questions(subject_name: str, unit_number: int, risk_level: str) -> List[Dict[str, Any]]:
    """
    API endpoint compatible function to generate quiz questions dynamically.
    """
    try:
        # Determine total questions based on risk level
        if risk_level.upper() == "HIGH":
            total_questions = 20
        elif risk_level.upper() == "LOW":
            total_questions = 30
        else:  # MEDIUM
            total_questions = 25
        
        quiz = DynamicQuizGenerator.generate_quiz(subject_name, unit_number, risk_level, total_questions)
        
        print(f"DEBUG: Generated {len(quiz)} quiz questions dynamically for {subject_name} Unit {unit_number}")
        return quiz
    
    except Exception as e:
        print(f"ERROR in generate_quiz_questions: {str(e)}")
        return []


def generate_assessment_quiz(subject_name: str, unit_number: int, assessment_type: str, risk_level: str = "MEDIUM") -> List[Dict[str, Any]]:
    """
    Generate mixed-type quiz questions for assessments.
    
    Question Type Mix:
    - SlipTest: 20 questions (30% MCQ, 40% MCS, 30% NAT)
    - CIA: 40 questions (25% MCQ, 50% MCS, 25% NAT)
    - ModelExam: 50 questions (30% MCQ, 40% MCS, 30% NAT)
    
    Returns a list of questions with proper question_type and assessment_type fields.
    """
    try:
        # Define assessment configurations
        configs = {
            "SlipTest": {"total": 20, "mcq": 6, "mcs": 8, "nat": 6},      # 30%, 40%, 30%
            "CIA": {"total": 40, "mcq": 10, "mcs": 20, "nat": 10},        # 25%, 50%, 25%
            "ModelExam": {"total": 50, "mcq": 15, "mcs": 20, "nat": 15},  # 30%, 40%, 30%
        }
        
        config = configs.get(assessment_type, configs["SlipTest"])
        total_questions = config["total"]
        mcq_count = config["mcq"]
        mcs_count = config["mcs"]
        nat_count = config["nat"]
        
        # Generate the base questions
        quiz = DynamicQuizGenerator.generate_quiz(subject_name, unit_number, risk_level, total_questions)
        
        # Reorganize questions to match the required distribution
        result = []
        mcq_added = 0
        mcs_added = 0
        nat_added = 0
        
        for q in quiz:
            if mcq_added < mcq_count and q.get("question_type") == "MCQ":
                q["assessment_type"] = assessment_type
                result.append(q)
                mcq_added += 1
            elif mcs_added < mcs_count and q.get("question_type") == "MCS":
                q["assessment_type"] = assessment_type
                result.append(q)
                mcs_added += 1
            elif nat_added < nat_count and q.get("question_type") == "NAT":
                q["assessment_type"] = assessment_type
                result.append(q)
                nat_added += 1
        
        # If we don't have enough of one type, add more from the quiz
        while len(result) < total_questions and len(quiz) > 0:
            for q in quiz:
                if q not in result:
                    if mcq_added < mcq_count and q.get("question_type") == "MCQ":
                        q["assessment_type"] = assessment_type
                        result.append(q)
                        mcq_added += 1
                        if len(result) >= total_questions:
                            break
                    elif mcs_added < mcs_count and q.get("question_type") == "MCS":
                        q["assessment_type"] = assessment_type
                        result.append(q)
                        mcs_added += 1
                        if len(result) >= total_questions:
                            break
                    elif nat_added < nat_count and q.get("question_type") == "NAT":
                        q["assessment_type"] = assessment_type
                        result.append(q)
                        nat_added += 1
                        if len(result) >= total_questions:
                            break
            break
        
        print(f"DEBUG: Generated {len(result)} assessment questions ({assessment_type}) for {subject_name} Unit {unit_number}")
        print(f"       MCQ: {mcq_added}, MCS: {mcs_added}, NAT: {nat_added}")
        return result
    
    except Exception as e:
        print(f"ERROR in generate_assessment_quiz: {str(e)}")
        return []


if __name__ == "__main__":
    # Test the quiz generator
    quiz = generate_quiz_questions("Computer Networks", 1, "MEDIUM")
    print(f"\nGenerated {len(quiz)} questions:")
    for q in quiz[:3]:
        print(f"\n{q['id']}. [{q['question_type']}] {q['question']}")
        if q['question_type'] != 'NAT':
            print(f"   A: {q.get('option_a', 'N/A')}")
            print(f"   B: {q.get('option_b', 'N/A')}")
            print(f"   C: {q.get('option_c', 'N/A')}")
            print(f"   D: {q.get('option_d', 'N/A')}")
        print(f"   Answer: {q['correct_answer']}")
