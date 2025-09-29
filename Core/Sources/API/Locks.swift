//
//  Locks.swift
//
//  Copyright © 2020 snabble. All rights reserved.
//

// Simple mutex and read/write lock wrappers around pthread_ methods

import Foundation

public final class ReadWriteLock: @unchecked Sendable {
    private var lock: pthread_rwlock_t

    public init() {
        lock = pthread_rwlock_t()
        pthread_rwlock_init(&lock, nil)
    }

    deinit {
        pthread_rwlock_destroy(&lock)
    }

    private func writeLock() {
        pthread_rwlock_wrlock(&lock)
    }

    private func readLock() {
        pthread_rwlock_rdlock(&lock)
    }

    private func unlock() {
        pthread_rwlock_unlock(&lock)
    }

    public func reading<T>(_ closure: () -> T) -> T {
        self.readLock()
        defer { self.unlock() }
        return closure()
    }

    public func writing<T>(_ closure: () -> T) -> T {
        self.writeLock()
        defer { self.unlock() }
        return closure()
    }
}

public final class Mutex: @unchecked Sendable {
    private var mutex: pthread_mutex_t

    public init() {
        mutex = pthread_mutex_t()
        pthread_mutex_init(&mutex, nil)
    }

    deinit {
        pthread_mutex_destroy(&mutex)
    }

    public func lock() {
        pthread_mutex_lock(&mutex)
    }

    public func unlock() {
        pthread_mutex_unlock(&mutex)
    }

    func run<T>(closure: () -> T) -> T {
        self.lock()
        defer { self.unlock() }
        return closure()
    }
}
