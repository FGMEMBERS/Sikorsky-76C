aircraft.livery.init("Aircraft/Sikorsky-76C/Models/Liveries", "sim/model/livery/name", "sim/model/livery/index");
var ViewNum=0;
var EyePoint = 0;
var last_time = 0;
var GPS = 0.0248015;  ### avg cruise = 600 lbs/hr
var Fuel_Density=6.72;
var Fuel_Level= props.globals.getNode("/consumables/fuel/tank/level-gal_us",1);
var Fuel_LBS= props.globals.getNode("/consumables/fuel/tank/level-lbs",1);
var NoFuel=props.globals.getNode("/engines/engine/out-of-fuel",1);
var Cvolume=props.globals.getNode("/sim/sound/S76C/Cvolume",1);
var Spitch=props.globals.getNode("/sim/sound/S76C/pitch",1);
var Ovolume=props.globals.getNode("/sim/sound/S76C/Ovolume",1);
var N1 = props.globals.getNode("engines/engine/n1",1);
var N2 = props.globals.getNode("engines/engine/n2",1);

var view_list =[];
var Sview = props.globals.getNode("/sim").getChildren("view");
foreach (v;Sview) {
append(view_list,"sim/view["~v.getIndex()~"]/config/default-field-of-view-deg");
}
aircraft.data.add(view_list);


var strobe_switch = props.globals.getNode("controls/lighting/strobe", 1);
aircraft.light.new("sim/model/S-76C/lighting/strobe-state", [0.05, 1.50], strobe_switch);
var beacon_switch = props.globals.getNode("controls/lighting/beacon", 1);
aircraft.light.new("sim/model/S-76C/lighting/beacon-state", [1.0, 1.0], beacon_switch);

var FHmeter = aircraft.timer.new("/instrumentation/clock/flight-meter-sec", 10);
FHmeter.stop();
var TX_list=["S76livery.rgb","S76livery1.rgb","S76livery2.rgb","S76livery3.rgb"];
Cvolume.setDoubleValue(0.0);
Ovolume.setDoubleValue(0.0);
N1.setDoubleValue(0.0);
N2.setDoubleValue(0.0);

setlistener("/sim/signals/fdm-initialized", func {
    Cvolume.setDoubleValue(0.8);
    Ovolume.setDoubleValue(0.3);
    Fuel_Density=props.globals.getNode("/consumables/fuel/tank/density-ppg").getValue();
    setprop("/environment/turbulence/use-cloud-turbulence","true");
    setprop("/instrumentation/clock/ET-min",0);
    setprop("/instrumentation/clock/ET-hr",0);
    setprop("/instrumentation/clock/flight-meter-hour",0);
    setprop("/instrumentation/inst-vertical-speed-indicator/serviceable",1);
    setprop("/instrumentation/altimeter/DH",200);
    setprop("/autopilot/settings/altitude-preset",0);
    print("Systems ... Check");
    var VR =getprop("sim/model/variant");
    if(VR==nil)VR=0;
    if(VR > size(TX_list)){
    VR=0;
    setprop("sim/model/variant",0);
    }
    setprop("/sim/model/texture",TX_list[VR]);
    settimer(update_systems,2);
});

setlistener("/sim/current-view/view-number", func(vw){
    ViewNum = vw.getValue();
    Cvolume.setValue(0.1);
    Ovolume.setValue(1.0);
    if(ViewNum == 0){
        Cvolume.setValue(0.8);
        Ovolume.setValue(0.3);
        }
    if(ViewNum == 7){
        Cvolume.setValue(0.8);
        Ovolume.setValue(0.3);
        }
},0,0);

setlistener("/gear/gear[1]/wow", func(gr){
    if(gr.getBoolValue()){
    FHmeter.stop();
    }else{FHmeter.start();}
},0,0);

setlistener("/engines/engine/running", func(run){
    var running = run.getBoolValue();
    var fuel =props.globals.getNode("/engines/engine/out-of-fuel").getBoolValue();
    if(running and !fuel){
        interpolate(N2, 100, 10);
        }else{
        props.globals.getNode("/engines/engine/running").setBoolValue(0);
        interpolate(N2, 0, 15);
    }
},0,0);

setlistener("/engines/engine/out-of-fuel", func(fl){
    var nofuel = fl.getBoolValue();
    if(nofuel){
        props.globals.getNode("/engines/engine/running").setBoolValue(0);
    }
},0,0);

setlistener("/sim/model/start-idling", func(idle){
    var run= idle.getBoolValue();
    if(run){
    Startup();
    }else{
    Shutdown();
    }
},0,0);

var Startup = func{
setprop("controls/electric/engine[0]/generator",1);
setprop("controls/electric/battery-switch",1);
setprop("controls/lighting/instrument-lights",1);
setprop("controls/lighting/nav-lights",1);
setprop("controls/lighting/beacon",1);
setprop("controls/lighting/strobe",1);
setprop("controls/engines/engine[0]/magnetos",3);
setprop("engines/engine[0]/running",1);
}

var Shutdown = func{
setprop("controls/electric/engine[0]/generator",0);
setprop("controls/electric/battery-switch",0);
setprop("controls/lighting/instrument-lights",0);
setprop("controls/lighting/nav-lights",0);
setprop("controls/lighting/beacon",0);
setprop("controls/engines/engine[0]/magnetos",0);
}

var flight_meter = func{
var fmeter = getprop("/instrumentation/clock/flight-meter-sec");
var fminute = fmeter * 0.016666;
var fhour = fminute * 0.016666;
setprop("/instrumentation/clock/flight-meter-hour",fhour);
}

var update_fuel = func{
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

var update_systems = func {
    var time = getprop("/sim/time/elapsed-sec");
    var dt = time - last_time;
    last_time = time;
    var n2 = N2.getValue();
    N1.setValue(n2 * 0.95);
    setprop("engines/engine/T5",getprop("rotors/tail/torque") * 0.6666);
    setprop("engines/engine/TQ",getprop("rotors/main/torque") * 0.0025);
    if(n2 >30){
        setprop("controls/engines/engine/magnetos",1);
        update_fuel(dt);
    }else{
        if(N2.getValue() < 70){
            setprop("controls/engines/engine/magnetos",0);
        }
    }
flight_meter();
settimer(update_systems,0);
}


