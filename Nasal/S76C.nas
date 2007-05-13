var ViewNum=0;
var EyePoint = 0;

Cvolume=props.globals.getNode("/sim/sound/S76C/Cvolume",1);
Ovolume=props.globals.getNode("/sim/sound/S76C/Ovolume",1);
var E_state = props.globals.getNode("sim/model/S-76C/state",1);

strobe_switch = props.globals.getNode("controls/lighting/strobe", 1);
aircraft.light.new("sim/model/S-76C/lighting/strobe-state", [0.05, 1.50], strobe_switch);
beacon_switch = props.globals.getNode("controls/lighting/beacon", 1);
aircraft.light.new("sim/model/S-76C/lighting/beacon-state", [1.0, 1.0], beacon_switch);

Cvolume.setDoubleValue(0.0);
Ovolume.setDoubleValue(0.0);

setlistener("/sim/signals/fdm-initialized", func {
    Cvolume.setDoubleValue(0.7);
    Ovolume.setDoubleValue(0.3);
    setprop("/environment/turbulence/use-cloud-turbulence","true");
    setprop("/instrumentation/clock/ET-min",0);
    setprop("/instrumentation/clock/ET-hr",0);
    EyePoint = 0.02 + getprop("sim/view/config/y-offset-m");
    print("Systems ... Check");
    settimer(update_systems,1);
});

setlistener("/sim/current-view/view-number", func {
    ViewNum = cmdarg().getValue();
    if(ViewNum == 0){
        Cvolume.setValue(0.7);
        Ovolume.setValue(0.3);
        }else{
        Cvolume.setValue(0.1);
        Ovolume.setValue(1.0);
    }
});

setlistener("/engines/engine/running", func {
    var running = cmdarg().getBoolValue();
    if(running){
        interpolate(E_state, 1, 3);
    }else{
        E_state.setDoubleValue(0);
    }
});

update_systems = func {
    if(E_state.getValue() == 1){
        props.globals.getNode("controls/engines/engine/magnetos").setValue(1);
    }else{
        if(E_state.getValue() == 0){
        props.globals.getNode("controls/engines/engine/magnetos").setValue(0);
        }
    }
    force = props.globals.getNode("/accelerations/pilot-g").getValue();
    if(force == nil) {force = 1.0;}
    eyepoint = EyePoint - (force * 0.02);
    if(ViewNum == 0){
        props.globals.getNode("/sim/current-view/y-offset-m").setDoubleValue(eyepoint);
    }
settimer(update_systems,0);
}


