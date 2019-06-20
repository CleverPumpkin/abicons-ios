//
//  ABOption.swift
//  ABIcons
//
//  Created by Kirill byss Bystrov on 2/19/17.
//  Copyright © 2017 Cleverpumpkin, Ltd. All rights reserved.
//

import AppKit

// MARK: Public interface

public enum ABMode: String {
	case ios = "ios";
	case android = "android";
}

public protocol ABOptionProtocol {
	var defaultsKey: String { get }
	var localizedName: String { get }
	var localizedDescription: String { get }
}

public struct ABOption <ValueType>: ABOptionProtocol {
	public let defaultsKey: String;
	public let localizedName: String;
	public let localizedDescription: String;
	public let value: ValueType;
	
	private init () {
		fatalError ("ABOption.init () should not be called");
	}
}

// MARK: Supported options

public protocol ABOptionsProtocol {
	static var groupName: String { get }
	static var options: [ABOptionProtocol] { get }
	static var groups: [ABOptionsProtocol.Type] { get }
}

extension ABOptionsProtocol {
	public static var options: [ABOptionProtocol] { return [] }
	public static var groups: [ABOptionsProtocol.Type] { return [] }
}

public struct ABOptions: ABOptionsProtocol {
	public static let groupName = "";
	public static let options: [ABOptionProtocol] = [mode];
	public static let groups: [ABOptionsProtocol.Type] = [Versioning.self, Paths.self, Drawing.self];
	
	public static let mode = ABOption (ABOptionsInfo.mode);
	
	public struct Versioning: ABOptionsProtocol {
		public static let groupName = "Versioning Options";
		public static let options: [ABOptionProtocol] = [overrideShowVersion];
		public static let groups: [ABOptionsProtocol.Type] = [iOS.self, Android.self];
		
		public static let overrideShowVersion = ABOption (ABOptionsInfo.overrideShowVersion);
		
		public struct iOS: ABOptionsProtocol {
			public static let groupName = "iOS";
			public static let options: [ABOptionProtocol] = [infoPlistPath, devBundleRegexp, useShortVersion];
			
			public static let infoPlistPath = ABOption (ABOptionsInfo.infoPlistPath);
			public static let devBundleRegexp = ABOption (ABOptionsInfo.devBundleRegexp);
			public static let useShortVersion = ABOption (ABOptionsInfo.useShortVersion);
		};
		
		public struct Android: ABOptionsProtocol {
			public static let groupName = "Android";
			public static let options: [ABOptionProtocol] = [applicationVersion, needVersionInfo];
			
			public static let applicationVersion = ABOption (ABOptionsInfo.applicationVersion);
			public static let needVersionInfo = ABOption (ABOptionsInfo.needVersionInfo);
		};
	};
	
	public struct Paths: ABOptionsProtocol {
		public static let groupName = "Icon Search Options";
		public static let groups: [ABOptionsProtocol.Type] = [iOS.self, Android.self];
		
		public struct iOS: ABOptionsProtocol {
			public static let groupName = "iOS";
			public static let options: [ABOptionProtocol] = [infoPlistPath, appIconsPath];
			
			public static let infoPlistPath = ABOption (ABOptionsInfo.infoPlistPath);
			public static let appIconsPath = ABOption (ABOptionsInfo.appIconsPath);
		};
		
		public struct Android: ABOptionsProtocol {
			public static let groupName = "Android";
			public static let options: [ABOptionProtocol] = [resourcesPath, iconDirectoryPrefix, iconFilename];
			
			public static let resourcesPath = ABOption (ABOptionsInfo.resourcesPath);
			public static let iconDirectoryPrefix = ABOption (ABOptionsInfo.iconDirectoryPrefix);
			public static let iconFilename = ABOption (ABOptionsInfo.iconFilename);
		};
	};
	
	public struct Drawing: ABOptionsProtocol {
		public static let groupName = "Icon Processing Options";
		public static let options: [ABOptionProtocol] = [originalIconSuffix, originalIconPrefix, versionBackgroundColor, versionTextColor];
		
		public static let originalIconSuffix = ABOption (ABOptionsInfo.originalIconSuffix);
		public static let originalIconPrefix = ABOption (ABOptionsInfo.originalIconPrefix);
		public static let versionBackgroundColor = ABOption (ABOptionsInfo.versionBackgroundColor);
		public static let versionTextColor = ABOption (ABOptionsInfo.versionTextColor);
	};
}

// MARK: Private option initializer

fileprivate extension ABOption {
	init (_ info: ABOptionInfo <ValueType>) {
		self.defaultsKey = info.defaultsKey;
		self.localizedName = info.localizedName;
		self.localizedDescription = info.localizedDescription;
		if let value = info.valueGetter (info.defaultsKey) {
			self.value = value;
		} else {
			if (UserDefaults.standard.object (forKey: defaultsKey) != nil) {
				print ("warning: Cannot parse value for option -\(defaultsKey), using default one.");
			}
			self.value = info.defaultValue;
		}
	}
}

// MARK: Reading option values from UserDefaults

fileprivate struct ABOptionsInfo {
	static func readBoolean (defaultsKey: String) -> Bool? {
		guard UserDefaults.standard.object (forKey: defaultsKey) != nil else {
			return nil;
		}
		
		return UserDefaults.standard.bool (forKey: defaultsKey);
	}
	
	static func readString (defaultsKey: String) -> String? {
		guard let string = UserDefaults.standard.string (forKey: defaultsKey) else {
			return nil;
		}
		
		return string;
	}
	
	static func readMode (defaultsKey: String) -> ABMode? {
		guard let string = UserDefaults.standard.string (forKey: defaultsKey),
		      let mode = ABMode (rawValue: string) else {
			return nil;
		}
		
		return mode;
	}
	
	static func readColor (defaultsKey: String) -> NSColor? {
		guard let string = UserDefaults.standard.string (forKey: defaultsKey),
		      let color = NSColor (string: string) else {
			return nil;
		}
		
		return color;
	}
}

fileprivate extension NSColor {
	private static func isLengthValid (colorString string: String) -> Bool {
		switch (string.utf16.count) {
			case 6, 8:
				return true;
			default:
				return false;
		}
	}
	
	convenience init? (string: String) {
		guard NSColor.isLengthValid (colorString: string),
		      let hexColor = UInt32 (string, radix: 0x10) else {
				return nil;
		}
		
		self.init (srgbRed: CGFloat ((hexColor & 0xFF0000) >> 16) / 255.0, green: CGFloat ((hexColor & 0xFF00) >> 8) / 255.0, blue: CGFloat (hexColor & 0xFF) / 255.0, alpha: 1.0 - CGFloat ((hexColor & 0xFF000000) >> 24) / 255.0);
	}
}

// MARK: Static option data (descriptions etc)

fileprivate struct ABOptionInfo <ValueType> {
	let defaultsKey: String;
	let localizedName: String;
	let localizedDescription: String;
	let valueGetter: (String) -> ValueType?;
	let defaultValue: ValueType;
}

fileprivate extension ABOptionsInfo {
	/* Common */
	static let mode = ABOptionInfo (
		defaultsKey: "mode",
		localizedName: "Processing Mode",
		localizedDescription: "Toggles application work mode between one for iOS apps and one for Android apps. Possible values are, respectively, `ios' (default) and 'android'.",
		valueGetter: ABOptionsInfo.readMode,
		defaultValue: ABMode.ios
	);
	static let originalIconSuffix = ABOptionInfo (
		defaultsKey: "originalIconSuffix",
		localizedName: "Original Icon Suffix",
		localizedDescription: "Original icon images are backed up using this filename suffix (default: `-orig'). Note that suffix is appended the whole filename, including file extension.",
		valueGetter: ABOptionsInfo.readString,
		defaultValue: "-orig"
	);
	static let originalIconPrefix = ABOptionInfo (
		defaultsKey: "originalIconPrefix",
		localizedName: "Original Icon Prefix",
		localizedDescription: "Original icon images are backed up using this filename prefix (default: none).",
		valueGetter: ABOptionsInfo.readString,
		defaultValue: ""
	);
	static let versionBackgroundColor = ABOptionInfo (
		defaultsKey: "versionBackgroundColor",
		localizedName: "Version Background Color",
		localizedDescription: "This color is used to draw version info background on processed icon. Default value is `7f7f7f7f' (50% gray with 50% opacity).",
		valueGetter: ABOptionsInfo.readColor,
		defaultValue: NSColor (white: 0.5, alpha: 0.5)
	);
	static let versionTextColor = ABOptionInfo (
		defaultsKey: "versionTextColor",
		localizedName: "Version Foreground Color",
		localizedDescription: "This color is used to draw version number on processed icon. Default value is `ffffff' (100% white with 100% opacity)",
		valueGetter: ABOptionsInfo.readColor,
		defaultValue: .white
	);
	static let overrideShowVersion = ABOptionInfo (
		defaultsKey: "overrideShowVersion",
		localizedName: "Override Version Visibility",
		localizedDescription: "This option allows manual control of version name drawing. Supported values are: `YES' to draw version number, `NO' to disable version number drawing and no value to use default Bundle ID/Package Name logic.",
		valueGetter: ABOptionsInfo.readBoolean,
		defaultValue: nil
	);

	/* iOS */
	static let useShortVersion = ABOptionInfo (
		defaultsKey: "useShortVersion",
		localizedName: "Draw Short Version Name (iOS)",
		localizedDescription: "Use CFBundleShortVersionString instead of CFBundleVersion. Default value is `YES'.",
		valueGetter: ABOptionsInfo.readBoolean,
		defaultValue: true
	);
	static let infoPlistPath = ABOptionInfo (
		defaultsKey: "infoPlistPath",
		localizedName: "Info.plist Path",
		localizedDescription: "Path to project's Info.plist file. Defaults to `${SRCROOT}/${TARGET_NAME}/Supporting Files/Info.plist'.",
		valueGetter: ABOptionsInfo.readString,
		defaultValue: "${SRCROOT}/${TARGET_NAME}/Supporting Files/Info.plist"
	);
	static let devBundleRegexp = ABOptionInfo (
		defaultsKey: "devBundleRegexp",
		localizedName: "Development Bundle ID Regex",
		localizedDescription: "ABIcons uses this regular expression to distinguish development and distribution Bundle IDs; Default value is `\\.debug$'.",
		valueGetter: ABOptionsInfo.readString,
		defaultValue: "\\.debug$"
	);
	static let appIconsPath = ABOptionInfo (
		defaultsKey: "appIconsPath",
		localizedName: "App Icons Path (iOS)",
		localizedDescription: "Location of all app icons (e.g. .appiconset directory if .xcassets is used), `${SRCROOT}/${TARGET_NAME}/Resources/Assets.xcassets/${ASSETCATALOG_COMPILER_APPICON_NAME}.appiconset' by default.",
		valueGetter: ABOptionsInfo.readString,
		defaultValue: "${SRCROOT}/${TARGET_NAME}/Resources/Assets.xcassets/${ASSETCATALOG_COMPILER_APPICON_NAME}.appiconset"
	);
	
	/* Android */
	static let applicationVersion = ABOptionInfo (
		defaultsKey: "applicationVersion",
		localizedName: "App Version (Android)",
		localizedDescription: "ABIcons does not attempt to read any Android projects so one should manually set app version for rendering. No default value.",
		valueGetter: ABOptionsInfo.readString,
		defaultValue: nil
	);
	static let needVersionInfo = ABOptionInfo (
		defaultsKey: "needVersionInfo",
		localizedName: "Override Version Visibility (Deprecated)",
		localizedDescription: "This option is deprecated, please see `-overrideShowVersion'.",
		valueGetter: ABOptionsInfo.readBoolean,
		defaultValue: nil
	);
	static let resourcesPath = ABOptionInfo (
		defaultsKey: "resourcesPath",
		localizedName: "Resources Path (Android)",
		localizedDescription: "Root resources directory, starting point for app icons search. Default value: `./res'.",
		valueGetter: ABOptionsInfo.readString,
		defaultValue: "./res"
	);
	static let iconDirectoryPrefix = ABOptionInfo (
		defaultsKey: "iconDirectoryPrefix",
		localizedName: "Icon Directory Prefix",
		localizedDescription: "Prefixes of subdirectories of resources directory, containing app icons. `mipmap-' by default.",
		valueGetter: ABOptionsInfo.readString,
		defaultValue: "mipmap-"
	);
	static let iconFilename = ABOptionInfo (
		defaultsKey: "iconFilename",
		localizedName: "Icon Filename (Android)",
		localizedDescription: "Basename of launcher icon files, default value is `ic_launcher.png'.",
		valueGetter: ABOptionsInfo.readString,
		defaultValue: "ic_launcher.png"
	);
}
