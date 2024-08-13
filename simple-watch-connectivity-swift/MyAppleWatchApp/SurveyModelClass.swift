//
//  SurveyModelClass.swift
//  MyAppleWatchApp
//

// MARK: - SurveyItemType Enum
enum SurveyItemType: Int, Codable {
    case multipleChoiceQuestion
    case binaryChoice
    case contactForm
    case inlineQuestionGroup
    case commentsForm
}

// MARK: - Survey Class
final class Survey: ObservableObject, Codable {
    @Published var questions: [SurveyQuestion]
    let version: String
    var metadata: [String: String]? // Debugging information

    enum CodingKeys: CodingKey {
        case questions, version, metadata
    }

    init(questions: [SurveyQuestion], version: String) {
        self.questions = questions
        self.version = version
        
        var tags = Set<String>()
        for question in questions {
            assert(!tags.contains(question.tag), "Duplicate tag found: \(question.tag)")
            tags.insert(question.tag)
        }
    }

    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.questions = try container.decode([SurveyItem].self, forKey: .questions).map { $0.question }
        self.version = try container.decode(String.self, forKey: .version)
        self.metadata = try container.decodeIfPresent([String: String].self, forKey: .metadata)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(questions.map { SurveyItem(question: $0) }, forKey: .questions)
        try container.encode(version, forKey: .version)
        try container.encodeIfPresent(metadata, forKey: .metadata)
    }

    func choiceWithId(_ id: UUID) -> MultipleChoiceResponse? {
        for question in questions {
            if let choice = question.findChoice(by: id) {
                return choice
            }
        }
        return nil
    }
}

// MARK: - SurveyItem Class
final class SurveyItem: Codable {
    let type: SurveyItemType
    let question: SurveyQuestion

    enum CodingKeys: CodingKey {
        case type, question
    }

    init(question: SurveyQuestion) {
        self.question = question
        self.type = question.type
    }

    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.type = try container.decode(SurveyItemType.self, forKey: .type)

        switch type {
        case .multipleChoiceQuestion:
            self.question = try container.decode(MultipleChoiceQuestion.self, forKey: .question)
        case .binaryChoice:
            self.question = try container.decode(BinaryQuestion.self, forKey: .question)
        case .contactForm:
            self.question = try container.decode(ContactFormQuestion.self, forKey: .question)
        case .commentsForm:
            self.question = try container.decode(CommentsFormQuestion.self, forKey: .question)
        case .inlineQuestionGroup:
            self.question = try container.decode(InlineMultipleChoiceQuestionGroup.self, forKey: .question)
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(type, forKey: .type)
        try container.encode(question, forKey: .question)
    }
}

// MARK: - SurveyQuestion Protocol and Extension
protocol SurveyQuestion: Codable {
    var title: String { get }
    var uuid: UUID { get }
    var tag: String { get }
    var type: SurveyItemType { get }
    var required: Bool { get set }
    var visibilityLogic: VisibilityLogic? { get set }

    func findChoice(by id: UUID) -> MultipleChoiceResponse?
}

extension SurveyQuestion {
    var type: SurveyItemType {
        switch self {
        case is MultipleChoiceQuestion:
            return .multipleChoiceQuestion
        case is BinaryQuestion:
            return .binaryChoice
        case is ContactFormQuestion:
            return .contactForm
        case is InlineMultipleChoiceQuestionGroup:
            return .inlineQuestionGroup
        case is CommentsFormQuestion:
            return .commentsForm
        default:
            fatalError("Unsupported question type")
        }
    }

    func isVisible(for survey: Survey) -> Bool {
        if let logic = visibilityLogic {
            return survey.choiceWithId(logic.choiceId)?.selected ?? false
        }
        return true
    }

    func setVisibleWhenSelected(_ response: MultipleChoiceResponse) -> Self {
        var new = self
        new.visibilityLogic = VisibilityLogic(type: .choiceMustBeSelected, choiceId: response.uuid)
        return new
    }

    func required() -> Self {
        var new = self
        new.required = true
        return new
    }

    func optional() -> Self {
        var new = self
        new.required = false
        return new
    }

    func findChoice(by id: UUID) -> MultipleChoiceResponse? {
        return nil
    }
}

// MARK: - Specific Question Classes
class InlineMultipleChoiceQuestionGroup: ObservableObject, SurveyQuestion {
    let title: String
    var uuid: UUID = UUID()
    var questions: [MultipleChoiceQuestion]
    var visibilityLogic: VisibilityLogic?
    var required: Bool = false
    let tag: String

    init(title: String, questions: [MultipleChoiceQuestion], tag: String) {
        self.title = title
        self.questions = questions
        self.tag = tag
    }
}

class MultipleChoiceQuestion: ObservableObject, SurveyQuestion {
    let title: String
    var uuid: UUID = UUID()
    var choices: [MultipleChoiceResponse]
    var visibilityLogic: VisibilityLogic?
    var required: Bool = false
    var allowsMultipleSelection: Bool
    let tag: String

    init(title: String, answers: [String], multiSelect: Bool = false, tag: String) {
        self.title = title
        self.choices = answers.map { MultipleChoiceResponse($0) }
        self.allowsMultipleSelection = multiSelect
        self.tag = tag
    }

    init(title: String, items: [Any], multiSelect: Bool = false, tag: String) {
        self.title = title
        self.choices = items.compactMap {
            if let text = $0 as? String {
                return MultipleChoiceResponse(text)
            } else if let response = $0 as? MultipleChoiceResponse {
                return response
            }
            return nil
        }
        self.allowsMultipleSelection = multiSelect
        self.tag = tag
    }

    func findChoice(by id: UUID) -> MultipleChoiceResponse? {
        return choices.first { $0.uuid == id }
    }
}

class MultipleChoiceResponse: ObservableObject, Codable {
    let text: String
    var uuid: UUID = UUID()
    var selected = false
    let allowsCustomTextEntry: Bool
    var customTextEntry: String?

    init(_ text: String, allowsCustomTextEntry: Bool = false) {
        self.text = text
        self.allowsCustomTextEntry = allowsCustomTextEntry
    }
}

class BinaryQuestion: ObservableObject, SurveyQuestion {
    let title: String
    var uuid: UUID = UUID()
    var choices: [MultipleChoiceResponse]
    var required: Bool = false
    var visibilityLogic: VisibilityLogic?
    let autoAdvanceOnChoice: Bool
    let tag: String

    init(title: String, answers: [String], autoAdvanceOnChoice: Bool = true, tag: String) {
        assert(answers.count == 2, "BinaryQuestion must have exactly two answers")
        self.title = title
        self.choices = answers.map { MultipleChoiceResponse($0) }
        self.autoAdvanceOnChoice = autoAdvanceOnChoice
        self.tag = tag
    }

    func findChoice(by id: UUID) -> MultipleChoiceResponse? {
        return choices.first { $0.uuid == id }
    }
}

class ContactFormQuestion: ObservableObject, SurveyQuestion {
    let title: String
    var uuid: UUID = UUID()
    var required: Bool = false
    var visibilityLogic: VisibilityLogic?
    let tag: String

    var emailAddress: String = ""
    var name: String = ""
    var company: String = ""
    var phoneNumber: String = ""
    var feedback: String = ""

    init(title: String, tag: String) {
        self.title = title
        self.tag = tag
    }
}

class CommentsFormQuestion: ObservableObject, SurveyQuestion {
    let title: String
    let subtitle: String
    var uuid: UUID = UUID()
    var required: Bool = false
    var visibilityLogic: VisibilityLogic?
    let tag: String

    var emailAddress: String = ""
    var feedback: String = ""

    init(title: String, subtitle: String, tag: String) {
        self.title = title
        self.subtitle = subtitle
        self.tag = tag
    }
}

// MARK: - VisibilityLogic Class
class VisibilityLogic: Codable {
    enum LogicType: Int, Codable {
        case choiceMustBeSelected
        case choiceMustNotBeSelected
    }
    let type: LogicType
    let choiceId: UUID

    init(type: LogicType, choiceId: UUID) {
        self.type = type
        self.choiceId = choiceId
    }
}
