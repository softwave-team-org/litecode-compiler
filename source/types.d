module types;

import std.conv;

// Base type class
abstract class LCType {
    bool isNullable;
    
    this(bool isNullable = false) {
        this.isNullable = isNullable;
    }
    
    abstract bool equals(LCType other) const;
    abstract override string toString() const;
    abstract LCType makeNullable() const;
    abstract LCType makeNonNullable() const;
    
    bool canAssignFrom(LCType other) {
        if (this.equals(other)) return true;
        
        // null can be assigned to nullable types
        if (this.isNullable && cast(NullType)other) return true;
        
        // non-nullable can be assigned to nullable of same base type
        if (this.isNullable && !other.isNullable) {
            auto thisNonNull = this.makeNonNullable();
            return thisNonNull.equals(other);
        }
        
        return false;
    }
}

class NumType : LCType {
    this(bool isNullable = false) {
        super(isNullable);
    }
    
    override bool equals(LCType other) const {
        auto numType = cast(NumType)other;
        return numType !is null && this.isNullable == numType.isNullable;
    }
    
    override string toString() const {
        return isNullable ? "num?" : "num";
    }
    
    override LCType makeNullable() const {
        return new NumType(true);
    }
    
    override LCType makeNonNullable() const {
        return new NumType(false);
    }
}

class TextType : LCType {
    this(bool isNullable = false) {
        super(isNullable);
    }
    
    override bool equals(LCType other) const {
        auto textType = cast(TextType)other;
        return textType !is null && this.isNullable == textType.isNullable;
    }
    
    override string toString() const {
        return isNullable ? "text?" : "text";
    }
    
    override LCType makeNullable() const {
        return new TextType(true);
    }
    
    override LCType makeNonNullable() const {
        return new TextType(false);
    }
}

class CharType : LCType {
    this(bool isNullable = false) {
        super(isNullable);
    }
    
    override bool equals(LCType other) const {
        auto charType = cast(CharType)other;
        return charType !is null && this.isNullable == charType.isNullable;
    }
    
    override string toString() const {
        return isNullable ? "char?" : "char";
    }
    
    override LCType makeNullable() const {
        return new CharType(true);
    }
    
    override LCType makeNonNullable() const {
        return new CharType(false);
    }
}

class BoolType : LCType {
    this(bool isNullable = false) {
        super(isNullable);
    }
    
    override bool equals(LCType other) const {
        auto boolType = cast(BoolType)other;
        return boolType !is null && this.isNullable == boolType.isNullable;
    }
    
    override string toString() const {
        return isNullable ? "bool?" : "bool";
    }
    
    override LCType makeNullable() const {
        return new BoolType(true);
    }
    
    override LCType makeNonNullable() const {
        return new BoolType(false);
    }
}

class VoidType : LCType {
    this() {
        super(false); // void cannot be nullable
    }
    
    override bool equals(LCType other) const {
        return cast(VoidType)other !is null;
    }
    
    override string toString() const {
        return "void";
    }
    
    override LCType makeNullable() const {
        return cast(LCType)this; // void cannot be nullable
    }
    
    override LCType makeNonNullable() const {
        return cast(LCType)this;
    }
}

class NullType : LCType {
    this() {
        super(true); // null is always nullable
    }
    
    override bool equals(LCType other) const {
        return cast(NullType)other !is null;
    }
    
    override string toString() const {
        return "null";
    }
    
    override LCType makeNullable() const {
        return cast(LCType)this;
    }
    
    override LCType makeNonNullable() const {
        return cast(LCType)this; // null cannot be non-nullable
    }
}

class FunctionType : LCType {
    LCType[] parameterTypes;
    LCType returnType;
    
    this(LCType[] parameterTypes, LCType returnType) {
        super(false); // functions are not nullable
        this.parameterTypes = parameterTypes;
        this.returnType = returnType;
    }
    
    override bool equals(LCType other) const {
        auto funcType = cast(FunctionType)other;
        if (funcType is null) return false;
        
        if (!this.returnType.equals(funcType.returnType)) return false;
        if (this.parameterTypes.length != funcType.parameterTypes.length) return false;
        
        for (size_t i = 0; i < this.parameterTypes.length; i++) {
            if (!this.parameterTypes[i].equals(funcType.parameterTypes[i])) {
                return false;
            }
        }
        
        return true;
    }
    
    override string toString() const {
        string result = "fnc[";
        for (size_t i = 0; i < parameterTypes.length; i++) {
            if (i > 0) result ~= ", ";
            result ~= parameterTypes[i].toString();
        }
        result ~= "]:" ~ returnType.toString();
        return result;
    }
    
    override LCType makeNullable() const {
        return cast(LCType)this; // functions cannot be nullable
    }
    
    override LCType makeNonNullable() const {
        return cast(LCType)this;
    }
}

class ArrayType : LCType {
    LCType elementType;
    int size; // -1 for dynamic arrays, positive for fixed size
    
    this(LCType elementType, int size, bool isNullable = false) {
        super(isNullable);
        this.elementType = elementType;
        this.size = size;
    }
    
    override bool equals(LCType other) const {
        auto arrayType = cast(ArrayType)other;
        if (arrayType is null) return false;
        
        return this.elementType.equals(arrayType.elementType) && 
               this.size == arrayType.size &&
               this.isNullable == arrayType.isNullable;
    }
    
    override string toString() const {
        string result = elementType.toString();
        if (size > 0) {
            result ~= "[" ~ to!string(size) ~ "]";
        } else {
            result ~= "[]";
        }
        return isNullable ? result ~ "?" : result;
    }
    
    override LCType makeNullable() const {
        return new ArrayType(cast(LCType)elementType, size, true);
    }
    
    override LCType makeNonNullable() const {
        return new ArrayType(cast(LCType)elementType, size, false);
    }
    
    bool isFixedSize() const {
        return size > 0;
    }
    
    bool isDynamic() const {
        return size <= 0;
    }
}

// Struct field definition
struct StructField {
    string name;
    LCType type;
    
    this(string name, LCType type) {
        this.name = name;
        this.type = type;
    }
}

// Struct type for user-defined structs
class StructType : LCType {
    string name;
    StructField[] fields;
    
    this(string name, StructField[] fields, bool isNullable = false) {
        super(isNullable);
        this.name = name;
        this.fields = fields;
    }
    
    override bool equals(LCType other) const {
        auto structType = cast(StructType)other;
        if (structType is null) return false;
        
        if (this.name != structType.name) return false;
        if (this.isNullable != structType.isNullable) return false;
        
        return true; // Same struct name = same type
    }
    
    override string toString() const {
        return isNullable ? name ~ "?" : name;
    }
    
    override LCType makeNullable() const {
        StructField[] newFields;
        foreach (field; fields) {
            newFields ~= StructField(field.name, cast(LCType)field.type);
        }
        return new StructType(name, newFields, true);
    }
    
    override LCType makeNonNullable() const {
        StructField[] newFields;
        foreach (field; fields) {
            newFields ~= StructField(field.name, cast(LCType)field.type);
        }
        return new StructType(name, newFields, false);
    }
    
    // Get field type by name
    LCType getFieldType(string fieldName) const {
        foreach (field; fields) {
            if (field.name == fieldName) {
                return cast(LCType)field.type;
            }
        }
        return null; // field not found
    }
    
    // Check if field exists
    bool hasField(string fieldName) const {
        foreach (field; fields) {
            if (field.name == fieldName) {
                return true;
            }
        }
        return false;
    }
}

// Global struct registry
private StructType[string] registeredStructs;

// Register a struct type
void registerStruct(StructType structType) {
    registeredStructs[structType.name] = structType;
}

// Get a registered struct type by name
StructType getStructType(string name) {
    if (name in registeredStructs) {
        return registeredStructs[name];
    }
    return null;
}

// Clear all registered struct types
void clearStructRegistry() {
    registeredStructs.clear();
}

// Utility functions
LCType parseType(string typeStr) {
    bool nullable = typeStr.length > 0 && typeStr[$-1] == '?';
    if (nullable) {
        typeStr = typeStr[0..$-1];
    }
    
    // Check for array syntax: type[size] or type[]
    import std.string;
    import std.algorithm;
    
    ptrdiff_t bracketPos = typeStr.indexOf('[');
    if (bracketPos != -1) {
        string baseTypeStr = typeStr[0..bracketPos];
        string arrayPart = typeStr[bracketPos..$];
        
        // Parse base type
        LCType baseType = parseType(baseTypeStr);
        if (baseType is null) return null;
        
        // Parse array size
        if (arrayPart == "[]") {
            // Dynamic array
            return new ArrayType(baseType, -1, nullable);
        } else if (arrayPart.startsWith("[") && arrayPart.endsWith("]")) {
            // Fixed size array
            string sizeStr = arrayPart[1..$-1];
            try {
                int size = to!int(sizeStr);
                if (size > 0) {
                    return new ArrayType(baseType, size, nullable);
                }
            } catch (Exception e) {
                return null; // Invalid size
            }
        }
        return null; // Invalid array syntax
    }
    
    // Regular types
    switch (typeStr) {
        case "num":
            return new NumType(nullable);
        case "text":
            return new TextType(nullable);
        case "char":
            return new CharType(nullable);
        case "bool":
            return new BoolType(nullable);
        case "void":
            return new VoidType(); // void cannot be nullable
        default:
            // Check if it's a custom struct type
            StructType structType = getStructType(typeStr);
            if (structType !is null) {
                return nullable ? structType.makeNullable() : structType.makeNonNullable();
            }
            return null; // unknown type
    }
}

bool isNumeric(LCType type) {
    return cast(NumType)type !is null;
}

bool isText(LCType type) {
    return cast(TextType)type !is null;
}

bool isChar(LCType type) {
    return cast(CharType)type !is null;
}

bool isBool(LCType type) {
    return cast(BoolType)type !is null;
}

bool isVoid(LCType type) {
    return cast(VoidType)type !is null;
}

bool isNull(LCType type) {
    return cast(NullType)type !is null;
}

bool isArray(LCType type) {
    return cast(ArrayType)type !is null;
}

bool isFixedArray(LCType type) {
    auto arrayType = cast(ArrayType)type;
    return arrayType !is null && arrayType.isFixedSize();
}

bool isDynamicArray(LCType type) {
    auto arrayType = cast(ArrayType)type;
    return arrayType !is null && arrayType.isDynamic();
}

bool isStruct(LCType type) {
    return cast(StructType)type !is null;
}
