//
//  ci_pre_xcodebuild.swift
//  blueprints
//
//  Created by serac on 9/22/25.
//

#!/bin/sh

if [ "$CI_WORKFLOW_ID" = "your-workflow-id" ]; then
    xcodebuild -downloadComponent metalToolchain -exportPath /tmp/MyMetalExport/
    sed -i '' -e 's/17A5241c/17A5241e/g' /tmp/MyMetalExport/MetalToolchain-17A5241c.exportedBundle/ExportMetadata.plist
    xcodebuild -importComponent metalToolchain -importPath /tmp/MyMetalExport/MetalToolchain-17A5241c.exportedBundle
fi
