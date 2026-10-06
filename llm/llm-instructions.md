# Coding Guidelines

These aren't ordered by priority. Keep all of them in mind.

## Simplicity

- Write code that's immediately understandable. If a solution feels complex, simplify it.
- Prefer plain, explicit code over clever one-liners.
- Add complexity only when a requirement justifies it. Don't optimize for theoretical performance gains.

```python
# Bad
def primes_below(limit: int) -> list[int]:
    return [n for n in range(2, limit) if all(n % d for d in range(2, int(n**0.5) + 1))]


# Good
def primes_below(limit: int) -> list[int]:
    primes: list[int] = []
    for number in range(2, limit):
        if is_prime(number):
            primes.append(number)
    return primes


def is_prime(number: int) -> bool:
    if number < 2:
        return False
    for divisor in range(2, int(number**0.5) + 1):
        if number % divisor == 0:
            return False
    return True
```

## Build it properly

- Build things the proper way the first time. Don't take shortcuts to stand a feature up faster.
- Don't build oversimplified MVPs that will need a rewrite later. Avoid the technical debt now.

## Existing solutions

- Use the standard library and the project's shared modules before writing your own.
- For common tasks, choose well-maintained, popular libraries.
- Keep dependencies minimal but practical.

## Functions and classes

- Give each function and class one responsibility and one reason to change.
- Keep functions short, typically under 20 lines. Extract helpers when logic grows.
- Limit parameters to three or fewer where possible.
- Initialize all attributes in the constructor so an object's state is clear from the start.
- Hide internal details behind a small public interface.
- Favor composition over inheritance. Avoid deep or multiple inheritance.
- Pass dependencies in instead of creating them inside methods.

```python
# Bad
class OrderService:
    def process_order(self, order: Order) -> None:
        emailer = EmailService()  # Hidden dependency
        emailer.send_confirmation(order)


# Good
class OrderService:
    def __init__(self, email_service: EmailService) -> None:
        self._email_service = email_service

    def process_order(self, order: Order) -> None:
        self._email_service.send_confirmation(order)
```

## Types

- In dynamically typed languages, annotate every function signature and any variable whose type isn't obvious.
- In Python, use built-in generics and union syntax (`list[str]`, `str | None`) unless the project targets a version older than 3.10.
- Avoid `Any` and its equivalents unless there's no reasonable alternative.

## Errors and validation

- Handle errors explicitly. Never swallow an exception silently.
- Validate input at boundaries, such as user input, external APIs, files, and public interfaces. Don't re-validate the same data in every internal function.
- Write error messages that name the rule that failed and the value that failed it.

## Naming and style

- Use descriptive names that say what a variable, function, or class is for.
- Follow the conventions of the code I provide. If a convention causes problems, follow it anyway and point out the problem.
- Avoid deep nesting. Use early returns and guard clauses.

## Comments and documentation

- **Keep it plain.** Use short, plain sentences. Cut filler, restatement, and jargon. If a sentence needs rereading, rewrite it.
- **No colons in prose.** Split the sentence or use commas instead. Colons inside code, values, and URLs are fine.
- **No em-dashes.** Use commas, parentheses, or separate sentences.
- **Use the imperative mood.** A command's docstring is its `--help` text, so its first sentence must stand alone.
- **Say what and why, not how.** Document the rule the code enforces, the reason behind it, and any side effect a caller would not expect. Do not narrate the code line by line.
- **Delete what the code already says.** Leave a simple function without a docstring. Do not repeat field names, types, or signatures in prose. An error message that names its rule is documentation enough.
- **No internal references.** Never cite the engineering spec, the build, the plan, or similar documents. They are not part of the repository.
- **Avoid lists that go stale.** Do not enumerate the callers, files, or stages that use something. Say what is true of all of them.

## Testing

- Write tests first when practical.
- Test public interfaces, not implementation details.
- Name tests after the scenario they check.
- Keep tests independent of each other.
- Cover edge cases and error conditions.

```python
def test_withdraw_more_than_balance_raises() -> None:
    account = BankAccount()
    account.deposit(100)

    with pytest.raises(InsufficientFundsError):
        account.withdraw(150)
```

## Maintenance

- Remove unused code instead of commenting it out.
- Refactor when code becomes unclear.
- Keep dependencies updated.

## Responses

- Deliver code changes the way the active response skill describes.
- After finishing a change, list a few ways we could continue and say which one you'd pick and why.
