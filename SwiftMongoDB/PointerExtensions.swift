//
//  PointerExtensions.swift
//  SwiftMongoDB
//
//  Created by Dan Appel on 11/22/15.
//  Copyright © 2015 Dan Appel. All rights reserved.
//

// cannot be generic due to Swift compiler constraints
class UnsafeMutablePointerGenerator: GeneratorType {

    typealias Pointer = UnsafeMutablePointer<Element>
    typealias Element = UnsafeMutablePointer<Int8>
    
    let pointer: Pointer
    var index: Int

    var element: Element? {
        
        if self.pointer.advancedBy(index).memory == nil {
            return nil
        }
        
        return self.pointer.advancedBy(index).memory
    }

    init(pointer: Pointer) {
        self.index = 0
        self.pointer = pointer
    }

    func next() -> Element? {
        defer { index++ }
        return element
    }
}

class UnsafeMutablePointerSequence: SequenceType {


    let pointer: UnsafeMutablePointerGenerator.Pointer
    init(pointer: UnsafeMutablePointerGenerator.Pointer) {
        self.pointer = pointer
    }

    func generate() -> UnsafeMutablePointerGenerator {
        return UnsafeMutablePointerGenerator(pointer: pointer)
    }
}

func sequence(pointer: UnsafeMutablePointerGenerator.Pointer) -> UnsafeMutablePointerSequence {
    return UnsafeMutablePointerSequence(pointer: pointer)
}
