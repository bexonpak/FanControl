import Foundation

enum Command: String {
    case setMode = "set-mode"
    case setSpeed = "set-speed"
    case reset
}

func printHelp() {
    print("""
    smc-helper - Privileged SMC fan control helper
    Usage:
      smc-helper set-mode <fanId> <0|1>     (0=automatic, 1=forced)
      smc-helper set-speed <fanId> <rpm>
      smc-helper reset
    """)
}

func setMode(fanId: Int, mode: Int) {
    let smc = SMC()
    let fanMode: FanMode = mode == 0 ? .automatic : .forced
    if smc.setFanMode(fanId, mode: fanMode) {
        exit(0)
    } else {
        print("ERROR: Failed to set fan \(fanId) mode to \(fanMode)")
        exit(1)
    }
}

func setSpeed(fanId: Int, speed: Int) {
    let smc = SMC()
    if smc.setFanSpeed(fanId, speed: speed) {
        exit(0)
    } else {
        print("ERROR: Failed to set fan \(fanId) speed to \(speed)")
        exit(1)
    }
}

func reset() {
    let smc = SMC()
    if smc.resetFanControl() {
        exit(0)
    } else {
        print("ERROR: Failed to reset fan control")
        exit(1)
    }
}

let args = CommandLine.arguments
guard args.count > 1 else {
    printHelp()
    exit(1)
}

guard let command = Command(rawValue: args[1]) else {
    print("ERROR: Unknown command '\(args[1])'")
    printHelp()
    exit(1)
}

switch command {
case .setMode:
    guard args.count >= 4, let fanId = Int(args[2]), let mode = Int(args[3]) else {
        print("ERROR: Usage: smc-helper set-mode <fanId> <0|1>")
        exit(1)
    }
    setMode(fanId: fanId, mode: mode)

case .setSpeed:
    guard args.count >= 4, let fanId = Int(args[2]), let speed = Int(args[3]) else {
        print("ERROR: Usage: smc-helper set-speed <fanId> <rpm>")
        exit(1)
    }
    setSpeed(fanId: fanId, speed: speed)

case .reset:
    reset()
}
