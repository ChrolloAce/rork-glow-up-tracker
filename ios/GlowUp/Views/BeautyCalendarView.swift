import SwiftUI

struct BeautyCalendarView: View {
    @Bindable var viewModel: GlowViewModel
    @State private var currentMonth: Date = Date()
    @State private var selectedDay: Date? = nil
    @State private var showAddTreatment: Bool = false
    @State private var showAddRoutine: Bool = false
    @State private var expandedSection: ChecklistCategory? = .face

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                HStack {
                    Text("Beauty Cal")
                        .font(.system(size: 40, weight: .heavy))
                        .foregroundStyle(Theme.textPrimary)
                    Spacer()
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)

                upcomingAppointmentsRow
                calendarContent
                checklistContent
            }
            .padding(.bottom, 100)
        }
        .background(Theme.screenGradient.ignoresSafeArea())
        .scrollIndicators(.hidden)
        .sheet(isPresented: $showAddTreatment) {
            AddTreatmentSheet(viewModel: viewModel, selectedDate: selectedDay ?? Date())
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
                .adaptivePresentationBackground()
        }
        .sheet(item: $selectedDay) { day in
            DayDetailSheet(viewModel: viewModel, date: day, onAdd: { showAddTreatment = true })
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
                .presentationContentInteraction(.scrolls)
                .adaptivePresentationBackground()
        }
        .sheet(isPresented: $showAddRoutine) {
            AddRoutineSheet(viewModel: viewModel)
                .presentationDetents([.medium])
                .presentationDragIndicator(.visible)
                .adaptivePresentationBackground()
        }
    }


    private var upcomingAppointments: [BeautyTreatment] {
        let today = Calendar.current.startOfDay(for: Date())
        return viewModel.treatments
            .filter { $0.date >= today }
            .sorted { $0.date < $1.date }
    }

    private var upcomingAppointmentsRow: some View {
        Group {
            if let next = upcomingAppointments.first {
                UpcomingAppointmentBar(treatment: next) {
                    selectedDay = next.date
                }
            } else {
                EmptyAppointmentBar {
                    selectedDay = nil
                    showAddTreatment = true
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 20)
    }

    private var calendarContent: some View {
        VStack(spacing: 16) {
            monthHeader
                .padding(.top, 8)
            calendarGrid
            legendStrip
            Button {
                selectedDay = nil
                showAddTreatment = true
            } label: {
                HStack {
                    Image(systemName: "plus")
                    Text("Add Appointment")
                        .font(.system(size: 15, weight: .bold))
                }
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 48)
                .background(Theme.pink)
                .clipShape(Capsule())
            }
            .sensoryFeedback(.impact(weight: .light), trigger: showAddTreatment)
        }
        .padding(.horizontal, 20)
        .padding(.top, 32)
    }

    private var monthHeader: some View {
        HStack {
            Button { changeMonth(-1) } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(Theme.pink)
            }
            Spacer()
            Text(monthYearString)
                .font(.system(size: 20, weight: .bold))
                .foregroundStyle(Theme.textPrimary)
            Spacer()
            Button { changeMonth(1) } label: {
                Image(systemName: "chevron.right")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(Theme.pink)
            }
        }
    }

    private var monthYearString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: currentMonth)
    }

    private func changeMonth(_ offset: Int) {
        withAnimation(.snappy) {
            currentMonth = Calendar.current.date(byAdding: .month, value: offset, to: currentMonth) ?? currentMonth
        }
    }

    private var calendarGrid: some View {
        let calendar = Calendar.current
        let daysInMonth = calendar.range(of: .day, in: .month, for: currentMonth)!.count
        let firstDay = calendar.date(from: calendar.dateComponents([.year, .month], from: currentMonth))!
        let startWeekday = calendar.component(.weekday, from: firstDay)
        let offset = startWeekday - 1
        let today = calendar.startOfDay(for: Date())
        let treatmentDates = viewModel.datesWithTreatments(in: currentMonth)

        return VStack(spacing: 8) {
            HStack(spacing: 0) {
                ForEach(["S", "M", "T", "W", "T", "F", "S"], id: \.self) { day in
                    Text(day)
                        .font(.system(size: 12))
                        .foregroundStyle(Theme.textTertiary)
                        .frame(maxWidth: .infinity)
                }
            }

            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 0), count: 7), spacing: 6) {
                ForEach(0..<42, id: \.self) { index in
                    let dayNum = index - offset + 1
                    if dayNum >= 1 && dayNum <= daysInMonth {
                        let date = calendar.date(byAdding: .day, value: dayNum - 1, to: firstDay)!
                        let isToday = calendar.isDate(date, inSameDayAs: today)
                        let treatments = treatmentDates[calendar.startOfDay(for: date)] ?? []

                        Button {
                            selectedDay = date
                        } label: {
                            VStack(spacing: 2) {
                                Text("\(dayNum)")
                                    .font(.system(size: 15, weight: isToday ? .bold : .regular))
                                    .foregroundStyle(isToday ? .white : Theme.textPrimary)
                                    .frame(width: 36, height: 36)
                                    .background(isToday ? Theme.pink : Color.clear)
                                    .clipShape(Circle())

                                HStack(spacing: 2) {
                                    ForEach(treatments.prefix(3), id: \.rawValue) { type in
                                        Circle()
                                            .fill(type.dotColor)
                                            .frame(width: 4, height: 4)
                                    }
                                }
                                .frame(height: 6)
                            }
                        }
                    } else {
                        Color.clear.frame(height: 44)
                    }
                }
            }
        }
    }

    private var legendStrip: some View {
        ScrollView(.horizontal) {
            HStack(spacing: 8) {
                ForEach(TreatmentType.allCases) { type in
                    HStack(spacing: 6) {
                        Circle()
                            .fill(type.dotColor)
                            .frame(width: 7, height: 7)
                        Text(type.rawValue)
                            .font(.system(size: 11, weight: .medium))
                            .foregroundStyle(Theme.textSecondary)
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(type.dotColor.opacity(0.14))
                    .clipShape(Capsule())
                }
            }
        }
        .contentMargins(.horizontal, 0)
        .scrollIndicators(.hidden)
    }

    private var checklistContent: some View {
        VStack(spacing: 12) {
            ForEach(ChecklistCategory.allCases) { category in
                VStack(spacing: 0) {
                    Button {
                        withAnimation(.snappy) {
                            expandedSection = expandedSection == category ? nil : category
                        }
                    } label: {
                        HStack {
                            Text(category.rawValue)
                                .font(.system(size: 18, weight: .bold))
                                .foregroundStyle(Theme.textPrimary)
                            Spacer()
                            Image(systemName: expandedSection == category ? "chevron.down" : "chevron.right")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundStyle(Theme.textTertiary)
                        }
                        .padding(16)
                    }

                    if expandedSection == category {
                        let items = viewModel.checklistItems.filter { $0.category == category }
                        ForEach(items) { item in
                            ChecklistRow(item: item)
                        }
                        .padding(.horizontal, 16)
                        .padding(.bottom, 12)
                    }
                }
                .glassCard()
            }

            Button {
                showAddRoutine = true
            } label: {
                HStack {
                    Image(systemName: "plus")
                    Text("Add Routine")
                        .font(.system(size: 14, weight: .semibold))
                }
                .foregroundStyle(Theme.pink)
                .frame(maxWidth: .infinity)
                .frame(height: 48)
                .overlay(Capsule().stroke(Theme.pink.opacity(0.4), lineWidth: 1))
            }
            .sensoryFeedback(.impact(weight: .light), trigger: showAddRoutine)
        }
        .padding(.horizontal, 20)
        .padding(.top, 20)
    }
}

extension Date: @retroactive Identifiable {
    public var id: TimeInterval { timeIntervalSince1970 }
}

struct UpcomingAppointmentBar: View {
    let treatment: BeautyTreatment
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 14) {
                ZStack {
                    Circle()
                        .fill(treatment.type.dotColor.opacity(0.22))
                        .frame(width: 44, height: 44)
                    Image(systemName: treatment.type.icon)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(treatment.type.dotColor)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text("Next \(treatment.type.rawValue)")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(Theme.textSecondary)
                        .lineLimit(1)
                    Text(dateString)
                        .font(.system(size: 17, weight: .heavy))
                        .foregroundStyle(Theme.textPrimary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                }

                Spacer(minLength: 8)

                VStack(alignment: .trailing, spacing: 2) {
                    Text(treatment.time)
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(Theme.textPrimary)
                    Image(systemName: "chevron.right")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(Theme.textTertiary)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
        }
        .buttonStyle(.plain)
        .glassCard()
    }

    private var dateString: String {
        let calendar = Calendar.current
        if calendar.isDateInToday(treatment.date) { return "Today" }
        if calendar.isDateInTomorrow(treatment.date) { return "Tomorrow" }
        let f = DateFormatter()
        f.dateFormat = "EEE, MMM d"
        return f.string(from: treatment.date)
    }
}

struct EmptyAppointmentBar: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 14) {
                ZStack {
                    Circle()
                        .fill(Theme.pink.opacity(0.16))
                        .frame(width: 44, height: 44)
                    Image(systemName: "calendar.badge.plus")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(Theme.pink)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text("Upcoming")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(Theme.textSecondary)
                    Text("No plans yet")
                        .font(.system(size: 17, weight: .heavy))
                        .foregroundStyle(Theme.textPrimary)
                }

                Spacer(minLength: 8)

                Text("Add")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(Theme.pink)
                    .clipShape(Capsule())
            }
            .frame(maxWidth: .infinity)
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
        }
        .buttonStyle(.plain)
        .glassCard()
    }
}

struct ChecklistRow: View {
    let item: ChecklistItem

    var body: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(item.status.color)
                .frame(width: 10, height: 10)

            VStack(alignment: .leading, spacing: 2) {
                Text(item.name)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(Theme.textPrimary)
                Text("Last done: \(item.lastDone)")
                    .font(.system(size: 12))
                    .foregroundStyle(Theme.textSecondary)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                Text(item.status.rawValue)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(item.status.color)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(item.status.backgroundColor)
                    .clipShape(Capsule())
                Text("Next: \(item.nextDue)")
                    .font(.system(size: 11))
                    .foregroundStyle(Theme.textTertiary)
            }
        }
        .padding(.vertical, 6)
    }
}

struct DayDetailSheet: View {
    let viewModel: GlowViewModel
    let date: Date
    let onAdd: () -> Void

    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                let treatments = viewModel.treatmentsForDate(date)

                if treatments.isEmpty {
                    Spacer()
                    VStack(spacing: 8) {
                        Text("No treatments scheduled")
                            .font(.system(size: 16))
                            .foregroundStyle(Theme.textSecondary)
                        Text("Tap + to add")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(Theme.textTertiary)
                            .italic()
                    }
                    Spacer()
                } else {
                    ForEach(treatments) { treatment in
                        HStack(spacing: 12) {
                            Circle()
                                .fill(treatment.type.dotColor)
                                .frame(width: 10, height: 10)
                            Text(treatment.type.rawValue)
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundStyle(Theme.textPrimary)
                            Spacer()
                            Text(treatment.time)
                                .font(.system(size: 13))
                                .foregroundStyle(Theme.textSecondary)
                            Image(systemName: "pencil")
                                .font(.system(size: 13))
                                .foregroundStyle(Theme.textTertiary)
                        }
                        .padding(.vertical, 6)
                    }
                }

                Button(action: onAdd) {
                    HStack {
                        Image(systemName: "plus")
                        Text("Add Treatment")
                            .font(.system(size: 16, weight: .bold))
                    }
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(Theme.pink)
                    .clipShape(.rect(cornerRadius: 28))
                }
            }
            .padding(20)
            .navigationTitle(dateString)
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    private var dateString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMMM d"
        return formatter.string(from: date)
    }
}

struct AddTreatmentSheet: View {
    @Bindable var viewModel: GlowViewModel
    let selectedDate: Date
    @Environment(\.dismiss) private var dismiss
    @State private var selectedType: TreatmentType = .nails
    @State private var notes: String = ""
    @State private var repeatFreq: RepeatFrequency = .none
    @State private var time: Date = Date()
    @State private var date: Date = Date()

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Treatment")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(Theme.textPrimary)
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 10), count: 3), spacing: 10) {
                            ForEach(TreatmentType.allCases) { type in
                                Button {
                                    selectedType = type
                                } label: {
                                    VStack(spacing: 8) {
                                        ZStack {
                                            Circle()
                                                .fill(type.dotColor.opacity(selectedType == type ? 1 : 0.22))
                                                .frame(width: 36, height: 36)
                                            Image(systemName: type.icon)
                                                .font(.system(size: 15, weight: .semibold))
                                                .foregroundStyle(selectedType == type ? .white : type.dotColor)
                                        }
                                        Text(type.rawValue)
                                            .font(.system(size: 12, weight: .semibold))
                                            .foregroundStyle(Theme.textPrimary)
                                            .lineLimit(1)
                                            .minimumScaleFactor(0.85)
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 14)
                                    .background(selectedType == type ? type.dotColor.opacity(0.16) : Theme.softPink)
                                    .clipShape(.rect(cornerRadius: 16))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 16)
                                            .stroke(selectedType == type ? type.dotColor.opacity(0.55) : Color.clear, lineWidth: 1.2)
                                    )
                                }
                                .sensoryFeedback(.selection, trigger: selectedType)
                            }
                        }
                    }

                    DatePicker("Date", selection: $date, displayedComponents: .date)
                        .tint(Theme.pink)
                        .foregroundStyle(Theme.textPrimary)

                    DatePicker("Time", selection: $time, displayedComponents: .hourAndMinute)
                        .tint(Theme.pink)
                        .foregroundStyle(Theme.textPrimary)

                    TextField("Notes", text: $notes, axis: .vertical)
                        .foregroundStyle(Theme.textPrimary)
                        .padding(14)
                        .background(Theme.softPink)
                        .clipShape(.rect(cornerRadius: 14))
                        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Theme.pink.opacity(0.2), lineWidth: 0.5))
                        .lineLimit(3...6)

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Repeat")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(Theme.textPrimary)
                        ScrollView(.horizontal) {
                            HStack(spacing: 8) {
                                ForEach(RepeatFrequency.allCases) { freq in
                                    Button {
                                        repeatFreq = freq
                                    } label: {
                                        Text(freq.rawValue)
                                            .font(.system(size: 13, weight: .medium))
                                            .foregroundStyle(repeatFreq == freq ? .white : Theme.textSecondary)
                                            .padding(.horizontal, 14)
                                            .padding(.vertical, 8)
                                            .background(repeatFreq == freq ? Theme.pink : Theme.softPink)
                                            .clipShape(Capsule())
                                    }
                                }
                            }
                        }
                        .scrollIndicators(.hidden)
                    }

                    Button {
                        let formatter = DateFormatter()
                        formatter.dateFormat = "h:mm a"
                        let treatment = BeautyTreatment(
                            type: selectedType,
                            date: date,
                            time: formatter.string(from: time),
                            notes: notes,
                            repeatFrequency: repeatFreq
                        )
                        viewModel.addTreatment(treatment)
                        dismiss()
                    } label: {
                        Text("Save Treatment")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                            .background(Theme.pink)
                            .clipShape(.rect(cornerRadius: 28))
                    }
                    .sensoryFeedback(.impact(weight: .light), trigger: viewModel.treatments.count)
                }
                .padding(20)
            }
            .scrollDismissesKeyboard(.interactively)
            .navigationTitle("Add Treatment")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(Theme.pink)
                }
            }
            .onAppear {
                date = selectedDate
            }
        }
    }
}

struct AddRoutineSheet: View {
    @Bindable var viewModel: GlowViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var name: String = ""
    @State private var category: ChecklistCategory = .face

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    TextField("Routine name", text: $name)
                        .foregroundStyle(Theme.textPrimary)
                        .padding(14)
                        .background(Theme.softPink)
                        .clipShape(.rect(cornerRadius: 14))
                        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Theme.pink.opacity(0.2), lineWidth: 0.5))

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Category")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(Theme.textPrimary)
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 10), count: 2), spacing: 10) {
                            ForEach(ChecklistCategory.allCases) { cat in
                                Button {
                                    category = cat
                                } label: {
                                    Text(cat.rawValue)
                                        .font(.system(size: 14, weight: .semibold))
                                        .foregroundStyle(category == cat ? .white : Theme.textPrimary)
                                        .frame(maxWidth: .infinity)
                                        .frame(height: 44)
                                        .background(category == cat ? Theme.pink : Theme.softPink)
                                        .clipShape(.rect(cornerRadius: 14))
                                }
                            }
                        }
                    }

                    Button {
                        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
                        guard !trimmed.isEmpty else { return }
                        viewModel.addChecklistItem(name: trimmed, category: category)
                        dismiss()
                    } label: {
                        Text("Save Routine")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                            .background(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? Theme.pink.opacity(0.4) : Theme.pink)
                            .clipShape(.rect(cornerRadius: 28))
                    }
                    .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    .sensoryFeedback(.impact(weight: .light), trigger: viewModel.checklistItems.count)
                }
                .padding(20)
            }
            .scrollDismissesKeyboard(.interactively)
            .navigationTitle("Add Routine")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(Theme.pink)
                }
            }
        }
    }
}
