
// Iterative Hilbert Curve in Swift
// Original algorithm by Marcin Chwedczuk
// Translated by Martin Castro 2021


import Foundation

let startTime = CFAbsoluteTimeGetCurrent()

// MARK: - Hilbert Curve Struct

struct HilbertCurve {
    
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
        
        // Quadrant position within our N=2 curve (ie. our 2x2 building block)
        // 0 at the bottom left and 3 at the bottom right.
        let positions: [[UInt16]] = [
            /* 0: */ [0, 0],
            /* 1: */ [0, 1],
            /* 2: */ [1, 1],
            /* 3: */ [1, 0]
            ]
        
        // Returns [x,y] coordinates within our 2x2 building block
        let initialPositions = positions[Int(last2bits(of: index))]
        
        var x = initialPositions[0]
        var y = initialPositions[1]
        var temp: UInt16 = 0
        
        // We are now looking at the next 2 bits, which represent the quadrant position within the encapsulating (N = 4) curve.
        // Shifting bits 2 to the right divides by 4 and throws out remainders ie. 17 -> 4
        index = index >> 2
        
        
        
        // The current amount of indices
        // Brought up by factor of 2 (thus multiplying numbers by 4)
        var k: UInt16 = 4
        
        while(k <= maxIndices) {
            
            // Used to calculate amount of transform to add to our 2x2 building block
            let k2: UInt16 = k/2
            
            // Transform and/or flip the 2x2 curve's coordinates, maintaining proper position and orientation within the encapsulating curve.
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
            
            // Bring k up by factor of 2 until the coordinates have been transformed enough
            k *= 2
            
            // Shift 2 bits again
            index = index >> 2
        }
        
        return (x: x, y: y)
    }
}

// MARK: - Just playing around...

let indices = UInt16(8)

let hilbert = HilbertCurve(nIndices: indices)
print(hilbert.coordinates)
print(hilbert.coordinates.count)

let diff = CFAbsoluteTimeGetCurrent() - startTime
print("It took \(diff) seconds to create a curve with \(indices) indices (\(indices*indices) points) on a 13 inch M1 Macbook Pro.")

// It took 2.4 seconds for 32 indices
// It took 373.6 seconds for 128 indices
// Turning off metrics on Swift Playgrounds is a DRASTIC improvement
