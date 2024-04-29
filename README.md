<p align="center">
<picture>
  <source media="(prefers-color-scheme: dark)" srcset="https://github.com/vapor/mysql-kit/assets/1130717/d5582d0a-f8b2-4fab-aeea-79b170bebc28">
  <source media="(prefers-color-scheme: light)" srcset="https://github.com/vapor/mysql-kit/assets/1130717/71d0fa71-5ded-492c-9657-4206f233419e">
  <img src="https://github.com/vapor/mysql-kit/assets/1130717/71d0fa71-5ded-492c-9657-4206f233419e" height="96" alt="FluentMySQLDriver">
</picture> 
<br>
<br>
<a href="https://docs.vapor.codes/4.0/"><img src="https://design.vapor.codes/images/readthedocs.svg" alt="Documentation"></a>
<a href="https://discord.gg/vapor"><img src="https://design.vapor.codes/images/discordchat.svg" alt="Team Chat"></a>
<a href="LICENSE"><img src="https://design.vapor.codes/images/mitlicense.svg" alt="MIT License"></a>
<a href="https://github.com/vapor/fluent-mysql-driver/actions/workflows/test.yml"><img src="https://img.shields.io/github/actions/workflow/status/vapor/fluent-mysql-driver/test.yml?event=push&style=plastic&logo=github&label=tests&logoColor=%23ccc" alt="Continuous Integration"></a>
<a href="https://codecov.io/github/vapor/fluent-mysql-driver"><img src="https://img.shields.io/codecov/c/github/vapor/fluent-mysql-driver?style=plastic&logo=codecov&label=codecov"></a>
<a href="https://swift.org"><img src="https://design.vapor.codes/images/swift58up.svg" alt="Swift 5.8+"></a>
</p>

<br>

FluentMySQLDriver is a [FluentKit] driver for MySQL clients. It provides support for using the Fluent ORM with MySQL databases, and uses [MySQLKit] to provide [SQLKit] driver services, [MySQLNIO] to connect and communicate with the database server asynchronously, and [AsyncKit] to provide connection pooling.

[FluentKit]: https://github.com/vapor/fluent-kit
[SQLKit]: https://github.com/vapor/sql-kit
[MySQLKit]: https://github.com/vapor/mysql-kit
[MySQLNIO]: https://github.com/vapor/mysql-nio
[AsyncKit]: https://github.com/vapor/async-kit

### Usage

Use the SPM string to easily include the dependendency in your `Package.swift` file:

```swift
.package(url: "https://github.com/vapor/fluent-mysql-driver.git", from: "4.0.0")
```

For additional information, see [the Fluent documentation](https://docs.vapor.codes/fluent/overview/).
