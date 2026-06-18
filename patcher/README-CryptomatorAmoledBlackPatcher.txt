Cryptomator AMOLED Black Theme Patcher - OSS source edition

Files:
- CryptomatorAmoledBlackPatcher.exe : single-file executable patcher
- CryptomatorAmoledBlackPatcher.ps1 : readable PowerShell source
- README-CryptomatorAmoledBlackPatcher.txt : this file

What this version changes in an OSS source tree:
- Replaces both dark_theme.css and light_theme.css with an AMOLED black palette.
- Adds JavaFX CSS for the custom black title bar and black tray popup menu.
- Sets Settings.DEFAULT_THEME to UiTheme.DARK.
- Replaces the native Windows white title bar with an undecorated JavaFX title bar.
- Replaces the AWT native white tray menu popup with a JavaFX ContextMenu.
- Creates .amoled-backup files before editing.

Usage for the provided cryptomator-develop source:
CryptomatorAmoledBlackPatcher.exe -Target "C:\path\to\cryptomator-develop"

Installed Cryptomator note:
- The installed app can still have its CSS patched, but the title bar and tray menu require source changes and rebuilding Cryptomator.
- For the full fix requested here, apply this to the OSS source tree, then build the Windows app from that patched source.

Restore:
- Replace each patched file with its matching .amoled-backup file.
