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
    var date: Date
    var comments:[String]? = nil
    var tickets:[String]? = nil
}

/// Parse a changelog
public struct ParseCommand: CommandProtocol {
    public let verb = "parse"
    public let function = "Parse a Changelog"

    public struct Options: OptionsProtocol {
        public let file: String?
        public let outfile: String?
        public let withIssues: Bool?
        public let withVersion: Bool?
        
        public static func create(_ file: String?)
            -> (_ outfile: String?)
            -> (_ withIssues: Bool?)
            -> (_ withVersion: Bool?)
            -> Options {
                return { outfile in { withIssues in { withVersion in
                    return self.init(file: file,
                                     outfile: outfile,
                                     withIssues: withIssues,
                                     withVersion: withVersion)
                    } } }
        }
        
        public static func evaluate(_ m: CommandMode) -> Result<Options, CommandantError<ChangelogParserError>> {
            
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
    
    public func run(_ options: Options) -> Result<(), ChangelogParserError> {
        
        guard let file:String = options.file,
            let outfile:String  = options.outfile,
            let showIssues:Bool = options.withIssues,
            let _:Bool = options.withVersion
            else {
                return .failure(.invalidArgument(description: "Missing values: file, outfile"))
        }

        let path = URL(fileURLWithPath: file)
        do {

            let text = try NSString(contentsOf: path, encoding: String.Encoding.utf8.rawValue) as String
            var lines:[String] = []
            text.enumerateLines{ (line, stop) -> () in
                lines.append(line)
            }
            
            let cla = ChangelogAnalyzer(changelog: lines)
            self.getLog(cla, completion: { (result) in
               
                guard let log = result.data , result.success else {
                    print(ChangelogParserError.parseFailed(description: "Parse failed").description)
                    //return .Failure(.ParseFailed(description: "Parse failed"))
                    exit(EXIT_FAILURE)
                }
                
                self.writeLog(log, file: outfile, completion: { (writeResult) in
                    
                    if let error = writeResult.error , !writeResult.success {
                        print(error.description)
                        exit(EXIT_FAILURE)
                    }
                    
                    print(self.buildInfo(log))
                    
                    if let tickets:String = self.getTicketIds(log) , showIssues {
                        print(tickets)
                    }
                
                    exit(EXIT_SUCCESS)
                })
            })

            CFRunLoopRun()
            return .success(())
        } catch let error as NSError {
            
            print(ChangelogParserError.parseFailed(description: error.localizedDescription).description)
            //exit(EXIT_FAILURE)
            return .failure(.parseFailed(description: "Parse failed"))
        }
        
        // return .Failure(.ParseFailed(description: "Parse failed"))
    }
    
    /// Write a `Changelog` to the provided file on disk.
    fileprivate func writeLog(_ log: Changelog, file: String, completion: (_ result: ChangelogParserResult) -> ()) {
        
        let outUrl:URL = URL.init(fileURLWithPath: file)

        do {
            let markdown = textualize(log)
            try markdown.write(to: outUrl, atomically: false, encoding: String.Encoding.utf8)
            completion(ChangelogParserResult(success: true, error: nil, data: nil))

        } catch let error as NSError {
            completion(ChangelogParserResult(success: false, error: .fileWriteFailed(description: "Write to output file \(outUrl) failed: \(error.localizedDescription)"), data: nil))
        }
    }
    
    /// Creates a Markdown formatted string representation of the Changelog.
    fileprivate func textualize(_ changelog: Changelog) -> String {
        
        let buildString = String(changelog.buildNumber)
        var text = "\(changelog.version) #\(buildString)\n"
        
        if let comments = changelog.comments , !comments.isEmpty {
            for comment in comments.reversed() {
                text = text + "* \(comment)\n"
            }
        }
        
        if let tickets = changelog.tickets , !tickets.isEmpty {
            for ticket in tickets.reversed() {
                text = text + "* \(ticket)\n"
            }
        }
        
        return text
    }
    
    /// Obtain the data from the `ChangelogAnalyzer` and build a `Changelog` representation of it.
    fileprivate func getLog(_ cla: ChangelogAnalyzer, completion: (_ result: ChangelogParserResult) -> ()) {
        
        if cla.isTBD() {
            let error = ChangelogParserError.buildIsTBD(description: "Build date is To Be Determined")
            let result = ChangelogParserResult.init(success: false, error: error, data: nil)
            completion(result)
            return
        }
        
        guard let buildVersion = cla.buildVersionString(), let buildNumber = cla.buildNumber(), let buildDate = cla.buildDate(), let comments = cla.comments(), let tickets = cla.tickets() , (!comments.isEmpty || !tickets.isEmpty) else {
            
            let result = ChangelogParserResult.init(success: false, error: .buildHasNoTicketsNorComments(description: "Changelog must have tickets or comments defined"), data: nil)
            completion(result)
            return
        }
        
        let logData = Changelog(version: buildVersion, buildNumber: buildNumber, date: buildDate, comments: comments, tickets: tickets)
        let result = ChangelogParserResult(success: true, error: nil, data: logData)
        completion(result)
    }
    
    fileprivate func getTicketIds(_ changelog: Changelog) -> String? {

        guard let tickets = changelog.tickets , !tickets.isEmpty else {
            return nil
        }
        
        var ticketIds:String = ""
        
        for ticket in tickets.reversed() {
            if let ticketId = ticket.components(separatedBy: " ").first {
                
                let appending = ( ticketIds.isEmpty ) ? ticketId : ",\(ticketId)"
                ticketIds = ticketIds + appending
            }
        }
        
        return ticketIds
    }
    
    /// Write Issues to a file on disk.
    fileprivate func writeIssues(_ issueText: String, file: String, completion: (_ result: ChangelogParserResult) -> ()) {
        
        let outUrl:URL = URL.init(fileURLWithPath: file)
        do {
            try issueText.write(to: outUrl, atomically: false, encoding: String.Encoding.utf8)
            completion(ChangelogParserResult(success: true, error: nil, data: nil))
            
        } catch let error as NSError {
            completion(ChangelogParserResult(success: false, error: .fileWriteFailed(description: "Write to output file \(outUrl) failed: \(error.localizedDescription)"), data: nil))
        }
    }
    
    /// Write Version to a file on disk.
    fileprivate func writeVersion(_ version: String, build:String, file: String, completion: (_ result: ChangelogParserResult) -> ()) {
        
        let outUrl:URL = URL.init(fileURLWithPath: file)

        do {
            let text = version + " #" + build
            try text.write(to: outUrl, atomically: false, encoding: String.Encoding.utf8)
            completion(ChangelogParserResult(success: true, error: nil, data: nil))
            
        } catch let error as NSError {
            completion(ChangelogParserResult(success: false, error: .fileWriteFailed(description: "Write to output file \(outUrl) failed: \(error.localizedDescription)"), data: nil))
        }
    }
    
    /// Build a string with 'Version: x.y.z Number: buildnumber'
    fileprivate func buildInfo(_ log: Changelog) -> String {
        
        let buildNumber:UInt = log.buildNumber
        let buildString:String = String(buildNumber)
        return "Version: \(log.version) Number:\(buildString)"
    }

}

