from scoring_service import scoring_service

class MockQuestion:
    def __init__(self, q_type, correct, a=None, b=None, c=None, d=None):
        self.question_type = q_type
        self.correct_answer = correct
        self.option_a = a
        self.option_b = b
        self.option_c = c
        self.option_d = d

def test_scoring():
    # 1. MCQ Test: Label vs Value
    q1 = MockQuestion("MCQ", "Option A", a="smtp", b="pop3")
    print(f"MCQ (Label Input): {scoring_service.evaluate_answer('Option A', q1)}")
    print(f"MCQ (Value Input): {scoring_service.evaluate_answer('smtp', q1)}")
    
    # 2. MCS Test: Set matching
    q2 = MockQuestion("MCS", "Option A, Option B", a="tcp", b="udp", c="ip")
    print(f"MCS (Value Set): {scoring_service.evaluate_answer(['tcp', 'udp'], q2)}")
    print(f"MCS (Mixed Set): {scoring_service.evaluate_answer(['Option A', 'udp'], q2)}")
    
    # 3. NAT Test: Robustness
    q3 = MockQuestion("NAT", "80")
    print(f"NAT (Numeric): {scoring_service.evaluate_answer('80', q3)}")
    print(f"NAT (Empty): {scoring_service.evaluate_answer('', q3)}")
    print(f"NAT (With Text): {scoring_service.evaluate_answer('Port 80', q3)}")

if __name__ == "__main__":
    test_scoring()
