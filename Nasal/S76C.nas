aircraft.livery.init("Aircraft/Sikorsky-76C/Models/Liveries", "sim/model/livery/name", "sim/model/livery/index");
var ViewNum=0;
var EyePoint = 0;
var last_time = 0;
var NoFuel=props.globals.getNode("/engines/engine/out-of-fuel",1);
var Cvolume=props.globals.getNode("/sim/sound/S76C/Cvolume",1);
var Spitch=props.globals.getNode("/sim/sound/S76C/pitch",1);
var Ovolume=props.globals.getNode("/sim/sound/S76C/Ovolume",1);

#HelicopterEngine class 
# ie: var Eng = Engine.new(engine number,rotor_prop,max_rpm);
var Engine = {
    new : func(eng_num,rotor_prop,max_rpm){
        m = { parents : [Engine]};
        m.fdensity = getprop("consumables/fuel/tank/density-ppg");
        if(m.fdensity ==nil)m.fdensity=6.72;
        m.ttl_fuel_lbs = props.globals.getNode("consumables/fuel/total-fuel-lbs",1);
        m.ttl_fuel_lbs.setDoubleValue(10);
        m.MAXrpm=max_rpm;
        m.air_temp = props.globals.getNode("environment/temperature-degc",1);
        m.eng = props.globals.getNode("engines/engine["~eng_num~"]",1);
        m.rotor_rpm = props.globals.getNode(rotor_prop,1);
        m.running = m.eng.getNode("running",1);
        m.magneto = props.globals.getNode("controls/engines/engine["~eng_num~"]/magnetos",1);
        m.cutoff = props.globals.getNode("controls/engines/engine["~eng_num~"]/cutoff",1);
        m.rpm = m.eng.getNode("n2",1);
        m.n1 = m.eng.getNode("n1",1);
        m.fuel_pph=m.eng.getNode("fuel-flow_pph",1);
        m.oil_temp=m.eng.getNode("oil-temp-c",1);
        m.oil_temp.setDoubleValue(m.air_temp.getValue());
        m.fuel_pph.setDoubleValue(0);
        m.fuel_gph=m.eng.getNode("fuel-flow-gph",1);
        m.hpump=props.globals.getNode("systems/hydraulics/pump-psi["~eng_num~"]",1);
        m.hpump.setDoubleValue(0);
    return m;
    },
#### update ####
    update_eng : func{
        var rtr =me.rotor_rpm.getValue()/me.MAXrpm;
        me.rpm.setValue(rtr *100);
        me.n1.setValue(rtr *98);
        var rpm =me.rpm.getValue();
        var hpsi =rpm;
        if(hpsi>60)hpsi = 60;
        me.hpump.setValue(hpsi);
        var OT= me.oil_temp.getValue();
        if(OT < rpm)OT+=0.01;
        if(OT > rpm)OT-=0.001;
        me.oil_temp.setValue(OT);
        },

    update_fuel : func(dt,gph,tnk){
        var Rrpm =me.rpm.getValue();
        var ttl_lbs=0;
        var rpm_factor= Rrpm *0.01;
        var cur_gph= gph * rpm_factor;
        var cur_pph = cur_gph * me.fdensity;
        me.fuel_gph.setDoubleValue(cur_gph);
       me.fuel_pph.setDoubleValue(cur_pph);
        var gph_used = (cur_gph/3600)*dt;
        for(var i=0; i<tnk; i+=1) {
            var fl1 = getprop("consumables/fuel/tank["~i~"]/level-gal_us");
            var amnt = gph_used /tnk;
            fl1 = fl1 - amnt;
            setprop("consumables/fuel/tank["~i~"]/level-gal_us", fl1);
            setprop("consumables/fuel/tank["~i~"]/level-lbs", fl1 * me.fdensity);
            ttl_lbs +=fl1*me.fdensity;
        }
    me.ttl_fuel_lbs.setDoubleValue(ttl_lbs);
    },
#### check fuel cutoff , copy mixture setting to condition for turboprop ####
    condition_check :  func{
        if(me.cutoff.getBoolValue()){
            me.condition.setValue(0);
            me.running.setBoolValue(0);
        }else{
            me.condition.setValue(me.mixture.getValue());
        }
    }
};


var strobe_switch = props.globals.getNode("controls/lighting/strobe", 1);
aircraft.light.new("sim/model/S-76C/lighting/strobe-state", [0.05, 1.50], strobe_switch);
var beacon_switch = props.globals.getNode("controls/lighting/beacon", 1);
aircraft.light.new("sim/model/S-76C/lighting/beacon-state", [1.0, 1.0], beacon_switch);
var Eng = Engine.new(0,"rotors/main/rpm",293);
var FHmeter = aircraft.timer.new("/instrumentation/clock/flight-meter-sec", 10);
FHmeter.stop();
var TX_list=["S76livery.rgb","S76livery1.rgb","S76livery2.rgb","S76livery3.rgb"];
Cvolume.setDoubleValue(0.0);
Ovolume.setDoubleValue(0.0);

setlistener("/sim/signals/fdm-initialized", func {
    Cvolume.setDoubleValue(0.8);
    Ovolume.setDoubleValue(0.3);
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

var radar_range=func(rng){
    var rdr_rng=getprop("instrumentation/radar/range");
    if(rng > 0){
        rdr_rng = rdr_rng * 2;
        if(rdr_rng>160)rdr_rng=160;
    }elsif(rng<0){
        rdr_rng = rdr_rng * 0.5;
        if(rdr_rng<10)rdr_rng=10;
    }
    setprop("instrumentation/radar/range",rdr_rng);
}

var radar_switch=func(swt){
# switch positions= off, stby,tst,on #
    var rdr_swt=getprop("instrumentation/radar/switch");
    var pos=getprop("instrumentation/radar/switch-pos");
    if(swt > 0){
        if(rdr_swt =="off"){
            rdr_swt="stby";pos=1;
            }elsif(rdr_swt=="stby"){
            rdr_swt="tst";pos=2;
        }elsif(rdr_swt=="tst"){
            rdr_swt="on";pos=3;
        }
    }elsif(swt<0){
        if(rdr_swt =="on"){
            rdr_swt="tst";pos=2;
        }elsif(rdr_swt=="tst"){
            rdr_swt="stby";pos=1;
        }elsif(rdr_swt=="stby"){
            rdr_swt="off";pos=0;
        }
    }
    setprop("instrumentation/radar/switch",rdr_swt);
    setprop("instrumentation/radar/switch-pos",pos);
}

var update_systems = func {
    Eng.update_eng();
    var dt = getprop("sim/time/delta-sec");
    Eng.update_fuel(dt,92.26,2); # elapsed seconds,gallons per hour, number of tanks
    setprop("engines/engine/T5",getprop("rotors/tail/torque") * 0.6666);
    setprop("engines/engine/TQ",getprop("rotors/main/torque") * 0.0025);
flight_meter();
settimer(update_systems,0);
}


