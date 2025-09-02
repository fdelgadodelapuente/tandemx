#!/usr/bin/env python3
import argparse
import isce
import isceobj
import numpy as np
import shelve
import os
import datetime 
from isceobj.Constants import SPEED_OF_LIGHT
from isceobj.Util.Poly2D import Poly2D

def cmdLineParse():
    '''
    Command line parser.
    '''

    parser = argparse.ArgumentParser( description='Create DEM simulation for merged images')
    parser.add_argument('-a','--alks', dest='alks', type=int, default=1,
            help = 'Number of azimuth looks')
    parser.add_argument('-r','--rlks', dest='rlks', type=int, default=1,
            help = 'Number of range looks')
    parser.add_argument('-m', '--master', dest='master', type=str, required=True,
            help = 'Dir with master frame')
    parser.add_argument('-g', '--geom', dest='geom', type=str, default=None,
            help = 'Dir with geometry products')
    parser.add_argument('-s', '--slave', dest='slave', type=str, required=True,
            help = 'Dir with slave frame')
    parser.add_argument('-o', '--outdir', dest='outdir', type=str, default=None,
            help='Output directory')
    parser.add_argument('-n', '--native', dest='native', action='store_true',
            default=False, help='Use native doppler geometry')
    parser.add_argument('-l', '--legendre', dest='legendre', action='store_true',
            default=False, help='Use legendre polynomials for orbit interpolation')
    
    inps =  parser.parse_args()

    if inps.master.endswith('/'):
        inps.master = inps.master[:-1]

    if inps.slave.endswith('/'):
        inps.slave = inps.slave[:-1]

    if inps.geom is None:
        inps.geom = 'geometry_' + os.path.basename(inps.master)

    if inps.outdir is None:
        inps.outdir = os.path.join('coreg', os.path.basename(inps.slave))

    return inps


def runGeo2rdr(minfo, sinfo,
        latImage, lonImage, demImage, outdir,
        dop=None, nativedop=False, legendre=False,
        alks=1, rlks=1, azoff=0.0, rgoff=0.0):
    from zerodop.bistaticgeo2rdr.BistaticGeo2rdr import BistaticGeo2rdr
    from isceobj.Planet.Planet import Planet

    #####Run Topo
    planet = Planet(pname='Earth')
    topo = BistaticGeo2rdr()
    topo.configure()

    topo.slantRangePixelSpacing = minfo.getInstrument().getRangePixelSize()
    topo.prf = minfo.getInstrument().getPulseRepetitionFrequency()
    topo.radarWavelength = minfo.getInstrument().getRadarWavelength()
    topo.activeOrbit = minfo.getOrbit()
    topo.passiveOrbit = sinfo.getOrbit()
    topo.width = minfo.getImage().getWidth()
    topo.length = minfo.getImage().getLength()
    topo.wireInputPort(name='planet', object=planet)
    topo.lookSide =  minfo.instrument.platform.pointingDirection

    topo.setSensingStart(minfo.sensingStart - datetime.timedelta(seconds = (azoff-(alks-1)/2)/topo.prf))
    topo.activeRangeFirstSample = minfo.getStartingRange() - (rgoff - (rlks-1)/2)*topo.slantRangePixelSpacing
    topo.passiveRangeFirstSample = sinfo.getStartingRange() - (azoff - (alks-1)/2)*topo.slantRangePixelSpacing
    topo.numberRangeLooks = alks
    topo.numberAzimuthLooks = rlks

    if nativedop and (dop is not None):
        try:
            coeffs = [x/topo.prf for x in dop._coeffs]
        except:
            coeffs = [x/topo.prf for x in dop]

        topo.dopplerCentroidCoeffs = coeffs
    else:
        print('Zero doppler')
        topo.dopplerCentroidCoeffs = [0.]

    topo.fmrateCoeffs = [0.]

    topo.rangeOffsetImageName = os.path.join(outdir, 'range.off')
    topo.azimuthOffsetImageName= os.path.join(outdir, 'azimuth.off')
    topo.demImage = demImage
    topo.latImage = latImage
    topo.lonImage = lonImage

    if legendre:
        topo.orbitInterpolationMethod = 'LEGENDRE'

#    topo.outputPrecision = 'DOUBLE'
    topo.bistaticgeo2rdr()

    return


if __name__ == '__main__':

    
    inps = cmdLineParse()
    
    
    with shelve.open( os.path.join(inps.slave, 'data'), flag='r') as db:
        sframe = db['frame']


    with shelve.open( os.path.join(inps.master, 'data'), flag='r') as db:
        mframe = db['frame']

    ####Setup dem
    demImage = isceobj.createDemImage()
    #demImage.load(os.path.join(inps.geom, 'z.rdr.xml'))
    demImage.load(os.path.join(inps.geom, 'hgt.rdr.xml'))
    demImage.setAccessMode('read')

    latImage = isceobj.createImage()
    latImage.load(os.path.join(inps.geom, 'lat.rdr.xml'))
    latImage.setAccessMode('read')

    lonImage = isceobj.createImage()
    lonImage.load(os.path.join(inps.geom, 'lon.rdr.xml'))
    lonImage.setAccessMode('read')

    if not os.path.isdir(inps.outdir):
        os.mkdir(inps.outdir)

    
    ####Setup input file
    runGeo2rdr(mframe,sframe, 
            latImage,lonImage,demImage, inps.outdir, 
            nativedop = inps.native, legendre=inps.legendre,
            alks=inps.alks, rlks=inps.rlks)




