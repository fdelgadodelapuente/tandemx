Add-ons for the NASA/Caltech JPL ISCE InSAR sofwtare. The packages have to be installed in the isce2-2.6.4/contrib/stack/stripmapStack folder.

TanDEM-X bistatic interferogram processor (April 2017). Implementation follows technical advice provided by Piyush Agram (formerly at JPL). To run, it create a text file called tandemxApp.txt with the following

alks 4

rlks 4

fs 0.1

tdx_date 20191025

bbox -0.92 -0.64 -91.35 -91.0

mask no

dem /Volumes/T7_Shield/sierra_negra/tandemx12m.dem

unwm icu

and then run tandemxApp.csh tandemxApp.txt unpack geocode
