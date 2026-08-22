import AppKit

final class MenuBarRightMenuBuilder {
    @MainActor
    static func buildMenu(
        target: AnyObject?,
        launchAtLoginAction: Selector,
        refreshAction: Selector,
        settingsAction: Selector,
        quitAction: Selector
    ) -> NSMenu {
        let menu = NSMenu()
        
        let refresh = NSMenuItem(title: "Ekranı yenile", action: refreshAction, keyEquivalent: "")
        refresh.target = target
        menu.addItem(refresh)
        
        let settings = NSMenuItem(title: "Ayarlar...", action: settingsAction, keyEquivalent: ",")
        settings.target = target
        menu.addItem(settings)
        
        let launchAtLogin = NSMenuItem(title: "Girişte başlat: Kapalı", action: launchAtLoginAction, keyEquivalent: "")
        launchAtLogin.target = target
        menu.addItem(launchAtLogin)
        
        menu.addItem(.separator())
        
        let quit = NSMenuItem(title: "AmbientSync'ten Çık", action: quitAction, keyEquivalent: "q")
        quit.target = target
        menu.addItem(quit)
        
        return menu
    }
}
