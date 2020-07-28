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

extension DatabaseID {
    public static var mysql: DatabaseID {
        return .init(string: "mysql")
    }
}
