//
//  PointerExtensions.swift
//  SwiftMongoDB
//
//  Created by Dan Appel on 11/22/15.
//  Copyright © 2015 Dan Appel. All rights reserved.
//

// TODO: Make this more generic
struct UnsafeMutablePointerSequence {

    typealias Pointer = UnsafeMutablePointer<Element>
    typealias Element = UnsafeMutablePointer<Int8>

    var pointer: Pointer
}

extension UnsafeMutablePointerSequence: SequenceType {
    func generate() -> UnsafeMutablePointerSequence {
        return UnsafeMutablePointerSequence(pointer: pointer)
    }
}
extension UnsafeMutablePointerSequence: GeneratorType {
    mutating func next() -> Element? {
        defer { pointer = pointer.advancedBy(1) }

        if pointer.memory == nil {
            return nil
        }

        return pointer.memory
    }
}


protocol UnsafeMutablePointerType {}
extension UnsafeMutablePointer: UnsafeMutablePointerType {}


// constrains memory memory to UnsafeMutablePointer
// ie: UnsafeMutablePointer<UnsafeMutablePointer<T>>
extension UnsafeMutablePointer where Memory: UnsafeMutablePointerType {
    func sequence() -> UnsafeMutablePointerSequence? {

        switch memory {
        case is UnsafeMutablePointer<Int8>:
            let ptr = UnsafeMutablePointer<UnsafeMutablePointer<Int8>>(self)
            return UnsafeMutablePointerSequence(pointer: ptr)

        default:
            return nil
        }
    }
}
