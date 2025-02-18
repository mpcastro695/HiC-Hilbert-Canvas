//
//  HilbertCurve.swift
//
//  Created by Martin Castro on 11/23/21.
//  Original algorithm by Marcin Chwedczuk

import Foundation

// MARK: - Hilbert Curve Struct

struct HilbertCurve {
    
    let startTime = CFAbsoluteTimeGetCurrent()
    
    var nIndices: UInt16
    var coordinates: [(x: UInt16, y: UInt16)] = []
    
    init(nIndices: UInt16){
        self.nIndices = nIndices
        var coordinates: [(x: UInt16, y: UInt16)] = []
        
        for hIndex in 0..<(nIndices*nIndices) {
            let coord = hIndex2XY(hIndex: hIndex, maxIndices: nIndices)
            coordinates.append(coord)
        }
        self.coordinates = coordinates
    }
    
// MARK: - Hilbert Curve Algorithm
    
    // Helper Function to check value of last 2 bits
    func last2bits(of byte: UInt16) -> UInt16 {
        return (byte & 3)
        // 3 -> 0011
    }
    
    // Algorithm for turning Hilbert Index into Cortesian Coordinates
    func hIndex2XY(hIndex: UInt16, maxIndices: UInt16 ) -> (x: UInt16, y: UInt16) {
        
        var index = hIndex
        
        // Initial coordinates within our base N=2 curve (ie. our 2x2 building block)
        // Pattern goes from 0 at the bottom left to 3 at the bottom right.
        let positions: [[UInt16]] = [
            /* 0: */ [0, 0],
            /* 1: */ [0, 1],
            /* 2: */ [1, 1],
            /* 3: */ [1, 0]
            ]
        
        let initialPosition = positions[Int(last2bits(of: index))]
        
        var x = initialPosition[0]
        var y = initialPosition[1]
        var temp: UInt16 = 0
        
        // Shifting 2 bits to the right (divides by 4 and throws out remainder, ie. 17 -> 4)
        // We are now looking at the next 2 bits, which represent the quadrant position within the encapsulating (N = 4) curve.
        index = index >> 2
        
        // Current amount of indices
        var k: UInt16 = 4
        while(k <= maxIndices) {
            
            // Used to calculate amount of transform to add
            let k2: UInt16 = k/2
            
            // Iteratively transform/flip the coordinates of our N = K curve to maintainin proper position and orientation
            switch last2bits(of: index){
            case 0: // Left Bottom, flip along diagonal
                temp = x
                x = y
                y = temp
                break
            case 1: // Left Upper, translate upward
                y = y + k2
                break
            case 2: // Right Upper, translate upward and to right
                x = x + k2
                y = y + k2
                break
            case 3: // Right Bottom, flip along opposite diagonal and translate to the right
                temp = y
                y = (k2-1) - x
                x = (k2-1) - temp
                x = x + k2
                break
            default:
                print("Whoops! No curve for you!")
            }
            
            // Double the indices in each direction
            k *= 2
            // Shift 2 bits again and repeat
            index = index >> 2
        }
        
        return (x: x, y: y)
    }
}
