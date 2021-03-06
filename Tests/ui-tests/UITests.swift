//
//
//  Created by Tapash Majumder on 9/26/18.
//  Copyright © 2018 Iterable. All rights reserved.
//

import XCTest


class UITests: XCTestCase {
    private static var timeout = 15.0

    static var application: XCUIApplication = {
        let app = XCUIApplication()
        app.launch()
        return app
    }()
    
    static var monitor: NSObjectProtocol? = nil

    // shortcut calculated property
    private var app: XCUIApplication {
        return UITests.application
    }
    
    let springboard = XCUIApplication(bundleIdentifier: "com.apple.springboard")
    
    override func setUp() {
        // Put setup code here. This method is called before the invocation of each test method in the class.

        // In UI tests it is usually best to stop immediately when a failure occurs.
        continueAfterFailure = false

        // UI tests must launch the application that they test. Doing this in setup will make sure it happens for each test method.
        
        // In UI tests it’s important to set the initial state - such as interface orientation - required for your tests before they run. The setUp method is a good place to do this.
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }
    
    func testSendNotificationOpenSafari() {
        allowNotificationsIfNeeded()
        
        app.buttons["Send Notification"].tap()
        
        let notification = springboard.otherElements["NotificationShortLookView"]
        XCTAssert(notification.waitForExistence(timeout: 10))
        
        notification.swipeDown()
        
        // Give one second pause before interacting
        sleep(1)
        
        let button = SpringBoardNotification(springboard: springboard).buttonOpenSafari
        button.tap()

        // Give some time to open
        sleep(1)
        
        // Assert that Safari is Active
        let safariApp = XCUIApplication(bundleIdentifier: "com.apple.mobilesafari")
        XCTAssertEqual(safariApp.state, .runningForeground, "Safari is not active")
        
        // launch this app again for other tests
        app.launch()
    }

    func testSendNotificationOpenDeeplink() {
        allowNotificationsIfNeeded()
        
        app.buttons["Send Notification"].tap()
        
        let notification = springboard.otherElements["NotificationShortLookView"]
        XCTAssert(notification.waitForExistence(timeout: 10))
        
        notification.swipeDown()
        
        // Give one second pause before interacting
        sleep(1)
        
        let button = SpringBoardNotification(springboard: springboard).buttonOpenDeeplink
        button.tap()
        
        // Give some time to open
        sleep(1)
        
        waitForElementToAppear(app.staticTexts["https://www.myuniqueurl.com"])
    }

    func testSendNotificationCustomAction() {
        allowNotificationsIfNeeded()
        
        app.buttons["Send Notification"].tap()
        
        let notification = springboard.otherElements["NotificationShortLookView"]
        XCTAssert(notification.waitForExistence(timeout: 10))
        
        notification.swipeDown()
        
        // Give one second pause before interacting
        sleep(1)
        
        let button = SpringBoardNotification(springboard: springboard).buttonCustomAction
        button.tap()
        
        // Give some time to open
        sleep(1)
        
        waitForElementToAppear(app.staticTexts["MyUniqueCustomAction"])
    }

    
    func testShowSystemNotification() {
        // Tap the Left Button
        app.buttons["Show System Notification#1"].tap()

        let alert = app.alerts.element
        waitForElementToAppear(alert)
        
        XCTAssertTrue(alert.staticTexts["Zee Title"].exists)
        XCTAssertTrue(alert.staticTexts["Zee Body"].exists)

        app.buttons["Left Button"].tap()

        waitForElementToAppear(app.staticTexts["Left Button"])

        app.buttons["Show System Notification#1"].tap()
        waitForElementToAppear(alert)

        // Tap the Right Button
        app.buttons["Right Button"].tap()
        waitForElementToAppear(app.staticTexts["Right Button"])
    }

    func testShowSystemNotification2() {
        // Tap the Left Button
        app.buttons["Show System Notification#2"].tap()
        
        let alert = app.alerts.element
        waitForElementToAppear(alert)
        
        XCTAssertTrue(alert.staticTexts["Zee Title"].exists)
        XCTAssertTrue(alert.staticTexts["Zee Body"].exists)
        
        app.buttons["Zee Button"].tap()
        
        waitForElementToAppear(app.staticTexts["Zee Button"])
    }

    func testShowInApp1() {
        // Tap the Left Button
        app.buttons["Show InApp#1"].tap()
        
        let clickMe = app.links["Click Me"]
        waitForElementToAppear(clickMe)
        clickMe.tap()

        let callbackUrl = self.app.staticTexts["http://website/resource#something"]
        waitForElementToAppear(callbackUrl)
    }

    func testShowInApp2() {
        // Tap the Left Button
        app.buttons["Show InApp#2"].tap()
        
        let clickHere = app.links["Click Here"]
        _  = waitForElementToAppear(clickHere)
        clickHere.tap()

        let callbackLink = app.staticTexts["https://www.google.com/q=something"]
        waitForElementToAppear(callbackLink)
    }

    func testShowInApp3() {
        // Tap the Left Button
        app.buttons["Show InApp#3"].tap()
        
        let clickHere = app.links["Click Here"]
        _  = waitForElementToAppear(clickHere)
        clickHere.tap()
        
        let callbackLink = app.staticTexts["https://www.google.com/q=something"]
        waitForElementToAppear(callbackLink)
    }

    private func waitForElementToAppear(_ element: XCUIElement, fail: Bool = true) {
        let exists = element.waitForExistence(timeout: UITests.timeout)
        
        if fail && !exists {
            XCTFail("expected element: \(element)")
        }
    }
    
    private func allowNotificationsIfNeeded() {
        app.buttons["Setup Notifications"].tap()
        UITests.monitor = addUIInterruptionMonitor(withDescription: "Getting Notification Permission") { (alert) -> Bool in
            let okButton = alert.buttons["Allow"]
            self.waitForElementToAppear(okButton)
            okButton.tap()
            if let monitor = UITests.monitor {
                self.removeUIInterruptionMonitor(monitor)
            }
            return true
        }
        // Xcode bug?, need to make this app active
        app.swipeUp()
    }
}

struct SpringBoardNotification {
    let springboard: XCUIApplication
    
    var buttonOpenSafari: XCUIElement {
        return springboard.buttons["Open Safari"].firstMatch
    }

    var buttonOpenDeeplink: XCUIElement {
        return springboard.buttons["Open Deeplink"].firstMatch
    }

    var buttonCustomAction: XCUIElement {
        return springboard.buttons["Custom Action"].firstMatch
    }
}

