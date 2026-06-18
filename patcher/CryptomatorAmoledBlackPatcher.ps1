param(
	[string] $Target = "",
	[switch] $SetUserTheme,
	[switch] $NoPause
)

$ErrorActionPreference = "Stop"

function Write-Info($message) {
	Write-Host "[AMOLED] $message"
}

function Set-TextUtf8NoBom {
	param(
		[string] $Path,
		[string] $Value
	)
	$encoding = New-Object System.Text.UTF8Encoding($false)
	[System.IO.File]::WriteAllText((Resolve-Path -LiteralPath $Path).Path, $Value, $encoding)
}

function Get-AmoledCss {
	param([string] $OriginalCss)

	$palette = @'
.root {
	PRIMARY_D2: #004018;
	PRIMARY_D1: #007A2D;
	PRIMARY: #00C853;
	PRIMARY_L1: #36E27A;
	PRIMARY_L2: #07140B;

	SECONDARY: #00E5FF;

	GRAY_0: #000000;
	GRAY_1: #030303;
	GRAY_2: #080808;
	GRAY_3: #111111;
	GRAY_4: #222222;
	GRAY_5: #8A8A8A;
	GRAY_6: #A8A8A8;
	GRAY_7: #C8C8C8;
	GRAY_8: #E0E0E0;
	GRAY_9: #F5F5F5;

	GREEN_3: PRIMARY_D1;
	GREEN_5: PRIMARY;
	RED_5: #FF5252;
	ORANGE_5: #FF9800;
	YELLOW_4: #D4B000;
	YELLOW_5: #FFD740;

	MAIN_BG: #000000;
	MUTED_BG: #080808;
	TEXT_FILL: #F5F5F5;
	TEXT_FILL_HIGHLIGHTED: PRIMARY;
	TEXT_FILL_MUTED: #9A9A9A;

	TITLE_BG: #000000;
	TITLE_TEXT_FILL: #00C853;

	CONTROL_BORDER_NORMAL: #1A1A1A;
	CONTROL_BORDER_FOCUSED: #00C853;
	CONTROL_BORDER_DISABLED: #0B0B0B;
	CONTROL_BG_NORMAL: #000000;
	CONTROL_BG_HOVER: #070707;
	CONTROL_BG_ARMED: #101010;
	CONTROL_BG_DISABLED: #030303;
	CONTROL_BG_SELECTED: #0B160F;

	CONTROL_PRIMARY_BORDER_NORMAL: PRIMARY;
	CONTROL_PRIMARY_BORDER_ARMED: PRIMARY_L1;
	CONTROL_PRIMARY_BORDER_FOCUSED: SECONDARY;
	CONTROL_PRIMARY_BG_NORMAL: #003D19;
	CONTROL_PRIMARY_BG_ARMED: #005C25;

	SCROLL_BAR_THUMB_NORMAL: #181818;
	SCROLL_BAR_THUMB_HOVER: #2A2A2A;

	PROGRESS_INDICATOR_BEGIN: #00C853;
	PROGRESS_INDICATOR_END: #007A2D;
	PROGRESS_BAR_BG: #080808;

	-fx-background-color: #000000;
	-fx-text-fill: TEXT_FILL;
	-fx-font-family: 'Open Sans';
}
'@

	$css = [regex]::Replace($OriginalCss, "(?s)\.root\s*\{.*?\n\}", $palette, 1)
	$override = @'

/*******************************************************************************
 * AMOLED Black hard override
 ******************************************************************************/

.root,
.main-window,
.split-pane,
.scroll-pane,
.scroll-pane > .viewport,
.tab-pane,
.tab-pane .tab-header-area,
.tab-pane .tab-header-background,
.dialog-pane,
.notification,
.vault-detail,
.vault-list,
.list-view,
.tree-view,
.table-view,
.text-area,
.text-area .content,
.text-field,
.password-field,
.combo-box,
.choice-box,
.menu-button,
.context-menu,
.menu-item,
.titled-pane,
.accordion,
.progress-bar,
.progress-indicator {
	-fx-background-color: #000000;
}

.content,
.pane,
.anchor-pane,
.border-pane,
.grid-pane,
.hbox,
.vbox,
.flow-pane,
.tile-pane,
.stack-pane {
	-fx-background-color: transparent;
}

.button,
.toggle-button,
.combo-box-base,
.choice-box,
.text-input,
.list-cell,
.tree-cell,
.table-row-cell,
.tab {
	-fx-background-color: #000000;
	-fx-border-color: #1A1A1A;
	-fx-text-fill: #F5F5F5;
}

.button:hover,
.toggle-button:hover,
.combo-box-base:hover,
.choice-box:hover,
.list-cell:hover,
.tree-cell:hover,
.table-row-cell:hover,
.tab:hover {
	-fx-background-color: #070707;
}

.button:armed,
.toggle-button:selected,
.list-cell:selected,
.tree-cell:selected,
.table-row-cell:selected,
.tab:selected {
	-fx-background-color: #0B160F;
	-fx-border-color: #00C853;
}

.label,
.text,
.text-flow > *,
.menu-item .label,
.check-box,
.radio-button {
	-fx-text-fill: #F5F5F5;
	-fx-fill: #F5F5F5;
}

.glyph-icon {
	-fx-fill: #F5F5F5;
}

.separator *.line {
	-fx-border-color: #1A1A1A;
}

.scroll-bar,
.scroll-bar .track,
.scroll-bar .increment-button,
.scroll-bar .decrement-button {
	-fx-background-color: #000000;
}

.scroll-bar .thumb {
	-fx-background-color: #181818;
}

.tooltip {
	-fx-background-color: #050505;
	-fx-text-fill: #F5F5F5;
	-fx-border-color: #1A1A1A;
}

.amoled-title-bar {
	-fx-background-color: #000000;
	-fx-border-color: #1A1A1A;
	-fx-border-width: 0 0 1px 0;
}

.amoled-title-label {
	-fx-padding: 0 0 0 12px;
	-fx-text-fill: #F5F5F5;
	-fx-font-family: 'Open Sans SemiBold';
}

.amoled-window-button,
.amoled-window-close-button {
	-fx-background-color: #000000;
	-fx-background-radius: 0;
	-fx-border-color: transparent;
	-fx-text-fill: #F5F5F5;
	-fx-padding: 0;
}

.amoled-window-button:hover,
.amoled-window-close-button:hover {
	-fx-background-color: #111111;
}

.amoled-window-button:armed,
.amoled-window-close-button:armed {
	-fx-background-color: #1A1A1A;
}

.amoled-window-close-button:hover {
	-fx-background-color: #7A0000;
}

.amoled-window-icon-minimize {
	-fx-background-color: #F5F5F5;
	-fx-min-width: 10px;
	-fx-pref-width: 10px;
	-fx-max-width: 10px;
	-fx-min-height: 1.5px;
	-fx-pref-height: 1.5px;
	-fx-max-height: 1.5px;
}

.amoled-window-icon-maximize {
	-fx-background-color: transparent;
	-fx-border-color: #F5F5F5;
	-fx-border-width: 1.5px;
	-fx-min-width: 10px;
	-fx-pref-width: 10px;
	-fx-max-width: 10px;
	-fx-min-height: 10px;
	-fx-pref-height: 10px;
	-fx-max-height: 10px;
}

.amoled-window-icon-close {
	-fx-background-color: #F5F5F5;
	-fx-shape: "M 0 1 L 1 0 L 5 4 L 9 0 L 10 1 L 6 5 L 10 9 L 9 10 L 5 6 L 1 10 L 0 9 L 4 5 Z";
	-fx-min-width: 10px;
	-fx-pref-width: 10px;
	-fx-max-width: 10px;
	-fx-min-height: 10px;
	-fx-pref-height: 10px;
	-fx-max-height: 10px;
}

.amoled-tray-menu,
.amoled-tray-menu.context-menu {
	-fx-background-color: #000000;
	-fx-border-color: #1A1A1A;
}

.amoled-tray-menu .menu-item,
.amoled-tray-menu .menu {
	-fx-background-color: #000000;
}

.amoled-tray-menu .menu-item:focused {
	-fx-background-color: #0B160F;
}

.amoled-tray-menu .menu-item > .label {
	-fx-text-fill: #F5F5F5;
}
'@

	if ($css -notmatch "AMOLED Black hard override") {
		$css += $override
	}
	if ($css -notmatch "amoled-window-icon-minimize") {
		$css += @'

/* Font-independent window control icons */
.amoled-window-button,
.amoled-window-close-button {
	-fx-padding: 0;
}

.amoled-window-icon-minimize {
	-fx-background-color: #F5F5F5;
	-fx-min-width: 10px;
	-fx-pref-width: 10px;
	-fx-max-width: 10px;
	-fx-min-height: 1.5px;
	-fx-pref-height: 1.5px;
	-fx-max-height: 1.5px;
}

.amoled-window-icon-maximize {
	-fx-background-color: transparent;
	-fx-border-color: #F5F5F5;
	-fx-border-width: 1.5px;
	-fx-min-width: 10px;
	-fx-pref-width: 10px;
	-fx-max-width: 10px;
	-fx-min-height: 10px;
	-fx-pref-height: 10px;
	-fx-max-height: 10px;
}

.amoled-window-icon-close {
	-fx-background-color: #F5F5F5;
	-fx-shape: "M 0 1 L 1 0 L 5 4 L 9 0 L 10 1 L 6 5 L 10 9 L 9 10 L 5 6 L 1 10 L 0 9 L 4 5 Z";
	-fx-min-width: 10px;
	-fx-pref-width: 10px;
	-fx-max-width: 10px;
	-fx-min-height: 10px;
	-fx-pref-height: 10px;
	-fx-max-height: 10px;
}
'@
	}
	return $css
}

function Backup-File {
	param([string] $Path)
	$backup = "$Path.amoled-backup"
	if (-not (Test-Path -LiteralPath $backup)) {
		Copy-Item -LiteralPath $Path -Destination $backup -Force
	}
}

function Patch-CssFile {
	param([string] $Path)
	Backup-File $Path
	$original = Get-Content -LiteralPath $Path -Raw -Encoding UTF8
	$patched = Get-AmoledCss $original
	Set-TextUtf8NoBom $Path $patched
	Write-Info "patched CSS: $Path"
}

function Patch-SourceTree {
	param([string] $Root)
	$cssDir = Join-Path $Root "src\main\resources\css"
	if (-not (Test-Path -LiteralPath $cssDir)) {
		return $false
	}
	Patch-CssFile (Join-Path $cssDir "dark_theme.css")
	Patch-CssFile (Join-Path $cssDir "light_theme.css")

	$settings = Join-Path $Root "src\main\java\org\cryptomator\common\settings\Settings.java"
	if (Test-Path -LiteralPath $settings) {
		Backup-File $settings
		$text = Get-Content -LiteralPath $settings -Raw -Encoding UTF8
		$text = $text -replace "static final UiTheme DEFAULT_THEME = UiTheme\.[A-Z]+;", "static final UiTheme DEFAULT_THEME = UiTheme.DARK;"
		Set-TextUtf8NoBom $settings $text
		Write-Info "default theme set to DARK: $settings"
	}
	Patch-MainWindowChrome $Root
	Patch-JavaFxTrayMenu $Root
	return $true
}

function Patch-MainWindowChrome {
	param([string] $Root)
	$fxml = Join-Path $Root "src\main\resources\fxml\main_window.fxml"
	$module = Join-Path $Root "src\main\java\org\cryptomator\ui\mainwindow\MainWindowModule.java"
	$controller = Join-Path $Root "src\main\java\org\cryptomator\ui\mainwindow\MainWindowController.java"

	if (Test-Path -LiteralPath $fxml) {
		Backup-File $fxml
		$text = Get-Content -LiteralPath $fxml -Raw -Encoding UTF8
		if ($text -notmatch "amoled-title-bar") {
			$text = $text -replace "<\?import javafx.scene.control.SplitPane\?>", "<?import javafx.scene.control.Button?>`r`n<?import javafx.scene.control.Label?>`r`n<?import javafx.scene.control.SplitPane?>"
			$text = $text -replace "<\?import javafx.scene.layout.StackPane\?>", "<?import javafx.scene.layout.HBox?>`r`n<?import javafx.scene.layout.Pane?>`r`n<?import javafx.scene.layout.Priority?>`r`n<?import javafx.scene.layout.Region?>`r`n<?import javafx.scene.layout.StackPane?>"
			$titleBar = @'
		<HBox alignment="CENTER_LEFT" minHeight="34" prefHeight="34" styleClass="amoled-title-bar" onMousePressed="#didPressAmoledTitleBar" onMouseDragged="#didDragAmoledTitleBar">
			<Label text="Cryptomator" styleClass="amoled-title-label"/>
			<Pane HBox.hgrow="ALWAYS"/>
			<Button minWidth="46" prefWidth="46" styleClass="amoled-window-button" onAction="#didClickAmoledMinimize">
				<graphic><Region styleClass="amoled-window-icon-minimize"/></graphic>
			</Button>
			<Button minWidth="46" prefWidth="46" styleClass="amoled-window-button" onAction="#didClickAmoledMaximize">
				<graphic><Region styleClass="amoled-window-icon-maximize"/></graphic>
			</Button>
			<Button minWidth="46" prefWidth="46" styleClass="amoled-window-close-button" onAction="#didClickAmoledClose">
				<graphic><Region styleClass="amoled-window-icon-close"/></graphic>
			</Button>
		</HBox>
'@
			$text = $text -replace '(<VBox minWidth="600">\s*)', "`$1$titleBar"
			$text = $text -replace "</HBox><InfoBar", "</HBox>`r`n`t`t<InfoBar"
			$text = $text -replace '\r?\n\t{4,}<HBox', "`r`n`t`t<HBox"
		}
		$text = $text -replace '<\?import javafx.scene.layout.Priority\?>\r?\n(?!<\?import javafx.scene.layout.Region\?>)', "<?import javafx.scene.layout.Priority?>`r`n<?import javafx.scene.layout.Region?>`r`n"
		$text = [regex]::Replace($text, '<Button[^>]*onAction="#didClickAmoledMinimize"[^>]*/>', '<Button minWidth="46" prefWidth="46" styleClass="amoled-window-button" onAction="#didClickAmoledMinimize"><graphic><Region styleClass="amoled-window-icon-minimize"/></graphic></Button>')
		$text = [regex]::Replace($text, '<Button[^>]*onAction="#didClickAmoledMaximize"[^>]*/>', '<Button minWidth="46" prefWidth="46" styleClass="amoled-window-button" onAction="#didClickAmoledMaximize"><graphic><Region styleClass="amoled-window-icon-maximize"/></graphic></Button>')
		$text = [regex]::Replace($text, '<Button[^>]*onAction="#didClickAmoledClose"[^>]*/>', '<Button minWidth="46" prefWidth="46" styleClass="amoled-window-close-button" onAction="#didClickAmoledClose"><graphic><Region styleClass="amoled-window-icon-close"/></graphic></Button>')
		Set-TextUtf8NoBom $fxml $text
		Write-Info "custom AMOLED title bar added/updated: $fxml"
	}

	if (Test-Path -LiteralPath $module) {
		Backup-File $module
		$text = Get-Content -LiteralPath $module -Raw -Encoding UTF8
		if ($text -notmatch "javafx.stage.StageStyle") {
			$text = $text -replace "import javafx.stage.Stage;", "import javafx.stage.Stage;`r`nimport javafx.stage.StageStyle;"
		}
		if ($text -notmatch "StageStyle\.UNDECORATED") {
			$text = $text -replace "initializer\.accept\(stage\);", "initializer.accept(stage);`r`n`t`tstage.initStyle(StageStyle.UNDECORATED);"
		}
		Set-TextUtf8NoBom $module $text
		Write-Info "native white title bar disabled: $module"
	}

	if (Test-Path -LiteralPath $controller) {
		Backup-File $controller
		$text = Get-Content -LiteralPath $controller -Raw -Encoding UTF8
		if ($text -notmatch "javafx.scene.input.MouseEvent") {
			$text = $text -replace "import javafx.scene.layout.StackPane;", "import javafx.scene.input.MouseEvent;`r`nimport javafx.scene.layout.StackPane;"
		}
		if ($text -notmatch "amoledTitleBarDragOffsetX") {
			$text = $text -replace "private final LicenseHolder licenseHolder;", "private final LicenseHolder licenseHolder;`r`n`tprivate double amoledTitleBarDragOffsetX;`r`n`tprivate double amoledTitleBarDragOffsetY;"
		}
		if ($text -notmatch "didClickAmoledMinimize") {
			$methods = @'

	@FXML
	public void didPressAmoledTitleBar(MouseEvent event) {
		amoledTitleBarDragOffsetX = event.getSceneX();
		amoledTitleBarDragOffsetY = event.getSceneY();
	}

	@FXML
	public void didDragAmoledTitleBar(MouseEvent event) {
		if (!window.isMaximized()) {
			window.setX(event.getScreenX() - amoledTitleBarDragOffsetX);
			window.setY(event.getScreenY() - amoledTitleBarDragOffsetY);
		}
	}

	@FXML
	public void didClickAmoledMinimize() {
		window.setIconified(true);
	}

	@FXML
	public void didClickAmoledMaximize() {
		window.setMaximized(!window.isMaximized());
	}

	@FXML
	public void didClickAmoledClose() {
		window.fireEvent(new WindowEvent(window, WindowEvent.WINDOW_CLOSE_REQUEST));
	}
'@
			$text = $text -replace "\r?\n\}", "$methods`r`n}`r`n"
		}
		Set-TextUtf8NoBom $controller $text
		Write-Info "title bar actions added: $controller"
	}
}

function Patch-JavaFxTrayMenu {
	param([string] $Root)
	$controller = Join-Path $Root "src\main\java\org\cryptomator\ui\traymenu\AwtTrayMenuController.java"
	if (-not (Test-Path -LiteralPath $controller)) {
		return
	}
	Backup-File $controller
	$text = @'
package org.cryptomator.ui.traymenu;

import com.google.common.base.Preconditions;
import org.apache.commons.lang3.SystemUtils;
import org.cryptomator.integrations.common.CheckAvailability;
import org.cryptomator.integrations.common.Priority;
import org.cryptomator.integrations.tray.ActionItem;
import org.cryptomator.integrations.tray.SeparatorItem;
import org.cryptomator.integrations.tray.SubMenuItem;
import org.cryptomator.integrations.tray.TrayIconLoader;
import org.cryptomator.integrations.tray.TrayMenuController;
import org.cryptomator.integrations.tray.TrayMenuException;
import org.cryptomator.integrations.tray.TrayMenuItem;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import javafx.application.Platform;
import javafx.scene.Group;
import javafx.scene.Scene;
import javafx.scene.control.ContextMenu;
import javafx.scene.control.Menu;
import javafx.scene.control.MenuItem;
import javafx.scene.control.SeparatorMenuItem;
import javafx.stage.Stage;
import javafx.stage.StageStyle;
import java.awt.AWTException;
import java.awt.Image;
import java.awt.SystemTray;
import java.awt.Toolkit;
import java.awt.TrayIcon;
import java.awt.event.MouseAdapter;
import java.awt.event.MouseEvent;
import java.util.ArrayList;
import java.util.List;
import java.util.function.Consumer;

/**
 * AMOLED patch: use AWT only for the tray icon and JavaFX for the popup menu, so
 * the menu follows Cryptomator's black JavaFX stylesheet instead of Windows' native white menu.
 */
@CheckAvailability
@Priority(Priority.FALLBACK)
public class AwtTrayMenuController implements TrayMenuController {

	private static final Logger LOG = LoggerFactory.getLogger(AwtTrayMenuController.class);

	private final ContextMenu menu = new ContextMenu();
	private List<TrayMenuItem> latestItems = new ArrayList<>();
	private TrayIcon trayIcon;
	private Image image;
	private Stage popupOwner;
	private Runnable beforeOpenMenu = () -> {};

	@CheckAvailability
	public static boolean isAvailable() {
		return SystemTray.isSupported();
	}

	@Override
	public void showTrayIcon(Consumer<TrayIconLoader> iconLoader, Runnable defaultAction, String tooltip) throws TrayMenuException {
		TrayIconLoader.PngData callback = this::showTrayIconWithPngData;
		iconLoader.accept(callback);
		trayIcon = new TrayIcon(image, tooltip);
		trayIcon.setImageAutoSize(true);
		trayIcon.addMouseListener(new MouseAdapter() {
			@Override
			public void mousePressed(MouseEvent e) {
				if (isMenuTrigger(e)) {
					showMenu(e);
				}
			}

			@Override
			public void mouseReleased(MouseEvent e) {
				if (isMenuTrigger(e)) {
					showMenu(e);
				}
			}

			@Override
			public void mouseClicked(MouseEvent e) {
				if (isMenuTrigger(e)) {
					showMenu(e);
				}
			}
		});
		if (SystemUtils.IS_OS_WINDOWS) {
			trayIcon.addActionListener(evt -> defaultAction.run());
		}

		try {
			SystemTray.getSystemTray().add(trayIcon);
			LOG.debug("initialized tray icon");
		} catch (AWTException e) {
			throw new TrayMenuException("Failed to add icon to system tray.", e);
		}
	}

	private void showTrayIconWithPngData(byte[] imageData) {
		image = Toolkit.getDefaultToolkit().createImage(imageData);
	}

	@Override
	public void updateTrayIcon(Consumer<TrayIconLoader> iconLoader) {
		TrayIconLoader.PngData callback = this::updateTrayIconWithPngData;
		iconLoader.accept(callback);
	}

	private void updateTrayIconWithPngData(byte[] imageData) {
		if (trayIcon == null) {
			throw new IllegalStateException("Failed to update the icon as it has not yet been added");
		}
		var image = Toolkit.getDefaultToolkit().createImage(imageData);
		trayIcon.setImage(image);
	}

	@Override
	public void updateTrayMenu(List<TrayMenuItem> items) {
		latestItems = List.copyOf(items);
		Platform.runLater(() -> {
			menu.getItems().setAll(toFxItems(latestItems));
			menu.getStyleClass().add("amoled-tray-menu");
		});
	}

	@Override
	public void onBeforeOpenMenu(Runnable listener) {
		Preconditions.checkNotNull(this.trayIcon);
		beforeOpenMenu = listener;
	}

	private boolean isMenuTrigger(MouseEvent e) {
		return e.isPopupTrigger() || e.getButton() == MouseEvent.BUTTON3;
	}

	private void showMenu(MouseEvent e) {
		beforeOpenMenu.run();
		Platform.runLater(() -> {
			ensurePopupOwner();
			menu.getItems().setAll(toFxItems(latestItems));
			menu.getStyleClass().remove("amoled-tray-menu");
			menu.getStyleClass().add("amoled-tray-menu");
			if (menu.isShowing()) {
				menu.hide();
			}
			menu.show(popupOwner, e.getXOnScreen(), e.getYOnScreen());
		});
	}

	private void ensurePopupOwner() {
		if (popupOwner == null) {
			popupOwner = new Stage(StageStyle.TRANSPARENT);
			popupOwner.setScene(new Scene(new Group(), 1, 1));
			popupOwner.setWidth(1);
			popupOwner.setHeight(1);
			popupOwner.setOpacity(0.01);
			popupOwner.setAlwaysOnTop(true);
			popupOwner.show();
		}
	}

	private List<MenuItem> toFxItems(List<TrayMenuItem> items) {
		List<MenuItem> fxItems = new ArrayList<>();
		for (var item : items) {
			switch (item) {
				case ActionItem a -> {
					var menuItem = new MenuItem(a.title());
					menuItem.setOnAction(evt -> a.action().run());
					menuItem.setDisable(!a.enabled());
					fxItems.add(menuItem);
				}
				case SeparatorItem s -> fxItems.add(new SeparatorMenuItem());
				case SubMenuItem s -> {
					var submenu = new Menu(s.title());
					submenu.getItems().setAll(toFxItems(s.items()));
					fxItems.add(submenu);
				}
			}
		}
		return fxItems;
	}
}
'@
	Set-TextUtf8NoBom $controller $text
	Write-Info "tray menu switched to JavaFX AMOLED popup: $controller"
}

function Update-ZipEntry {
	param(
		[System.IO.Compression.ZipArchive] $Zip,
		[string] $EntryName,
		[string] $Text
	)
	$existing = $Zip.GetEntry($EntryName)
	if ($null -ne $existing) {
		$existing.Delete()
	}
	$newEntry = $Zip.CreateEntry($EntryName)
	$stream = $newEntry.Open()
	try {
		$writer = New-Object System.IO.StreamWriter($stream, [System.Text.UTF8Encoding]::new($false))
		try {
			$writer.Write($Text)
		} finally {
			$writer.Dispose()
		}
	} finally {
		$stream.Dispose()
	}
}

function Patch-Jar {
	param([string] $JarPath)
	Add-Type -AssemblyName System.IO.Compression.FileSystem
	Add-Type -AssemblyName System.IO.Compression
	Backup-File $JarPath

	$zip = [System.IO.Compression.ZipFile]::Open($JarPath, [System.IO.Compression.ZipArchiveMode]::Update)
	try {
		foreach ($entryName in @("css/dark_theme.css", "css/light_theme.css")) {
			$entry = $zip.GetEntry($entryName)
			if ($null -eq $entry) {
				throw "Entry not found in jar: $entryName"
			}
			$reader = New-Object System.IO.StreamReader($entry.Open(), [System.Text.Encoding]::UTF8)
			try {
				$original = $reader.ReadToEnd()
			} finally {
				$reader.Dispose()
			}
			$patched = Get-AmoledCss $original
			Update-ZipEntry $zip $entryName $patched
			Write-Info "patched jar entry: $JarPath -> $entryName"
		}
	} finally {
		$zip.Dispose()
	}
}

function Patch-InstalledCryptomator {
	param([string] $Root)
	$mods = Join-Path $Root "app\mods"
	if (-not (Test-Path -LiteralPath $mods)) {
		return $false
	}
	$jar = Get-ChildItem -LiteralPath $mods -Filter "cryptomator-*.jar" -File | Sort-Object LastWriteTime -Descending | Select-Object -First 1
	if ($null -eq $jar) {
		return $false
	}
	Patch-Jar $jar.FullName
	return $true
}

function Patch-UserSettings {
	$settingsPath = Join-Path $env:APPDATA "Cryptomator\settings.json"
	if (-not (Test-Path -LiteralPath $settingsPath)) {
		Write-Info "settings.json not found, skipped: $settingsPath"
		return
	}
	Backup-File $settingsPath
	$json = Get-Content -LiteralPath $settingsPath -Raw -Encoding UTF8
	if ($json -match '"theme"\s*:') {
		$json = $json -replace '"theme"\s*:\s*"[^"]*"', '"theme" : "DARK"'
	} else {
		$json = $json.TrimEnd()
		$json = $json -replace "\}\s*$", ', "theme" : "DARK" }'
	}
	Set-TextUtf8NoBom $settingsPath $json
	Write-Info "user theme set to DARK: $settingsPath"
}

function Resolve-Targets {
	if ($Target) {
		return @((Resolve-Path -LiteralPath $Target).Path)
	}

	$candidates = @()
	$programFilesPath = "C:\Program Files\Cryptomator"
	if (Test-Path -LiteralPath $programFilesPath) {
		$candidates += $programFilesPath
	}
	if (Test-Path -LiteralPath ".\cryptomator-develop") {
		$candidates += (Resolve-Path -LiteralPath ".\cryptomator-develop").Path
	}
	if (Test-Path -LiteralPath ".\src\main\resources\css") {
		$candidates += (Resolve-Path -LiteralPath ".").Path
	}
	return $candidates
}

try {
	Write-Info "Cryptomator AMOLED Black Theme Patcher"
	$targets = Resolve-Targets
	if ($targets.Count -eq 0) {
		throw "No target found. Run with -Target `"C:\Program Files\Cryptomator`" or -Target path\to\cryptomator-source."
	}

	$patchedAny = $false
	foreach ($t in $targets) {
		Write-Info "target: $t"
		$patched = (Patch-SourceTree $t)
		if (-not $patched) {
			$patched = (Patch-InstalledCryptomator $t)
		}
		if (-not $patched) {
			Write-Info "skipped, target layout was not recognized: $t"
		}
		$patchedAny = $patchedAny -or $patched
	}

	if ($SetUserTheme) {
		Patch-UserSettings
	}

	if (-not $patchedAny) {
		throw "No Cryptomator CSS was patched."
	}

	Write-Info "done. Backups were created with the .amoled-backup suffix."
	Write-Info "Restart Cryptomator to see the AMOLED black theme."
} catch {
	Write-Host "[AMOLED] ERROR: $($_.Exception.Message)" -ForegroundColor Red
	exit 1
} finally {
	if (-not $NoPause) {
		Write-Host ""
		Read-Host "Press Enter to close"
	}
}
