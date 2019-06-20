//
//  URL+CPFoundation.swift
//  CPFoundation
//
//  Created by Kirill byss Bystrov on 2/20/17.
//  Copyright © 2017 Cleverpumpkin, Ltd. All rights reserved.
//

import Foundation

extension URL {
	public struct URLFlags: OptionSet {
		public let rawValue: UInt;
		
		public static let isReadable = URLFlags (rawValue: 1 << 0);
		public static let isWriteable = URLFlags (rawValue: 1 << 1);
		public static let isExecutable = URLFlags (rawValue: 1 << 2);
		
		public static let isRegularFile = URLFlags (rawValue: 1 << 3);
		public static let isDirectory = URLFlags (rawValue: 2 << 3);
		public static let isSymlink = URLFlags (rawValue: 3 << 3);
		private static let resourceTypeMask = URLFlags (rawValue: 3 << 3);
		
		public static let isReadableFile: URLFlags = [.isReadable, .isRegularFile];
		public static let isReadableDirectory: URLFlags = [.isReadable, .isDirectory];
		public static let isWriteableFile: URLFlags = [.isWriteable, .isRegularFile];
		public static let isWriteableDirectory: URLFlags = [.isWriteable, .isDirectory];
		public static let isExecutableFile: URLFlags = [.isReadable, .isExecutable, .isRegularFile];
		
		public init (rawValue: UInt) {
			self.rawValue = rawValue;
		}
		
		fileprivate var resourceKeys: Set <URLResourceKey> {
			let supportedResourceKeys: [URLResourceKey] = [
				.isReadableKey, .isWritableKey, .isExecutableKey,
				.isRegularFileKey, .isDirectoryKey, .isAliasFileKey,
			];
			let requestedKeys: [Bool] = [
				self.contains (.isReadable), self.contains (.isWriteable), self.contains (.isExecutable),
				(self.intersection (.resourceTypeMask) == .isRegularFile),
				(self.intersection (.resourceTypeMask) == .isDirectory),
				(self.intersection (.resourceTypeMask) == .isSymlink),
			];
			
			return Set (zip (supportedResourceKeys, requestedKeys).compactMap { $1 ? $0 : nil });
		};
	};
	
	public func checkResourceReachableAndHasValues (forKeys keys: Set <URLResourceKey>) -> Bool {
		guard self.isFileURL,
		      let isReachable = try? self.checkResourceIsReachable (),
		      isReachable,
		      let values = try? self.resourceValues (forKeys: keys) else {
			return false;
		}
		
		return !values.allValues.compactMap { keys.contains ($0) ? $1 as? Bool : nil }.contains (false);
	}
	
	public func checkResourceReachable (andHasFlags flags: URLFlags) -> Bool {
		return self.checkResourceReachableAndHasValues (forKeys: flags.resourceKeys);
	}
	
	public var isLocalReadableFile: Bool {
		return self.checkResourceReachable (andHasFlags: .isReadableFile);
	}

	public var isLocalReadableDirectory: Bool {
		return self.checkResourceReachable (andHasFlags: .isReadableDirectory);
	}
	
	public var isLocalWriteableFile: Bool {
		return self.checkResourceReachable (andHasFlags: .isWriteableFile);
	}
	
	public var isLocalWriteableDirectory: Bool {
		return self.checkResourceReachable (andHasFlags: .isWriteableDirectory);
	}

	public var isLocalExecutableFile: Bool {
		return self.checkResourceReachable (andHasFlags: .isExecutableFile);
	}
}

public extension URL {
	enum SearchFlags {
		case none;
		case createDirectoriesIfNeeded;
		case createDirectoriesAndFilesIfNeeded;
	};
	
	static var temporaryDirectory: URL {
		return FileManager.default.temporaryDirectory;
	}
	
	init? <SD, FN, EXT> (userDirectory: FileManager.SearchPathDirectory, subdirectories: SD? = nil, filename: FN? = nil, extension: EXT? = nil, flags: SearchFlags = .none) where SD: Sequence, SD.Element: StringProtocol, FN: StringProtocol, EXT: StringProtocol {
		let fileMgr = FileManager.default;
		
		guard let result = try? fileMgr.url (for: userDirectory, in: .userDomainMask, appropriateFor: nil, create: false) else {
			return nil;
		}
		self = result;
		
		if let subdirectories = subdirectories {
			subdirectories.forEach {
				self.appendPathComponent (String ($0), isDirectory: true);
			};
		}
		let dirname = self;
		
		if let filename = filename {
			self.appendPathComponent (String (filename));
		}
		if let `extension` = `extension` {
			self.appendPathExtension (String (`extension`));
		}
		
		if (flags != .none) {
			do {
			 try fileMgr.createDirectory (at: dirname, withIntermediateDirectories: true, attributes: nil);
				if ((flags == .createDirectoriesAndFilesIfNeeded) && !self.isLocalReadableFile) {
					try Data ().write (to: self);
				}
			} catch {
				return nil;
			}
		}
	}
}
