import SwiftUI

/// How a challenge card's image area should be rendered until real artwork is supplied.
enum ImageSlotLayout: String, Codable, Sendable {
    case hero        // one large hero image
    case collage     // a 4-image collage
    case illustration // soft illustrated artwork
    case gradient    // pastel placeholder gradient only
}

/// A single image placeholder slot. `assetName` is nil until the user supplies artwork.
struct ImageSlot: Codable, Sendable, Hashable, Identifiable {
    var id: String = UUID().uuidString
    var assetName: String? = nil
    var caption: String? = nil
}

enum ChallengeDifficulty: String, Codable, Sendable, CaseIterable {
    case beginner = "Beginner"
    case beginnerIntermediate = "Beginner / Intermediate"
    case intermediate = "Intermediate"
    case advanced = "Advanced"

    var dotColor: Color {
        switch self {
        case .beginner: return Color(red: 0.557, green: 0.769, blue: 0.627) // sage
        case .beginnerIntermediate: return Color(red: 0.788, green: 0.659, blue: 0.298) // warm gold
        case .intermediate: return Color(red: 0.96, green: 0.62, blue: 0.38) // warm orange
        case .advanced: return Color(red: 0.86, green: 0.38, blue: 0.50) // pink deep
        }
    }
}

/// The interaction style of a daily habit, surfaced as a small type badge.
enum HabitTaskType: String, Codable, Sendable, CaseIterable {
    case checkmark   // simple done / not done
    case quantity    // hit a numeric goal (oz, steps, pages…)
    case routine     // a multi-step ritual
    case photo       // capture a progress photo
    case journal     // write a short reflection

    var label: String {
        switch self {
        case .checkmark: return "Check off"
        case .quantity: return "Track goal"
        case .routine: return "Routine"
        case .photo: return "Photo"
        case .journal: return "Journal"
        }
    }

    /// Small glyph shown inside the type badge.
    var glyph: String {
        switch self {
        case .checkmark: return "checkmark"
        case .quantity: return "number"
        case .routine: return "list.bullet"
        case .photo: return "camera.fill"
        case .journal: return "pencil"
        }
    }

    var tint: Color {
        switch self {
        case .checkmark: return Color(red: 0.557, green: 0.769, blue: 0.627) // sage
        case .quantity: return Color(red: 0.42, green: 0.66, blue: 0.86)      // water blue
        case .routine: return Color(red: 0.70, green: 0.62, blue: 0.88)       // lavender
        case .photo: return Color(red: 0.96, green: 0.62, blue: 0.38)         // warm orange
        case .journal: return Color(red: 0.788, green: 0.659, blue: 0.298)    // gold
        }
    }
}

/// One habit a user performs daily inside a challenge.
struct DailyHabit: Codable, Sendable, Hashable, Identifiable {
    /// Stable per-challenge identity (names are unique within a challenge).
    var id: String { name }
    var icon: String          // SF Symbol representing the habit
    var name: String
    var explanation: String   // one short line of context
    var type: HabitTaskType
    /// Quantity habits: numeric target + unit (e.g. 101 "oz").
    var goal: Double? = nil
    var unit: String? = nil
    /// Routine habits: the sub-steps shown as check circles when expanded.
    var subTasks: [String] = []
    /// Real, specific coaching advice shown in the Today dropdown.
    var tip: String = ""

    /// Slab / accent color, driven by the task type for a soft, varied palette.
    var themeColor: Color { type.tint }
}

/// A reusable, data-driven challenge definition. Add new entries to
/// `ChallengeCatalog.popular` to surface new challenges — the UI is fully dynamic.
struct Challenge: Identifiable, Codable, Sendable, Hashable {
    var id: String
    var name: String
    var durationDays: Int
    var difficulty: ChallengeDifficulty
    var description: String
    var joinedCount: Int
    var focusTags: [String]
    var habitPreview: [String]
    var imageSlots: [ImageSlot]
    var imageLayout: ImageSlotLayout
    /// Hex-free theme color stored as RGB components for Codable safety.
    var themeRGB: [Double]
    /// Rich per-challenge detail content (drives the Challenge Detail & Progress screens).
    var dailyHabits: [DailyHabit] = []
    var rules: [String] = []
    var trackedMetrics: [String] = []
    /// Show the Body Progress (weight) section only when a challenge opts in.
    var tracksBody: Bool = false

    var themeColor: Color {
        guard themeRGB.count == 3 else { return Color(red: 0.96, green: 0.56, blue: 0.66) }
        return Color(red: themeRGB[0], green: themeRGB[1], blue: themeRGB[2])
    }

    /// Whether the challenge captures photos (drives the Progress photos section).
    var usesPhotos: Bool { dailyHabits.contains { $0.type == .photo } }
    /// Whether Glow Score is a headline metric for this challenge.
    var usesGlowScore: Bool { trackedMetrics.contains { $0.localizedCaseInsensitiveContains("glow") } }
    /// Quantity habit measured in oz, if any (drives the "Water" overview stat).
    var waterHabit: DailyHabit? { dailyHabits.first { $0.unit == "oz" } }

    var durationLabel: String { "\(durationDays) days" }

    var joinedLabel: String {
        if joinedCount >= 1000 {
            let thousands = Double(joinedCount) / 1000.0
            let formatted = String(format: "%.1f", thousands)
                .replacingOccurrences(of: ".0", with: "")
            return "+\(formatted)k joined"
        }
        return "+\(joinedCount) joined"
    }
}

enum ChallengeCatalog {
    static let popular: [Challenge] = [
        Challenge(
            id: "75-soft",
            name: "75 Soft",
            durationDays: 75,
            difficulty: .beginner,
            description: "A softer discipline challenge focused on movement, water, clean eating, reading, and consistency.",
            joinedCount: 12400,
            focusTags: ["Wellness", "Movement", "Hydration"],
            habitPreview: ["Water", "Movement", "Steps", "Clean Eating", "Reading"],
            imageSlots: [ImageSlot(caption: "Soft mornings")],
            imageLayout: .hero,
            themeRGB: [0.86, 0.60, 0.68], // dusty rose
            dailyHabits: [
                DailyHabit(icon: "drop.fill", name: "Water Intake", explanation: "Sip your way to today's hydration goal.", type: .quantity, goal: 80, unit: "oz", tip: "Get to 80 oz today. Start with a full glass the second you wake up and keep a bottle on you so sipping is automatic. Don't wait until you feel thirsty."),
                DailyHabit(icon: "figure.walk", name: "Movement", explanation: "30 minutes of any movement you enjoy.", type: .checkmark, tip: "Move for 30 minutes. A walk, pilates, dancing, whatever you'll actually do. It doesn't have to be hard, it just has to happen. Done beats perfect."),
                DailyHabit(icon: "shoeprints.fill", name: "Steps Goal", explanation: "Reach your daily step target.", type: .quantity, goal: 8000, unit: "steps", tip: "Hit 8,000 steps. Take the stairs, park far, walk 10 minutes after meals. The little walks add up faster than you think."),
                DailyHabit(icon: "leaf.fill", name: "Clean Eating", explanation: "Stick to your clean meals for the day.", type: .checkmark, tip: "Eat real food today. Protein, veggies, good carbs. Skip the processed stuff and added sugar. If the ingredient list is long, leave it on the shelf."),
                DailyHabit(icon: "book.fill", name: "Reading", explanation: "Read 10 pages of something uplifting.", type: .checkmark, tip: "Read 10 pages of something that makes you smarter instead of scrolling for three hours straight. Go pick up the book right now.")
            ],
            rules: [
                "Complete each daily habit to keep your streak alive.",
                "Movement can be a walk, yoga, or pilates. Your choice.",
                "Miss a day? You keep your progress and pick back up.",
                "Built to be sustainable, never punishing."
            ],
            trackedMetrics: ["Daily completion", "Movement streak", "Water intake", "Reading streak", "Consistency score"]
        ),
        Challenge(
            id: "75-medium",
            name: "75 Medium",
            durationDays: 75,
            difficulty: .intermediate,
            description: "A balanced challenge for users who want stronger discipline without going fully extreme.",
            joinedCount: 8200,
            focusTags: ["Discipline", "Fitness", "Nutrition"],
            habitPreview: ["Workout", "Steps", "Water", "No Sugar", "Reading", "Progress Photo"],
            imageSlots: [ImageSlot(), ImageSlot(), ImageSlot(), ImageSlot()],
            imageLayout: .collage,
            themeRGB: [0.70, 0.62, 0.88], // lavender
            dailyHabits: [
                DailyHabit(icon: "dumbbell.fill", name: "Workout", explanation: "One focused 45-minute session.", type: .checkmark, tip: "Get a real 45 minute workout in. Strength or a hard sweat session, full effort. Show up like it matters."),
                DailyHabit(icon: "figure.walk", name: "Steps Goal", explanation: "Reach your daily step goal.", type: .quantity, goal: 10000, unit: "steps", tip: "Hit 10,000 steps. A morning walk, a lunch lap, an evening loop. Walking after meals helps your digestion and energy too."),
                DailyHabit(icon: "drop.fill", name: "Water Intake", explanation: "Hit your hydration target.", type: .quantity, goal: 100, unit: "oz", tip: "Drink 100 oz today. Front load it early so you're not chugging before bed. Add lemon or cucumber if plain water bores you."),
                DailyHabit(icon: "nosign", name: "No Added Sugar", explanation: "Skip added sugar for the day.", type: .checkmark, tip: "No added sugar today. Watch the sneaky stuff in sauces, drinks, and healthy looking bars. Want something sweet? Reach for fruit."),
                DailyHabit(icon: "book.fill", name: "Reading", explanation: "Read 10 pages.", type: .checkmark, tip: "Read 10 pages of something that builds you, not a feed. Start the chapter now while it's on your mind."),
                DailyHabit(icon: "camera.fill", name: "Progress Photo", explanation: "Capture a daily progress photo.", type: .photo, tip: "Snap your photo. Same spot, same light, same time. You won't see daily change but in 30 days it'll be obvious.")
            ],
            rules: [
                "All habits should be completed each day.",
                "One real workout daily, indoor or outdoor.",
                "No added sugar throughout the day.",
                "A slip won't reset you, but aim for consistency."
            ],
            trackedMetrics: ["Daily completion", "Workout streak", "Water intake", "No-sugar streak", "Progress photos"]
        ),
        Challenge(
            id: "75-hard",
            name: "75 Hard",
            durationDays: 75,
            difficulty: .advanced,
            description: "A strict transformation challenge built around workouts, water, diet, reading, and daily progress photos.",
            joinedCount: 15600,
            focusTags: ["Discipline", "Fitness", "Mental Toughness"],
            habitPreview: ["Strength", "Cardio", "Water", "Diet", "Reading", "Photo"],
            imageSlots: [ImageSlot(caption: "Transformation")],
            imageLayout: .hero,
            themeRGB: [0.86, 0.38, 0.50], // pink deep
            dailyHabits: [
                DailyHabit(icon: "dumbbell.fill", name: "Strength Training", explanation: "45 minutes of lifting.", type: .checkmark, tip: "Lift heavy today. Challenging weight for 8 to 15 reps, clean form over ego, a full 45 minutes. Muscle is what reshapes your body."),
                DailyHabit(icon: "figure.run", name: "Cardio", explanation: "Get your heart rate up.", type: .checkmark, tip: "Get your heart rate up. A 40 minute run, or HIIT with short explosive intervals to burn fat. Take it outside if you can."),
                DailyHabit(icon: "drop.fill", name: "Water Intake", explanation: "Drink a full gallon of water.", type: .quantity, goal: 128, unit: "oz", tip: "Drink the full gallon, 128 oz. Carry one big bottle and pace it all day. Hydration drives your energy, recovery, and appetite."),
                DailyHabit(icon: "fork.knife", name: "Strict Diet", explanation: "Follow your diet exactly today.", type: .checkmark, tip: "Stay locked in. Whole foods, high protein, nothing ultra processed. Don't grab the fried chicken because you're busy. Hit your targets."),
                DailyHabit(icon: "nosign", name: "No Cheat Meals", explanation: "Zero cheat meals.", type: .checkmark, tip: "Zero cheat meals, zero exceptions. One bite off plan resets today. The point is proving you can hold the line. It's only 75 days."),
                DailyHabit(icon: "book.fill", name: "Reading", explanation: "Read 10 pages of non-fiction.", type: .checkmark, tip: "Read 10 pages of something that makes you smarter. Business, mindset, a real skill. Instead of scrolling for three hours, open the book right now."),
                DailyHabit(icon: "camera.fill", name: "Progress Photo", explanation: "Take a daily progress photo.", type: .photo, tip: "Take your daily photo. Same spot, same light. This is your proof the work is paying off when the mirror lies to you.")
            ],
            rules: [
                "Every task must be completed each day, no exceptions.",
                "Two workouts daily, one of them outdoors.",
                "No alcohol and no cheat meals.",
                "Miss anything and the challenge restarts at day 1."
            ],
            trackedMetrics: ["Daily completion", "Workout streak", "Water intake", "Reading streak", "Progress photos"]
        ),
        Challenge(
            id: "glow-up",
            name: "Glow Up Challenge",
            durationDays: 75,
            difficulty: .beginnerIntermediate,
            description: "A beauty and wellness challenge focused on skincare, hydration, clean eating, sleep, and feeling radiant.",
            joinedCount: 21300,
            focusTags: ["Skin", "Beauty", "Wellness"],
            habitPreview: ["AM Skincare", "PM Skincare", "Water", "Lymphatic", "Clean Eating", "Sleep"],
            imageSlots: [ImageSlot(), ImageSlot(), ImageSlot(), ImageSlot()],
            imageLayout: .collage,
            themeRGB: [0.96, 0.56, 0.66], // pink
            dailyHabits: [
                DailyHabit(icon: "sun.max.fill", name: "AM Skincare Routine", explanation: "Your morning glow routine.", type: .routine, subTasks: ["Cleanser", "Vitamin C Serum", "Moisturizer", "SPF"], tip: "Cleanse, vitamin C, moisturize, and never skip SPF. Sun is the number one cause of aging. Be gentle, your skin barrier matters."),
                DailyHabit(icon: "moon.stars.fill", name: "PM Skincare Routine", explanation: "Evening cleanse and treat.", type: .routine, subTasks: ["Double Cleanse", "Treatment", "Eye Cream", "Night Cream"], tip: "Double cleanse if you wore SPF or makeup, then layer your treatment and a rich night cream. Night is when your skin actually repairs."),
                DailyHabit(icon: "drop.fill", name: "Water Intake", explanation: "Hydrate for radiant skin.", type: .quantity, goal: 100, unit: "oz", tip: "Drink 100 oz. Hydrated skin is plump, glowing skin. Dehydration shows up on your face first. Keep a bottle on you and sip all day."),
                DailyHabit(icon: "hands.sparkles.fill", name: "Lymphatic Drainage", explanation: "Face + body routine.", type: .routine, subTasks: ["Dry brushing", "Gua sha", "Face massage", "Movement"], tip: "Dry brush toward your heart, gua sha upward, add light massage. It reduces puffiness, sculpts, and gets your circulation moving. Five minutes is plenty."),
                DailyHabit(icon: "leaf.fill", name: "Clean Eating for Skin", explanation: "Nourish with skin-loving foods.", type: .checkmark, tip: "Eat for your skin. Healthy fats, colorful veggies, water rich foods. Cut sugar and dairy if you're breaking out. Your face reflects your plate."),
                DailyHabit(icon: "bed.double.fill", name: "Sleep Goal", explanation: "Aim for 7+ hours of rest.", type: .quantity, goal: 7, unit: "hrs", tip: "Get 7 plus hours. This is your real beauty sleep, when skin regenerates and cortisol resets. Get off screens an hour before bed."),
                DailyHabit(icon: "camera.fill", name: "Glow Check-In", explanation: "Capture today's glow.", type: .photo, tip: "Snap a glow check in in natural light. Tracking your skin over time shows what's actually working, way more honest than the mirror.")
            ],
            rules: [
                "Focus on consistency over perfection.",
                "Small daily rituals beat occasional big efforts.",
                "Missed a day? Gently return tomorrow.",
                "Watch your skin and energy evolve week by week."
            ],
            trackedMetrics: ["Glow Score", "Skincare consistency", "Water intake", "Lymphatic routine", "Sleep", "Clean eating"]
        ),
        Challenge(
            id: "clean-eating",
            name: "Clean Eating Challenge",
            durationDays: 30,
            difficulty: .beginnerIntermediate,
            description: "A whole-food reset designed to reduce cravings, improve energy, and build cleaner eating habits.",
            joinedCount: 9800,
            focusTags: ["Whole Foods", "Cravings", "Nutrition"],
            habitPreview: ["Whole Foods", "No Added Sugar", "Protein", "Water", "Craving Check-In"],
            imageSlots: [ImageSlot(caption: "Fresh & whole")],
            imageLayout: .illustration,
            themeRGB: [0.557, 0.769, 0.627], // sage green
            dailyHabits: [
                DailyHabit(icon: "carrot.fill", name: "Whole Foods Meals", explanation: "Build meals around whole foods.", type: .checkmark, tip: "Build every meal around whole foods. A protein, veggies, a smart carb. If it comes in a wrapper with a long ingredient list, leave it."),
                DailyHabit(icon: "nosign", name: "No Added Sugar", explanation: "Avoid added and refined sugar.", type: .checkmark, tip: "Cut added sugar today. It hides in sauces, yogurt, and snacks that look healthy, so read labels. Craving hits? Fruit and a glass of water first."),
                DailyHabit(icon: "flame.fill", name: "Protein Goal", explanation: "Hit your daily protein goal.", type: .quantity, goal: 120, unit: "g", tip: "Hit your protein. It keeps you full, steadies blood sugar, and protects muscle. Lead every meal with a protein source."),
                DailyHabit(icon: "drop.fill", name: "Water Intake", explanation: "Reach your hydration target.", type: .quantity, goal: 100, unit: "oz", tip: "Drink 100 oz. Half the time hunger is really thirst. Have water first, wait 10 minutes, then decide if you're actually hungry."),
                DailyHabit(icon: "leaf.fill", name: "Fruit & Veggie Goal", explanation: "Eat 5 servings today.", type: .quantity, goal: 5, unit: "servings", tip: "Get 5 servings of fruits and veggies. Aim for color and variety, half your plate each meal. Fiber keeps you full and your gut happy."),
                DailyHabit(icon: "text.book.closed.fill", name: "Craving Check-In", explanation: "Note and reflect on cravings.", type: .journal, tip: "Write down your cravings. What you wanted, when, and what set it off. Naming the trigger is how you finally beat it."),
                DailyHabit(icon: "list.bullet.clipboard.fill", name: "Meal Prep / Plan", explanation: "Plan tomorrow's meals.", type: .checkmark, tip: "Prep tomorrow's meals tonight. Ten minutes now kills the what do I even eat panic that sends you straight to takeout.")
            ],
            rules: [
                "Center every meal on whole foods.",
                "No added sugar or ultra-processed snacks.",
                "Meet cravings with a mindful check-in.",
                "Progress over perfection, one clean choice at a time."
            ],
            trackedMetrics: ["Sugar-free streak", "Whole food consistency", "Protein goal", "Craving check-ins", "Water intake"]
        ),
        Challenge(
            id: "sugar-free",
            name: "Sugar Free Challenge",
            durationDays: 30,
            difficulty: .beginner,
            description: "A simple reset for cutting added sugar, reducing cravings, and building better food choices.",
            joinedCount: 7100,
            focusTags: ["Sugar Free", "Cravings", "Energy"],
            habitPreview: ["No Added Sugar", "Water", "Whole Foods", "Craving Log", "Protein"],
            imageSlots: [ImageSlot(caption: "Sweet freedom")],
            imageLayout: .gradient,
            themeRGB: [0.96, 0.62, 0.38], // warm orange
            dailyHabits: [
                DailyHabit(icon: "nosign", name: "No Added Sugar", explanation: "Cut all added sugar today.", type: .checkmark, tip: "Zero added sugar today. The first few days are the hardest while your body adjusts. Push through and the cravings fade. Read your labels."),
                DailyHabit(icon: "drop.fill", name: "Water Intake", explanation: "Stay hydrated to curb cravings.", type: .quantity, goal: 100, unit: "oz", tip: "Drink 100 oz. Water is your weapon against cravings. Want something sweet? Down a glass first. Usually it was just thirst."),
                DailyHabit(icon: "leaf.fill", name: "Whole Foods", explanation: "Choose whole, unprocessed foods.", type: .checkmark, tip: "Stick to whole, unprocessed foods. They keep your blood sugar steady, which means fewer crashes and way fewer cravings later."),
                DailyHabit(icon: "square.and.pencil", name: "Craving Log", explanation: "Log cravings as they appear.", type: .journal, tip: "Log every craving the second it hits. Writing it down creates a pause, and most cravings pass in a few minutes if you wait them out."),
                DailyHabit(icon: "flame.fill", name: "Protein Goal", explanation: "Get enough protein to stay full.", type: .quantity, goal: 120, unit: "g", tip: "Hit your protein. It's the most filling macro and it flattens the blood sugar spikes that push you toward sugar. Anchor every meal with it.")
            ],
            rules: [
                "No added or refined sugar for the day.",
                "Read labels. Hidden sugars count.",
                "Reach for water or protein when cravings hit.",
                "One day at a time builds the streak."
            ],
            trackedMetrics: ["Sugar-free streak", "Craving check-ins", "Whole food consistency", "Protein goal", "Water intake"]
        )
    ]
}
