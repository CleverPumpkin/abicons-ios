Tool for adding badge with version number to application icons.

## Installation

Just add `pod 'ABIcons'` to your Podfile and install/update your pods.

## How to use

Add new build phase to your main target of your project before compile sources. This build phase will generate new app icons with (or without) version number badge.

The ABIcons binary will be available via `${ABICONS_PATH}`. Provide Info.plist file path via `-infoPlistPath` and app icon path via `-appIconsPath` parameters to ABIcons binary. Also use `-overrideShowVersion 1` to draw badge on icon (and 0 otherwise).

Example script:

```"${ABICONS_PATH}" -infoPlistPath "${SRCROOT}/${TARGET_NAME}/Info.plist" -appIconsPath "${SRCROOT}/${TARGET_NAME}/Resources/Assets.xcassets/AppIcon.appiconset" -overrideShowVersion 1```

Full list of options available via `-help` parameter.

ABIcons will generate `png-orig` (e.g. icon_20pt.png-orig) icon files. Store them in your CVS system for comfortable use and add your previous icons to .gitignore file (via adding line `Path/to/your/AppIcon/appiconset/*.png`) to avoid unnecessary conflicts when generating images.

## Credits

ABIcons is owned and maintained by the [CleverPumpkin, Ltd](https://cleverpumpkin.ru/)

CleverPumpkin, company@cleverpumpkin.ru

## License

ABIcons is available under the MIT license. See the [LICENSE](https://github.com/CleverPumpkin/abicons-ios/blob/master/LICENSE) for more info.
