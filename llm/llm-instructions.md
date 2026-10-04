## Coding Guidelines

These guidelines are not necessarily ordered by priority, but just a list of things to keep in mind.

1. Embrace Simplicity Over Cleverness

- Write code that's immediately understandable to others
- If a solution feels complex, it probably needs simplification

```python
# Avoid overly complex clever one-liners
# Bad
return [n for n in range(max_num) if all(n % i != 0 for i in range(2, n))]

# Good
def find_prime_numbers(max_num):
    primes = []
    for number in range(2, max_num):
        if is_prime(number):
            primes.append(number)
    return primes

def is_prime(n):
    if n < 2:
        return False
    for i in range(2, int(n ** 0.5) + 1):
        if n % i == 0:
            return False
    return True
```

2. Avoid Shortcuts

- Build based on the proper way to do things, no shortcuts to stand up a feature quicker
  - I generally don't want to build overly simplified MVPs that will just require me to go back and refactor/rewrite later
  - Avoid the technical debt now

3. Leverage Existing Solutions

- Use standard libraries and shared modules whenever possible
- Don't reinvent the wheel
- Choose well-maintained, popular libraries for common tasks
- Keep dependencies minimal but practical

```python
# Bad: Custom implementation
def parse_json_file(file_path):
    with open(file_path, 'r') as f:
        content = f.read()
        # Custom parsing logic...

# Good: Use standard library
import json

def read_config(file_path):
    with open(file_path, 'r') as f:
        return json.load(f)
```

4. Function Design

- Each function should have a single responsibility
- Keep functions short (typically under 20 lines)
- Use descriptive names that indicate purpose
- Limit number of parameters (3 or fewer is ideal)

```python
# Bad: Multiple responsibilities
def process_user_data(user_data):
    # Validates, saves, and sends notifications
    if validate_user(user_data):
        save_to_database(user_data)
        send_welcome_email(user_data)
        update_metrics(user_data)

# Good: Single responsibility
def save_user(user_data):
    """Saves validated user data to database."""
    if not user_data:
        raise ValueError("User data cannot be empty")
    return database.insert("users", user_data)
```

5. Project Structure

- Keep related code together
- Use consistent file organization
- Group by responsibility
- Follow best conventions from industry and open source projects

```plaintext
# Good project structure
project/
├── main.py
├── config.py
├── users/
│   ├── models.py
│   ├── services.py
│   └── tests/
└── utils/
    └── helpers.py
```

6. Code Review Guidelines

- Review for simplicity first
- Question complexity and overengineering
- Look for duplicate code and abstraction opportunities
- Ensure consistent style and naming conventions, please follow the conventions in the code that I provide (unless there are issues with it and in that case let me know)

7. Maintenance Practices

- Regularly remove unused code
- Keep dependencies updated
- Refactor when code becomes unclear
- Document only what's necessary and likely to change

8. Comments, Docstrings, and Documentation

- Only include docstrings when the function/method isn't immediately obvious
  - If the entity is immediately obvious you don't need to include a docstring
- Documentation should not be self-referential and should not contain any references to any internal specs or documents in the project knowledge
- All documentation and comments should be in imperative tone

Remember:

- Write code for humans first, computers second
- Add complexity only when justified by requirements
- If you can't explain your code simply, it's probably too complex

## Response Guidelines

Please remember the following points when structuring your response:

- When you finish editing, present me with a list of options of how we could continue
- Indicate what you think should be the next step
- If I am using a non-statically typed language (like Python), always use type hints and type annotations
- Use descriptive, meaningful names for variables, functions, and classes
- Handle potential errors explicitly
- Validate input data
- Return meaningful error messages
- Use consistent formatting
- Avoid deep nesting of conditionals

# Object-Oriented Programming Guidelines for Simple, Robust Code

## Core Principles

### 1. Single Responsibility Principle

Each class should have one clear purpose and reason to change. Break complex classes into smaller, focused ones.

Example:

```python
# Bad
class UserManager:
    def save_user(self, user): ...
    def send_email(self, user): ...
    def generate_report(self): ...

# Good
class UserRepository:
    def save_user(self, user): ...

class EmailService:
    def send_email(self, user): ...

class ReportGenerator:
    def generate_report(self): ...
```

### 2. Encapsulation

Hide internal details and provide a clean interface. Use private attributes and public methods judiciously.

Example:

```python
class BankAccount:
    def __init__(self):
        self._balance = 0  # Protected attribute

    def deposit(self, amount):
        if amount <= 0:
            raise ValueError("Amount must be positive")
        self._balance += amount

    def get_balance(self):
        return self._balance
```

### 3. Clear Constructor Initialization

Initialize all attributes in the constructor. Make the object's state clear from the start.

Example:

```python
class Customer:
    def __init__(self, name, email):
        self.name = name
        self.email = email
        self.orders = []
        self.total_spent = 0
```

### 4. Favor Composition Over Inheritance

Use composition to build complex objects from simpler ones instead of deep inheritance hierarchies.

Example:

```python
# Bad
class SupermarketItem(ElectronicDevice, Perishable, Taxable):
    pass

# Good
class SupermarketItem:
    def __init__(self):
        self.electronic = ElectronicProperties()
        self.perishable = PerishableProperties()
        self.tax = TaxProperties()
```

### 5. Make Dependencies Explicit

Use dependency injection instead of creating dependencies inside methods.

Example:

```python
# Bad
class OrderService:
    def process_order(self, order):
        emailer = EmailService()  # Hidden dependency
        emailer.send_confirmation(order)

# Good
class OrderService:
    def __init__(self, email_service):
        self.email_service = email_service  # Explicit dependency

    def process_order(self, order):
        self.email_service.send_confirmation(order)
```

### 7. Use Strong Types and Interface Contracts

Define clear interfaces and type hints to make code more maintainable and self-documenting.

Example:

```python
from typing import List, Optional

class ShoppingCart:
    def __init__(self) -> None:
        self.items: List[Item] = []

    def add_item(self, item: Item) -> None:
        self.items.append(item)

    def get_total(self) -> float:
        return sum(item.price for item in self.items)
```

### 8. Keep Methods Short and Focused

Each method should do one thing well. Extract complex logic into helper methods.

Example:

```python
# Bad
def process_order(self, order):
    # 100 lines of mixed logic

# Good
def process_order(self, order):
    self.validate_order(order)
    total = self.calculate_total(order)
    self.apply_discounts(order)
    self.update_inventory(order)
    self.send_confirmation(order)
```

## Best Practices for Testing

1. Write tests first (TDD) when possible
2. Test public interfaces, not implementation details
3. Use meaningful test names that describe the scenario
4. Keep tests independent and isolated
5. Test edge cases and error conditions

Example:

```python
def test_withdraw_insufficient_funds():
    account = BankAccount()
    account.deposit(100)

    with pytest.raises(InsufficientFunds):
        account.withdraw(150)
```

## Common Anti-Patterns to Avoid

1. God Classes: Classes that do too much
2. Feature Envy: Methods that use more features of other classes than their own
3. Long Parameter Lists: Methods with too many parameters
4. Tight Coupling: Classes that know too much about each other
5. Premature Optimization: Making code complex for theoretical performance gains
