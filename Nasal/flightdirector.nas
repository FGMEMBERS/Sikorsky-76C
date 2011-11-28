#############################################################################
# Flight Director/Autopilot controller.
# Syd Adams

var FD = {
    new : func{
        m = {parents : [FD]};
        m.LatMode = "ROLL";
        m.VrtMode = "PTCH";
        m.LatArm = " ";
        m.VrtArm = " ";
        m.AP_on = 0;
        m.nav_src = ["VOR1","VOR2","FMS"];
        m.timer=0;
        m.AP_states=[" ","AP ENGAGED","AP FAIL:"];
        m.AP_settings=props.globals.getNode("autopilot/settings",1);
        m.AP_locks=props.globals.getNode("autopilot/locks",1);
        m.AP_internal=props.globals.getNode("autopilot/internal",1);
        m.yawdamper = m.AP_locks.initNode("yaw-damper",0,"BOOL");
        m.lateral = m.AP_locks.initNode("heading","ROLL","STRING");
        m.lateral_armed= m.AP_locks.initNode("heading-armed"," ","STRING");
        m.vertical = m.AP_locks.initNode("altitude","PTCH","STRING");
        m.vertical_armed = m.AP_locks.initNode("altitude-armed","  ","STRING");
        m.AP_state=m.AP_locks.initNode("AP-state",m.AP_states[0],"STRING");
        m.selected_AP=m.AP_locks.initNode("AP-selected",0,"INT");
        m.passive=m.AP_locks.initNode("passive-mode",1,"BOOL");
        m.coll_enabled=m.AP_locks.initNode("collective",0,"BOOL");
        m.coupled=m.AP_locks.initNode("coupled",0,"BOOL");
        m.radalt=m.AP_locks.initNode("radalt",0,"BOOL");
        m.velhld=m.AP_locks.initNode("velocity-hold",0,"BOOL");
        m.FD_enabled=m.AP_locks.initNode("FD-enabled",0,"INT");
        m.NAV_src=m.AP_locks.initNode("nav-source","VOR1","STRING");
        
        m.bank_min=m.AP_settings.initNode("bank-min",-27.0);
        m.bank_max=m.AP_settings.initNode("bank-max",27.0);
        m.vnav_alt=m.AP_settings.initNode("vnav-alt",35000.0);
        m.co=m.AP_settings.initNode("changeover",0,"BOOL");
        m.bc=props.globals.initNode("instrumentation/nav/back-course-btn",0,"BOOL");
        m.target_alt=m.AP_settings.initNode("target-altitude-ft",0.0);
        m.target_spd=m.AP_settings.initNode("target-speed-kt",80.0);
        m.target_vs=m.AP_settings.initNode("target-vs",0,"INT");
        m.target_pitch=m.AP_settings.initNode("target-pitch-deg",0.0);
        m.target_roll=m.AP_settings.initNode("target-roll-deg",0.0);
        m.target_hdg=m.AP_settings.initNode("heading-bug-deg",0.0,"DOUBLE");
        
     return m;
    },

    reset : func{
        me.target_hdg.setValue(0);
        me.target_pitch.setValue(0);
        me.target_vs.setValue(0);
        me.target_spd.setValue(80);
        me.target_alt.setValue(10000);
        me.bc.setValue(0);
        me.co.setValue(0);
        me.vnav_alt.setValue(35000);
        me.bank_max.setValue(27);
        me.bank_min.setValue(-27);
        me.passive.setValue(1);
        me.AP_state.setValue(me.AP_states[0]);
        me.vertical_armed.setValue("");
        me.lateral_armed.setValue("");
        me.vertical.setValue("PTCH");
        me.lateral.setValue("ROLL");
        me.yawdamper.setValue(0);
        print("Flight Director reset");
    },
#### lateral buttons ####
    set_lateral_mode : func(mode){
        if(mode=="bc"){
            var bc = 0;
            if(me.lateral.getValue() == "LOC" or me.lateral_armed.getValue() == "LOC" ){
                if(!me.bc.getValue())bc = 1;
            }
           me.bc.setValue(bc); 
        }else{
        if(me.lateral.getValue()==mode) mode = "ROLL";
        me.LatMode=mode;
        me.lateral.setValue(me.LatMode);
        
        }
    },
 
#### lateral arm buttons ####
    set_lateral_arm_mode : func(mode){
       if(me.lateral_armed.getValue()==mode) mode = " ";
        me.LatArm=mode;  
        me.lateral_armed.setValue(me.LatArm);
    }, 
    
####vertical buttons ####
    set_vertical_mode : func(mode){
        if(me.vertical.getValue()==mode) mode = "PTCH";
        
        if(mode=="ALT"){
            me.target_alt.setValue(getprop("instrumentation/altimeter/mode-c-alt-ft"));;
        }elsif(mode=="FLC"){
            var spd = int(getprop("instrumentation/airspeed-indicator/indicated-speed-kt"));
            me.target_spd.setValue(spd);
        }elsif(mode=="VS"){
            var vs1 = getprop("autopilot/internal/vert-speed-fpm");
            var vspd = int(vs1 * 0.01) * 100;
            me.target_vs.setValue(vspd);
        }
        me.VrtMode=mode;
        me.vertical.setValue(me.VrtMode);
   },

####vertical arm buttons ####
    set_vertical_arm_mode : func(mode){
       if(me.vertical_armed.getValue()==mode) mode = " ";
       me.VrtArm = mode; 
        me.vertical_armed.setValue(me.VrtArm);
    },
    
#### check AP errors####
    check_AP_limits : func(){
        var apmode = me.AP_off.getBoolValue();
        var navunit =me.NAV.getValue();
        me.nav_crs(navunit);
        var tmp_nav="instrumentation/nav["~navunit~"]/";
            me.crs.setValue(getprop(tmp_nav~"radials/selected-deg"));
            me.Defl.setValue(getprop(tmp_nav~"heading-needle-deflection"));
            me.GSDefl.setValue(getprop(tmp_nav~"gs-needle-deflection"));
        if(getprop(tmp_nav~"data-is-valid")){
            me.NavLoc.setValue(getprop(tmp_nav~"nav-loc") or 0);
            me.hasGS.setValue(getprop(tmp_nav~"has-gs") or 0);
            me.navValid.setValue(getprop(tmp_nav~"in-range") or 0);
         }else{
            me.NavLoc.setValue(0);
            me.hasGS.setValue(0);
            me.navValid.setValue(0);
        }

        var agl=getprop("/position/altitude-agl-ft");
        if(!apmode){
            var maxroll = getprop("/orientation/roll-deg");
            var maxpitch = getprop("/orientation/pitch-deg");
            if(maxroll > 65 or maxroll < -65){
                apmode = 1;
            }
            if(maxpitch > 30 or maxpitch < -20){
                apmode = 1;
                setprop("controls/flight/elevator-trim",0);
            }
            if(agl < 180)apmode = 1;
            me.AP_off.setBoolValue(apmode);
        }
        if(agl < 50)me.yawdamper.setBoolValue(0);
        return apmode;
    },

#### autopilot engage####
    toggle_autopilot : func(unit){
        var ap_num = me.selected_AP.getValue();
        var ap_mode = "";
        if(unit == ap_num) unit = 0;
        if(unit >0)ap_mode="AP ENGAGED";
        me.AP_state.setValue(ap_mode);
        me.selected_AP.setValue(unit);
    },

#### flightdirector engage####
    toggle_fd: func(unit){
        var fd_num = me.FD_enabled.getValue();
        if(unit == fd_num) unit = 0;
        me.FD_enabled.setValue(unit);
    },

#### toggle ####
    toggle_bank : func{
       var tmp1= me.bank_max.getValue();
       if(tmp1 == 27)(
            tmp1 = 14
            )else tmp1 = 27;
        me.bank_max.setValue(tmp1);
        me.bank_min.setValue(-tmp1);
    },
 
### set nav src ####
    set_nav_src : func(src){
       if(src == "nav"){
       var tst = me.NAV_src.getValue();
       if(tst =="VOR1")tst = "VOR2" else tst = "VOR1";
       me.NAV_src.setValue(tst);
       }else me.NAV_src.setValue("FMS");
},

#### pitch wheel####
    pitch_wheel : func(amt){
        var factor=amt;
        var vmd = me.vertical.getValue();
        if(vmd=="PTCH"){
            var ptc =me.target_pitch.getValue();
            ptc +=(amt * 0.01);
            if(ptc > 15)ptc = 15;
            if(ptc <-10)ptc=10;
            me.target_pitch.setValue(ptc);
        }elsif(vmd=="VS"){
            ptc = me.target_vs.getValue();
            ptc+= (amt * 100);
            if(ptc>6000)ptc=6000;
            if(ptc<-6000)ptc=-6000;
            me.target_vs.setValue(ptc);
        }elsif(vmd=="FLC"){
            ptc = me.target_spd.getValue();
            ptc+= amt;
            if(ptc>280)ptc=280;
            if(ptc< 80)ptc= 80;
            me.target_spd.setValue(ptc);
        }
    },
#### altitude ###
    update_fd : func{
        #me.check_AP_limits();
    }
};


##################################################
##################################################

var FlDr=FD.new();

setlistener("/sim/signals/fdm-initialized", func {
    
    FlDr.reset();
    settimer(update, 2);
});



var update = func{
FlDr.update_fd();

settimer(update,1);
}