var ap_settings = gui.Dialog.new("/sim/gui/dialogs/autopilot/dialog",
        "Aircraft/Sikorsky-76C/Systems/autopilot-dlg.xml");
var options = gui.Dialog.new("/sim/gui/dialogs/options/dialog",
        "Aircraft/Sikorsky-76C/Systems/options.xml");



gui.menuBind("autopilot-settings", "dialogs.ap_settings.open()");
