//
//  PieSlice.swift
//  Migraine
//
//  Created by Ricky Kresslein on 3/24/23.
//

import SwiftUI

struct PieSliceView: View {
    var pieSliceData: PieSliceData
    
    var midRadians: Double {
        return Double.pi / 2.0 - (pieSliceData.startAngle + pieSliceData.endAngle).radians / 2.0
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Path { path in
                    let width: CGFloat = min(geometry.size.width, geometry.size.height)
                    let height = width
                    
                    let center = CGPoint(x: width * 0.5, y: height * 0.5)
                    
                    path.move(to: center)
                    
                    path.addArc(
                        center: center,
                        radius: width * 0.5,
                        startAngle: Angle(degrees: -90.0) + pieSliceData.startAngle,
                        endAngle: Angle(degrees: -90.0) + pieSliceData.endAngle,
                        clockwise: false)
                }
//                .fill(pieSliceData.color)
//                .fill(RadialGradient(gradient: Gradient(colors: [pieSliceData.color.opacity(0.60), pieSliceData.color]), center: .center, startRadius: 50, endRadius: 60))
                .fill(RadialGradient(gradient: Gradient(colors: [pieSliceData.color.opacity(0.60), pieSliceData.color]), center: .center, startRadius: 40, endRadius: 90))
                
                if pieSliceData.percent > 4.99 {
                    Text(String(format: "%.0f%%", pieSliceData.percent))
                        .position(
                            x: geometry.size.width * 0.5 * CGFloat(1.0 + 0.78 * cos(self.midRadians)),
                            y: geometry.size.height * 0.5 * CGFloat(1.0 - 0.78 * sin(self.midRadians)))
                        .bold()
                        .foregroundColor(Color.white)
                }
            }
        }
        .aspectRatio(1, contentMode: .fit)
    }
}

struct PieSliceData {
    var startAngle: Angle
    var endAngle: Angle
    var percent: Double
    var color: Color
}

struct PieSliceView_Previews: PreviewProvider {
    static var previews: some View {
        PieSliceView(pieSliceData: PieSliceData(
            startAngle: Angle(degrees: 0.0),
            endAngle: Angle(degrees: 220.0),
            percent: 65.00,
            color: Color.black))
    }
}
