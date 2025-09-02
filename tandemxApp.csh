#! /bin/csh
#
# Francisco Delgado, April 2017
# Cornell University / JPL
# 
# Automatically process a TanDEM-X bistatic interferogram.
# Based on the GMTSAR p2p_SAT.csh scripts.
#


###set bbox = "-40.66 -40.38 -72.51 -72.01 "
###set alks = 4
###set rlks = 4
###set fs = 0.3
###set outname = "110829" 
###set dem = "demLat_*.dem.wgs84"
###set dem = "demLat_*_10m.dem.wgs84"

  if ($#argv < 1 ) then
    echo ""
    echo ""
    echo "ISCE TanDEM-X bistatic interferogram processor"
    echo ""
    echo "Francisco Delgado, April 2017"
    echo "Cornell University / Jet Propulsion Laboratory"
    echo "Based on the GMTSAR p2p_SAT.csh scripts"
    echo ""
    echo "Usage:   tdxTDX.csh control_file.txt step1 step2  "
    echo "Example: tdxTDX.csh int150420.txt bistat filter"
    echo "Steps: unpack, baseline, orbit, topo, bistat, flatten, mask, looks, filter, unwrap, geocode"
    echo ""
    echo ""
    echo "Step 01: unpack TanDEM-X data"
    echo "Step 02: calculate baseline"
    echo "Step 03: get orbital information for interferogram flattening and slant range phase to topographic change conversion"
    echo "Step 04: project DEM into range azimuth coordinates"
    echo "Step 05: calculate synthetic phase for bistatic interferogram"
    echo "Step 06: remove flat earth and DEM synthetic phase "
    echo "Step 07: mask layover"
    echo "Step 08: take looks for unwrapping"
    echo "Step 09: filter interferogram"
    echo "Step 10: unwrap interferogram"
    echo "Step 11: geocode interferogram"
    echo ""
    echo ""
    echo "The control file structure is"
    echo "alks 4   			  (azimuth looks)"
    echo "rlks 4   			  (range looks)"
    echo "fs 0.3                            (power spectrum filtering coefficient, 0-1)"
    echo "tdx_date 120325                   (TDX image to be processed)"
    echo "bbox -40.66 -40.38 -72.51 -72.01  (geocode bounding box)"
    echo "mask no			  (mask layover, yes/no)"
    echo "dem  /u/pez-z3/fpuente/caulle/demLat_S42_S39_Lon_W074_W071_10m.dem.wgs84        (DEM, ISCE format)"
    echo "unwm icu"
    echo ""
    echo ""
    exit 1
  endif

clear


###Read inputs and configuration file
set confile = ${1}
set step1 = ${2}
set step2 = ${3}
###echo $1 $2

##if steps are not provided, then process from raw to geocode
if ( $step1 == "" ) then
	set step1 = "unpack"
	set step2 = "geocode"
	###echo $step1
endif


##process a single step 
if ($step2 == "" ) then
	set step2 = $step1
	###echo $step1
endif

echo ""
echo ""
echo "Running TanDEM-X processor"
echo "Processing from $step1 to $step2"


###echo $step1 $step2 $confile
set alks    = `more $confile | grep alks     | awk '{print $2}'`
set rlks    = `more $confile | grep rlks     | awk '{print $2}'`
set fs      = `more $confile | grep fs       | awk '{print $2}'`
set outname = `more $confile | grep tdx_date | awk '{print $2}'`
set bbox    = `more $confile | grep bbox     | awk '{print $2 "  " $3 "  " $4 "  " $5}'`
set dem     = `more $confile | grep dem      | awk '{print $2}'`
set mask    = `more $confile | grep mask     | awk '{print $2}'`
set unwm    = `more $confile | grep unwm     | awk '{print $2}'`


##Set step1 into numbers
if ($step1 == unpack) then
	set step1 = 1
endif
if ($step1 == baseline) then
	set step1 = 2
endif
if ($step1 == orbit) then
	set step1 = 3
endif
if ($step1 == topo) then
	set step1 = 4
endif
if ($step1 == bistat) then
	set step1 = 5
endif
if ($step1 == flatten) then
	set step1 = 6
endif
if ($step1 == mask) then
	set step1 = 7
endif
if ($step1 == looks) then
	set step1 = 8
endif
if ($step1 == filter) then
	set step1 = 9
endif
if ($step1 == unwrap) then
	set step1 = 10
endif
if ($step1 == geocode) then
	set step1 = 11
endif
##Set step2 into numbers
if ($step2 == baseline) then
	set step2 = 2
endif
if ($step2 == orbit) then
	set step2 = 3
endif
if ($step2 == topo) then
	set step2 = 4
endif
if ($step2 == bistat) then
	set step2 = 5
endif
if ($step2 == flatten) then
	set step2 = 6
endif
if ($step2 == mask) then
	set step2 = 7
endif
if ($step2 == looks) then
	set step2 = 8
endif
if ($step2 == filter) then
	set step2 = 9
endif
if ($step2 == unwrap) then
	set step2 = 10
endif
if ($step2 == geocode) then
	set step2 = 11
endif


set tdx = "../${outname}/TDM.SAR.COSSC/*/TDM1*/"
####set active = ${outname}_TSX
####set passive = ${outname}_TDX

    	echo ""
    	echo ""
    	echo "Step 0: Reading configuration file"
    	echo ""	
	echo "$outname TanDEM-X date"	
	echo "$alks azimuth looks"
	echo "$rlks range looks"
	echo "$fs filtering strength"
	set sat_act = `more ../$outname/*/*/*/TDM1*xml | grep bistaticActive -C 2 | grep SAT | awk '{print substr($0,29,4)}'` #check if either TDX or TSX are active
	echo ${sat_act}
	if ($sat_act == SAT1) then
		set active = ${outname}_TSX
		set passive = ${outname}_TDX
	else if ($sat_act == SAT2) then
		set active = ${outname}_TDX
		set passive = ${outname}_TSX
	endif
	endif
    	echo "$active is active image"
    	echo "$passive is passive image"
    	echo ""
	####Bp<0 -> TSX=active, otherwise   Bp>0 -> TDX=active

set bboxl = `echo $bbox | wc -c` #bounding box length
set bbox_window = 0.05

if ($bboxl < 4 ) then
	echo "No bounding box, use image dimensions plus a $bbox_window degrees margin "
	bbox.py -i $active -m $bbox_window 
	bbox.py -i $active -m $bbox_window > bbox.txt
	set bbox_lat = `more bbox.txt | grep Lat | awk '{print $3 "  " $4}'`
	set bbox_lon = `more bbox.txt | grep Lon | awk '{print $3 "  " $4}'`
	set bbox     = "$bbox_lat   $bbox_lon"
	echo "Bounding box $bbox"
endif

if ($step1 <= 1 ) then
    	echo ""
    	echo ""
    	echo "Step 1: Unpacking TanDEM-X data"
    	echo ""
    	echo ""

	unpackFrame_TDX.py -i $tdx -o $outname
endif


if ($step1 <= 2 && $step2 >= 2) then
    	echo ""
    	echo ""
    	echo "Step 2: Calculating perpendicular baselines"
    	echo ""
    	echo ""
	baseline.py -m $active -s $passive                 #reference/secondary
	baseline.py -m $active -s $passive > temp.txt	   #reference/secondary
	more temp.txt | grep Baseline | awk '{print ($4 "   " $5)}' > Bperp.txt   #baselines at top/bottom to text file
	rm temp.txt
endif

if ($step1 <= 3 && $step2 >= 3) then
    	echo ""
    	echo ""
    	echo "Step 3: get orbit info for flattening and phase to topographic change conversion"
    	echo ""
    	echo ""
	rangePix.py -m $active -s $passive
	rangePix.py -m $active -s $passive > temp.txt
	more temp.txt | grep "Starting range master"  | awk '{print $4}' > range0.txt  #Starting slant range for master image
	rm temp.txt
	rangePix.py -s $passive -m $active | grep Wavelength | awk '{print $2}' > wvl.txt
	rangePix.py -s $passive -m $active | grep slantRangePixelSpacing | awk '{print $2}' > rps.txt
	####more rps.txt
	####more wvl.txt
endif

if ($step1 <= 4 && $step2 >= 4 ) then
    	echo ""
    	echo ""
    	echo "Step 4: project DEM into range azimuth coordinates. This is the longest step in the processing"
    	echo ""
    	echo ""
	echo "The DEM is $dem"
    	echo ""
	ln -sf $dem* .  #link DEM in ISCE format
	topo.py -m ${active}/ -d $dem -o geom_active
endif

if ($step1 <= 5 && $step2 >= 5 ) then
    	echo ""
    	echo ""
    	echo "Step 5: calculate synthetic phase for bistatic interferogram "
    	echo ""
    	echo ""
        #bigeo2rdr.py -m ${active}/ -s ${passive}/ -g geom_active/ -o coreg_passive -a ${alks} -r ${rlks}
	bigeo2rdr.py -m ${active}/ -s ${passive}/ -g geom_active/ -o coreg_passive
endif

if ($step1 <= 6 && $step2 >= 6) then
    	echo ""
    	echo ""
    	echo "Step 6: remove flat earth and DEM synthetic phase "
    	echo ""
    	echo ""
	set rps = `more rps.txt`
	set wvl = `more wvl.txt`
	echo "slant range pixel spacing $rps m"
	echo "radar wavelength $wvl m"
	####set form = "a*conj(b)"
	set form = "a*conj(b)*exp(-J*4*PI*${rps}*c/${wvl})"
	echo "$form"  ###requires double quotes to avoid no match error produced by the wildcard character
	imageMath.py -e="${form}" --a=${active}/${active}.slc  --b=${passive}/${passive}.slc --c=coreg_passive/range.off -o bistat.int -t CFLOAT -s BIP
	#####imageMath.py -e='a*conj(b)*exp(-J*4*PI*1.364105*c/0.031067)' --a=${active}/${active}.slc  --b=${passive}/${passive}.slc --c=coreg_passive/range.off -o bistat.int -t CFLOAT -s BIP
endif

if ($step1 <= 7 && $step2 >= 7 ) then
    	echo ""
    	echo ""
    	echo "Step 7: mask layover"
    	echo ""
    	echo ""
	if ($mask == "yes" ) then
    		echo "Applying layover mask from topo.py outputs"
		#maskLayover.py -i bistat.int -m geom_active/shadowMask.rdr -o bistat_masked.int
		imageMath.py -e='a*(b<2 )' --a=bistat.int  --b=geom_active/shadowMask.rdr -t CFLOAT -o bistat_masked.int
	endif
	if ($mask == "no" ) then
    		echo "Skip layover mask, linking files"
		ln -sf bistat.int bistat_masked.int
		ln -sf bistat.int.xml bistat_masked.int.xml
		ln -sf bistat.int.vrt bistat_masked.int.vrt
	endif
endif

if ($step1 <= 8 && $step2 >= 8 ) then
    	echo ""
    	echo ""
    	echo "Step 8: looks for unwrapping and phase to height conversion"
    	echo ""
    	echo ""
	if ( $alks > 1 && $rlks > 1 ) then
		looks.py -i bistat_masked.int -a ${alks} -r ${rlks}
		looks.py -i geom_active/los.rdr -a ${alks} -r ${rlks}
		looks.py -i geom_active/shadowMask.rdr -a ${alks} -r ${rlks}
		looks.py -i coreg_passive/range.off -a ${alks} -r ${rlks}
	endif
	if ( $alks == 1 && $rlks == 1 ) then
    		echo "No multilooking, linking files"
		ln -sf bistat_masked.int         bistat_masked.1alks_1rlks.int
		ln -sf bistat_masked.int.xml     bistat_masked.1alks_1rlks.int.xml
		ln -sf bistat_masked.int.vrt     bistat_masked.1alks_1rlks.int.vrt
		ln -sf geom_active/los.rdr       los.1alks_1rlks.rdr
		ln -sf geom_active/los.rdr.xml   los.1alks_1rlks.rdr.xml
		ln -sf geom_active/los.rdr.vrt   los.1alks_1rlks.rdr.vrt
	endif
endif

if ($step1 <= 9 && $step2 >= 9 ) then
    	echo ""
    	echo ""
    	echo "Step 9: filtering and coherence for unwrapping"
    	echo ""
    	echo ""
	FilterAndCoherence.py -i bistat_masked.${alks}alks_${rlks}rlks.int -f filt_bistat_masked.${alks}alks_${rlks}rlks.int -c bistat_masked.${alks}alks_${rlks}rlks.phsig.cor -s $fs
endif

if ($step1 <= 10 && $step2 >= 10 ) then
    	echo ""
    	echo ""
    	echo "Step 10: unwrapping with ${unwm}"
    	echo ""
    	echo ""
        unwrap.py -i filt_bistat_masked.${alks}alks_${rlks}rlks.int  -u filt_bistat_masked.${alks}alks_${rlks}rlks.unw -c bistat_masked.${alks}alks_${rlks}rlks.phsig.cor -a ${alks} -r ${rlks} -m ${unwm} -s $active
        /home/fdelgado/isce/isce2-2.6.1/contrib/stack/stripmapStack/unwrap2017.py -i filt_bistat_masked.${alks}alks_${rlks}rlks.int  -u filt_bistat_masked.${alks}alks_${rlks}rlks.unw -c bistat_masked.${alks}alks_${rlks}rlks.phsig.cor -a ${alks} -r ${rlks} -m snaphu -s $active

	####maskUnwrap.py -u filt_bistat_masked.${alks}alks_${rlks}rlks.unw -o filt_bistat_masked.${alks}alks_${rlks}rlks_masked.unw #masking is not really required for data with no temporal decorrelation such as TDX
	#####now copy files for phase2topo correction, use phase2topo_tdx.m script and modify header as required
 	cp filt_bistat_masked.${alks}alks_${rlks}rlks.unw     filt_bistat_masked.${alks}alks_${rlks}rlks_rads.unw  #copy files for phase2topo conversion
	cp filt_bistat_masked.${alks}alks_${rlks}rlks.unw.xml filt_bistat_masked.${alks}alks_${rlks}rlks_rads.unw.xml
	cp filt_bistat_masked.${alks}alks_${rlks}rlks.unw.vrt filt_bistat_masked.${alks}alks_${rlks}rlks_rads.unw.vrt
endif

if ($step1 <= 11 && $step2 >= 11 ) then
    	echo ""
    	echo ""
    	echo "Step 11: geocoding unwrapped interferogram"
    	echo ""
    	echo ""
	###if ($mask == "yes" ) then
    	###	echo "Applying layover mask from topo.py outputs"
	###	ln -sf  geom_active/mask.${alks}alks_${rlks}.rdr*
	###	maskUnwrapLayover.py -u filt_bistat_masked.${alks}alks_${rlks}rlks.unw -m mask.${alks}alks_${rlks}.rdr
	###endif
	###if ($mask == "no" ) then
    	###	echo "Skip layover mask, linking files"
	###	ln -sf filt_bistat_masked.${alks}alks_${rlks}rlks.unw filt_bistat_masked.${alks}alks_${rlks}rlks_masked.unw
	###	ln -sf filt_bistat_masked.${alks}alks_${rlks}rlks.unw.xml filt_bistat_masked.${alks}alks_${rlks}rlks_masked.unw.xml
	###	ln -sf filt_bistat_masked.${alks}alks_${rlks}rlks.unw.vrt filt_bistat_masked.${alks}alks_${rlks}rlks_masked.unw.vrt
	###endif
	###echo "Geocoding bounding box ${bbox}" 
        geocode.py -a ${alks} -r ${rlks} -d $dem -i filt_bistat_masked.${alks}alks_${rlks}rlks.unw_icu.unw -m ${active}/ -b $bbox
	geocode.py -a ${alks} -r ${rlks} -d $dem -i filt_bistat_masked.${alks}alks_${rlks}rlks.unw -m ${active}/ -b $bbox
	geocode.py -a ${alks} -r ${rlks} -d $dem -i filt_bistat_masked.${alks}alks_${rlks}rlks_hgt.unw -m ${active}/ -b $bbox
####	geocode.py -a ${alks} -r ${rlks} -d $dem -i filt_bistat_masked.${alks}alks_${rlks}rlks_rads.unw -m ${active}/ -b $bbox  #THIS IS NOT WORKING, CHECK WHY?????	
endif

    	echo ""
    	echo ""
    	echo "Processing done at step $step2 out of 11"
    	echo ""
    	echo ""

if ($step2 == 11 ) then
    	echo "Interferogram done !! "
    	echo ""
    	echo ""

	mdx.py filt_bistat_masked.${alks}alks_${rlks}rlks.unw.geo &
	mdx.py filt_bistat_masked.${alks}alks_${rlks}rlks.unw.geo -kml filt_bistat_masked.${alks}alks_${rlks}rlks.unw.geo.kml &
endif
