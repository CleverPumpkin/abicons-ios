//
//  ABFilesManager.swift
//  ABIcons
//
//  Created by Kirill byss Bystrov on 2/19/17.
//  Copyright © 2017 Cleverpumpkin, Ltd. All rights reserved.
//

import Foundation

// MARK: Public Interface

public class ABFilesManager {
	fileprivate struct FilesError {
		private enum _FilesError: LocalizedError {
			case unknown;
			case requiredOptionMissing (String);
			case requiredOptionInvalid (String, String);
			case cannotReadFile (String);
			case optionDeprecated (String, String);
			
			public var errorDescription: String? {
				switch (self) {
					case .unknown:
						return "Unknown error.";
						
					case let .requiredOptionMissing (option):
						return "Required option `-\(option)' was not set.";
						
					case let .requiredOptionInvalid (option, value):
						return "Required option `-\(option)' has invalid value `\(value)'.";
						
					case let .cannotReadFile (errorInfo):
						return "Cannot open or read \(errorInfo).";
					
					case let .optionDeprecated (option, newOption):
						return "`-\(option)' is deprecated, please use `-\(newOption)'."
				}
			}
		}
		
		fileprivate static let unknown: Error = _FilesError.unknown;
		
		fileprivate static func requiredOptionMissing <ValueType> (_ option: ABOption <ValueType>) -> Error {
			let defaultsKey = option.defaultsKey;
			switch (option.value) {
				case let value as String where value.isEmpty: fallthrough;
				case nil:
					return _FilesError.requiredOptionMissing (defaultsKey);
				
				default:
					return _FilesError.requiredOptionInvalid (defaultsKey, "\(option.value)");
			}
		}
		
		fileprivate static func cannotReadFile (_ filename: String, reason: String? = nil) -> Error {
			guard let reason = reason else {
				return _FilesError.cannotReadFile (filename);
			}
			
			return _FilesError.cannotReadFile ("\(filename): \(reason)");
		}
		
		fileprivate static func optionDeprectated <ValueType1, ValueType2> (_ option: ABOption <ValueType1>, inFavorOf newOption: ABOption <ValueType2>) -> Error {
			return _FilesError.optionDeprecated (option.defaultsKey, newOption.defaultsKey);
		}
	};
	
	fileprivate enum VersionInfo {
		case disabled;
		case error (Error);
		case enabled (String);
	};
	
	public static let shared: ABFilesManager = {
		switch (ABOptions.mode.value) {
			case .ios:
				return ABiOSFilesManager ();
			case .android:
				return ABAndroidFilesManager ();
		}
	} ();
	
	fileprivate init () {}
	
	public func appVersion () throws -> String? {
		switch (self.appVersionInfo) {
			case .none,
			     .some (.disabled):
				return nil;
			
			case .some (.error (let error)):
				throw error;
			
			case .some (.enabled (let version)):
				return version;
		}		
	}
	
	fileprivate var appVersionInfo: VersionInfo? {
		if let overrideVersion = ABOptions.Versioning.overrideShowVersion.value,
		   !overrideVersion {
			return .disabled;
		}
		
		return nil;
	};
	
	public func icons () throws -> [ABIcon] {
		fatalError ("Not implemented");
	}
}

// MARK: iOS-specific Icon Handling

private class ABiOSFilesManager: ABFilesManager {
	private enum Result {
		case success ([String: Any]);
		case error (Error);
	}
	
	private static let infoPlistResult = { () -> Result in
		let infoPlistPath = ABOptions.Versioning.iOS.infoPlistPath.value.expandingShellVariables;
		guard !infoPlistPath.isEmpty else {
			return .error (FilesError.requiredOptionMissing (ABOptions.Versioning.iOS.infoPlistPath));
		}
		let infoPlistURL = URL (fileURLWithPath: infoPlistPath);
		guard let infoPlist = NSDictionary (contentsOf: infoPlistURL) as? [String: Any] else {
			return .error (FilesError.cannotReadFile ("Info.plist"));
		}
		
		return .success (infoPlist);
	} ();
	private func infoPlist () throws -> [String: Any] {
		switch (ABiOSFilesManager.infoPlistResult) {
			case .success (let infoPlist):
				return infoPlist;
			case .error (let error):
				throw error;
		}
	}
	
	fileprivate override var appVersionInfo: VersionInfo {
		if let result = super.appVersionInfo {
			return result;
		}
		
		let infoPlist: [String: Any];
		do {
			infoPlist = try self.infoPlist ();
		} catch {
			return VersionInfo.error (error);
		}
		let versionKey = (ABOptions.Versioning.iOS.useShortVersion.value ? "CFBundleShortVersionString" : "CFBundleVersion");
		guard let version = (infoPlist [versionKey] as? String)?.expandingShellVariables,
		      !version.isEmpty else {
			return VersionInfo.error (FilesError.cannotReadFile ("Info.plist", reason: "\(versionKey) is missing"));
		}
		switch (ABOptions.Versioning.overrideShowVersion.value) {
			case .some (false):
				return VersionInfo.disabled;
			case .some (true):
				return VersionInfo.enabled (version);
			case .none:
				break;
		}
		
		let devBundleRE: NSRegularExpression;
		do {
			let devBundlePattern = ABOptions.Versioning.iOS.devBundleRegexp.value;
			guard !devBundlePattern.isEmpty else {
				return VersionInfo.error (FilesError.requiredOptionMissing (ABOptions.Versioning.iOS.devBundleRegexp));
			}
			devBundleRE = try NSRegularExpression (pattern: devBundlePattern);
		} catch {
			return VersionInfo.error (error);
		}
		guard let bundleID = (infoPlist [kCFBundleIdentifierKey as String] as? String)?.expandingShellVariables,
		      !bundleID.isEmpty else {
			return VersionInfo.error (FilesError.cannotReadFile ("Info.plist", reason: "\(kCFBundleIdentifierKey!) is missing"));
		}
		if (devBundleRE.rangeOfFirstMatch (in: bundleID, options: [], range: NSRange (0 ..< bundleID.utf16.count)).location != NSNotFound) {
			return VersionInfo.enabled (version);
		} else {
			return VersionInfo.disabled;
		}
	}
	
	fileprivate override func icons () throws -> [ABIcon] {
		let appIconsURL = URL (fileURLWithPath: ABOptions.Paths.iOS.appIconsPath.value.expandingShellVariables);
		guard appIconsURL.isLocalWriteableDirectory else {
			throw FilesError.requiredOptionMissing (ABOptions.Paths.iOS.appIconsPath);
		}
		
		let filenames: [String];
		let infoPlist = try self.infoPlist ();
		switch (infoPlist ["CFBundleIconFiles"]) {
			case let iconsArray as [String]:
				filenames = iconsArray;
			
			default:
				let contentsJsonData = try Data (contentsOf: appIconsURL.appendingPathComponent ("Contents.json"));
				let contentsObject = try JSONSerialization.jsonObject (with: contentsJsonData, options: []);
				guard let contentsDict = contentsObject as? [String: Any] else {
					throw FilesError.cannotReadFile ("Contents.json", reason: "unexpected top-level object (non-dict)");
				}
				guard let imagesArray = contentsDict ["images"] as? [[String: String]] else {
					throw FilesError.cannotReadFile ("Contents.json", reason: "images array is not found");
				}
				filenames = imagesArray.compactMap { $0 ["filename"] };
		}

		return filenames.compactMap { ABIcon (fileURL: appIconsURL.appendingPathComponent ($0)); };
	}
}

// MARK: Android-specific Icon Handling

private class ABAndroidFilesManager: ABFilesManager {
	fileprivate override var appVersionInfo: VersionInfo {
		if let result = super.appVersionInfo {
			return result;
		}
		
		guard (ABOptions.Versioning.Android.needVersionInfo.value == nil) else {
			return VersionInfo.error (FilesError.optionDeprectated (ABOptions.Versioning.Android.needVersionInfo, inFavorOf: ABOptions.Versioning.overrideShowVersion));
		}
		guard let showVersion = ABOptions.Versioning.overrideShowVersion.value else {
			return VersionInfo.error (FilesError.requiredOptionMissing (ABOptions.Versioning.overrideShowVersion));
		}
		guard let version = ABOptions.Versioning.Android.applicationVersion.value?.expandingShellVariables,
		      !version.isEmpty else {
			return VersionInfo.error (FilesError.requiredOptionMissing (ABOptions.Versioning.Android.applicationVersion));
		}
		guard showVersion else {
			return VersionInfo.disabled;
		}
		
		return VersionInfo.enabled (version);
	}
	
	fileprivate override func icons () throws -> [ABIcon] {
		let resourcesURL = URL (fileURLWithPath: ABOptions.Paths.Android.resourcesPath.value.expandingShellVariables);
		let contents: [URL] = try FileManager.default.contentsOfDirectory (at: resourcesURL, includingPropertiesForKeys: nil);

		let iconDirectoryPrefix = ABOptions.Paths.Android.iconDirectoryPrefix.value.expandingShellVariables;
		let iconDirectories = contents.filter { $0.lastPathComponent.hasPrefix (iconDirectoryPrefix) && $0.isLocalWriteableDirectory };
		
		let iconFilename = ABOptions.Paths.Android.iconFilename.value.expandingShellVariables;
		return iconDirectories.map { ABIcon (fileURL: $0.appendingPathComponent (iconFilename)) };
	}
}
