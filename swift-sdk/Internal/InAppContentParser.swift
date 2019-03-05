//
//  Created by Tapash Majumder on 2/15/19.
//  Copyright © 2019 Iterable. All rights reserved.
//
// Parses content JSON coming from the server based on 'contentType' attribute.
//

import Foundation

enum InAppContentParseResult {
    case success(content: IterableContent)
    case failure(reason: String)
}

struct InAppContentParser {
    static func parse(contentDict: [AnyHashable : Any]) -> InAppContentParseResult {
        let contentType: IterableContentType
        if let contentTypeStr = contentDict[.ITBL_IN_APP_CONTENT_TYPE] as? String {
            contentType = IterableContentType.from(string: contentTypeStr)
        } else {
            contentType = .html
        }

        return contentCreator(forContentType: contentType).tryCreate(from: contentDict)
    }
    
    private static func contentCreator(forContentType contentType: IterableContentType) -> ContentFromJsonCreator.Type {
        switch contentType {
        case .html:
            return InAppHtmlContentCreator.self
        case .inboxHtml:
            return InboxHtmlContentCreator.self
        default:
            return InAppHtmlContentCreator.self
        }
    }
}

fileprivate protocol ContentFromJsonCreator {
    static func tryCreate(from json: [AnyHashable : Any]) -> InAppContentParseResult
}

struct HtmlContentCreator {
    enum Result {
        case success(content: HtmlContent)
        case failure(reason: String)
    }
    
    struct HtmlContent {
        let edgeInsets: UIEdgeInsets
        let backgroundAlpha: Double
        let html: String
    }
    
    fileprivate static func tryCreate(from json: [AnyHashable : Any]) -> Result {
        guard let html = json[.ITBL_IN_APP_HTML] as? String else {
            return .failure(reason: "no html")
        }
        guard html.range(of: AnyHashable.ITBL_IN_APP_HREF, options: [.caseInsensitive]) != nil else {
            return .failure(reason: "No href tag found in in-app html payload \(html)")
        }
        
        let inAppDisplaySettings = json[.ITBL_IN_APP_DISPLAY_SETTINGS] as? [AnyHashable : Any]
        let backgroundAlpha = getBackgroundAlpha(fromInAppSettings: inAppDisplaySettings)
        let edgeInsets = getPadding(fromInAppSettings: inAppDisplaySettings)
        return .success(content: HtmlContent(edgeInsets: edgeInsets, backgroundAlpha: backgroundAlpha, html: html))
    }

    /**
     Parses the padding offsets from the payload
     
     - parameter settings:         the settings distionary.
     
     - returns: the UIEdgeInset
     */
    static func getPadding(fromInAppSettings settings: [AnyHashable : Any]?) -> UIEdgeInsets {
        guard let dict = settings else {
            return UIEdgeInsets.zero
        }
        
        var padding = UIEdgeInsets.zero
        if let topPadding = dict[PADDING_TOP] {
            padding.top = CGFloat(decodePadding(topPadding))
        }
        if let leftPadding = dict[PADDING_LEFT] {
            padding.left = CGFloat(decodePadding(leftPadding))
        }
        if let rightPadding = dict[PADDING_RIGHT] {
            padding.right = CGFloat(decodePadding(rightPadding))
        }
        if let bottomPadding = dict[PADDING_BOTTOM] {
            padding.bottom = CGFloat(decodePadding(bottomPadding))
        }
        
        return padding
    }
    
    /**
     Gets the int value of the padding from the payload
     
     @param value          the value
     
     @return the padding integer
     
     @discussion Passes back -1 for Auto expanded padding
     */
    static func decodePadding(_ value: Any?) -> Int {
        guard let dict = value as? [AnyHashable : Any] else {
            return 0
        }
        
        if let displayOption = dict[IN_APP_DISPLAY_OPTION] as? String, displayOption == IN_APP_AUTO_EXPAND {
            return -1
        } else {
            if let percentage = dict[IN_APP_PERCENTAGE] as? NSNumber {
                return percentage.intValue
            } else {
                return 0
            }
        }
    }
    
    static func getBackgroundAlpha(fromInAppSettings settings: [AnyHashable : Any]?) -> Double {
        guard let settings = settings else {
            return 0
        }
        
        if let number = settings[.ITBL_IN_APP_BACKGROUND_ALPHA] as? NSNumber {
            return number.doubleValue
        } else {
            return 0
        }
    }

    private static let PADDING_TOP = "top"
    private static let PADDING_LEFT = "left"
    private static let PADDING_BOTTOM = "bottom"
    private static let PADDING_RIGHT = "right"
    
    private static let IN_APP_DISPLAY_OPTION = "displayOption"
    private static let IN_APP_AUTO_EXPAND = "AutoExpand"
    private static let IN_APP_PERCENTAGE = "percentage"
}

struct InAppHtmlContentCreator : ContentFromJsonCreator {
    fileprivate static func tryCreate(from json: [AnyHashable : Any]) -> InAppContentParseResult {
        switch HtmlContentCreator.tryCreate(from: json) {
        case .failure(let reason):
            return .failure(reason: reason)
        case .success(let content):
            return .success(content: IterableInAppHtmlContent(edgeInsets: content.edgeInsets, backgroundAlpha: content.backgroundAlpha, html: content.html))
        }
    }
}

struct InboxHtmlContentCreator : ContentFromJsonCreator {
    fileprivate static func tryCreate(from json: [AnyHashable : Any]) -> InAppContentParseResult {
        switch HtmlContentCreator.tryCreate(from: json) {
        case .failure(let reason):
            return .failure(reason: reason)
        case .success(let htmlContent):
            return .success(content: createInboxHtmlContent(json: json, htmlContent: htmlContent))
        }
    }
    
    private static func createInboxHtmlContent(json: [AnyHashable : Any], htmlContent: HtmlContentCreator.HtmlContent) -> IterableInboxHtmlContent {
        return IterableInboxHtmlContent(edgeInsets: htmlContent.edgeInsets,
                                        backgroundAlpha: htmlContent.backgroundAlpha,
                                        html: htmlContent.html,
                                        title: json.getStringValue(key: .inboxTitle),
                                        subTitle: json.getStringValue(key: .inboxSubtitle),
                                        icon: json.getStringValue(key: .inboxIcon))
    }
}

