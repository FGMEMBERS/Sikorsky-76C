var rev1 = nil;
var r1 = nil;
var r2 = nil;
var v1 = nil;
var cl = 0.0;
var c2 = 0.0;
var hpsi = 0.0;
var pph1=0.0;
var pph2=0.0;
var fuel_density=0.0;
var n_offset=0;
var nm_calc=0.0;
var et_min = 0.0;
var et_hr = 0.0;
var et_min_start = 0.0;
var ViewNum=0;
var EyePoint = 0;

Cvolume=props.globals.getNode("/sim/sound/S76C/Cvolume",1);
Ovolume=props.globals.getNode("/sim/sound/S76C/Ovolume",1);
var E_state = props.globals.getNode("sim/model/S-76C/state",1);

strobe_switch = props.globals.getNode("controls/switches/strobe", 1);
aircraft.light.new("sim/model/S-76C/lighting/strobe", [0.05, 1.50], strobe_switch);
beacon_switch = props.globals.getNode("controls/switches/beacon", 1);
aircraft.light.new("sim/model/S-76C/lighting/beacon", [1.0, 1.0], beacon_switch);
Cvolume.setDoubleValue(0.6);
Ovolume.setDoubleValue(0.2);


setlistener("/sim/signals/fdm-initialized", func {
    setprop("/environment/turbulence/use-cloud-turbulence","true");
    setprop("/instrumentation/clock/ET-min",0);
    setprop("/instrumentation/clock/ET-hr",0);
    EyePoint = getprop("sim/view/config/y-offset-m");
    reset_et();
    print("Systems ... Check");
});

reset_et = func{
    var et_base = getprop("/sim/time/elapsed-sec");
    var et_min_start = 0.0;
    et_min_start = et_base;
    et_hr=0.0;
    et_min=0.0;
}

update_clock = func{
    var sec = getprop("/sim/time/elapsed-sec") - et_min_start;
    if(sec >= 60.0){et_min += 1;
    et_min_start = getprop("/sim/time/elapsed-sec");
    }
    if(et_min ==60){et_min = 0; et_hr += 1;}
    etmin = props.globals.getNode("/instrumentation/clock/ET-min");
    etmin.setIntValue(et_min);
    ethr = props.globals.getNode("/instrumentation/clock/ET-hr");
    ethr.setIntValue(et_hr);
}

setlistener("/sim/current-view/view-number", func {
    ViewNum = cmdarg().getValue();
    if(ViewNum == 0){
        Cvolume.setValue(0.6);
        Ovolume.setValue(0.2);
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
    update_clock();
    force = getprop("/accelerations/pilot-g");
    if(force == nil) {force = 1.0;}
    eyepoint = EyePoint +0.02;
    eyepoint -= (force * 0.02);
    if(ViewNum == 0){
        props.globals.getNode("/sim/current-view/y-offset-m"),setDoubleValue(eyepoint);
    }
settimer(update_systems,0);
}

    settimer(update_systems,0);
