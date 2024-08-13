//
//  SampleSurvey.swift
//  MyAppleWatchApp
//

typealias MCQ = MultipleChoiceQuestion
typealias MCR = MultipleChoiceResponse

// MARK: - Helper Functions
/// Creates a `MultipleChoiceQuestion` for determining the importance of a feature.
func importanceQuestion(_ title: String) -> MultipleChoiceQuestion {
    MultipleChoiceQuestion(title: title, answers: ["Not Important", "Somewhat Important", "Very Important"], tag: titleToTag(title))
}

// MARK: - Survey Questions
let askContactUs = BinaryQuestion(
    title: "Would you like to be contacted about new features?",
    answers: ["Yes", "No"],
    tag: "contact-us"
)

let contactForm = ContactFormQuestion(
    title: "Please share your contact info and we will reach out",
    tag: "contact-form"
)

let askComments = BinaryQuestion(
    title: "Do you have any feedback or feature ideas for us?",
    answers: ["Yes", "No"],
    autoAdvanceOnChoice: true,
    tag: "do-you-have-feedback"
)

let commentsForm = CommentsFormQuestion(
    title: "Tell us your feedback or feature requests",
    subtitle: "Optionally leave your email",
    tag: "feedback-comments-form"
)

// MARK: - Sample Survey
let SampleSurvey = Survey(
    questions: [

        CommentsFormQuestion(
            title: "Think back to 15 minutes ago. What activity were you doing?",
            subtitle: "",
            tag: "feedback-comments-form"
        ),
        
        MCQ(
            title: "I feel focused.",
            items: [
                "Not at all",
                "A little",
                "Somewhat",
                "Very Much So"
                // MCR("Other", allowsCustomTextEntry: true)
            ],
            multiSelect: false,
            tag: "q2"
        ),
        
        MCQ(
            title: "I feel stressed.",
            items: [
                "Not at all",
                "A little",
                "Somewhat",
                "Very Much So"
                // MCR("Other", allowsCustomTextEntry: true)
            ],
            multiSelect: false,
            tag: "q3"
        ),
        
        MCQ(
            title: "I feel excited.",
            items: [
                "Not at all",
                "A little",
                "Somewhat",
                "Very Much So"
                // MCR("Other", allowsCustomTextEntry: true)
            ],
            multiSelect: false,
            tag: "q4"
        ),
        
        MCQ(
            title: "I feel anxious.",
            items: [
                "Not at all",
                "A little",
                "Somewhat",
                "Very Much So"
                // MCR("Other", allowsCustomTextEntry: true)
            ],
            multiSelect: false,
            tag: "q5"
        ),
        
        MCQ(
            title: "I feel pleasant.",
            items: [
                "Not at all",
                "A little",
                "Somewhat",
                "Very Much So"
                // MCR("Other", allowsCustomTextEntry: true)
            ],
            multiSelect: false,
            tag: "q6"
        ),
        
        MCQ(
            title: "I feel relaxed.",
            items: [
                "Not at all",
                "A little",
                "Somewhat",
                "Very Much So"
                // MCR("Other", allowsCustomTextEntry: true)
            ],
            multiSelect: false,
            tag: "q7"
        ),
        
        MCQ(
            title: "I feel happy.",
            items: [
                "Not at all",
                "A little",
                "Somewhat",
                "Very Much So"
                // MCR("Other", allowsCustomTextEntry: true)
            ],
            multiSelect: false,
            tag: "q8"
        )
        
        
        /*InlineMultipleChoiceQuestionGroup(
            title: "What new features are important to you?",
            questions: [
                importanceQuestion("Faster load times"),
                importanceQuestion("Dark mode support"),
                importanceQuestion("Lasers")
            ],
            tag: "importance-what-improvements"
        ),
        
        askContactUs,
        contactForm.setVisibleWhenSelected(askContactUs.choices.first!),
        
        askComments,
        commentsForm.setVisibleWhenSelected(askComments.choices.first!)*/
    ],
    version: "001"
)
