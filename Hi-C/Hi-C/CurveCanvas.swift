//
//  CurveCanvas.swift
//  Hilbert Curve Demo
//
//  Created by Martin Castro on 7/27/24.
//

import SwiftUI

struct CurveCanvas: View {
    
    var coordinates: [(UInt16, UInt16)]
    @Binding var spacing: Float
    @Binding var markers: Bool
    @Binding var channels: Bool
    @Binding var channelDepth: Float
    @Binding var lineWidth: Float
    @Binding var markerDiameter: Float
    
    @Binding var dxf: Bool
    @Binding var scale: Float
    
    var cgScaling: CGFloat = 2
    let colors: [GraphicsContext.Shading] = [GraphicsContext.Shading.color(.red),
                                             GraphicsContext.Shading.color(.orange),
                                             GraphicsContext.Shading.color(.yellow),
                                             GraphicsContext.Shading.color(.green),
                                             GraphicsContext.Shading.color(.teal),
                                             GraphicsContext.Shading.color(.blue),
                                             GraphicsContext.Shading.color(.indigo),
                                             GraphicsContext.Shading.color(.purple)]
    
    var body: some View {
        Canvas { context, size in
            let paths = cgPathsFromCoordinates(coordinates)
            let splitPath = cgSplitPathFromCoordinates(coordinates)
            
            if channels{
                let depthPath = paths.0.applying(CGAffineTransform(translationX: 0, y: CGFloat(channelDepth) * cgScaling))
                context.stroke(depthPath, with: .linearGradient(Gradient(colors: [Color.red, Color.green, Color.blue, Color.yellow]), startPoint: paths.0.currentPoint!, endPoint: paths.0.cgPath.boundingBox.origin), lineWidth: CGFloat(channelDepth)*cgScaling*CGFloat(scale))
                context.stroke(depthPath, with: .color(white: 0, opacity: 0.2), lineWidth: CGFloat(lineWidth)*cgScaling*CGFloat(scale))
            }
            if dxf {
                // Single Path
                context.stroke(paths.0, with: .color(.black), lineWidth:  CGFloat(lineWidth)*cgScaling*CGFloat(scale))
                if markers {
                    context.fill(paths.1, with: .color(.black))
                }
            }else{
                // Sectioned Path
                for (index, path) in splitPath.enumerated() {
                    context.stroke(path, with: colors[index], lineWidth: CGFloat(lineWidth)*cgScaling*CGFloat(scale))
                }
                if markers {
                    context.fill(paths.1, with: .color(.secondary))
                }
            }
            let barPath = cgBarPathFromCoordinates(coordinates)
            let gradient = Gradient(colors: [.red, .orange, .yellow, .green, .teal, .blue, .indigo, .purple])
            context.fill(barPath, with: .linearGradient(gradient, startPoint: CGPoint(x: barPath.boundingRect.minX, y: barPath.boundingRect.midY), endPoint: CGPoint(x: barPath.boundingRect.maxX, y: barPath.boundingRect.midY)))
            
            let nIndices = Float(sqrt(Double(coordinates.count)))
            let edgelength = nIndices * (spacing)
            let label = Text(String(format: "%.1f mm", edgelength)).foregroundColor(.primary).font(.caption)
            
            let measurePath = cgMeasurePathFromCoordinates(coordinates)
            context.stroke(measurePath, with: .color(.secondary), style: StrokeStyle(lineWidth: 2, dash: [CGFloat(spacing) * cgScaling]))
            context.translateBy(x: CGFloat(edgelength+spacing+lineWidth) * cgScaling * CGFloat(scale), y: CGFloat(edgelength) * cgScaling * CGFloat(scale) / 2)
            context.rotate(by: Angle(degrees: 90))
            context.draw(label, in: CGRect(origin: CGPoint(x: -20, y: -10), size: CGSize(width: 80, height: 10)))
            
        }//END CANVAS
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .layoutPriority(1)

    }
    
    private func cgPathsFromCoordinates(_ coordinates: [(UInt16, UInt16)]) -> (Path, Path) {
        let cgCoordinates = coordinates.map{ CGPoint(x: CGFloat($0.0) * CGFloat(spacing), y: CGFloat($0.1) * CGFloat(spacing))}
        let linePath = Path { path in
            path.move(to: cgCoordinates[0])
            for point in cgCoordinates {
                path.addLine(to: point)
            }
        }
        let offsetLinePath = linePath.applying(CGAffineTransform(translationX: CGFloat(lineWidth), y: CGFloat(lineWidth)))
        let scaledLinePath = offsetLinePath.applying(CGAffineTransform(scaleX: cgScaling * CGFloat(scale), y: cgScaling * CGFloat(scale)))
        
        let markerPath = Path { path in
            path.move(to: cgCoordinates[0])
            for point in cgCoordinates {
                path.addEllipse(in: CGRect(origin: CGPoint(x: point.x - CGFloat(markerDiameter)/2, y: point.y - CGFloat(markerDiameter)/2), size: CGSize(width: CGFloat(markerDiameter), height: CGFloat(markerDiameter))))
            }
        }
        let offsetMarkerPath = markerPath.applying(CGAffineTransform(translationX: CGFloat(lineWidth), y: CGFloat(lineWidth)))
        let scaledMarkerPath = offsetMarkerPath.applying(CGAffineTransform(scaleX: cgScaling * CGFloat(scale), y: cgScaling * CGFloat(scale)))
        
        return (scaledLinePath, scaledMarkerPath)
    }
    
    private func cgSplitPathFromCoordinates(_ coordinates: [(UInt16, UInt16)]) -> [Path] {
        let cgCoordinates = coordinates.map{ CGPoint(x: CGFloat($0.0) * CGFloat(spacing), y: CGFloat($0.1) * CGFloat(spacing))}
        
        var splitPaths: [Path] = []
        let splits = colors.count
        
        for i in 0..<splits {
            let startPoint = (cgCoordinates.count/splits) * i
            var endPoint = cgCoordinates.count/splits * (i+1) - 1
            
            // Add first point from the next path
            if i != splits - 1 {
                endPoint += 1
            }
            
            let coordinateSlice = Array(cgCoordinates[startPoint...endPoint])
            let path = Path { path in
                path.addLines(coordinateSlice)
            }
            let offsetPath = path.applying(CGAffineTransform(translationX: CGFloat(lineWidth), y: CGFloat(lineWidth)))
            let scaledPath = offsetPath.applying(CGAffineTransform(scaleX: cgScaling * CGFloat(scale), y: cgScaling * CGFloat(scale)))
            splitPaths.append(scaledPath)
        }
        return splitPaths
    }
    
    private func cgBarPathFromCoordinates(_ coordinates: [(UInt16, UInt16)]) -> Path {
        let edgeLength = pathEdgeLength(coordinates)
        let roundedRect = CGRect(origin: CGPoint(x: 0, y: CGFloat(edgeLength)), size: CGSize(width: Double(edgeLength), height: CGFloat(lineWidth)))
        let barPath = Path{ path in
            path.addRoundedRect(in: roundedRect, cornerSize: CGSize(width: 5, height: 5))
        }
        let offsetPath = barPath.applying(CGAffineTransform(translationX: CGFloat(lineWidth), y: CGFloat(lineWidth)))
        let scaledPath = offsetPath.applying(CGAffineTransform(scaleX: cgScaling * CGFloat(scale), y: cgScaling * CGFloat(scale)))
        return scaledPath
    }
    
    private func cgMeasurePathFromCoordinates(_ coordinates: [(UInt16, UInt16)]) -> Path {
        let edgeLength = pathEdgeLength(coordinates)
        
        let measurePath = Path{ path in
            path.move(to: CGPoint(x: CGFloat(edgeLength), y: 0))
            path.addLine(to: CGPoint(x: CGFloat(edgeLength), y: CGFloat(edgeLength)))
        }
        let offsetPath = measurePath.applying(CGAffineTransform(translationX: CGFloat(lineWidth), y: CGFloat(lineWidth)))
        let scaledPath = offsetPath.applying(CGAffineTransform(scaleX: cgScaling * CGFloat(scale), y: cgScaling * CGFloat(scale)))
        return scaledPath
    }
    
    private func pathEdgeLength(_ coordinates: [(UInt16, UInt16)]) -> Float {
        let nIndices = Float(sqrt(Double(coordinates.count)))
        let edgeLength = nIndices * (spacing)
        return edgeLength
    }
    
    static func pathLength(_ coordinates: [(UInt16, UInt16)], spacing: Float) -> Float {
        let cgCoordinates = coordinates.map{ CGPoint(x: CGFloat($0.0) * CGFloat(spacing), y: CGFloat($0.1) * CGFloat(spacing))}
        var distanceX: CGFloat = 0
        var distanceY: CGFloat = 0
        
        var lastPoint: CGPoint = cgCoordinates[0]
        for point in cgCoordinates{
            distanceX += abs(point.x - lastPoint.x)
            distanceY += abs(point.y - lastPoint.y)
            lastPoint = point
        }
        return Float(distanceX + distanceY)
    }
    
    static func pathArea(_ coordinates: [(UInt16, UInt16)], spacing: Float, pathWidth: Float) -> Float {
        let pathDistance = CurveCanvas.pathLength(coordinates, spacing: spacing)
        let pathArea = pathDistance * pathWidth
        return pathArea
    }
    
    static func markerArea(nIndices: Int, markerDiameter: Float, pathWidth: Float) -> Float{
        if markerDiameter <= pathWidth { return 0 }
        
        // Find chord length for path edge through marker
        let length = 2 * sqrt(pow((markerDiameter/2), 2) - pow((pathWidth/2), 2))
        // Find central angle for chord section
        let angle = 2 * asin(length/(markerDiameter))
        // Find area for section bounded by chord
        let sectionArea = 0.5 * pow((markerDiameter/2), 2) * (angle - sin(angle))
        // Double for each node and sum
        let numNodes = Float(nIndices * nIndices)
        let totalArea = 2 * numNodes * sectionArea
        
        return totalArea
    }
}
