import FluentSQL

internal class MySQLSerializer: SQLSerializer {
    /// Creates a new `MySQLSerializer`
    init() { }

    /// See `SQLSerializer.makeEscapedString(from:)`
    func makeEscapedString(from string: String) -> String {
        return "`\(string)`"
    }

    /// See `SQLSerializer.makePlaceholder(name:)`
    func makePlaceholder(name: String) -> String {
        return "?"
    }
}
