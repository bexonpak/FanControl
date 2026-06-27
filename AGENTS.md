# FanControl macOS App

macOS AppKit app for controlling fan speed via SMC (System Management Controller).

## Architecture

Clean Architecture with MVVM, organized as feature-first vertical slices:

- `Presentation/` — ViewModels and Managers (business logic, state management)
- `UI/` — AppKit views (NSViewController, NSView, NSWindowController subclasses, xibs/storyboards)

Each feature gets its own directory with Presentation and UI subgroups when needed:
```
Features/FanControl/
  Presentation/FanControlViewModel.swift
  Presentation/FanControlManager.swift
  UI/FanControlViewController.swift
  UI/FanControlView.xib
```

## Conventions

- Swift 6 strict concurrency: annotate all ViewModels and Managers with `@MainActor`
- Use `@Published` properties on `@MainActor` classes for bindings
- SMC interactions happen through `SMCService` protocol with `SMC` as the concrete implementation
- All service classes should be injectable via protocols, not singletons

## App Sandbox

App Sandbox is disabled (`ENABLE_APP_SANDBOX = NO`) because SMC IOKit access is incompatible with the sandbox. Do not re-enable it.

The app runs as an LSUIElement (menu bar only, no dock icon).

## Build & Test

Build: Cmd+B or `xcodebuild -project FanControl.xcodeproj -scheme FanControl build`
Test: Cmd+U or `xcodebuild -project FanControl.xcodeproj -scheme FanControl test`
