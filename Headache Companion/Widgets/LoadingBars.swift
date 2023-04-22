//
//  LoadingBars.swift
//  Headache Companion
//
//  Created by Ricky Kresslein on 3/27/23.
//

import SwiftUI

public struct LoadingBars: View {
    @Binding private var isAnimating: Bool
    public let count: UInt
    public let spacing: CGFloat
    public let cornerRadius: CGFloat
    public let scaleRange: ClosedRange<Double>
    public let opacityRange: ClosedRange<Double>

    public init(animate: Binding<Bool>,
                count: UInt = 8,
                spacing: CGFloat = 8,
                cornerRadius: CGFloat = 8,
                scaleRange: ClosedRange<Double> = (0.5...1),
                opacityRange: ClosedRange<Double> = (0.25...1))
    {
        self._isAnimating = animate
        self.count = count
        self.spacing = spacing
        self.cornerRadius = cornerRadius
        self.scaleRange = scaleRange
        self.opacityRange = opacityRange
    }

    public var body: some View {
        GeometryReader { geometry in
            ForEach(0 ..< Int(count), id: \.self) { index in
                item(forIndex: index, in: geometry.size)
            }
        }
        .aspectRatio(contentMode: .fit)
    }

    private var scale: CGFloat { CGFloat(isAnimating ? scaleRange.lowerBound : scaleRange.upperBound) }
    private var opacity: Double { isAnimating ? opacityRange.lowerBound : opacityRange.upperBound }

    private func size(count: UInt, geometry: CGSize) -> CGFloat {
        (geometry.width / CGFloat(count)) - (spacing - 2)
    }

    private func item(forIndex index: Int, in geometrySize: CGSize) -> some View {
        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
            .frame(width: size(count: count, geometry: geometrySize), height: geometrySize.height)
            .scaleEffect(x: 1, y: scale, anchor: .center)
            .opacity(opacity)
            .animation(
                Animation
                    .default
                    .repeatCount(isAnimating ? .max : 1, autoreverses: true)
                    .delay(Double(index) / Double(count) / 2),
                value: isAnimating
            )
            .offset(x: CGFloat(index) * (size(count: count, geometry: geometrySize) + spacing))
    }
}
