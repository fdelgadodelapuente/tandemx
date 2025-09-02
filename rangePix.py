#!/usr/bin/env python3

import numpy as np 
import argparse
import os
import isce
import isceobj
import datetime
import shelve
import stdproc
import json
import logging
from mroipac.baseline.Baseline import Baseline
from isceobj.Planet.Planet import Planet
from stdproc.stdproc import crossmul
from isceobj.Util.Poly2D import Poly2D
from iscesys.ImageUtil.ImageUtil import ImageUtil as IU
from isceobj.Constants import SPEED_OF_LIGHT


def cmdLineParse():
    '''
    Command line parser.
    '''

    parser = argparse.ArgumentParser( description='Output slant range pixel size')
    parser.add_argument('-m', type=str, dest='master', required=True,
            help='Directory with the master image')
    parser.add_argument('-s', type=str, dest='slave', required=True,
            help='Directory with the slave image')

    return parser.parse_args()


if __name__ == '__main__':
    '''
    Display wavelength and range pixel size, then remove reference phase of bistatic int.
    '''

    inps = cmdLineParse()

    try:
        mdb = shelve.open( os.path.join(inps.master, 'data'), flag='r')
    except:
        mdb = shelve.open( os.path.join(inps.master, 'raw'), flag='r')

    mFrame = mdb['frame']

    try:
        sdb = shelve.open( os.path.join(inps.slave, 'data'), flag='r')
    except:
        sdb = shelve.open( os.path.join(inps.slave, 'raw'), flag='r')


    sFrame = sdb['frame']

    print(mFrame)
    #print(mFrame.getInstrument())

    mdb.close()
    sdb.close()
    imag=sFrame
    imag=mFrame


    ##### ------- Velocity calculation, must be run with stripmapProc, not with 201704 version
    #import isceobj.StripmapProc.StripmapProc as St
    #stObj = St()
    #stObj.configure(	
    #frame = stObj.loadProduct("120205_TDX/120205_TDX.slc.xml")    
    #elp = Planet(pname='Earth').ellipsoid
    #tmid = frame.sensingMid
	#
 	#sv = frame.orbit.interpolateOrbit( tmid, method='hermite') #.getPosition()
  	#llh = elp.xyz_to_llh(sv.getPosition())
	#
	#
	#hdg = frame.orbit.getENUHeading(tmid)
	#elp.setSCH(llh[0], llh[1], hdg)
	#sch, vsch = elp.xyzdot_to_schdot(sv.getPosition(), sv.getVelocity()) #position and velocity in SCH
    #print(vsch)

    ##### ------- Velocity calculation

    rps_s = sFrame.startingRange
    rps_m = mFrame.startingRange
    ###farRange_m = mFrame.FarRange
    fsamp = mFrame.rangeSamplingRate
    prf = mFrame.PRF
    #print(mFrame.__dict__) ##print all variables in mFrame
    #print(imag.__dict__) ##print all variables in mFrame
    sch_vel = mFrame.schVelocity
    print(mFrame.schVelocity)
    #print('SCH velocity: %f %f'%(sch_vel(1), sch_vel(1))) 
    slantRangePixelSpacing = 0.5 * SPEED_OF_LIGHT / fsamp
    wvl   = imag.getInstrument().getRadarWavelength()
    delr  = imag.getInstrument().getRangePixelSize()
    #r0 = imag.getInstrument().getRange()
    print('Wavelength: %.60f %.60f'%(wvl,wvl))
    print('RangePixelSize: %.60f %.60f'%(delr,delr))
    print('slantRangePixelSpacing: %.60f %.60f'%(slantRangePixelSpacing,slantRangePixelSpacing))
    print('Starting range slave: %f %f'%(rps_s,rps_s))
    print('Starting range master: %f %f'%(rps_m,rps_m))
   #### print('far range master: %f %f'%(farRange_m,farRange_m))
    print('PRF: %f %f'%(prf,prf))
    ##print('RangePixelSize: %f %f'%(r0,r0))
    ##mm = inps.master + "/" + inps.master + ".slc"
    ##ss = inps.slave + "/" + inps.slave + ".slc"
    ##print(inps.master)
    ##print(inps.slave)
    ##print(mm)

#    imageMath.py -e='a*conj(b)*exp(-J*4*PI*delr*c/wvl)' --a=mm  --b=ss --c=coreg_passive/range.off -o bistat.int -t CFLOAT -s BIP

