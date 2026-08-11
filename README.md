# CruiserParts iOS

Native SwiftUI mobile storefront for CruiserParts. It uses the LAN CruiserParts adapter at `http://192.168.0.172:8787` by default, including live search, cached images, saved build list, recommendations, and in-app product detail pages.

## Build on macOS

```bash
brew install xcodegen
xcodegen generate
xcodebuild -project CruiserParts.xcodeproj -scheme CruiserParts -sdk iphonesimulator -configuration Debug CODE_SIGNING_ALLOWED=NO build
```

Change the API base URL in `CruiserParts/Services/CatalogClient.swift` if the adapter is hosted elsewhere on your LAN.
