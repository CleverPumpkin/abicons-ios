//
//  ABIcon.swift
//  ABIcons
//
//  Created by Kirill byss Bystrov on 2/19/17.
//  Copyright © 2017 Cleverpumpkin, Ltd. All rights reserved.
//

import AppKit
import CoreText
import Foundation

public struct ABIcon {
	fileprivate enum IconError: LocalizedError {
		case unknown;
		case fileMissing (String);
		case imageError (String);
		
		public var errorDescription: String? {
			switch (self) {
				case .unknown:
					return "Unknown error.";
				
				case .fileMissing (let filename):
					return "File is missing: \(filename).";
				
				case .imageError (let filename):
					return "Cannot read \(filename).";
			}
		}
	}
	
	public let fileURL: URL;
	private let origURL: URL;
	
	public init (fileURL: URL) {
		let directoryURL = fileURL.deletingLastPathComponent ();
		let fileName = fileURL.lastPathComponent;
		let origPrefix = ABOptions.Drawing.originalIconPrefix.value.expandingShellVariables,
		    origSuffix = ABOptions.Drawing.originalIconSuffix.value.expandingShellVariables;
		
		self.fileURL = fileURL;
		self.origURL = directoryURL.appendingPathComponent ("\(origPrefix)\(fileName)\(origSuffix)");
	}
	
	private func prepareFiles () throws {
		if (!self.origURL.isLocalReadableFile) {
			if (!self.fileURL.isLocalWriteableFile) {
				throw IconError.fileMissing (self.fileURL.lastPathComponent);
			}
			
			try FileManager.default.moveItem (at: self.fileURL, to: self.origURL);
		}
	}
	
	private func createOriginalFileIfNeeded () throws {
		if (!self.origURL.isLocalReadableFile) {
			try FileManager.default.copyItem (at: self.fileURL, to: self.origURL);
		}
	}
	
	public func drawVersionNumber (_ version: String) throws {
		try self.createOriginalFileIfNeeded ();
		
		guard let origIcon = NSImage (data: try Data (contentsOf: self.origURL)) else {
			throw IconError.imageError (self.origURL.lastPathComponent);
		}
		
		let iconSize = origIcon.size;
		let ctx = CGContext (data: nil, width: Int (iconSize.width), height: Int (iconSize.height), bitsPerComponent: 8, bytesPerRow: 0, space: CGColorSpaceCreateDeviceRGB (), bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!;
		
		ctx.draw (origIcon.cgImage (forProposedRect: nil, context: nil, hints: nil)!, in: CGRect (origin: .zero, size: iconSize));
		
		let style = NSMutableParagraphStyle ();
		style.alignment = .center;
		let versionString = NSAttributedString (string: version, attributes: [
			NSAttributedString.Key.paragraphStyle: style,
			NSAttributedString.Key.foregroundColor: ABOptions.Drawing.versionTextColor.value,
			NSAttributedString.Key.font: NSFont.systemFont (ofSize: iconSize.height / 6.0),
		]);
		
		let versionSize = versionString.boundingRect (with: NSSize (width: iconSize.width * 0.9, height: iconSize.height * (0.8 - 1.0 / 12)), options: .usesLineFragmentOrigin);
		ctx.setFillColor (ABOptions.Drawing.versionBackgroundColor.value.cgColor);
		ctx.fill (CGRect (x: 0.0, y: (iconSize.height / 10).rounded (), width: iconSize.width, height: versionSize.height + iconSize.height / 12));
		
		NSGraphicsContext.current = NSGraphicsContext (cgContext: ctx, flipped: false);
		versionString.draw (with: NSRect (x: 0.05 * iconSize.width, y: round (iconSize.height / 10 + iconSize.height / 24), width: 0.9 * iconSize.width, height: ceil (versionSize.height)), options: .usesLineFragmentOrigin);
		
		let resultImage = NSBitmapImageRep (cgImage: ctx.makeImage ()!);
		try resultImage.representation (using: .png, properties: [:])!.write (to: self.fileURL);
	}
	
	public func keepOriginal () throws {
		try self.createOriginalFileIfNeeded ();
		
		try? FileManager.default.removeItem (at: self.fileURL);
		try FileManager.default.copyItem (at: self.origURL, to: self.fileURL);
	}
}
