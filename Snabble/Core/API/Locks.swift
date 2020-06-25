//
//  Locks.swift
//
//  Copyright © 2020 snabble. All rights reserved.
//

// Simple mutex and read/write lock wrappers around pthread_ methods

import Foundation

final class ReadWriteLock {
    private var lock: pthread_rwlock_t

    init() {
        lock = pthread_rwlock_t()
        pthread_rwlock_init(&lock, nil)
    }

    deinit {
        pthread_rwlock_destroy(&lock)
    }

    func writeLock() {
        pthread_rwlock_wrlock(&lock)
    }

    func readLock() {
        pthread_rwlock_rdlock(&lock)
    }

    func unlock() {
        pthread_rwlock_unlock(&lock)
    }

    func reading<T>(closure: () -> T) -> T {
        self.readLock()
        defer { self.unlock() }
        return closure()
    }

    func writing<T>(closure: () -> T) -> T {
        self.writeLock()
        defer { self.unlock() }
        return closure()
    }
}

final class Mutex {
    private var mutex: pthread_mutex_t

    init() {
        mutex = pthread_mutex_t()
        pthread_mutex_init(&mutex, nil)
    }

    deinit {
        pthread_mutex_destroy(&mutex)
    }

    func lock() {
        pthread_mutex_lock(&mutex)
    }

    func unlock() {
        pthread_mutex_unlock(&mutex)
    }

    func trylock() {
        pthread_mutex_trylock(&mutex)
    }

    func run<T>(closure: () -> T) -> T {
        self.lock()
        defer { self.unlock() }
        return closure()
    }
}
