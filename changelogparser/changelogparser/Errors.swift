//
//  Errors.swift
//  changelogparser
//
//  Created by Shane Zatezalo on 8/21/16.
//  Copyright © 2016 Lottadot LLC. All rights reserved.
//

import Foundation

/// Possible errors that can originate from ChnangelogParser.
public enum ChangelogParserError: ErrorType, Equatable {
    
    /// One or more arguments was invalid.
    case InvalidArgument(description: String)
    
    /// Parse Failed
    case ParseFailed(description: String)
    
    /// Output File Write Failed
    case FileWriteFailed(description: String)
    
    /// Build is TBD Failed
    case BuildIsTBD(description: String)
    
    case BuildHasNoTicketsNorComments(description: String)
}

public func == (lhs: ChangelogParserError, rhs: ChangelogParserError) -> Bool {
    switch (lhs, rhs) {
    case let (.InvalidArgument(left), .InvalidArgument(right)):
        return left == right
        
    default:
        return false
    }
}

extension ChangelogParserError: CustomStringConvertible {
    public var description: String {
        switch self {
        case let .InvalidArgument(description):
            return description
            
        case let .ParseFailed(description):
            return description
            
        case let .BuildIsTBD(description):
            return description
            
        case let .FileWriteFailed(description):
            return description
            
        case let .BuildHasNoTicketsNorComments(description):
            return description
        }
    }
}
