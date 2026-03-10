import math

def calculate_year(semester):
    return math.ceil(semester / 2)

test_cases = [
    (1, 1),
    (2, 1),
    (3, 2),
    (4, 2),
    (5, 3),
    (6, 3),
    (7, 4),
    (8, 4),
    (9, 5) # Future proofing
]

all_passed = True
for sem, expected_year in test_cases:
    actual_year = calculate_year(sem)
    if actual_year == expected_year:
        print(f"PASS: Semester {sem} -> Year {actual_year}")
    else:
        print(f"FAIL: Semester {sem} -> Expected {expected_year}, got {actual_year}")
        all_passed = False

if all_passed:
    print("\nLogic Verification SUCCESSFUL!")
else:
    print("\nLogic Verification FAILED!")
