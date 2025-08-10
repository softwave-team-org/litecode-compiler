# LiteCode Array Design

## Array Syntax Design (LiteCode Style)

### 1. Array Type Declarations
```litecode
// Fixed-size arrays
num[5] numbers;           // Array of 5 numbers
text[3] names;            // Array of 3 text strings
bool[10] flags;           // Array of 10 booleans

// Dynamic arrays (future implementation)
num[] dynamic_numbers;    // Dynamic array of numbers
```

### 2. Array Initialization
```litecode
// Literal initialization
num[5] numbers = [1, 2, 3, 4, 5];
text[3] names = ["Alice", "Bob", "Charlie"];
bool[2] flags = [true, false];

// Zero initialization
num[5] zeros = [0, 0, 0, 0, 0];

// Partial initialization (rest filled with default values)
num[5] partial = [1, 2];  // [1, 2, 0, 0, 0]
```

### 3. Array Access (LiteCode bracket style)
```litecode
// Element access
num value = numbers[0];        // Get first element
names[1] = "Updated";          // Set second element

// Array operations
num size = numbers.length[];   // Get array length
```

### 4. Array Operations
```litecode
// Iteration with for loop
for [num i = 0; i < numbers.length[]; i = i + 1] {
    @print["Element $i: $numbers[i]"];
}

// Array assignment
num[3] source = [1, 2, 3];
num[3] dest;
dest = source;  // Copy array
```

### 5. Multi-dimensional Arrays
```litecode
// 2D arrays
num[3][3] matrix = [
    [1, 2, 3],
    [4, 5, 6], 
    [7, 8, 9]
];

// Access 2D elements
num value = matrix[1][2];  // Gets 6
```

### 6. Array Functions (Built-in)
```litecode
// Array manipulation functions
arrays.fill[numbers, 42];           // Fill array with value
arrays.copy[source, dest];          // Copy arrays
arrays.compare[arr1, arr2];         // Compare arrays
```

## Implementation Plan

### Phase 1: Basic Fixed Arrays
1. Add array types to type system
2. Update lexer for array syntax
3. Update parser for array declarations and literals
4. Add semantic analysis for arrays
5. Implement code generation for arrays

### Phase 2: Array Operations
1. Array indexing operations
2. Array assignment
3. Length property
4. Bounds checking

### Phase 3: Advanced Features
1. Multi-dimensional arrays
2. Array functions
3. Array iteration helpers
