//
//  main.swift
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

if let jiraUpdaterPath = Bundle.main.executablePath {
    setenv("CHANGELOGPARSERPATH_PATH", jiraUpdaterPath, 0)
}

struct ChangelogParserResult {
    var success = false
    var error: ChangelogParserError? = nil
    var data: Changelog? = nil
}

let registry = CommandRegistry<ChangelogParserError>()
registry.register(VersionCommand())

let helpCommand = HelpCommand(registry: registry)
registry.register(helpCommand)

let parseCommand = ParseCommand()
registry.register(parseCommand)

registry.main(defaultVerb: helpCommand.verb) { error in
    fputs(error.description + "\n", stderr)
}

NSApp.run()
