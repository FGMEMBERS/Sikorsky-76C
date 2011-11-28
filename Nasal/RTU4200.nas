RTU4200 = {
    new : func(number,comm_num,nav_num,atc_num,adf_num){
        m = { parents : [RTU4200] };
        m.RTU=props.globals.getNode("/instrumentation/RTU4200["~number~"]",1);
        m.comm_sby = props.globals.initNode("instrumentation/comm["~comm_num~"]/frequencies/standby-mhz");
        m.nav_sby = props.globals.initNode("instrumentation/nav["~nav_num~"]/frequencies/standby-mhz");
        m.atc = props.globals.initNode("instrumentation/transponder["~atc_num~"]/id-code");
        m.adf = props.globals.initNode("instrumentation/adf["~adf_num~"]/frequencies/standby-khz");
        m.selected = m.RTU.initNode("selected",0,"INT");
        return m;
    },
   
     set_freq_int: func (dir){
     var mode = me.selected.getValue();
    if(mode==0){
        var commfreq=me.comm_sby.getValue();
        commfreq += dir;
        if(commfreq >135.975) commfreq -=18.000;
        if(commfreq <118.000) commfreq +=18.000;
        me.comm_sby.setValue(commfreq);
    }elsif(mode==1){
        var navfreq=me.nav_sby.getValue();
        navfreq += dir;
        if(navfreq >117.975) navfreq -=10.000;
        if(navfreq <108.000) navfreq +=10.000;
        me.nav_sby.setValue(navfreq);
    }elsif(mode==2){
     
    }elsif(mode==3){
     
    }
    },

set_freq_dec: func (dir){
     var mode = me.selected.getValue();
    if(mode==0){
        var commfreq=me.comm_sby.getValue();
        commfreq += (0.025 * dir);
        if(commfreq >135.975) commfreq -=18.000;
        if(commfreq <118.000) commfreq +=18.000;
        me.comm_sby.setValue(commfreq);
        }elsif(mode==1){
        var navfreq=me.nav_sby.getValue();
        navfreq += (0.05*dir);
        if(navfreq >117.975) navfreq -=10.000;
        if(navfreq <108.000) navfreq +=10.000;
        me.nav_sby.setValue(navfreq);        
    }elsif(mode==2){
     
    }elsif(mode==3){
     
    }
    },
};



var RTU1=RTU4200.new(0,0,0,0,0);
var RTU2=RTU4200.new(1,1,1,0,0);
