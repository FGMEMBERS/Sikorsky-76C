var ViewNum=0;
var EyePoint = 0;
var last_time = 0;
var GPS = 0.0248015;  ### avg cruise = 600 lbs/hr
var Fuel_Density=6.72;
Fuel_Level= props.globals.getNode("/consumables/fuel/tank/level-gal_us",1);
Fuel_LBS= props.globals.getNode("/consumables/fuel/tank/level-lbs",1);
NoFuel=props.globals.getNode("/engines/engine/out-of-fuel",1);
Cvolume=props.globals.getNode("/sim/sound/S76C/Cvolume",1);
Ovolume=props.globals.getNode("/sim/sound/S76C/Ovolume",1);
N1 = props.globals.getNode("engines/engine/n1",1);
var FDM = 0;

strobe_switch = props.globals.getNode("controls/lighting/strobe", 1);
aircraft.light.new("sim/model/S-76C/lighting/strobe-state", [0.05, 1.50], strobe_switch);
beacon_switch = props.globals.getNode("controls/lighting/beacon", 1);
aircraft.light.new("sim/model/S-76C/lighting/beacon-state", [1.0, 1.0], beacon_switch);

Cvolume.setDoubleValue(0.0);
Ovolume.setDoubleValue(0.0);
N1.setDoubleValue(0.0);

setlistener("/sim/signals/fdm-initialized", func {
    Cvolume.setDoubleValue(0.7);
    Ovolume.setDoubleValue(0.3);
    Fuel_Density=props.globals.getNode("/consumables/fuel/tank/density-ppg").getValue();
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
    var fuel =props.globals.getNode("/engines/engine/out-of-fuel").getBoolValue();
    if(running and !fuel){
        interpolate(N1, 95, 10);
    }else{
        props.globals.getNode("/engines/engine/running").setBoolValue(0);
        interpolate(N1, 0, 15);
    }
});

setlistener("/engines/engine/out-of-fuel", func {
    var nofuel = cmdarg().getBoolValue();
    if(nofuel){
        props.globals.getNode("/engines/engine/running").setBoolValue(0);
    }
});

update_fuel = func{
    var amnt = arg[0] * GPS;
    var lvl = Fuel_Level.getValue();
    Fuel_Level.setDoubleValue(lvl-amnt);
    Fuel_LBS.setDoubleValue(lvl * Fuel_Density);
    if(lvl < 0.2){
        if(!NoFuel.getBoolValue()){
            NoFuel.setBoolValue(1);
        }
    }

}

update_systems = func {
    var time = props.globals.getNode("/sim/time/elapsed-sec").getValue();
    var dt = time - last_time;
    last_time = time;
    var n1 = N1.getValue();
    if(n1 >30){
        props.globals.getNode("controls/engines/engine/magnetos").setValue(1);
        update_fuel(dt);
    }else{
        if(N1.getValue() < 70){
            props.globals.getNode("controls/engines/engine/magnetos").setValue(0);
        }
    }
settimer(update_systems,0);
}


