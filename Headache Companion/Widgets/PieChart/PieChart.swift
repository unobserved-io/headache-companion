//
//  PieChart.swift
//  Migraine
//
//  Created by Ricky Kresslein on 3/24/23.
//

import SwiftUI

struct PieChart: View {
    @Environment(\.colorScheme) var colorScheme
    public let values: [Double]
    public var colors: [Color]
    public let icon: String
        
    var slices: [PieSliceData] {
        let sum = values.reduce(0, +)
        var endDeg: Double = 0
        var tempSlices: [PieSliceData] = []
        
        for (i, value) in values.enumerated() {
            let degrees: Double = value * 360 / sum
            tempSlices.append(PieSliceData(startAngle: Angle(degrees: endDeg), endAngle: Angle(degrees: endDeg + degrees), text: String(format: "%.0f%%", value * 100 / sum), color: colors[i]))
            endDeg += degrees
        }
        return tempSlices
    }
    
    var body: some View {
        ZStack {
            ForEach(0 ..< self.values.count, id: \.self) { i in
                PieSliceView(pieSliceData: self.slices[i])
            }
            
            Circle()
                .fill(colorScheme == .light ? .white : .black)
                .frame(width: 100, height: 100)
            
            Image(systemName: icon)
                .font(.system(size: 40))
        }
        .frame(height: 200)
        .padding()
    }
}

struct PieChartView_Previews: PreviewProvider {
    static var previews: some View {
        PieChart(values: [1300, 500, 300, 200], colors: [Color.blue, Color.green, Color.orange, Color.red], icon: "drop.fill")
    }
}
