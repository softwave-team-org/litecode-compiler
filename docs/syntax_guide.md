# LiteCode Comprehensive Syntax Guide

## Table of Contents
1. [Introduction](#introduction)
2. [Basic Syntax](#basic-syntax)
3. [Comments](#comments)
4. [Data Types](#data-types)
5. [Variables and Constants](#variables-and-constants)
6. [Null Safety](#null-safety)
7. [Operators](#operators)
8. [Functions](#functions)
9. [Control Flow](#control-flow)
10. [Error Handling](#error-handling)
11. [Input and Output](#input-and-output)
12. [Program Structure](#program-structure)
13. [Examples](#examples)
14. [Best Practices](#best-practices)
15. [Common Errors](#common-errors)

---

## Introduction

LiteCode is a minimal, ergonomic programming language designed for simplicity and safety. It features:
- Mandatory entry point with `run { }` block
- Null safety by default
- Immutable constants with `val` keyword
- Ergonomic syntax using square brackets `[]` for calls
- C-like logical operators
- Multi-architecture compilation support

## Basic Syntax

### Statements and Termination
- All statements must end with a semicolon `;`
- Code blocks use curly braces `{ }`
- Square brackets `[]` are used for function calls and control structures

```litecode
run {
    @print["Hello, World!"];
};
```

### Case Sensitivity
LiteCode is case-sensitive:
```litecode
// These are different identifiers
val num myValue = 10;
val num MyValue = 20;
val num MYVALUE = 30;
```

---

## Comments

LiteCode supports two types of comments:

### Single-line Comments
Use `//` for single-line comments:
```litecode
// This is a single-line comment
num x = 5; // Comment at end of line
```

### Multi-line Comments
Use `/? ... ?/` for multi-line comments:
```litecode
/?
This is a multi-line comment
that can span several lines
?/
num y = 10;
```

---

## Data Types

LiteCode has five basic data types:

### Numeric Type (`num`)
Stores both integers and floating-point numbers:
```litecode
num integer = 42;
num decimal = 3.14159;
num negative = -100;
num scientific = 1.5e-10;
```

### Text Type (`text`)
Stores string values enclosed in double quotes:
```litecode
text name = "LiteCode";
text message = "Hello, World!";
text empty = "";
text withEscapes = "Line 1\nLine 2\tTabbed";
```

### Character Type (`char`)
Stores single characters enclosed in single quotes:
```litecode
char letter = 'A';
char digit = '5';
char symbol = '@';
char newline = '\n';
```

### Boolean Type (`bool`)
Stores true or false values:
```litecode
bool isTrue = true;
bool isFalse = false;
bool result = 10 > 5; // true
```

### Null Type
Special value for nullable types:
```litecode
num? nullableNumber = null;
```

---

## Variables and Constants

### Variable Declaration
Variables are mutable and can be reassigned:
```litecode
// Basic variable declaration
num counter = 0;
text userName = "admin";
bool isLoggedIn = false;

// Variables can be reassigned
counter = counter + 1;
userName = "guest";
isLoggedIn = true;
```

### Constant Declaration with `val`
Constants are immutable and cannot be reassigned:
```litecode
// Constant declaration
val num PI = 3.14159;
val text APP_NAME = "LiteCode";
val bool DEBUG_MODE = true;

// This would cause a compile error:
// PI = 3.14; // Error: Cannot reassign constant
```

### Variable Naming Rules
- Must start with a letter (a-z, A-Z)
- Can contain letters, digits, and underscores
- Cannot be keywords
- Case-sensitive

```litecode
// Valid names
num value1 = 10;
text user_name = "admin";
bool isReady = true;
val num MAX_SIZE = 100;

// Invalid names (would cause errors)
// num 1value = 10;     // Cannot start with digit
// text user-name = ""; // Hyphen not allowed
// bool if = true;      // 'if' is a keyword
```

---

## Null Safety

LiteCode implements null safety to prevent null pointer errors:

### Non-nullable Types (Default)
By default, all types are non-nullable:
```litecode
num value = 10;        // Cannot be null
text name = "John";    // Cannot be null
// value = null;       // Compile error
```

### Nullable Types
Add `?` to make a type nullable:
```litecode
num? optionalValue = null;     // Can be null
text? optionalName = null;     // Can be null
char? optionalChar = null;     // Can be null
bool? optionalFlag = null;     // Can be null

// Nullable constants
val num? OPTIONAL_CONFIG = null;
val text? DEFAULT_USER = "admin";
```

### Null Checks
Always check for null before using nullable values:
```litecode
num? userAge = null;

if [userAge != null] {
    @print["User age: $userAge"];
} else {
    @print["Age not provided"];
}

// Null assignment
userAge = 25;
if [userAge == null] {
    @print["Still null"];
} else {
    @print["Now has value: $userAge"];
}
```

---

## Operators

### Arithmetic Operators
```litecode
num a = 10;
num b = 3;

num addition = a + b;       // 13
num subtraction = a - b;    // 7
num multiplication = a * b; // 30
num division = a / b;       // 3.333...
num modulo = a % b;         // 1 (remainder)
```

### Comparison Operators
```litecode
num x = 5;
num y = 10;

bool equal = x == y;        // false
bool notEqual = x != y;     // true
bool less = x < y;          // true
bool greater = x > y;       // false
bool lessEqual = x <= y;    // true
bool greaterEqual = x >= y; // false
```

### Logical Operators
LiteCode uses C-like logical operators:
```litecode
bool a = true;
bool b = false;

bool andResult = a && b;    // false (AND)
bool orResult = a || b;     // true (OR)
bool notResult = !!a;       // false (NOT)

// Complex expressions
bool complex = (x > 0) && (y < 20) || !!b;
```

### String Concatenation
Use `+` to concatenate strings:
```litecode
text first = "Hello";
text second = "World";
text combined = first + " " + second; // "Hello World"

text greeting = "Hi, " + userName + "!";
```

### Assignment Operator
```litecode
num value = 10;     // Initial assignment
value = value + 5;  // Reassignment
value = 20;         // Direct reassignment
```

---

## Functions

### Function Declaration
Functions are declared with the `fnc` keyword:
```litecode
// Basic function syntax
fnc functionName[parameters]:returnType {
    // function body
    return value;
}
```

### Function Examples
```litecode
// Function with no parameters
fnc getCurrentYear[]:num {
    return 2025;
}

// Function with parameters
fnc add[num a, num b]:num {
    return a + b;
}

// Function with constant parameters
fnc calculateArea[val num radius]:num {
    val num PI = 3.14159;
    return PI * radius * radius;
}

// Function returning text
fnc greet[text name]:text {
    return "Hello, " + name + "!";
}

// Function returning boolean
fnc isEven[num n]:bool {
    return n % 2 == 0;
}

// Function with multiple parameters
fnc getMax[num a, num b, num c]:num {
    if [a >= b && a >= c] {
        return a;
    } or [b >= c] {
        return b;
    } else {
        return c;
    }
}
```

### Function Calls
Use square brackets `[]` for function calls:
```litecode
run {
    num year = getCurrentYear[];
    num sum = add[5, 3];
    text message = greet["Alice"];
    bool even = isEven[10];
    num maximum = getMax[15, 8, 12];
    
    @print["Year: $year"];
    @print["Sum: $sum"];
    @print[message];
    @print["Is 10 even? $even"];
    @print["Maximum: $maximum"];
};
```

### Recursive Functions
```litecode
fnc factorial[num n]:num {
    if [n <= 1] {
        return 1;
    } else {
        return n * factorial[n - 1];
    }
}

fnc fibonacci[num n]:num {
    if [n <= 1] {
        return n;
    } else {
        return fibonacci[n - 1] + fibonacci[n - 2];
    }
}
```

---

## Control Flow

### Conditional Statements

#### Basic if-else
```litecode
if [condition] {
    // code if condition is true
} else {
    // code if condition is false
}
```

#### if-or-else Chain
LiteCode uses `or` instead of `else if`:
```litecode
if [score >= 90] {
    @print["Grade A"];
} or [score >= 80] {
    @print["Grade B"];
} or [score >= 70] {
    @print["Grade C"];
} or [score >= 60] {
    @print["Grade D"];
} else {
    @print["Grade F"];
}
```

#### Nested Conditionals
```litecode
if [age >= 18] {
    if [hasLicense] {
        @print["Can drive"];
    } else {
        @print["Need license"];
    }
} else {
    @print["Too young to drive"];
}
```

### For Loops
LiteCode supports C-style for loops:
```litecode
// Basic for loop
for [num i = 0; i < 10; i = i + 1] {
    @print["Count: $i"];
}

// Countdown loop
for [num i = 10; i >= 1; i = i - 1] {
    @print["Countdown: $i"];
}

// Step by different amounts
for [num i = 0; i <= 20; i = i + 2] {
    @print["Even number: $i"];
}

// Nested loops
for [num i = 1; i <= 3; i = i + 1] {
    for [num j = 1; j <= 3; j = j + 1] {
        num product = i * j;
        @print["$i x $j = $product"];
    }
}
```

#### Loop Variable Constraints
Loop variables cannot be constants (since they need to be modified):
```litecode
// Valid - regular variable
for [num i = 0; i < 5; i = i + 1] {
    @print["$i"];
}

// Invalid - constant cannot be reassigned
// for [val num i = 0; i < 5; i = i + 1] { // Error!
```

---

## Error Handling

LiteCode provides try-catch-finally blocks for error handling:

### Basic try-catch
```litecode
try {
    // risky code
    num result = riskyOperation[];
    @print["Success: $result"];
} catch[error] {
    @print["Error occurred: $error"];
}
```

### try-catch-finally
```litecode
try {
    @print["Attempting operation"];
    performOperation[];
} catch[error] {
    @print["Error: $error"];
} finally {
    @print["Cleanup code - always runs"];
}
```

### Nested Error Handling
```litecode
try {
    @print["Outer try"];
    try {
        @print["Inner try"];
        riskyInnerOperation[];
    } catch[innerError] {
        @print["Inner catch: $innerError"];
    }
} catch[outerError] {
    @print["Outer catch: $outerError"];
} finally {
    @print["Outer finally"];
}
```

---

## Input and Output

### Print Statement
The `print` statement displays output with string interpolation:

#### Basic Printing
```litecode
@print["Hello, World!"];
@print["Simple message"];
```

#### String Interpolation
Use `$variableName` to insert variable values:
```litecode
num age = 25;
text name = "Alice";
bool isStudent = true;

@print["Name: $name"];
@print["Age: $age"];
@print["Student: $isStudent"];
@print["$name is $age years old"];
```

#### Format Specifiers
```litecode
num value = 42;
num pi = 3.14159;
text name = "LiteCode";

// Format as decimal
@print["Integer: $value:d"];

// Format as float
@print["Float: $pi:f"];

// Format as string
@print["String: $name:s"];
```

### Input Operations
The `read` function captures user input and returns a `text` value:

#### Basic Input
```litecode
// Read with a prompt
text userInput = @read["Enter your name: "];

// Read without a prompt
text data = @read[""];
```

#### Input Examples
```litecode
run {
    @print["Enter your name: "];
    text userName = @read[""];
    @print["Name entered successfully!"];
    
    @print["Enter your age: "];
    text userAge = @read[""];
    @print["Age entered successfully!"];
    
    // Note: String interpolation with input variables
    // may have limitations in current implementation
    @print["Input collection complete"];
};
```

#### Input Characteristics
- Input is read as `text` type
- Automatically removes trailing newlines
- Can include a prompt message as argument
- Returns user input as a string

---

## Program Structure

### Mandatory Run Block
Every LiteCode program must contain exactly one `run` block:

```litecode
// Optional function definitions
fnc helper[]:void {
    @print["Helper function"];
}

// Mandatory run block - program entry point
run {
    @print["Program starts here"];
    helper[];
    @print["Program ends here"];
};
```

### Complete Program Structure
```litecode
// File: example.lc

// Function definitions (optional)
fnc calculateTax[num income, val num rate]:num {
    return income * rate;
}

fnc isHighIncome[num income]:bool {
    val num HIGH_INCOME_THRESHOLD = 100000;
    return income >= HIGH_INCOME_THRESHOLD;
}

// Main program execution (required)
run {
    // Variable declarations
    num salary = 75000;
    val num TAX_RATE = 0.25;
    
    // Calculations
    num tax = calculateTax[salary, TAX_RATE];
    bool highEarner = isHighIncome[salary];
    
    // Output
    @print["Salary: $salary"];
    @print["Tax: $tax"];
    @print["High earner: $highEarner"];
    
    // Control flow
    if [highEarner] {
        @print["You are in the high income bracket"];
    } else {
        @print["You are in the standard income bracket"];
    }
};
```

---

## Examples

### Example 1: Calculator
```litecode
fnc add[num a, num b]:num {
    return a + b;
}

fnc subtract[num a, num b]:num {
    return a - b;
}

fnc multiply[num a, num b]:num {
    return a * b;
}

fnc divide[num a, num b]:num {
    if [b != 0] {
        return a / b;
    } else {
        return 0; // Simple error handling
    }
}

run {
    val num X = 10;
    val num Y = 3;
    
    @print["Calculator Results for $X and $Y:"];
    @print["Addition: $X + $Y = " + add[X, Y]];
    @print["Subtraction: $X - $Y = " + subtract[X, Y]];
    @print["Multiplication: $X * $Y = " + multiply[X, Y]];
    @print["Division: $X / $Y = " + divide[X, Y]];
};
```

### Example 2: Number Analysis
```litecode
fnc isEven[num n]:bool {
    return n % 2 == 0;
}

fnc isPrime[num n]:bool {
    if [n <= 1] {
        return false;
    }
    
    for [num i = 2; i * i <= n; i = i + 1] {
        if [n % i == 0] {
            return false;
        }
    }
    return true;
}

fnc factorial[num n]:num {
    if [n <= 1] {
        return 1;
    } else {
        return n * factorial[n - 1];
    }
}

run {
    @print["Number Analysis"];
    
    for [num i = 1; i <= 10; i = i + 1] {
        bool even = isEven[i];
        bool prime = isPrime[i];
        num fact = factorial[i];
        
        @print["$i: even=$even, prime=$prime, factorial=$fact"];
    }
};
```

### Example 3: Text Processing
```litecode
fnc greetUser[text name, bool formal]:text {
    if [formal] {
        return "Good day, " + name + ".";
    } else {
        return "Hey " + name + "!";
    }
}

fnc getInitials[text firstName, text lastName]:text {
    char first = firstName[0];  // Hypothetical string indexing
    char last = lastName[0];
    return first + "." + last + ".";
}

run {
    val text FIRST_NAME = "John";
    val text LAST_NAME = "Doe";
    val bool IS_FORMAL = true;
    
    text greeting = greetUser[FIRST_NAME, IS_FORMAL];
    text initials = getInitials[FIRST_NAME, LAST_NAME];
    
    @print[greeting];
    @print["Initials: $initials"];
    
    // Different greeting style
    text casualGreeting = greetUser[FIRST_NAME, false];
    @print[casualGreeting];
};
```

---

## Best Practices

### 1. Use Descriptive Names
```litecode
// Good
val num MAX_RETRY_ATTEMPTS = 3;
num userScore = 85;
bool isAuthenticated = false;

// Avoid
val num X = 3;
num s = 85;
bool flag = false;
```

### 2. Use Constants for Fixed Values
```litecode
// Good
val num PI = 3.14159;
val text APP_VERSION = "1.0.0";
val bool DEBUG_MODE = false;

// Less ideal
num pi = 3.14159;  // Could be accidentally modified
```

### 3. Check Nullable Values
```litecode
// Good
num? userAge = getUserAge[];
if [userAge != null] {
    @print["Age: $userAge"];
} else {
    @print["Age not provided"];
}

// Risky (if getUserAge could return null)
// num age = getUserAge[];  // Could cause runtime error
```

### 4. Use Meaningful Function Names
```litecode
// Good
fnc calculateMonthlyPayment[num principal, num rate, num months]:num {
    // calculation logic
}

// Less clear
fnc calc[num p, num r, num m]:num {
    // calculation logic
}
```

### 5. Structure Your Code
```litecode
// Helper functions first
fnc validateInput[num value]:bool {
    return value >= 0 && value <= 100;
}

fnc processData[num input]:num {
    if [validateInput[input]] {
        return input * 2;
    } else {
        return -1;
    }
}

// Main logic in run block
run {
    num userInput = 50;
    num result = processData[userInput];
    @print["Result: $result"];
};
```

---

## Common Errors

### 1. Missing Semicolon
```litecode
// Error
num x = 5
@print["Value: $x"];

// Correct
num x = 5;
@print["Value: $x"];
```

### 2. Reassigning Constants
```litecode
// Error
val num PI = 3.14;
PI = 3.14159;  // Cannot reassign constant

// Correct
num pi = 3.14;
pi = 3.14159;  // Variables can be reassigned
```

### 3. Missing Run Block
```litecode
// Error - no run block
fnc hello[]:void {
    @print["Hello"];
}

// Correct
fnc hello[]:void {
    @print["Hello"];
}

run {
    hello[];
};
```

### 4. Null Assignment to Non-nullable
```litecode
// Error
num value = null;  // num is not nullable

// Correct
num? value = null;  // num? is nullable
```

### 5. Using Square Brackets Incorrectly
```litecode
// Error - using parentheses
if (condition) {  // Should use square brackets
    print("Hello");  // String should use double quotes
}

// Correct
if [condition] {
    @print["Hello"];
};
```

### 6. Incorrect Loop Variable Types
```litecode
// Error - constant in loop
for [val num i = 0; i < 5; i = i + 1] {  // Constants can't be reassigned
    @print["$i"];
}

// Correct
for [num i = 0; i < 5; i = i + 1] {
    @print["$i"];
}
```

---

This comprehensive guide covers all aspects of LiteCode syntax. For more examples and advanced usage patterns, refer to the test files in the LiteCode repository.
