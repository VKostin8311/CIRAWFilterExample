//
//  ContentView.swift
//  CIRAWFilterExample
//
//  Created by Владимир Костин on 13.06.2023.
//

import CoreImage
import SwiftUI

struct ContentView: View {
    
    @StateObject var renderer: Renderer = Renderer()
    @State var format: RAWFormat = .Adobe
    
    let adobeData: Data
    let adobeFilter: CIRAWFilter
    let proRaw12Data: Data
    let proRaw12Filter: CIRAWFilter
    let proRaw48Data: Data
    let proRaw48Filter: CIRAWFilter
    
    init(){
        guard let adobeUrl = Bundle.main.url(forResource: "Adobe", withExtension: "dng"), let adobeData = try? Data(contentsOf: adobeUrl) else { fatalError() }
        self.adobeData = adobeData
        guard let adobeFilter = CIRAWFilter(imageData: self.adobeData, identifierHint: nil) else { fatalError() }
        self.adobeFilter = adobeFilter
                
        guard let proRaw12Url = Bundle.main.url(forResource: "ProRAW12", withExtension: "DNG"), let proRaw12Data = try? Data(contentsOf: proRaw12Url) else { fatalError() }
        self.proRaw12Data = proRaw12Data
        guard let proRaw12Filter = CIRAWFilter(imageData: self.proRaw12Data, identifierHint: nil) else { fatalError() }
        self.proRaw12Filter = proRaw12Filter
        
        guard let proRaw48Url = Bundle.main.url(forResource: "ProRAW48", withExtension: "DNG"), let proRaw48Data = try? Data(contentsOf: proRaw48Url) else { fatalError() }
        self.proRaw48Data = proRaw48Data
        guard let proRaw48Filter = CIRAWFilter(imageData: self.proRaw48Data, identifierHint: nil) else { fatalError() }
        self.proRaw48Filter = proRaw48Filter
    }
    
    var body: some View {
        VStack {
            Picker("Format", selection: $format) {
                Text("Adobe")
                    .tag(RAWFormat.Adobe)
                Text("ProRAW12")
                    .tag(RAWFormat.ProRAW12)
                Text("ProRAW48")
                    .tag(RAWFormat.ProRAW48)
            }
            .pickerStyle(SegmentedPickerStyle())
            MetalView(renderer: renderer)
            VStack(spacing: 4) {
                VStack(spacing: 0) {
                    HStack(){
                        Text("Exposure")
                        Spacer()
                        Text(String(format: "%.2f", renderer.exposure))
                    }
                    Slider(value: $renderer.exposure, in: -5...5, step: 0.01)
                }
                VStack(spacing: 0) {
                    HStack(){
                        Text("Boost Amount")
                        Spacer()
                        Text(String(format: "%.2f", renderer.boostAmount))
                    }
                    Slider(value: $renderer.boostAmount, in: 0...1, step: 0.01)
                }
                VStack(spacing: 0) {
                    HStack(){
                        Text("Boost Shadow Amount")
                        Spacer()
                        Text(String(format: "%.2f", renderer.boostShadowAmount))
                    }
                    Slider(value: $renderer.boostShadowAmount, in: 0...2, step: 0.01)
                }
                VStack(spacing: 0) {
                    HStack(){
                        Text("Shadow Bias")
                        Spacer()
                        Text(String(format: "%.2f", renderer.shadowBias))
                    }
                    Slider(value: $renderer.shadowBias, in: -1...1, step: 0.01)
                }
                VStack(spacing: 0) {
                    HStack(){
                        Text("Neutral Temperature")
                        Spacer()
                        Text("\(Int(renderer.neutralTemperature))")
                    }
                    Slider(value: $renderer.neutralTemperature, in: 2000...10000, step: 1)
                }
                VStack(spacing: 0) {
                    HStack(){
                        Text("Neutral Tint")
                        Spacer()
                        Text("\(Int(renderer.neutralTint))")
                    }
                    Slider(value: $renderer.neutralTint, in: -150...150, step: 1)
                }
            }
            .font(.footnote)
        }
        .padding()
        .onAppear {
            renderer.ciRAWFilter = adobeFilter
            renderer.neutralTint = adobeFilter.neutralTint
            renderer.neutralTemperature = adobeFilter.neutralTemperature
            renderer.exposure = adobeFilter.exposure
            renderer.boostAmount = adobeFilter.boostAmount
        }

        .onChange(of: format) { newValue in
            switch newValue {
            case .Adobe:
                renderer.ciRAWFilter = adobeFilter
                renderer.neutralTint = adobeFilter.neutralTint
                renderer.neutralTemperature = adobeFilter.neutralTemperature
                renderer.exposure = adobeFilter.exposure
                renderer.boostAmount = adobeFilter.boostAmount
            case .ProRAW12:
                renderer.ciRAWFilter = proRaw12Filter
                renderer.neutralTint = proRaw12Filter.neutralTint
                renderer.neutralTemperature = proRaw12Filter.neutralTemperature
                renderer.exposure = proRaw12Filter.exposure
                renderer.boostAmount = proRaw12Filter.boostAmount
            case .ProRAW48:
                renderer.ciRAWFilter = proRaw48Filter
                renderer.neutralTint = proRaw48Filter.neutralTint
                renderer.neutralTemperature = proRaw48Filter.neutralTemperature
                renderer.exposure = proRaw48Filter.exposure
                renderer.boostAmount = proRaw48Filter.boostAmount
            }
        }
    }
}


enum RAWFormat {
    case Adobe
    case ProRAW12
    case ProRAW48
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
