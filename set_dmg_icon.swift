import Cocoa

let arguments = CommandLine.arguments
if arguments.count < 3 {
    print("Usage: swift set_dmg_icon.swift <image_path> <target_file>")
    exit(1)
}

let imagePath = arguments[1]
let targetFile = arguments[2]

guard let image = NSImage(contentsOfFile: imagePath) else {
    print("Could not load image from \(imagePath)")
    exit(1)
}

let success = NSWorkspace.shared.setIcon(image, forFile: targetFile, options: [])
if success {
    print("Successfully set icon for \(targetFile)")
} else {
    print("Failed to set icon for \(targetFile)")
    exit(1)
}
