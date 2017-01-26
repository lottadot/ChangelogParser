//
//  Version.swift
//  changelogparser
//
//  Created by Shane Zatezalo on 8/21/16.
//  Copyright © 2016 Lottadot LLC. All rights reserved.
//

import Foundation

import Foundation
import Swift
import ChangelogKit
import Result
import Commandant

private let version = "0.1.3" // FIXME. See TODO below.

/// Provide the Version of ChangelogParser
public struct VersionCommand: CommandProtocol {
    public let verb = "version"
    public let function = "Display the current version of ChangelogParser"
    
    public func run(_ options: NoOptions<ChangelogParserError>) -> Result<(), ChangelogParserError> {
        print(version) // TODO. How to get a bundle for an app where you're running the app's executable w/o the app?
        return .success(())
    }
}

