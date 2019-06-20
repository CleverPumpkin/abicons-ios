//
//  String+variablesExpansion.swift
//  ABIcons
//
//  Created by Kirill byss Bystrov on 2/19/17.
//  Copyright © 2017 Cleverpumpkin, Ltd. All rights reserved.
//

import Foundation

fileprivate class CPEnvironmentExpander: NSRegularExpression {
	fileprivate static let shared = CPEnvironmentExpander ();
	
	private init () {
		try! super.init (pattern: "\\$[{(]?((?<=\\$)[a-z_][a-z0-9_]*()|(?<=\\{)[a-z_][a-z0-9_]*(?=(\\}))|(?<=\\()[a-z_][a-z0-9_]*(?=(\\))))(?:\\2|\\3|\\4)", options: [.caseInsensitive]);
	}
	
	required fileprivate init? (coder aDecoder: NSCoder) {
		super.init (coder: aDecoder);
	}
	
	fileprivate override func replacementString (for result: NSTextCheckingResult, in string: String, offset: Int, template templ: String) -> String {
		guard result.numberOfRanges > 1, let variableNameRange = Range (result.adjustingRanges (offset: offset).range (at: 1), in: string) else {
			return templ;
		}
		
		return (ProcessInfo.processInfo.environment [String (string [variableNameRange])] ?? "");
	}
}

extension String {
	private static let maxDepth = 100;
	
	public var expandingShellVariables: String {
		let string = NSMutableString (string: self);
		
		for _ in 0 ..< String.maxDepth {
			if (CPEnvironmentExpander.shared.replaceMatches (in: string, options: [], range: NSRange (0 ..< string.length), withTemplate: "") == 0) {
				return (string as String);
			}
		}
		
		fatalError ("Too many indirection levels while expanding environment variables.");
	}
}
