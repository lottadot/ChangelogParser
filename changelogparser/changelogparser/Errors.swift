//
//  Errors.swift
//  changelogparser
//
//  Created by Shane Zatezalo on 8/21/16.
//  Copyright © 2016 Lottadot LLC. All rights reserved.
//

import Foundation

/// Possible errors that can originate from ChnangelogParser.
public enum ChangelogParserError: Error, Equatable {
    
    /// One or more arguments was invalid.
    case invalidArgument(description: String)
    
    /// Parse Failed
    case parseFailed(description: String)
    
    /// Output File Write Failed
    case fileWriteFailed(description: String)
    
    /// Build is TBD Failed
    case buildIsTBD(description: String)
    
    case buildHasNoTicketsNorComments(description: String)
}

public func == (lhs: ChangelogParserError, rhs: ChangelogParserError) -> Bool {
    switch (lhs, rhs) {
    case let (.invalidArgument(left), .invalidArgument(right)):
        return left == right
        
    default:
        return false
    }
}

extension ChangelogParserError: CustomStringConvertible {
    public var description: String {
        switch self {
        case let .invalidArgument(description):
            return description
            
        case let .parseFailed(description):
            return description
            
        case let .buildIsTBD(description):
            return description
            
        case let .fileWriteFailed(description):
            return description
            
        case let .buildHasNoTicketsNorComments(description):
            return description
        }
    }
}
