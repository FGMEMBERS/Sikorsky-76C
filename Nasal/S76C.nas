aircraft.livery.init("Aircraft/Sikorsky-76C/Models/Liveries");
var Cvolume=props.globals.getNode("/sim/sound/S76C/Cvolume",1);
var Spitch=props.globals.getNode("/sim/sound/S76C/pitch",1);
var Ovolume=props.globals.getNode("/sim/sound/S76C/Ovolume",1);
var tcas_index=0;
var tcas_list=[3,5,10,15,20,40];
###########HelicopterEngine class ###############
# ie: var Eng = Engine.new(engine number,rotor_prop,max_rpm);
var Engine = {
    new : func(eng_num,rotor_prop,max_rpm){
        m = { parents : [Engine]};
        m.fdensity = getprop("consumables/fuel/tank/density-ppg") or 6.72;
        m.ttl_fuel_lbs = props.globals.getNode("consumables/fuel/total-fuel-lbs",1);
        m.ttl_fuel_lbs.setDoubleValue(10);
        m.MAXrpm=max_rpm;
        m.air_temp = props.globals.getNode("environment/temperature-degc",1);
        m.eng = props.globals.getNode("engines/engine["~eng_num~"]",1);
        m.rotor_rpm = props.globals.getNode(rotor_prop,1);
        m.running = m.eng.getNode("running",1);
        m.fuel_dry = m.eng.getNode("out-of-fuel",1);
        m.fuel_consumed = m.eng.initNode("fuel-consumed-lbs",0.0);
        m.T5 = m.eng.getNode("T5",1);
        m.T5.setDoubleValue(0);
        m.TQ = m.eng.getNode("TQ",1);
        m.TQ.setDoubleValue(0);
        m.magneto = props.globals.getNode("controls/engines/engine["~eng_num~"]/ignition",1);
        m.cutoff = props.globals.getNode("controls/engines/engine["~eng_num~"]/cutoff",1);
        m.rpm = m.eng.getNode("n2",1);
        m.n1 = m.eng.getNode("n1",1);
        m.fuel_pph=m.eng.getNode("fuel-flow_pph",1);
        m.oil_temp=m.eng.getNode("oil-temp-c",1);
        m.oil_temp.setDoubleValue(m.air_temp.getValue());
        m.oil_psi=m.eng.getNode("oil-pressure-psi",1);
        m.oil_psi.setDoubleValue(0);
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
        var oilp = rpm *2;
        if(oilp>95)oilp==95;
        me.oil_psi.setValue(oilp);
        var t5 = me.T5.getValue();
        if(t5<rpm){t5 +=0.01}else{t5-=0.005};
        if(t5<0)t5=0;
        me.T5.setValue(t5);
        var tq = getprop("rotors/main/torque");
        me.TQ.setValue(tq * 0.002857);
}, 

    update_fuel : func(gph){
        var gph_consumed = me.fuel_consumed.getValue();
        var gph_used=0;
         if(me.magneto.getValue()){
            gph_used=(gph*0.00027777)*getprop("sim/time/delta-sec");
        }
        gph_consumed+=(gph_used * me.fdensity);
        me.fuel_consumed.setValue(gph_consumed);
        if(me.fuel_dry.getValue())me.magneto.setValue(0);
       },
};

########################################
var Eng = Engine.new(0,"rotors/main/rpm",293);
var FHmeter = aircraft.timer.new("/instrumentation/clock/flight-meter-sec", 10);
FHmeter.stop();
Cvolume.setDoubleValue(0.0);
Ovolume.setDoubleValue(0.0);

setlistener("/sim/signals/fdm-initialized", func {
    Cvolume.setDoubleValue(0.8);
    Ovolume.setDoubleValue(0.3);
    setprop("/instrumentation/inst-vertical-speed-indicator/serviceable",1);
    setprop("/instrumentation/altimeter/DH",200);
    setprop("/autopilot/settings/altitude-preset",0);
    print("Systems ... Check");
    settimer(update_systems,2);
});

controls.gearDown = func(v) {
    if (v < 0) {
        if(!getprop("gear/gear[1]/wow"))setprop("/controls/gear/gear-down", 0);
    } elsif (v > 0) {
      setprop("/controls/gear/gear-down", 1);
    }
}

setlistener("/sim/signals/reinit", func(ri) {
    Shutdown();
},0,0);

setlistener("/sim/current-view/internal", func(vw){
    if(vw.getValue()){
        Cvolume.setValue(0.8);
        Ovolume.setValue(0.2);
    }else{
        Cvolume.setValue(0.1);
        Ovolume.setValue(1.0);
    }
},0,0);

setlistener("/gear/gear[1]/wow", func(gr){
    if(gr.getBoolValue()){
    FHmeter.stop();
    }else{FHmeter.start();}
},0,0);

setlistener("/sim/model/start-idling", func(idle){
    if(idle.getBoolValue()){
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
if(getprop("consumables/fuel/total-fuel-lbs")>2)setprop("controls/engines/engine[0]/ignition",1);
setprop("engines/engine[0]/running",1);
}

var Shutdown = func{
setprop("controls/electric/engine[0]/generator",0);
setprop("controls/electric/battery-switch",0);
setprop("controls/lighting/instrument-lights",0);
setprop("controls/lighting/nav-lights",0);
setprop("controls/lighting/beacon",0);
setprop("controls/engines/engine[0]/ignition",0);
}

var tcas_range = func(x1){
    tcas_index +=x1;
    if(tcas_index<0)tcas_index=0;
    if(tcas_index>5)tcas_index=5;
    var x2=tcas_list[tcas_index];
    setprop("/instrumentation/tcas/range",x2);
    setprop("/instrumentation/tcas-display/range",x2);
}

var flight_meter = func{
var fmeter = getprop("/instrumentation/clock/flight-meter-sec");
var fminute = fmeter * 0.016666;
var fhour = fminute * 0.016666;
setprop("/instrumentation/clock/flight-meter-hour",fhour);
}

var update_systems = func {
    Eng.update_eng();
    var dt = getprop("sim/time/delta-sec");
    Eng.update_fuel(93); # elapsed seconds,gallons per hour
    flight_meter();
settimer(update_systems,0);
}


