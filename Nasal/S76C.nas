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
engine_on = props.globals.getNode("/sim/sound/MR/on",1);
rotor_volume = props.globals.getNode("/sim/sound/MR/volume",1);
rotor_pitch = props.globals.getNode("/sim/sound/MR/pitch",1);
rotor_overspeed = props.globals.getNode("/sim/sound/MR/overspeed",1);
RPM_FACTOR = 0.0020;


strobe_switch = props.globals.getNode("controls/switches/strobe", 1);
aircraft.light.new("sim/model/S-76C/lighting/strobe", [0.05, 1.50], strobe_switch);
beacon_switch = props.globals.getNode("controls/switches/beacon", 1);
aircraft.light.new("sim/model/S-76C/lighting/beacon", [1.0, 1.0], beacon_switch);

setlistener("/sim/signals/fdm-initialized", func {
   setprop("/environment/turbulence/use-cloud-turbulence","true");
   setprop("/instrumentation/clock/ET-min",0);
   setprop("/instrumentation/clock/ET-hr",0);
   engine_on.setBoolValue(0);
   rotor_volume.setValue(0);
   rotor_pitch.setValue(0.0);
   rotor_overspeed.setBoolValue(0);
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

update_sounds = func{
var view0 = props.globals.getNode("/sim/current-view/view-number",0).getValue();
var sound_level = 0.9;
var AsV = props.globals.getNode("/velocities/airspeed-kt",0).getValue();
rotor_rpm =props.globals.getNode("/rotors/main/rpm",0); 
var test_rpm = rotor_rpm.getValue();

if(test_rpm == nil){test_rpm = 0.0;}
if(test_rpm < 5 or test_rpm == nil){
engine_on.setBoolValue(0);
rotor_volume.setValue(0);
rotor_pitch.setValue(0.05);
   }else{
engine_on.setBoolValue(1);
if(view0 == 0){sound_level = 0.3;}
rotor_volume.setValue(sound_level);
rotor_pitch.setValue((0.05)+(RPM_FACTOR * test_rpm));
if(AsV >150){rotor_overspeed.setBoolValue(1);}else{rotor_overspeed.setBoolValue(0);}   
   }
}


update_systems = func {
update_clock();
update_sounds();
   force = getprop("/accelerations/pilot-g");
   if(force == nil) {force = 1.0;}
   eyepoint = getprop("sim/view/config/y-offset-m") +0.02;
   eyepoint -= (force * 0.02);
   if(getprop("/sim/current-view/view-number") < 1){
      setprop("/sim/current-view/y-offset-m",eyepoint);
      }
 
   if(getprop("/sim/auto-coordination") !=0){
   var pedals = getprop("/controls/engines/engine/throttle");
   var output = 0.35 - (pedals * 0.7);    
   setprop("/controls/flight/rudder", output) 
   }
      
settimer(update_systems,0);
}
settimer(update_systems,0);

