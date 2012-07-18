#############################################################################
# Sperry SPZ-700
# Syd Adams
# Modes: HDG VS ALT NAV ILS DECEL VORAPP IAS ALTPRE BC SBY GA

var AP_lat=props.globals.initNode("autopilot/locks/heading","SBY");
var AP_lat_arm=props.globals.initNode("autopilot/locks/heading-arm","","STRING");
var AP_vrt=props.globals.initNode("autopilot/locks/altitude","SBY");
var AP_vrt_arm=props.globals.initNode("autopilot/locks/altitude-arm","","STRING");
var AP=props.globals.initNode("autopilot/locks/AP",0,"INT");
var FD=props.globals.initNode("autopilot/locks/FD",0,"INT");
var NAVSRC="NAV";
var NAVloc=props.globals.initNode("instrumentation/nav/nav-loc",0,"BOOL");
var NAVgs=props.globals.initNode("instrumentation/nav/has-gs",0,"BOOL");


var Lmode="";
var LAmode="";
var Vmode="";
var VAmode="";

setlistener("/sim/signals/fdm-initialized", func {
    settimer(update, 2);
});

setlistener("autopilot/locks/nav-source", func(nv){
    NAVSRC = nv.getValue();
},1,0);

setlistener(AP_lat, func(x1){
    Lmode = x1.getValue();
},1,0);

setlistener(AP_lat_arm, func(x2){
    LAmode = x2.getValue();
},1,0);

setlistener(AP_vrt, func(y1){
    Vmode =y1.getValue();
},1,0);

setlistener(AP_vrt_arm, func(y2){
    VAmode =y2.getValue();
},1,0);


var input = func(mode){
    if(mode=="HDG"){
        if(Lmode!="HDG") AP_lat.setValue("HDG") else AP_lat.setValue("SBY");
    }elsif(mode=="VS"){
        if(Vmode!="VS") AP_vrt.setValue("VS") else AP_vrt.setValue("SBY");
    }elsif(mode=="ALT"){
        if(Vmode!="ALT") AP_vrt.setValue("ALT") else AP_vrt.setValue("SBY");
    }elsif(mode=="NAV"){
        set_nav();
    }elsif(mode=="ILS"){
        
    }elsif(mode=="DECEL"){
        
    }elsif(mode=="VORAPP"){
        
    }elsif(mode=="IAS"){
        
    }elsif(mode=="ASEL"){
        
    }elsif(mode=="BC"){
        
    }elsif(mode=="SBY"){
        AP_lat.setValue("SBY");
        AP_vrt.setValue("SBY");
    }elsif(mode=="GA"){
        
    }elsif(mode=="AP1"){
        if(AP.getValue()!=1)AP.setValue(1) else AP.setValue(0);
    }elsif(mode=="AP2"){
        if(AP.getValue()!=2)AP.setValue(2) else AP.setValue(0);
    }elsif(mode=="FD1"){
        if(FD.getValue()!=1)FD.setValue(1) else FD.setValue(0);
    }elsif(mode=="FD2"){
        if(FD.getValue()!=2)FD.setValue(2) else FD.setValue(0);
    }
}

var pitchwheel=func(x5){
    if(Vmode=="VS"){
        var tmpvs=getprop("autopilot/settings/target-vs");
        tmpvs+=(x5*100);
        if(tmpvs>2000)tmpvs=2000;
        if(tmpvs<-2000)tmpvs=-2000;
        setprop("autopilot/settings/target-vs",tmpvs);
    }
}

var set_nav=func{
    if(NAVSRC=="NAV"){
        if(LAMode!="NAV"){
            AP_lat_arm.setValue("NAV");
            AP_lat.setValue("HDG");
        }else AP_lat_arm.setValue("");
    }elsif(NAVSRC=="FMS"){
        AP_lat_arm.setValue("");
        if(Lmode !="LNAV") AP_lat.setValue("LNAV") else AP_lat.setValue("");
        }
    }

var update = func{

settimer(update,1);
}