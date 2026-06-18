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