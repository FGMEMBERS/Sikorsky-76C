#############################################################################
# Sperry SPZ-700
# Syd Adams
# Modes: HDG VS ALT NAV ILS DECEL VORAPP IAS ALTPRE BC SBY GA

setlistener("/sim/signals/fdm-initialized", func {
    settimer(update, 2);
});

var input = func(mode){
    if(mode=="HDG"){
        
    }elsif(mode=="VS"){
        
    }elsif(mode=="ALT"){
        
    }elsif(mode=="NAV"){
        
    }elsif(mode=="ILS"){
        
    }elsif(mode=="DECEL"){
        
    }elsif(mode=="VORAPP"){
        
    }elsif(mode=="IAS"){
        
    }elsif(mode=="ASEL"){
        
    }elsif(mode=="BC"){
        
    }elsif(mode=="SBY"){
        
    }elsif(mode=="GA"){
        
    }elsif(mode=="AP"){
        
    }elsif(mode=="FD"){
        
    }
}

var update = func{
FlDr.update_fd();

settimer(update,1);
}