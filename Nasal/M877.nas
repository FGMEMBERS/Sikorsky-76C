var davtron=props.globals.getNode("/instrumentation/clock/m877",1);
var set_hour=davtron.getNode("set-hour",1);
var set_min=davtron.getNode("set-min",1);
var mode=davtron.getNode("mode",1);
var modestring =davtron.getNode("mode-string",1);
var modetext =["GMT","LT","FT","ET"];
var HR=davtron.getNode("indicated-hour",1);
var MN=davtron.getNode("indicated-min",1);
var MODE = 0;

setlistener("/sim/signals/fdm-initialized", func {
    set_hour.setBoolValue(0);
    set_min.setBoolValue(0);
    mode.setIntValue(MODE);
    modestring.setValue(modetext[MODE]);
    HR.setDoubleValue(0);
    MN.setDoubleValue(0);
    print("Chronometer ... Check");
    settimer(update_clock,5);
});

setlistener("/instrumentation/clock/m877/mode", func {
    MODE = cmdarg().getValue();
    modestring.setValue(modetext[MODE]);
});

update_clock = func{
    var FThr =getprop("/instrumentation/clock/flight-meter-hour");

    if (MODE == 0) {
    setprop("/instrumentation/clock/m877/indicated-hour",getprop("/instrumentation/clock/indicated-hour"));
    setprop("/instrumentation/clock/m877/indicated-min",getprop("/instrumentation/clock/indicated-min"));
    }

    if (MODE == 1) {
    setprop("/instrumentation/clock/m877/indicated-hour",getprop("/instrumentation/clock/local-hour"));
    setprop("/instrumentation/clock/m877/indicated-min",getprop("/instrumentation/clock/indicated-min"));
    }

    if (MODE == 2) {
    var FH = sprintf("%2.0d", FThr);
    var FM = sprintf("%2.0d", 60 * (FThr - FH));
    setprop("/instrumentation/clock/m877/indicated-hour",FH);
    setprop("/instrumentation/clock/m877/indicated-min",FM);
    }

    if (MODE == 3) {
    setprop("/instrumentation/clock/m877/indicated-hour",getprop("/instrumentation/clock/ET-hr"));
    setprop("/instrumentation/clock/m877/indicated-min",getprop("/instrumentation/clock/ET-min"));
    }

settimer(update_clock,0);
}