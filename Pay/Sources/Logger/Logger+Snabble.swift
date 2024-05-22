//
//  Logger+Snabble.swift
//
//
//  Created by Andreas Osberghaus on 2023-03-09.
//

import Foundation
import Logging

public class Logger {
    let label: String

    public static var shared: Logger = {
        .init(label: "io.snabble.paysdk")
    }()

    private init(label: String) {
        self.label = label
    }

    public lazy var logger = Logging.Logger(label: label)

    public var logLevel: Level {
        get {
            logger.logLevel.toSnabble()
        }
        set {
            logger.logLevel = newValue.toLogging()
        }
    }

    public func trace(_ message: @autoclosure () -> Logging.Logger.Message,
                      metadata: @autoclosure () -> Logging.Logger.Metadata? = nil,
                      file: String = #fileID, function: String = #function, line: UInt = #line) {
        logger.trace(message(), metadata: metadata(), file: file, function: function, line: line)
    }

    public func debug(_ message: @autoclosure () -> Logging.Logger.Message,
                      metadata: @autoclosure () -> Logging.Logger.Metadata? = nil,
                      file: String = #fileID, function: String = #function, line: UInt = #line) {
        logger.debug(message(), metadata: metadata(), file: file, function: function, line: line)
    }

    public func info(_ message: @autoclosure () -> Logging.Logger.Message,
                     metadata: @autoclosure () -> Logging.Logger.Metadata? = nil,
                     file: String = #fileID, function: String = #function, line: UInt = #line) {
        logger.info(message(), metadata: metadata(), file: file, function: function, line: line)
    }

    public func notice(_ message: @autoclosure () -> Logging.Logger.Message,
                       metadata: @autoclosure () -> Logging.Logger.Metadata? = nil,
                       file: String = #fileID, function: String = #function, line: UInt = #line) {
        logger.notice(message(), metadata: metadata(), file: file, function: function, line: line)
    }

    public func warning(_ message: @autoclosure () -> Logging.Logger.Message,
                        metadata: @autoclosure () -> Logging.Logger.Metadata? = nil,
                        file: String = #fileID, function: String = #function, line: UInt = #line) {
        logger.warning(message(), metadata: metadata(), file: file, function: function, line: line)
    }

    public func error(_ message: @autoclosure () -> Logging.Logger.Message,
                      metadata: @autoclosure () -> Logging.Logger.Metadata? = nil,
                      file: String = #fileID, function: String = #function, line: UInt = #line) {
        logger.error(message(), metadata: metadata(), file: file, function: function, line: line)
    }

    public func critical(_ message: @autoclosure () -> Logging.Logger.Message,
                         metadata: @autoclosure () -> Logging.Logger.Metadata? = nil,
                         file: String = #fileID, function: String = #function, line: UInt = #line) {
        logger.critical(message(), metadata: metadata(), file: file, function: function, line: line)
    }
}

extension Logger {
    /// The log level.
    ///
    /// Log levels are ordered by their severity, with `.trace` being the least severe and
    /// `.critical` being the most severe.
    public enum Level: String, Codable, CaseIterable {
        /// Appropriate for messages that contain information normally of use only when
        /// tracing the execution of a program.
        case trace

        /// Appropriate for messages that contain information normally of use only when
        /// debugging a program.
        case debug

        /// Appropriate for informational messages.
        case info

        /// Appropriate for conditions that are not error conditions, but that may require
        /// special handling.
        case notice

        /// Appropriate for messages that are not error conditions, but more severe than
        /// `.notice`.
        case warning

        /// Appropriate for error conditions.
        case error

        /// Appropriate for critical error conditions that usually require immediate
        /// attention.
        ///
        /// When a `critical` message is logged, the logging backend (`LogHandler`) is free to perform
        /// more heavy-weight operations to capture system state (such as capturing stack traces) to facilitate
        /// debugging.
        case critical
    }
}

extension Logging.Logger.Level {
    func toSnabble() -> Logger.Level {
        switch self {
        case .trace:
            return .trace
        case .info:
            return .info
        case .error:
            return .error
        case .critical:
            return .critical
        case .debug:
            return .debug
        case .notice:
            return .notice
        case .warning:
            return .warning
        }
    }
}

extension Logger.Level {
    func toLogging() -> Logging.Logger.Level {
        switch self {
        case .trace:
            return .trace
        case .info:
            return .info
        case .error:
            return .error
        case .critical:
            return .critical
        case .debug:
            return .debug
        case .notice:
            return .notice
        case .warning:
            return .warning
        }
    }
}
