# Install TameWheel

[简体中文](install.md) | **English**

Requires macOS 13 or later. The universal package includes Apple Silicon and Intel binaries. Tested on Apple Silicon / macOS 27; Intel and earlier macOS versions still need hardware testing.

## Download and install

1. Open the [GitHub Release](https://github.com/gitman-g1/TameWheel/releases/latest) and download **TameWheel-0.3.1-universal.dmg** from Assets.
2. Open the DMG and drag **TameWheel.app** into **Applications**.
3. Eject the disk image and open TameWheel from Applications. It lives in the menu bar and has no Dock icon.

Alternatively, download **TameWheel-0.3.1-universal.zip**, unzip it, and move the app into Applications. GitHub's automatic `Source code` archives are not installable apps.

## First launch

**This public testing build is ad-hoc signed and has not been notarized by Apple.** macOS may show a developer verification warning on first launch.

If macOS cannot verify the developer or check the app for malicious software, confirm that you obtained the package from the official Release above. After attempting to open the app, go to System Settings → Privacy & Security, choose **Open Anyway** for TameWheel, and confirm. This is Apple's per-app exception process. [Apple's instructions](https://support.apple.com/102445)

If macOS reports that the file is damaged, download it again and compare its checksum with `SHA256SUMS.txt` from the same Release. If it still cannot open, report your macOS version and the exact message in [Issues](https://github.com/gitman-g1/TameWheel/issues).

## Allow mouse-wheel control

1. Click the mouse icon in the menu bar and turn on the switch.
2. Allow TameWheel in System Settings → Privacy & Security → Accessibility. If you need to add it manually, select **TameWheel.app** in Applications.
3. Return to the menu bar. Once the switch is on, TameWheel is ready.

Leave macOS Natural Scrolling enabled for familiar Windows-style mouse-wheel direction while retaining your trackpad's feel. Turning the switch off or quitting restores system scrolling.

TameWheel handles standard, discrete vertical mouse wheels. Magic Mouse, high-resolution continuous wheels, and events modified by other drivers may pass through unchanged. Avoid running other tools that also change wheel direction or speed at the same time.

## Update or uninstall

Before updating, right-click the menu bar icon and choose **退出小滚轮** (Quit TameWheel), then replace the app in Applications. An ad-hoc signature changes between builds; if permission is enabled but the app still requests it, remove the old Accessibility entry and add the current **TameWheel.app** again.

To uninstall, quit the app, move it to Trash, and remove its Accessibility permission. TameWheel does not change system mouse or trackpad scrolling settings.
