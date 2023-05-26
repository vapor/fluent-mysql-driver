#if swift(>=5.8)

@_documentation(visiblity: internal) @_exported import FluentKit

@_documentation(visiblity: internal) @_exported import struct Foundation.URL

@_documentation(visiblity: internal) @_exported import struct MySQLKit.MySQLConfiguration
@_documentation(visiblity: internal) @_exported import struct MySQLKit.MySQLConnectionSource
@_documentation(visiblity: internal) @_exported import struct MySQLKit.MySQLDataEncoder
@_documentation(visiblity: internal) @_exported import struct MySQLKit.MySQLDataDecoder

@_documentation(visiblity: internal) @_exported import class MySQLNIO.MySQLConnection
@_documentation(visiblity: internal) @_exported import enum MySQLNIO.MySQLError
@_documentation(visiblity: internal) @_exported import struct MySQLNIO.MySQLData
@_documentation(visiblity: internal) @_exported import protocol MySQLNIO.MySQLDatabase
@_documentation(visiblity: internal) @_exported import protocol MySQLNIO.MySQLDataConvertible
@_documentation(visiblity: internal) @_exported import struct MySQLNIO.MySQLRow

@_documentation(visiblity: internal) @_exported import struct NIOSSL.TLSConfiguration

#else

@_exported import FluentKit

@_exported import struct Foundation.URL

@_exported import struct MySQLKit.MySQLConfiguration
@_exported import struct MySQLKit.MySQLConnectionSource
@_exported import struct MySQLKit.MySQLDataEncoder
@_exported import struct MySQLKit.MySQLDataDecoder

@_exported import class MySQLNIO.MySQLConnection
@_exported import enum MySQLNIO.MySQLError
@_exported import struct MySQLNIO.MySQLData
@_exported import protocol MySQLNIO.MySQLDatabase
@_exported import protocol MySQLNIO.MySQLDataConvertible
@_exported import struct MySQLNIO.MySQLRow

@_exported import struct NIOSSL.TLSConfiguration

#endif

extension DatabaseID {
    public static var mysql: DatabaseID {
        return .init(string: "mysql")
    }
}
