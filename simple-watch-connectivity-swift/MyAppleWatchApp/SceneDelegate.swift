//
//  SceneDelegate.swift
//  MyAppleWatchApp
//

import SwiftUI

class SceneDelegate: UIResponder, UIWindowSceneDelegate, UIGestureRecognizerDelegate {
    @ObservedObject var e4linkManager = E4linkManager.shared
    
    // file:///var/mobile/Containers/Data/Application/D4BD4F66-E243-44A7-AF99-8C6ACDDDAF99/Documents/ //
    let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    
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
        let filename = "SurveyResponses.csv"
        let csvUrl = self.documentsURL.appendingPathComponent(filename)

        // Prepare the CSV row
        let csvRow = survey.toCSVRow() + "\n"

        do {
            if FileManager.default.fileExists(atPath: csvUrl.path) {
                // Append to existing file
                if let fileHandle = try? FileHandle(forWritingTo: csvUrl) {
                    fileHandle.seekToEndOfFile()
                    if let data = csvRow.data(using: .utf8) {
                        fileHandle.write(data)
                    }
                    fileHandle.closeFile()
                }
            } else {
                // File doesn't exist, create it with headers
                let headers = "date,time,version," + survey.questions.map { $0.tag }.joined(separator: ",") + "\n"
                let combinedData = headers + csvRow
                try combinedData.write(to: csvUrl, atomically: true, encoding: .utf8)
            }
            print("Saved survey response to CSV: \(csvUrl.path)")
        } catch {
            print("Failed to save survey to CSV: \(error)")
        }

        // Reset the survey questions
        for question in survey.questions {
            question.reset()
        }

        e4linkManager.showSurvey = false
        e4linkManager.showSurveyButton = false
    }
    
    func surveyDeclined() { 
        e4linkManager.showSurvey = false
    }
    
    func surveyRemindMeLater() { }
    
}
