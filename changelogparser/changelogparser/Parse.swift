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

/// Parse a changelog
public struct ParseCommand: CommandType {
    public let verb = "parse"
    public let function = "Parse a Changelog"
    
    public struct Options: OptionsType {
        public let file: String
        public let outfile: String
        
        public static func create(file: String)
            -> (outfile: String)
            -> Options {
                return { outfile in
                    return self.init(file: file,
                                     outfile: outfile)
                    }
        }
        
        public static func evaluate(m: CommandMode) -> Result<Options, CommandantError<ChangelogParserError>> {
            
            return create
                <*> m <| Option(key: "file",
                                defaultValue: "CHANGELOG", usage: "the absolute path of the CHANGELOG file parse")
                <*> m <| Option(key: "outfile",
                                defaultValue: "CHANGELOG-RELEASENOTES.md", usage: "the out release notes file to build")
        }
    }
    
    public func run(options: Options) -> Result<(), ChangelogParserError> {
        
        guard let file:String = options.file,
            let outfile:String  = options.outfile
            else {
                return .Failure(.InvalidArgument(description: "Missing values: file, outfile"))
        }
        
        //let runLoop = CFRunLoopGetCurrent()
        
        // TODO
        print(file)
        print(outfile)
        
        CFRunLoopRun()
        return .Success(())
    }
}
