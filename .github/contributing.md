# Contributing to Fluent's MySQL Driver

👋 Welcome to the Vapor team! 

## Database

In order to build and test against Postgres, you will need a database running. The easiest way to do this is using Docker and the included `docker-compose.yml` file.

If you have Docker installed on your computer, all you will need to do is:

```fish
docker-compose  mysql-a mysql-b
# or for mariadb
docker-compose  mariadb-a mariadb-b
```

This will start the two databases required for running this package's unit tests. One of the databases will run on MySQL's default port 3306 and the other on 3307.

### Environment Variables

You will need to set the following environment variable to run the tests:

```
MYSQL_PORT_B=3307
```

This tells the tests that the second database is running on a different port.

You may also set the log level variable to increase or decrease logging:

```
LOG_LEVEL=notice
```

In Xcode, edit the `fluent-mysql-driver` scheme to add env variables. In the terminal, use `export`. 

## Xcode

To open the project in Xcode:

- Clone the repo to your computer
- Drag and drop the folder onto Xcode

You can then run the unit tests in Xcode by pressing `CMD+U`. 

## SPM

To develop using SPM, open the code in your favorite code editor. Use the following commands from within the project's root folder to build and test.

```sh
swift build
swift test
```

## SemVer

Vapor follows [SemVer](https://semver.org). This means that any changes to the source code that can cause
existing code to stop compiling _must_ wait until the next major version to be included. 

Code that is only additive and will not break any existing code can be included in the next minor release.

----------

Join us on Discord if you have any questions: [vapor.team](http://vapor.team).

&mdash; Thanks! 🙌
