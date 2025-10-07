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
    
    @Binding var isExporting: Bool
    
    let cgScaling: CGFloat = 2
    let colors: [GraphicsContext.Shading] = [GraphicsContext.Shading.color(.red),
                                             GraphicsContext.Shading.color(.orange),
                                             GraphicsContext.Shading.color(.yellow),
                                             GraphicsContext.Shading.color(.green),
                                             GraphicsContext.Shading.color(.teal),
                                             GraphicsContext.Shading.color(.blue),
                                             GraphicsContext.Shading.color(.indigo),
                                             GraphicsContext.Shading.color(.purple)]
    
    var body: some View {
        
        let paths = cgPathsFromCoordinates(coordinates)
        let splitPath = cgSplitPathsFromCoordinates(coordinates)
        let transitionPoints = cgTransitionPointsFromCoordinates(coordinates)
        
        ZStack{
            // MARK: - Depth Layer
            Canvas { context, size in
                if channels{
                    let depthPaths = cgDepthPathsFromCoordinates(coordinates).0
                    let markerPaths = cgDepthPathsFromCoordinates(coordinates).1
                    let gradient = GraphicsContext.Shading.linearGradient(Gradient(colors: [Color.red, Color.green, Color.blue, Color.yellow]), startPoint: paths.0.currentPoint!, endPoint: paths.0.cgPath.boundingBox.origin)
    
                    for depthPath in depthPaths {
                        context.stroke(depthPath, with: gradient, lineWidth: CGFloat(lineWidth)*cgScaling*CGFloat(scale))
                    }
                    if markers{
                        context.stroke(markerPaths.0, with: gradient, lineWidth: CGFloat(markerDiameter)*cgScaling*CGFloat(scale))
                        context.fill(markerPaths.1, with: gradient)
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .layoutPriority(0)
            .opacity(0.6)
            
            // MARK: - Main Layer
            Canvas { context, size in
                if dxf {
                    // Convert stroked line into fillable shape.
                    let strokedLine = paths.0.strokedPath(
                        StrokeStyle(lineWidth: CGFloat(lineWidth) * cgScaling * CGFloat(scale))
                    )

                    // Union line shape with marker shapes.
                    var combinedPath = strokedLine
                    if markers {
                        let markersPath = paths.1
                        combinedPath = pathUnion(strokedLine, with: markersPath)
                    }

                    context.fill(combinedPath, with: .color(isExporting ? .black : .primary))
                    
                } else {
                    // Sectioned Path
                    for (index, path) in splitPath.0.enumerated() {
                        context.stroke(path, with: colors[index], lineWidth: CGFloat(lineWidth)*cgScaling*CGFloat(scale))
                    }
                    // Gradient Transitions
                    for (index, pointPair) in transitionPoints.enumerated() {
                        let transitionColors: [Color] = [.red, .orange, .yellow, .green, .teal, .blue, .indigo, .purple]
                        let startPoint = pointPair.0
                        let endPoint = pointPair.1
                        let path = Path{ path in
                            path.addLines([startPoint, endPoint])
                        }
                        let gradient = Gradient(colors: Array(transitionColors[index...index+1]))
                        let gcGradient = GraphicsContext.Shading.linearGradient(gradient, startPoint: startPoint, endPoint: endPoint)
                        context.stroke(path, with: gcGradient, lineWidth: CGFloat(lineWidth)*cgScaling*CGFloat(scale))
                    }
                    if markers {
                        if markerDiameter > lineWidth {
                            for (index, markerPath) in splitPath.1.enumerated() {
                                context.fill(markerPath, with: colors[index])
                            }
                        }else{
                            context.fill(paths.1, with: .color(.white))
                        }
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
                
            }//END MAIN CANVAS
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .layoutPriority(1)
        }// END ZSTACK
        .padding(5)

    }
    
    private func pathUnion(_ path1: Path, with path2: Path) -> Path {
        let cgPath1 = path1.cgPath
        let cgPath2 = path2.cgPath
        
        let unionCGPath = cgPath1.union(cgPath2)
        return Path(unionCGPath)
    }
    
    private func cgCoordinatesFromCartesian(_ coordinates: [(UInt16, UInt16)]) -> [CGPoint] {
        return coordinates.map{ CGPoint(x: CGFloat($0.0) * CGFloat(spacing), y: CGFloat($0.1) * CGFloat(spacing))}
    }
    
    private func cgPathsFromCoordinates(_ coordinates: [(UInt16, UInt16)]) -> (Path, Path) {
        let cgCoordinates = cgCoordinatesFromCartesian(coordinates)
        let linePath = Path { path in
            path.move(to: cgCoordinates[0])
            for point in cgCoordinates {
                path.addLine(to: point)
            }
        }
        let offset = max(lineWidth, markerDiameter)
        let offsetLinePath = linePath.applying(CGAffineTransform(translationX: CGFloat(offset), y: CGFloat(offset)))
        let scaledLinePath = offsetLinePath.applying(CGAffineTransform(scaleX: cgScaling * CGFloat(scale), y: cgScaling * CGFloat(scale)))
        
        let markerPath = Path { path in
            path.move(to: cgCoordinates[0])
            for point in cgCoordinates {
                path.addEllipse(in: CGRect(origin: CGPoint(x: point.x - CGFloat(markerDiameter)/2, y: point.y - CGFloat(markerDiameter)/2), size: CGSize(width: CGFloat(markerDiameter), height: CGFloat(markerDiameter))))
            }
        }
        let offsetMarkerPath = markerPath.applying(CGAffineTransform(translationX: CGFloat(offset), y: CGFloat(offset)))
        let scaledMarkerPath = offsetMarkerPath.applying(CGAffineTransform(scaleX: cgScaling * CGFloat(scale), y: cgScaling * CGFloat(scale)))
        
        return (scaledLinePath, scaledMarkerPath)
    }
    
    private func cgSplitPathsFromCoordinates(_ coordinates: [(UInt16, UInt16)]) -> ([Path], [Path]) {
        let cgCoordinates = cgCoordinatesFromCartesian(coordinates)
        
        let splits = colors.count
        var splitPaths: [Path] = []
        var splitMarkerPaths: [Path] = []
        
        for i in 0..<splits {
            let startPoint = (cgCoordinates.count/splits) * i
            var endPoint = cgCoordinates.count/splits * (i+1) - 1
            
            // Add two points from the next path
            if i != splits - 1 {
                endPoint += 2
            }
            
            var coordinateSlice = Array(cgCoordinates[startPoint...endPoint])
            let path = Path { path in
                path.addLines(coordinateSlice)
            }
            let offset = max(lineWidth, markerDiameter)
            let offsetPath = path.applying(CGAffineTransform(translationX: CGFloat(offset), y: CGFloat(offset)))
            let scaledPath = offsetPath.applying(CGAffineTransform(scaleX: cgScaling * CGFloat(scale), y: cgScaling * CGFloat(scale)))
            splitPaths.append(scaledPath)
            
            if i != 0 {
                coordinateSlice.removeFirst(1)
            }
            let markerPath = Path { path in
                path.move(to: coordinateSlice[0])
                for point in coordinateSlice {
                    path.addEllipse(in: CGRect(origin: CGPoint(x: point.x - CGFloat(markerDiameter)/2, y: point.y - CGFloat(markerDiameter)/2), size: CGSize(width: CGFloat(markerDiameter), height: CGFloat(markerDiameter))))
                }
            }
            let offsetMarkerPath = markerPath.applying(CGAffineTransform(translationX: CGFloat(offset), y: CGFloat(offset)))
            let scaledMarkerPath = offsetMarkerPath.applying(CGAffineTransform(scaleX: cgScaling * CGFloat(scale), y: cgScaling * CGFloat(scale)))
            splitMarkerPaths.append(scaledMarkerPath)
        }
        return (splitPaths, splitMarkerPaths)
    }
    
    private func cgTransitionPointsFromCoordinates(_ coordinates: [(UInt16, UInt16)]) -> [(CGPoint, CGPoint)] {
        let cgCoordinates = cgCoordinatesFromCartesian(coordinates)
        
        var transitionPoints: [(CGPoint, CGPoint)] = []
        let transitions = colors.count - 1
        
        for i in 0..<transitions {
            let startPoint = (cgCoordinates.count/colors.count) * (i + 1)
            let endPoint = startPoint + 1
            
            var scaledSlice: [CGPoint] = []
            let coordinateSlice = Array(cgCoordinates[startPoint...endPoint])
            for coordinate in coordinateSlice {
                let offset = max(lineWidth, markerDiameter)
                let offsetPoint = CGPoint(x: coordinate.x + CGFloat(offset), y: coordinate.y + CGFloat(offset))
                let scaledPoint = CGPoint(x: offsetPoint.x * CGFloat(scale) * cgScaling, y: offsetPoint.y * CGFloat(scale) * cgScaling)
                scaledSlice.append(scaledPoint)
            }
            
            transitionPoints.append((scaledSlice[0], scaledSlice[1]))
        }
        return transitionPoints
    }
    
    private func cgDepthPathsFromCoordinates(_ coordinates: [(UInt16, UInt16)]) -> ([Path], (Path, Path)) {
        let path = cgPathsFromCoordinates(coordinates).0
        let pathCount = Int(ceil(channelDepth/lineWidth))
        
        var depthPaths: [Path] = []
        if pathCount<=1 {
            let offsetPath = path.applying(CGAffineTransform(translationX: 0, y: CGFloat(channelDepth*scale)*cgScaling))
            depthPaths.append(offsetPath)
        }else{
            for i in 1...pathCount {
                if i==pathCount && floor(channelDepth/lineWidth) != channelDepth/lineWidth {
                    let offset = CGFloat(channelDepth/lineWidth) * cgScaling * CGFloat(scale) * CGFloat(lineWidth)
                    let offsetPath = path.applying(CGAffineTransform(translationX: 0, y: offset))
                    depthPaths.append(offsetPath)
                }else{
                    let offsetPath = path.applying(CGAffineTransform(translationX: 0, y: CGFloat(lineWidth * Float(i)*scale)*cgScaling))
                    depthPaths.append(offsetPath)
                }
            }
        }
        let cgCoordinates = cgCoordinatesFromCartesian(coordinates)
        let markerLinePath = Path { path in
            path.move(to: cgCoordinates[0])
            for (index, point) in cgCoordinates.enumerated() {
                path.addLine(to: CGPoint(x: point.x, y: point.y + CGFloat(channelDepth)))
                if index == cgCoordinates.count-1 { break }
                path.move(to: cgCoordinates[index + 1])
            }
        }
        let offset = max(lineWidth, markerDiameter)
        let offsetLineMarkerPath = markerLinePath.applying(CGAffineTransform(translationX: CGFloat(offset), y: CGFloat(offset)))
        let scaledMarkerLinePath = offsetLineMarkerPath.applying(CGAffineTransform(scaleX: cgScaling * CGFloat(scale), y: cgScaling * CGFloat(scale)))
        
        let markerEllipsePath = Path { path in
            path.move(to: cgCoordinates[0])
            for point in cgCoordinates {
                path.addEllipse(in: CGRect(origin: CGPoint(x: point.x - CGFloat(markerDiameter)/2, y: point.y - CGFloat(markerDiameter)/2 + CGFloat(channelDepth)), size: CGSize(width: CGFloat(markerDiameter), height: CGFloat(markerDiameter))))
            }
        }
        let offsetMarkerEllipsePath = markerEllipsePath.applying(CGAffineTransform(translationX: CGFloat(offset), y: CGFloat(offset)))
        let scaledMarkerEllipsePath = offsetMarkerEllipsePath.applying(CGAffineTransform(scaleX: cgScaling * CGFloat(scale), y: cgScaling * CGFloat(scale)))
        
        return (depthPaths, (scaledMarkerLinePath, scaledMarkerEllipsePath))
    }
    
    private func cgBarPathFromCoordinates(_ coordinates: [(UInt16, UInt16)]) -> Path {
        let edgeLength = pathEdgeLength(coordinates)
        let roundedRect = CGRect(origin: CGPoint(x: 0, y: CGFloat(edgeLength)), size: CGSize(width: Double(edgeLength-2), height: CGFloat(lineWidth)))
        let barPath = Path{ path in
            path.addRoundedRect(in: roundedRect, cornerSize: CGSize(width: 5, height: 5))
        }
        let offset = max(lineWidth, markerDiameter)
        let offsetPath = barPath.applying(CGAffineTransform(translationX: CGFloat(offset), y: CGFloat(offset)))
        let scaledPath = offsetPath.applying(CGAffineTransform(scaleX: cgScaling * CGFloat(scale), y: cgScaling * CGFloat(scale)))
        return scaledPath
    }
    
    private func cgMeasurePathFromCoordinates(_ coordinates: [(UInt16, UInt16)]) -> Path {
        let edgeLength = pathEdgeLength(coordinates)
        
        let measurePath = Path{ path in
            path.move(to: CGPoint(x: CGFloat(edgeLength), y: 0))
            path.addLine(to: CGPoint(x: CGFloat(edgeLength), y: CGFloat(edgeLength-2)))
        }
        let offset = max(lineWidth, markerDiameter)
        let offsetPath = measurePath.applying(CGAffineTransform(translationX: CGFloat(offset), y: CGFloat(offset)))
        let scaledPath = offsetPath.applying(CGAffineTransform(scaleX: cgScaling * CGFloat(scale), y: cgScaling * CGFloat(scale)))
        return scaledPath
    }
    
    public func area() -> Double {
        let paths = cgPathsFromCoordinates(coordinates)
        let strokedLine = paths.0.strokedPath(
            StrokeStyle(lineWidth: CGFloat(lineWidth) * cgScaling * CGFloat(scale))
        )
        
        var combinedPath = strokedLine
        if markers {
            combinedPath = pathUnion(strokedLine, with: paths.1)
        }
        
        let inverseScale = (1 / cgScaling) * (1 / CGFloat(scale))
        let scaledPath = combinedPath.applying(CGAffineTransform(scaleX: inverseScale, y: inverseScale))
        
        return abs(signedArea(for: scaledPath))
    }

    private func signedArea(for path: Path) -> Double {
        var area: CGFloat = 0.0
        var currentPoint: CGPoint = .zero
        var subpathStartPoint: CGPoint = .zero

        path.cgPath.applyWithBlock { elementPointer in
            let element = elementPointer.pointee
            let points = element.points

            switch element.type {
            case .moveToPoint:
                currentPoint = points[0]
                subpathStartPoint = points[0]

            case .addLineToPoint:
                let p1 = points[0]
                area += (currentPoint.x * p1.y - p1.x * currentPoint.y)
                currentPoint = p1

            case .addQuadCurveToPoint:
                let p0 = currentPoint
                let p1 = points[0] // control point
                let p2 = points[1] // end point
                
                // Formula for quadratic Bezier segment contribution to Green's theorem integral
                area += (2.0/3.0) * (p0.x * p1.y - p1.x * p0.y + p1.x * p2.y - p2.x * p1.y) + (p0.x * p2.y - p2.x * p0.y)
                
                currentPoint = p2

            case .addCurveToPoint:
                let p0 = currentPoint
                let p1 = points[0] // control point 1
                let p2 = points[1] // control point 2
                let p3 = points[2] // end point

                // Formula for cubic Bezier segment contribution to Green's theorem integral
                area += (3.0/5.0) * (p0.x*p1.y - p1.x*p0.y + p1.x*p2.y - p2.x*p1.y + p2.x*p3.y - p3.x*p2.y)
                area += (1.0/5.0) * (p0.x*p2.y - p2.x*p0.y + p1.x*p3.y - p3.x*p1.y)
                area += (1.0/10.0) * (p0.x*p3.y - p3.x*p0.y)

                currentPoint = p3

            case .closeSubpath:
                // Add a line segment back to the start of the subpath
                area += (currentPoint.x * subpathStartPoint.y - subpathStartPoint.x * currentPoint.y)
                currentPoint = subpathStartPoint
                
            @unknown default:
                break
            }
        }
        
        return Double(area / 2.0)
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
    
    static func linePathArea(_ coordinates: [(UInt16, UInt16)], spacing: Float, pathWidth: Float) -> Float {
        let pathDistance = CurveCanvas.pathLength(coordinates, spacing: spacing)
        let pathArea = pathDistance * pathWidth
        return pathArea
    }
    
    static func markerPathArea(nIndices: Int, markerDiameter: Float, pathWidth: Float) -> Float{
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
