FROM vapor/swift:5.0
COPY ./Sources ./Sources
COPY ./Tests ./Tests
COPY ./Package.swift ./Package.swift
RUN swift test -l
ENTRYPOINT lldb .build/x86_64-unknown-linux/debug/fluent-mysql-driverPackageTests.xctest
