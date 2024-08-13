//
//  SceneDelegate.swift
//  MyAppleWatchApp
//

import SwiftUI

class SceneDelegate: UIResponder, UIWindowSceneDelegate, UIGestureRecognizerDelegate {
    @ObservedObject var e4linkManager = E4linkManager.shared
    
    // file:///var/mobile/Containers/Data/Application/D4BD4F66-E243-44A7-AF99-8C6ACDDDAF99/Documents/ //
    let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]

    var window: UIWindow?

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        // Use this method to optionally configure and attach the UIWindow `window` to the provided UIWindowScene `scene`.
        // If using a storyboard, the `window` property will automatically be initialized and attached to the scene.
        // This delegate does not imply the connecting scene or session are new (see `application:configurationForConnectingSceneSession` instead).
        
        /*let jsonUrl = self.documentsURL.appendingPathComponent("sample_survey.json")
        try? Survey.save(survey, to: jsonUrl)
        print( " Saved survey to: \n" , jsonUrl.path )
 
        if let loadedSurvey = try? Survey.load(from: jsonUrl) {
            print(" Loaded survey from:\n ", jsonUrl)
            survey = loadedSurvey
        }*/

        // Use a UIHostingController as window root view controller.
        /*if let windowScene = scene as? UIWindowScene {
            let window = UIWindow(windowScene: windowScene)
            window.rootViewController = UIHostingController(rootView: ContentView())
            self.window = window
            
            // Add a tap gesture to the background to dismiss the keyboard
            let tapGesture = UITapGestureRecognizer(target: window, action: #selector(UIView.endEditing))
            tapGesture.requiresExclusiveTouchType = false
            tapGesture.cancelsTouchesInView = false
            tapGesture.delegate = self
            window.addGestureRecognizer(tapGesture)
            
            window.makeKeyAndVisible()
        }*/
    }
    
    public func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return false // set to `false` if you don't want to detect tap during other gestures
    }
    
    func sceneDidDisconnect(_ scene: UIScene) {
        // Called as the scene is being released by the system.
        // This occurs shortly after the scene enters the background, or when its session is discarded.
        // Release any resources associated with this scene that can be re-created the next time the scene connects.
        // The scene may re-connect later, as its session was not necessarily discarded (see `application:didDiscardSceneSessions` instead).
        EmpaticaAPI.cancelDiscovery()
    }

    func sceneDidBecomeActive(_ scene: UIScene) {
        // Called when the scene has moved from an inactive state to an active state.
        // Use this method to restart any tasks that were paused (or not yet started) when the scene was inactive.
        UNUserNotificationCenter.current().removeAllDeliveredNotifications()
        UNUserNotificationCenter.current().setBadgeCount(0)
    }

    func sceneWillResignActive(_ scene: UIScene) {
        // Called when the scene will move from an active state to an inactive state.
        // This may occur due to temporary interruptions (ex. an incoming phone call).
    }

    func sceneWillEnterForeground(_ scene: UIScene) {
        // Called as the scene transitions from the background to the foreground.
        // Use this method to undo the changes made on entering the background.
        EmpaticaAPI.prepareForResume()
    }

    func sceneDidEnterBackground(_ scene: UIScene) {
        // Called as the scene transitions from the foreground to the background.
        // Use this method to save data, release shared resources, and store enough scene-specific state information
        // to restore the scene back to its current state.
        EmpaticaAPI.prepareForBackground()
    }
}

extension SceneDelegate : SurveyViewDelegate {
    func surveyCompleted(with survey: Survey) {
        print("COMPLETED")
        let date = Date()
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "dd-MM-yyyy!HH:mm:ss"
        let dayInWeek = dateFormatter.string(from: date)
        let filename = "Survey::" + dayInWeek
        
        let jsonUrl = self.documentsURL.appendingPathComponent(filename + ".json")
    
        try? Survey.save(survey, to: jsonUrl)
        print( "Saved survey to: \n" , jsonUrl.path )
        e4linkManager.showSurvey = false
        e4linkManager.showSurveyButton = false
    }
    
    func surveyDeclined() { 
        e4linkManager.showSurvey = false
    }
    
    func surveyRemindMeLater() { }
    
}
