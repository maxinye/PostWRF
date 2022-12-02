timelist = asciiread("wrf_time_list.txt", -1, "integer") - 1
load "read_wrfouts.ncl"
wrffile = a
 ;; Convert to kg/kg by mutliplying to 1e-9
dust1 = wrf_user_getvar(wrffile, "DUST_1", -1) * 1e-9
dust2 = wrf_user_getvar(wrffile, "DUST_2", -1) * 1e-9
dust3 = wrf_user_getvar(wrffile, "DUST_3", -1) * 1e-9
dust4 = wrf_user_getvar(wrffile, "DUST_4", -1) * 1e-9
dust5 = wrf_user_getvar(wrffile, "DUST_5", -1) * 1e-9
times = wrf_user_getvar(wrffile,"times",-1)
totallevels = dimsizes(dust4(0,:,0,0))
totallayers = totallevels - 2 ; one for layers, and one for indexing
filler_zero = new(totallevels-1, "float") ;conform to the number of levels
filler_zero = 0
iilon_total = dimsizes(dust4(0,0,0,:))
jjlat_total = dimsizes(dust4(0,0,:,0))
totprofnum = iilon_total*jjlat_total

myname = getenv("tablename")
headermain = (/"!", \
"!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!", \
"! WRF File Name: " + a[0]@SIMULATION_START_DATE, \
"! TOTAL PROFILES (Grid Points): " + totprofnum, \
"! TOTAL LEVELS (in each profile): " + totallevels, \
"! TOTAL LAYERS: " + (totallayers+1), \
"!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!", \
"!", \
"! NB This file must contain data for the same number of profiles as prof.dat.", \
"! For each profile, the first value is an integer. If the value is 1-10", \
"! this indicates that a climatological aerosol profile generated by", \
"! rttov_aer_clim_prof should be used:", \
"!         1  -->Continental clean", \
"!         2  -->Continental average", \
"!         3  -->Continental polluted", \
"!         4  -->Urban", \
"!         5  -->Desert", \
"!         6  -->Maritime clean", \
"!         7  -->Maritime polluted", \
"!         8  -->Maritime tropical", \
"!         9  -->Arctic", \
"!         10 -->Antarctic", \
"!", \
"! Any other value implies that input profiles for all 13 aerosol types", \
"! are provided here.", \
"!", \
"! Flag to indicate aerosol units (T => kg/kg; F => number density cm^-3):", \
"!", \
"T"/)
hlistmain = [/headermain/]

timedim = dimsizes(timelist) - 1
do tt=0, timedim
    ttstep = timelist(tt)
    if (timelist(tt).ge.dimsizes(times)) then
      print(timelist(tt) + " is greater than total number of times (" + dimsizes(times) + ")")
      break
    end if
    print("  Making profiles for time slot " + (ttstep+1) + ": " + times(ttstep) + " ...")
    time_suffix := str_split(times(ttstep), ":")
    tabel_name = myname + "_aerosol_" + time_suffix(0) + ".dat"
    write_table(tabel_name, "w", hlistmain, "%s")
    do jjlatitude=0, jjlat_total-1
        jjlat_title = jjlatitude+1
        kk = jjlatitude * iilon_total
        do iilongitude=0, iilon_total-1
            iilon_title = iilongitude+1
            profnumber = kk + iilon_title
            header = (/"! --- Start of profile (lat, lon):"/)
            prof_num = profnumber + " (" + jjlat_title + ", " + iilon_title + ") out of (" + jjlat_total + ", " + iilon_total + ")"
            hlist = [/header, prof_num/]
            write_table(tabel_name, "a", hlist, "%s%s")
            delete(header)
            delete(hlist)
            header = (/"! Supply the number density profiles here", \
                        "0", \
                        "! Concentration profiles for each aerosol particle type (1-13) for each layer", \
                        "!   INSO     WASO     SOOT     SSAM     SSCM          MINM          MIAM          MICM     MITR     SUSO     VOLA     VAPO     ASDU"/)
            hlist = [/header/]
            write_table(tabel_name, "a", hlist, "%s")
            delete(header)
            delete(hlist)
            mineral_nuc = dust1(ttstep,:totallayers:-1,jjlatitude,iilongitude)
            mineral_acc = dust2(ttstep,:totallayers:-1,jjlatitude,iilongitude) + dust3(ttstep,:totallayers:-1,jjlatitude,iilongitude) + dust4(ttstep,:totallayers:-1,jjlatitude,iilongitude)
            mineral_coa = dust5(ttstep,:totallayers:-1,jjlatitude,iilongitude)
            ;plevels = dust4(ttstep,:totallayers:-1,jjlatitude,iilongitude)
            ; delete(alist)
            alist = [/filler_zero, filler_zero, filler_zero, filler_zero, filler_zero, mineral_nuc, mineral_acc, mineral_coa, filler_zero, filler_zero, filler_zero, filler_zero, filler_zero/]
            write_table(tabel_name, "a", alist, "%8.3f%8.3f%8.3f%8.3f%8.3f%13.9f%13.9f%13.9f%8.3f%8.3f%8.3f%8.3f%8.3f")
        end do ;ii
    end do ;jj
end do ;tt