#!/bin/sh
#  prepare.sh
#  ABIcons
#
#  Created by Alex on 20/06/19.
#  Copyright © 2019 Cleverpumpkin, Ltd. All rights reserved.

pushd "$(dirname -- "$0")" > /dev/null
while ! [ -d 'ABIcons.xcodeproj' ]; do
	if [ "${PWD}" == '/' ]; then
		echo 'ABIcons.xcodeproj cannot be found' >&2
		return 1
	fi

	cd '..'
done

xcodebuild -project ABIcons.xcodeproj -scheme ABIcons -configuration Release -derivedDataPath build build
cp "build/Build/Products/Release/ABIcons" "ABIcons"

popd > /dev/null
