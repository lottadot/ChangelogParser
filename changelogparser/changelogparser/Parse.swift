//
//  Parse.swift
//  changelogparser
//
//  Created by Shane Zatezalo on 8/21/16.
//  Copyright © 2016 Lottadot LLC. All rights reserved.
//

import Foundation
import Swift
import ChangelogKit
import Result
import Commandant
import Cocoa

/// This struct is the `ParseCommand`'s changelog representation.
struct Changelog {
    var version: String
    var buildNumber: UInt
    var date: NSDate
    var comments:[String]? = nil
    var tickets:[String]? = nil
}

/// Parse a changelog
public struct ParseCommand: CommandType {
    public let verb = "parse"
    public let function = "Parse a Changelog"

    public struct Options: OptionsType {
        public let file: String?
        public let outfile: String?
        public let withIssues: Bool?
        public let withVersion: Bool?
        
        public static func create(file: String?)
            -> (outfile: String?)
            -> (withIssues: Bool?)
            -> (withVersion: Bool?)
            -> Options {
                return { outfile in { withIssues in { withVersion in
                    return self.init(file: file,
                                     outfile: outfile,
                                     withIssues: withIssues,
                                     withVersion: withVersion)
                    } } }
        }
        
        public static func evaluate(m: CommandMode) -> Result<Options, CommandantError<ChangelogParserError>> {
            
            return create
                <*> m <| Option(key: "file",
                                defaultValue: "CHANGELOG", usage: "the absolute path of the CHANGELOG file parse")
                <*> m <| Option(key: "outfile",
                                defaultValue: "CHANGELOG-RELEASENOTES.md", usage: "the out release notes file to build")
                <*> m <| Option(key: "withIssues",
                                defaultValue: false, usage: "write IssueIds to CHANGELOG-ISSUES.TXT")
                <*> m <| Option(key: "withVersion",
                                defaultValue: false, usage: "write Version Information to CHANGELOG-VERSION.TXT")
        }
    }
    
    public func run(options: Options) -> Result<(), ChangelogParserError> {
        
        guard let file:String = options.file,
            let outfile:String  = options.outfile,
            let showIssues:Bool = options.withIssues,
            let showVersion:Bool = options.withVersion
            else {
                return .Failure(.InvalidArgument(description: "Missing values: file, outfile"))
        }

        let path = NSURL(fileURLWithPath: file)
        do {

            let text = try NSString(contentsOfURL: path, encoding: NSUTF8StringEncoding) as String
            var lines:[String] = []
            text.enumerateLines { lines.append($0.line)}
            
            let cla = ChangelogAnalyzer(changelog: lines)
            self.getLog(cla, completion: { (result) in
               
                guard let log = result.data where result.success else {
                    print(ChangelogParserError.ParseFailed(description: "Parse failed").description)
                    //return .Failure(.ParseFailed(description: "Parse failed"))
                    exit(EXIT_FAILURE)
                }
                
                self.writeLog(log, file: outfile, completion: { (writeResult) in
                    
                    if let error = writeResult.error where !writeResult.success {
                        print(error.description)
                        exit(EXIT_FAILURE)
                    }
                    
                    if let info:String = self.buildInfo(log) where showVersion {
                        print(info)
                    }
                    
                    if let tickets:String = self.getTicketIds(log) where showIssues {
                        print(tickets)
                    }
                
                    exit(EXIT_SUCCESS)
                })
            })

            CFRunLoopRun()
            return .Success(())
        } catch let error as NSError {
            
            print(ChangelogParserError.ParseFailed(description: error.localizedDescription).description)
            //exit(EXIT_FAILURE)
            return .Failure(.ParseFailed(description: "Parse failed"))
        }
        
        // return .Failure(.ParseFailed(description: "Parse failed"))
    }
    
    /// Write a `Changelog` to the provided file on disk.
    private func writeLog(log: Changelog, file: String, completion: (result: ChangelogParserResult) -> ()) {
        
        guard let outUrl:NSURL = NSURL.init(fileURLWithPath: file) else {
            completion(result: ChangelogParserResult(success: false, error: .FileWriteFailed(description: "Write to output file failed"), data: nil))
            return
        }
        
        do {
            let markdown = textualize(log)
            try markdown.writeToURL(outUrl, atomically: false, encoding: NSUTF8StringEncoding)
            completion(result: ChangelogParserResult(success: true, error: nil, data: nil))

        } catch let error as NSError {
            completion(result: ChangelogParserResult(success: false, error: .FileWriteFailed(description: "Write to output file \(outUrl) failed: \(error.localizedDescription)"), data: nil))
        }
    }
    
    /// Creates a Markdown formatted string representation of the Changelog.
    private func textualize(changelog: Changelog) -> String {
        
        let buildString = String(changelog.buildNumber)
        var text = "\(changelog.version) #\(buildString)\n"
        
        if let comments = changelog.comments where !comments.isEmpty {
            for comment in comments.reverse() {
                text = text + "* \(comment)\n"
            }
        }
        
        if let tickets = changelog.tickets where !tickets.isEmpty {
            for ticket in tickets.reverse() {
                text = text + "* \(ticket)\n"
            }
        }
        
        return text
    }
    
    /// Obtain the data from the `ChangelogAnalyzer` and build a `Changelog` representation of it.
    private func getLog(cla: ChangelogAnalyzer, completion: (result: ChangelogParserResult) -> ()) {
        
        if cla.isTBD() {
            let error = ChangelogParserError.BuildIsTBD(description: "Build date is To Be Determined")
            let result = ChangelogParserResult.init(success: false, error: error, data: nil)
            completion(result: result)
            return
        }
        
        guard let buildVersion = cla.buildVersionString(), let buildNumber = cla.buildNumber(), let buildDate = cla.buildDate(), let comments = cla.comments(), let tickets = cla.tickets() where (!comments.isEmpty || !tickets.isEmpty) else {
            
            let result = ChangelogParserResult.init(success: false, error: .BuildHasNoTicketsNorComments(description: "Changelog must have tickets or comments defined"), data: nil)
            completion(result: result)
            return
        }
        
        let logData = Changelog(version: buildVersion, buildNumber: buildNumber, date: buildDate, comments: comments, tickets: tickets)
        let result = ChangelogParserResult(success: true, error: nil, data: logData)
        completion(result: result)
    }
    
    private func getTicketIds(changelog: Changelog) -> String? {

        guard let tickets = changelog.tickets where !tickets.isEmpty else {
            return nil
        }
        
        var ticketIds:String = ""
        
        for ticket in tickets.reverse() {
            if let ticketId = ticket.componentsSeparatedByString(" ").first {
                
                let appending = ( ticketIds.isEmpty ) ? ticketId : ",\(ticketId)"
                ticketIds = ticketIds + appending
            }
        }
        
        return ticketIds
    }
    
    /// Write Issues to a file on disk.
    private func writeIssues(issueText: String, file: String, completion: (result: ChangelogParserResult) -> ()) {
        
        guard let outUrl:NSURL = NSURL.init(fileURLWithPath: file) else {
            completion(result: ChangelogParserResult(success: false, error: .FileWriteFailed(description: "Write to output file failed"), data: nil))
            return
        }
        
        do {
            try issueText.writeToURL(outUrl, atomically: false, encoding: NSUTF8StringEncoding)
            completion(result: ChangelogParserResult(success: true, error: nil, data: nil))
            
        } catch let error as NSError {
            completion(result: ChangelogParserResult(success: false, error: .FileWriteFailed(description: "Write to output file \(outUrl) failed: \(error.localizedDescription)"), data: nil))
        }
    }
    
    /// Write Version to a file on disk.
    private func writeVersion(version: String, build:String, file: String, completion: (result: ChangelogParserResult) -> ()) {
        
        guard let outUrl:NSURL = NSURL.init(fileURLWithPath: file) else {
            completion(result: ChangelogParserResult(success: false, error: .FileWriteFailed(description: "Write to output file failed"), data: nil))
            return
        }
        
        do {
            let text = version + " #" + build
            try text.writeToURL(outUrl, atomically: false, encoding: NSUTF8StringEncoding)
            completion(result: ChangelogParserResult(success: true, error: nil, data: nil))
            
        } catch let error as NSError {
            completion(result: ChangelogParserResult(success: false, error: .FileWriteFailed(description: "Write to output file \(outUrl) failed: \(error.localizedDescription)"), data: nil))
        }
    }
    
    /// Build a string with 'Version: x.y.z Number: buildnumber'
    private func buildInfo(log: Changelog) -> String {
        
        guard let buildVersion:String = log.version, let buildNumber:UInt = log.buildNumber, let buildString:String = String(buildNumber) else {
            return ""
        }
        
        return "Version: \(buildVersion) Number:\(buildString)"
    }

}

