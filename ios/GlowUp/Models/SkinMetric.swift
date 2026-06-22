import SwiftUI

struct HabitMetricData: Identifiable {
    let id: String = UUID().uuidString
    let category: HabitCategory
    var value: Double
    var trend: [Double]

    var color: Color { category.slabColor }
    var shortName: String { category.shortName }
}
