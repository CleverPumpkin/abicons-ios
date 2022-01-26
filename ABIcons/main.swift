//
//  main.swift
//  ABIcons
//
//  Created by Kirill byss Bystrov on 2/19/17.
//  Copyright © 2017 Cleverpumpkin, Ltd. All rights reserved.
//

/*
"${ABICONS_PATH}" \
-infoPlistPath "${INFOPLIST_FILE}" \
-appIconsPath "${SRCROOT}/Resources/Images.xcassets/${ASSETCATALOG_COMPILER_APPICON_NAME}.appiconset" \
-overrideShowVersion "${CP_USE_ABICONS}"
 */

import Foundation

fileprivate func printHelp () {
	print ("Available options:");
	printOptions (ABOptions.self);
}

fileprivate func printOptions (_ options: ABOptionsProtocol.Type, indentationLevel: Int = 0) {
	let indentation = repeatElement ("  ", count: indentationLevel).reduce ("", +);
	for option in options.options {
		print ("\(indentation)-\(option.defaultsKey): \(option.localizedName)");
		print ("\(indentation)  \(option.localizedDescription)");
	}
	if (!options.groups.isEmpty) {
		for group in options.groups {
			print ();
			print ("\(indentation)\(group.groupName):");
			printOptions (group, indentationLevel: indentationLevel + 1);
		}
	}
}

if (ProcessInfo.processInfo.arguments.contains ("-help")) {
	printHelp ();
	exit (0);
}

fileprivate let filesMgr = ABFilesManager.shared;
fileprivate let version: String?;
fileprivate let icons: [ABIcon];
do {
	version = try filesMgr.appVersion ();
	icons = try filesMgr.icons ();
	for icon in icons {
		if let version = version {
			try icon.drawVersionNumber (version);
		} else {
			try icon.keepOriginal ();
		}
	}
} catch {
	print ("fatal error:", error.localizedDescription);
	print ("Usage: \(ProcessInfo.processInfo.arguments.first!) [OPTIONS]");
	print ("For a complete list of options use `-help'.");
	
	exit (132);
}
