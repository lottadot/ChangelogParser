//: Playground - noun: a place where people can play

import Cocoa

let r = "^\\w"
let str = "IssueId1 This is a Ticket Issue1"
private func applyToString(text: String, regex: String) -> AnyObject? {
    
    guard  let data = text.rangeOfString(regex, options: .RegularExpressionSearch) else {
        return nil
    }
    
    return text.substringWithRange(data)
}

print(applyToString(str, regex: r))
