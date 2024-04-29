@_documentation(visibility: internal) @_exported import FluentKit

@_documentation(visibility: internal) @_exported import struct Foundation.URL

@_documentation(visibility: internal) @_exported import struct MySQLKit.MySQLConfiguration
@_documentation(visibility: internal) @_exported import struct MySQLKit.MySQLConnectionSource
@_documentation(visibility: internal) @_exported import struct MySQLKit.MySQLDataEncoder
@_documentation(visibility: internal) @_exported import struct MySQLKit.MySQLDataDecoder

@_documentation(visibility: internal) @_exported import class MySQLNIO.MySQLConnection
@_documentation(visibility: internal) @_exported import enum MySQLNIO.MySQLError
@_documentation(visibility: internal) @_exported import struct MySQLNIO.MySQLData
@_documentation(visibility: internal) @_exported import protocol MySQLNIO.MySQLDatabase
@_documentation(visibility: internal) @_exported import protocol MySQLNIO.MySQLDataConvertible
@_documentation(visibility: internal) @_exported import struct MySQLNIO.MySQLRow

@_documentation(visibility: internal) @_exported import struct NIOSSL.TLSConfiguration

extension DatabaseID {
    /// A default `DatabaseID` to use for MySQL databases.
    public static var mysql: DatabaseID {
        .init(string: "mysql")
    }
}
