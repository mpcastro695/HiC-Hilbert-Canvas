//
//  ContentView.swift
//  Hilbert Curve Demo
//
//  Created by Martin Castro on 7/27/24.
//

import SwiftUI

struct ContentView: View {
    
    @State private var nIndices: UInt16 =  64
    
    //Settings
    @State private var spacing: Float = 2.2
    @State private var markers: Bool = true
    @State private var markerDiameter: Float = 1.0
    @State private var lineWidth: Float = 0.8
    @State private var channels: Bool = true
    @State private var channelDepth: Float = 0.4
    
    @State private var dxf: Bool = false
    @State private var scale: Float = 1.0
    @State private var showAlert: Bool = false
    
    // UInt16 max = 65,535 nodes
    let nOptions: [UInt16] = [4, 8, 16, 32, 64, 128]
    
    var body: some View {
        let coordinates = HilbertCurve(nIndices: nIndices).coordinates
        let curveCanvas = CurveCanvas(coordinates: coordinates, spacing: $spacing, markers: $markers, channels: $channels, channelDepth: $channelDepth, lineWidth: $lineWidth, markerDiameter: $markerDiameter, dxf: $dxf, scale: $scale)
        
            HStack{
                VStack(alignment: .leading){
                    VStack(alignment: .leading) {
                        Text("Parameters")
                            .font(.headline)
                            .padding(.bottom, 5)
                        Picker("Indices", selection: $nIndices){
                            ForEach(nOptions, id: \.self){
                                Text("\($0)")
                            }
                        }
                        .font(.caption)
                        
                        Slider(value: $lineWidth, in: 0.4...spacing-0.2, step: 0.2){
                            Text(String(format: "Width: %.1f mm", lineWidth))
                                .font(.caption)
                        }
                        .onChange(of: lineWidth){ oldValue, newValue in
                            if markerDiameter < newValue {
                                markerDiameter = newValue
                            }
                        }
                        
                        Slider(value: $spacing, in: lineWidth+0.2...4.2, step: 0.2){
                            Text(String(format: "Spacing: %.1f mm", spacing))
                                .font(.caption)
                        }
                        .padding(.bottom, 5)
                        .onChange(of: spacing){ oldValue, newValue in
                            if lineWidth >= newValue {
                                lineWidth = newValue - 0.2
                            }
                            if markerDiameter >= newValue {
                                markerDiameter = newValue - 0.2
                            }
                        }
                        
                        Toggle(isOn: $markers, label: {
                            Text("Markers")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        })
                        if markers{
                            Slider(value: $markerDiameter, in: 0.4...spacing, step: 0.2){
                                Text(String(format: "Diameter: %.1f mm", markerDiameter))
                                    .font(.caption)
                            }
                            .padding(.bottom, 5)
                        }
                            
                        Toggle(isOn: $channels, label: {
                            Text("Depth")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        })
                        .onChange(of: channels) { oldValue, newValue in
                            if newValue == true {
                                dxf = false
                            }
                        }
                        if channels{
                            Slider(value: $channelDepth, in: 0.2...2.1, step: 0.2){
                                Text(String(format: "Depth: %.1f mm", channelDepth))
                                    .font(.caption)
                            }
                            .padding(.bottom, 5)
                        }
                        Divider()
                        
                        Text("View")
                            .font(.headline)
                            .padding(.bottom, 5)
                        Toggle(isOn: $dxf, label: {
                            Text("DXF")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        })
                        .onChange(of: dxf) { oldValue, newValue in
                            if newValue == true {
                                channels = false
                            }
                        }
                        .padding(.bottom, 5)
                        
                        Slider(value: $scale, in: 0.2...5.0, step: 0.2){
                            Text(String(format: "Scale: %.1f x", scale))
                                .font(.caption)
                        }
                        .padding(.bottom, 5)
                        
                    }
                    .padding(.bottom, 5)
                    Divider()
                    
                    Text("Curve Stats")
                        .font(.callout)
                        .padding(.top, 5)
                        .padding(.bottom, 5)
                    VStack(alignment: .leading){
                        Text("Nodes: \(nIndices * nIndices)")
                        Text(String(format: "Edge Length: %.1f mm", Float(nIndices) * spacing))
                        Text(String(format: "Curve Area: %.1f mm2", pow(Float(nIndices) * spacing, 2)))
                        Text(String(format: "Path Length: %.1f mm", CurveCanvas.pathLength(coordinates, spacing: spacing)))
                        if channels{
                            if markers{
                                Text(String(format: "Path Volume: %.1f uL", (CurveCanvas.pathArea(coordinates, spacing: spacing, pathWidth: lineWidth) * channelDepth) + CurveCanvas.markerArea(nIndices: Int(nIndices), markerDiameter: markerDiameter, pathWidth: lineWidth) * channelDepth))
                            }
                            else{
                                Text(String(format: "Path Volume: %.1f uL", CurveCanvas.pathArea(coordinates, spacing: spacing, pathWidth: lineWidth) * channelDepth))
                            }
                        }
                    }
                    .font(.caption)
                    .foregroundColor(.secondary)
                    Spacer()
                    HStack{
                        Spacer()
                        Button("Export PDF") {
                            if dxf{
                                savePDFRendertoDisk(with: ImageRenderer(content: curveCanvas))
                            }
                            else{
                                showAlert = true
                            }
                        }
                        .alert("Enable DXF", isPresented: $showAlert) {
                            Button("OK", role: .cancel) {
                                dxf = true
                            }
                        }
                        Spacer()
                    }
                }//END LEFT 'PANE'
                .frame(minWidth: 250)
                
                Divider()
                VStack(alignment: .leading){
                    Text("My Curve")
                        .font(.title)
                        .bold()
                        .padding(.bottom, 5)
                    curveCanvas
                    Spacer()
                    HStack(alignment: .bottom){
                        Text("A space-filling curve with \(coordinates.count) points")
                            .font(.caption)
                        Spacer()
                        Text(String(format: "Path Distance: %.1f mm", CurveCanvas.pathLength(coordinates, spacing: spacing)))
                            .font(.caption)
                    }
                }
                .frame(maxWidth: .infinity)
                .layoutPriority(1)
            }// END HSTACK
            .padding(10)
            .frame(minWidth: 600, minHeight: 480)
    }//END BODY
    
    @MainActor private func savePDFRendertoDisk(with renderer: ImageRenderer<CurveCanvas>) {
        let cgSpacing = CGFloat(spacing * 2)
        print(cgSpacing)
        renderer.render { size, renderContext in
            if let downDirectory = try? FileManager.default.url(for: .downloadsDirectory, in: .userDomainMask, appropriateFor: nil, create: true){
                
                let date = Date()
                let dateFormatter = DateFormatter()
                dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
                let formattedDate = dateFormatter.string(from: date)
                
                let url = downDirectory.appendingPathComponent("My Curve \(formattedDate).pdf")
                print("\(url)")
                let cgEdgeLength = CGFloat(nIndices+2) * cgSpacing * CGFloat(scale)
                var mediaBox = CGRect(origin: .zero, size: CGSize(width: cgEdgeLength, height: cgEdgeLength))
                print("Media Box Size: Height \(mediaBox.size.height), Width: \(mediaBox.size.width)")
                guard let consumer = CGDataConsumer(url: url as CFURL),
                      let pdfContext =  CGContext(consumer: consumer,
                                                                  mediaBox: &mediaBox, nil) else {
                    print("pdfContext NOT made")
                    return
                }
                pdfContext.beginPDFPage(nil)
                let cgOffsetY =  mediaBox.size.height - sqrt(cgEdgeLength)
                pdfContext.translateBy(x: cgSpacing, y: cgOffsetY)
                renderContext(pdfContext)
                pdfContext.endPDFPage()
                pdfContext.closePDF()
            }
        }
    }
}


#Preview {
    ContentView()
}
