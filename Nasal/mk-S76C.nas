#################### If trim wheels are not on startup trim, you can click the trim reset button #############
var trimBackTime = 3.0;
var applyTrimWheels = func {
    interpolate("/controls/flight/elevator-trim",-0.11, trimBackTime);
    interpolate("/controls/flight/rudder-trim", 0.228, trimBackTime);
    interpolate("/controls/flight/aileron-trim",-0.114, trimBackTime);
}

var applyTrimWheelsZero = func {
    interpolate("/controls/flight/elevator-trim", 0, trimBackTime);
    interpolate("/controls/flight/rudder-trim", 0, trimBackTime);
    interpolate("/controls/flight/aileron-trim", 0, trimBackTime);
}

#setlistener( "/gear/gear/wow", func(v){
#	var v = v.getBoolValue() or 0;
#	applyTrimWheelsZero();
#},1,0);

######################### Autopilot helper F6 key ##########################
#toggle_autopilot = func {
#	var APeng = getprop("autopilot/locks/FD-enabled") or 0;
#	var hdg = getprop("autopilot/locks/heading") or "";
#	if(APeng) {
#		s76c.applyTrimWheelsZero();
#		setprop("autopilot/locks/heading", "");
#		setprop("autopilot/locks/altitude", "");
#	}else{
#        setprop("autopilot/settings/heading-bug-deg", getprop("/orientation/heading-magnetic-deg"));
#		setprop("autopilot/locks/heading", "HDG");
#	}
# 	s76c.FlDr.toggle_autopilot(1);
#	s76c.FlDr.toggle_fd(1);
#}

var toggle_autopilot = func {
		  if(getprop("/autopilot/locks/heading") == "" or getprop("/autopilot/locks/altitude") == ""){
	  		setprop("/autopilot/settings/target-altitude-ft", getprop("/position/altitude-ft"));
	  		setprop("/autopilot/settings/heading-bug-deg", getprop("/orientation/heading-magnetic-deg"));
	  		setprop("/autopilot/locks/altitude", "altitude-hold"); 
	  		setprop("/autopilot/locks/heading", "dg-heading-hold");
	  		setprop("/autopilot/locks/collective", 1);		  
		  }else{
  	  		setprop("/autopilot/locks/altitude", "");
  	  		setprop("/autopilot/locks/heading", "");
  	  		setprop("/autopilot/locks/speed", "");
  	  		setprop("/autopilot/locks/collective", 0);
  	  		setprop("/autopilot/locks/couple", 0);
		  }
}

setlistener("/instrumentation/airspeed-indicator/indicated-speed-kt", func(lowas) {
	var lowas = lowas.getValue() or 0;
	if((getprop("/autopilot/locks/heading") or getprop("/autopilot/locks/altitude") or
	    getprop("/autopilot/locks/collective") or getprop("/autopilot/locks/couple")) and lowas < 30){
		setprop("/autopilot/locks/altitude", "");
		setprop("/autopilot/locks/heading", "");
		setprop("/autopilot/locks/speed", "");
		setprop("/autopilot/locks/collective", 0);
		setprop("/autopilot/locks/couple", 0);
		screen.log.write("AUTOPILOT OFF - YOU ARE ON MANUAL CONTROL NOW!", 0.9, 0.1, 0.0);
	}
});

############################## view helper ###############################
var changeView = func (n){
  var actualView = props.globals.getNode("/sim/current-view/view-number", 1);
  if (actualView.getValue() == n){
    actualView.setValue(0);
  }else{
    actualView.setValue(n);
  }
}

################## Little Help Window on bottom of screen #################
var help_win = screen.window.new( 0, 0, 1, 5 );
help_win.fg = [1,1,1,1];

var messenger = func{
help_win.write(arg[0]);
}
print("Help infosystem started");

var stby_h_altimeter = func {
	var press_inhg = getprop("/instrumentation/standby-altimeter/setting-inhg");
	var press_qnh = getprop("//instrumentation/standby-altimeter/setting-hpa");
	if(  press_inhg == nil ) press_inhg = 0.0;
	if(  press_qnh == nil ) press_qnh = 0.0;
	help_win.write(sprintf("Standby-Baro alt pressure: %.0f hpa %.2f inhg ", press_qnh, press_inhg) );
}

var h_altimeter = func {
	var press_inhg = getprop("/instrumentation/altimeter/setting-inhg");
	var press_qnh = getprop("//instrumentation/altimeter/setting-hpa");
	if(  press_inhg == nil ) press_inhg = 0.0;
	if(  press_qnh == nil ) press_qnh = 0.0;
	help_win.write(sprintf("Baro alt pressure: %.0f hpa %.2f inhg ", press_qnh, press_inhg) );
}

var h_heading = func {
	var press_hdg = getprop("/autopilot/settings/heading-bug-deg");
	if(  press_hdg == nil ) press_hdg = 0.0;
	help_win.write(sprintf("Heading bug: %.0f ", press_hdg) );
}

var h_course = func {
	var press_course = getprop("/instrumentation/nav/radials/selected-deg");
	if(  press_course == nil ) press_course = 0.0;
	help_win.write(sprintf("Selected course is: %.0f ", press_course) );
}

var h_course_two = func {
	var press_course_two = getprop("/instrumentation/nav[1]/radials/selected-deg");
	if(  press_course_two == nil ) press_course_two = 0.0;
	help_win.write(sprintf("Selected course on copilot HSI is: %.0f ", press_course_two) );
}

var h_tas = func {
	var press_tas = getprop("/autopilot/settings/target-speed-kt");
	if(  press_tas == nil ) press_tas = 0.0;
	help_win.write(sprintf("Target speed: %.0f ", press_tas) );
}

var h_vs = func {
	var press_vs = getprop("/autopilot/settings/vertical-speed-fpm");
	if(  press_vs == nil ) press_vs = 0.0;
	help_win.write(sprintf("Vertical speed: %.0f ", press_vs) );
}

var h_mis = func {
	var press_mis = getprop("/instrumentation/rmi/face-offset");
	if(  press_mis == nil ) press_mis = 0.0;
	help_win.write(sprintf("%.0f degrees", press_mis) );
}

var h_set_target_alt = func{
	var set_alt = getprop("/autopilot/settings/target-altitude-ft");
	if(  set_alt == nil ) set_alt = 0.0;
	help_win.write(sprintf("Target altitude: %.0f ", set_alt) );

}

setlistener( "/instrumentation/altimeter/DH", func(v){
	var v = v.getValue() or 0;
	help_win.write(sprintf("Preselected offset altitude: %.0f ft", v) );
},0,1);

setlistener( "/instrumentation/standby-altimeter/setting-inhg", stby_h_altimeter );
setlistener( "/instrumentation/altimeter/setting-inhg", h_altimeter );
setlistener( "/autopilot/settings/heading-bug-deg", h_heading );
setlistener( "/instrumentation/nav/radials/selected-deg", h_course );
setlistener( "/instrumentation/nav[1]/radials/selected-deg", h_course_two );
setlistener( "/autopilot/settings/target-speed-kt", h_tas );
setlistener( "/autopilot/settings/vertical-speed-fpm", h_vs);
setlistener( "/autopilot/settings/target-altitude-ft", h_set_target_alt );
setlistener( "/instrumentation/rmi/face-offset", h_mis);


var show_alti = func {
	var press_inhg = getprop("/instrumentation/altimeter/setting-inhg");
	if(  press_inhg == nil ) press_inhg = 0.0;
	var alt_ft = getprop("/position/gear-agl-ft");
	if(  alt_ft == nil ) alt_ft = 0.0;	
  var s_alti = getprop("/instrumentation/altimeter/indicated-altitude-ft") or 0;
  help_win.write(sprintf("With %.2f inhg the actual altitude is: %.0f ft. AGL is %.0f ft", press_inhg, s_alti, alt_ft) );
}
 
# show the mp or ai aircraft information on the radar

var show_mp_info = func (i){
	var cs  = getprop("instrumentation/mptcas/mp[" ~ i ~ "]/callsign") or "";
	var al  = getprop("instrumentation/mptcas/mp[" ~ i ~ "]/altitude-ft") or 0;
	var as  = getprop("instrumentation/mptcas/mp[" ~ i ~ "]/tas-kt") or 0;
	var dis = getprop("instrumentation/mptcas/mp[" ~ i ~ "]/distance-nm") or 0;
	var code = getprop("instrumentation/mptcas/mp[" ~ i ~ "]/id-code") or "----";

  help_win.write(sprintf(cs~" / %.0fft / %.0fkts / %.2fnm / Transponder-Code: "~code~" ", al, as, dis) ); 
} 

var show_ai_info = func (i){
	var cs  = getprop("instrumentation/mptcas/ai[" ~ i ~ "]/callsign") or "";
	var al  = getprop("instrumentation/mptcas/ai[" ~ i ~ "]/altitude-ft") or 0;
	var as  = getprop("instrumentation/mptcas/ai[" ~ i ~ "]/tas-kt") or 0;
	var dis = getprop("instrumentation/mptcas/ai[" ~ i ~ "]/distance-nm") or 0;

  help_win.write(sprintf(cs~" / %.0fft / %.0fkts / %.2fnm", al, as, dis) );
}

var show_ta_info = func (i){
	var cs  = getprop("instrumentation/mptcas/ta[" ~ i ~ "]/callsign") or "";
	var al  = getprop("instrumentation/mptcas/ta[" ~ i ~ "]/altitude-ft") or 0;
	var as  = getprop("instrumentation/mptcas/ta[" ~ i ~ "]/tas-kt") or 0;
	var dis = getprop("instrumentation/mptcas/ta[" ~ i ~ "]/distance-nm") or 0;

  help_win.write(sprintf(cs~" / %.0fft / %.0fkts / %.2fnm", al, as, dis) );
}