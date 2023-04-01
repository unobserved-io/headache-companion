//
//  TempDatePicker.swift
//  Headache Companion
//
//  Created by Ricky Kresslein on 4/1/23.
//

import SwiftUI

struct TempDatePicker: UIViewRepresentable {
    @Binding var selection: Date
    var range: ClosedRange<Date>

    func makeUIView(context: Context) -> UIDatePicker {
        let datePicker = UIDatePicker()
        datePicker.datePickerMode = .date
        datePicker.addTarget(context.coordinator, action: #selector(Coordinator.changed(_:)), for: .valueChanged)
        datePicker.minimumDate = range.lowerBound
        datePicker.maximumDate = range.upperBound
        datePicker.contentHorizontalAlignment = .center
        datePicker.contentScaleFactor = .leastNormalMagnitude
        return datePicker
    }

    func updateUIView(_ datePicker: UIDatePicker, context: Context) {
        datePicker.date = selection
    }

    func makeCoordinator() -> TempDatePicker.Coordinator {
        Coordinator(date: $selection)
    }

    class Coordinator: NSObject {
        private let date: Binding<Date>

        init(date: Binding<Date>) {
            self.date = date
        }

        @objc func changed(_ sender: UIDatePicker) {
            self.date.wrappedValue = sender.date
        }
    }
}

struct TempDatePicker_Previews: PreviewProvider {
    static var previews: some View {
        TempDatePicker(selection: .constant(Date.now), range: Date.now ... Date.now)
    }
}
