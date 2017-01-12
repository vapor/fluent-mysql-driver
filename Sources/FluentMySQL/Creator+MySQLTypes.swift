import Fluent

extension Schema.Creator {

    /// Creates a DATETIME type
    ///
    /// - Parameters:
    ///   - name: name of column
    ///   - optional: make column optional
    ///   - unique: make column unique
    ///   - default: default value
    public func datetime(
        _ name: String,
        optional: Bool = false,
        unique: Bool = false,
        default value: NodeRepresentable? = nil
        ) {
        self.custom(name, type: "DATETIME", optional: optional, unique: unique, default: value)
    }
    
    // MARK: Timestamps
    
    /// Creates created_at & updated_at DATETIME
    public func timestamps() {
        self.datetime("created_at", optional: true)
        self.datetime("updated_at", optional: true)
    }
    
    
    /// Creates created_at & updated_at DATETIME
    public func softDelete() {
        self.datetime("deleted_at", optional: true)
    }
    
    // MARK: DATE
   
    /// Creates a DATE type
    ///
    /// - Parameters:
    ///   - name: name of column
    ///   - optional: make column optional
    ///   - unique: make column unique
    ///   - default: default value
    public func date(
        _ name: String,
        optional: Bool = false,
        unique: Bool = false,
        default value: NodeRepresentable? = nil
        ) {
        self.custom(name, type: "DATE", optional: optional, unique: unique, default: value)
    }
    
    /*
     MARK: Numeric datatypes
     */
    
    /// Creates a INT type
    ///
    /// - Parameters:
    ///   - name: name of column
    ///   - signed: make column signed/unsigned
    ///   - optional: make column optional
    ///   - unique: make column unique
    ///   - default: default value
    public func integer(
        _ name: String,
        signed: Bool = true,
        optional: Bool = false,
        unique: Bool = false,
        default value: NodeRepresentable? = nil
        ) {
        
        var typeSQL: String = "INTEGER"
        
        if (signed) {
            typeSQL += "(11)"
        } else {
            typeSQL += "(10) UNSIGNED"
        }
        
        self.custom(name, type: typeSQL, optional: optional, unique: unique, default: value)
    }
    
    
    /// Create a TINYINT type
    ///
    /// - Parameters:
    ///   - name: name of column
    ///   - signed: make column signed/unsigned
    ///   - optional: make column optional
    ///   - unique: make column unique
    ///   - default: default value
    public func tinyInteger(
        _ name: String,
        signed: Bool = true,
        optional: Bool = false,
        unique: Bool = false,
        default value: NodeRepresentable? = nil
        ) {
        
        var typeSQL: String = "TINYINT"
        
        if (!signed) {
            typeSQL += " UNSIGNED"
        }
        
        self.custom(name, type: typeSQL, optional: optional, unique: unique, default: value)
    }
    
    /// Create a SMALLINT type
    ///
    /// - Parameters:
    ///   - name: name of column
    ///   - signed: make column signed/unsigned
    ///   - optional: make column optional
    ///   - unique: make column unique
    ///   - default: default value
    public func smallInteger(
        _ name: String,
        signed: Bool = true,
        optional: Bool = false,
        unique: Bool = false,
        default value: NodeRepresentable? = nil
        ) {
        var typeSQL: String = "SMALLINT"
        
        if (!signed) {
            typeSQL += " UNSIGNED"
        }
        
        self.custom(name, type: typeSQL, optional: optional, unique: unique, default: value)
    }
    
    /// Create a MEDIUMINT type
    ///
    /// - Parameters:
    ///   - name: name of column
    ///   - signed: make column signed/unsigned
    ///   - optional: make column optional
    ///   - unique: make column unique
    ///   - default: default value
    public func mediumInteger(
        _ name: String,
        signed: Bool = true,
        optional: Bool = false,
        unique: Bool = false,
        default value: NodeRepresentable? = nil
        ) {
        var typeSQL: String = "MEDIUMINT"
        
        if (!signed) {
            typeSQL += " UNSIGNED"
        }
        
        self.custom(name, type: typeSQL, optional: optional, unique: unique, default: value)
    }
    
    /// Create a BIGINT type
    ///
    /// - Parameters:
    ///   - name: name of column
    ///   - signed: make column signed/unsigned
    ///   - optional: make column optional
    ///   - unique: make column unique
    ///   - default: default value
    public func bigInteger(
        _ name: String,
        signed: Bool = true,
        optional: Bool = false,
        unique: Bool = false,
        default value: NodeRepresentable? = nil
        ) {
        var typeSQL: String = "BIGINT"
        
        if (!signed) {
            typeSQL += " UNSIGNED"
        }
        
        self.custom(name, type: typeSQL, optional: optional, unique: unique, default: value)
    }
    
    /// Create a DECIMAL type
    ///
    /// - Parameters:
    ///   - name: name of column
    ///   - precision: precision of column
    ///   - digits: digits of column
    ///   - signed: make column signed/unsigned
    ///   - optional: make column optional
    ///   - unique: make column unique
    ///   - default: default value
    public func decimal(
        _ name: String,
        precision: UInt = 4,
        digits: UInt = 2,
        signed: Bool = true,
        optional: Bool = false,
        unique: Bool = false,
        default value: NodeRepresentable? = nil
        ) {
        var typeSQL: String = "DECIMAL(" + String(precision) + "," + String(digits) + ")"
        
        if (!signed) {
            typeSQL += " UNSIGNED"
        }
        
        self.custom(name, type: typeSQL, optional: optional, unique: unique, default: value)
    }
    
    /// Create a FLOAT type
    ///
    /// - Parameters:
    ///   - name: name of column
    ///   - precision: precision of column
    ///   - digits: digits of column
    ///   - signed: make column signed/unsigned
    ///   - optional: make column optional
    ///   - unique: make column unique
    ///   - default: default value
    public func float(
        _ name: String,
        precision: UInt = 4,
        digits: UInt = 2,
        signed: Bool = true,
        optional: Bool = false,
        unique: Bool = false,
        default value: NodeRepresentable? = nil
        ) {
        var typeSQL: String = "FLOAT(" + String(precision) + "," + String(digits) + ")"
        
        if (!signed) {
            typeSQL += " UNSIGNED"
        }
        
        self.custom(name, type: typeSQL, optional: optional, unique: unique, default: value)
    }
    
    /// Create a DOUBLE type
    ///
    /// - Parameters:
    ///   - name: name of column
    ///   - precision: precision of column
    ///   - digits: digits of column
    ///   - signed: make column signed/unsigned
    ///   - optional: make column optional
    ///   - unique: make column unique
    ///   - default: default value
    public func double(
        _ name: String,
        precision: UInt = 4,
        digits: UInt = 2,
        signed: Bool,
        optional: Bool = false,
        unique: Bool = false,
        default value: NodeRepresentable? = nil
        ) {
        var typeSQL: String = "DOUBLE(" + String(precision) + "," + String(digits) + ")"
        
        if (!signed) {
            typeSQL += " UNSIGNED"
        }
        
        self.custom(name, type: typeSQL, optional: optional, unique: unique, default: value)
    }
    
    
    /// crete CHAR type
    ///
    /// - Parameters:
    ///   - name: name of column
    ///   - length: length of column
    ///   - optional: make column optional
    ///   - unique: make column unique
    ///   - default: default value
    public func char(
        _ name: String,
        length: UInt = 4,
        optional: Bool = false,
        unique: Bool = false,
        default value: NodeRepresentable? = nil
        ) {
        self.custom(name, type: "CHAR(" + String(length) + ")", optional: optional, unique: unique, default: value)
    }
    
    /// crete VARCHAR type
    ///
    /// - Parameters:
    ///   - name: name of column
    ///   - length: length of column
    ///   - optional: make column optional
    ///   - unique: make column unique
    ///   - default: default value
    public func varchar(
        _ name: String,
        length: UInt = 255,
        optional: Bool = false,
        unique: Bool = false,
        default value: NodeRepresentable? = nil
        ) {
        self.custom(name, type: "VARCHAR(" + String(length) + ")", optional: optional, unique: unique, default: value)
    }
    
    /// crete TEXT type
    ///
    /// - Parameters:
    ///   - name: name of column
    ///   - optional: make column optional
    ///   - unique: make column unique
    ///   - default: default value
    public func text(
        _ name: String,
        optional: Bool = false,
        unique: Bool = false,
        default value: NodeRepresentable? = nil
        ) {
        self.custom(name, type: "TEXT", optional: optional, unique: unique, default: value)
    }
    
    /// crete MEDIUMTEXT type
    ///
    /// - Parameters:
    ///   - name: name of column
    ///   - optional: make column optional
    ///   - unique: make column unique
    ///   - default: default value
    public func mediumText(
        _ name: String,
        optional: Bool = false,
        unique: Bool = false,
        default value: NodeRepresentable? = nil
        ) {
        self.custom(name, type: "MEDIUMTEXT", optional: optional, unique: unique, default: value)
    }
    
    /// crete LONGTEXT type
    ///
    /// - Parameters:
    ///   - name: name of column
    ///   - optional: make column optional
    ///   - unique: make column unique
    ///   - default: default value
    public func longText(
        _ name: String,
        optional: Bool = false,
        unique: Bool = false,
        default value: NodeRepresentable? = nil
        ) {
        self.custom(name, type: "LONGTEXT", optional: optional, unique: unique, default: value)
    }
    
    
    /// Create ENUM type
    ///
    /// - Parameters:
    ///   - name: name of column
    ///   - options: the different options of the enum
    ///   - optional: make column optional
    ///   - unique: make column unique
    ///   - default: default value
    public func `enum`(
        _ name: String,
        options: [String],
        optional: Bool = false,
        unique: Bool = false,
        default value: NodeRepresentable? = nil
        ) {
        
        var typeSQL: String = "ENUM("
        
        for option in options {
            if(typeSQL.characters.last != "(") {
                typeSQL += ","
            }
            
            typeSQL += "'" + option + "'"
        }
        
        typeSQL += ")"
        
        self.custom(name, type: typeSQL, optional: optional, unique: unique, default: value)
    }
}
