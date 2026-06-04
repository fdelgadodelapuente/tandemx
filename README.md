
TanDEM-X bistatic interferogram processor (April 2017) for the NASA/Caltech JPL ISCE InSAR sofwtare. The files must be installed in the isce2-2.6.4/contrib/stack/stripmapStack folder.

The implementation follows technical advice provided by Piyush Agram (formerly at JPL). 

To process a bistatic interfeorgram run, create a text file called **tandemxApp.txt** with the following. 

```
alks 4
rlks 4
fs 0.1
tdx_date 20191025
bbox -0.92 -0.64 -91.35 -91.0
mask no
dem /Volumes/T7_Shield/sierra_negra/tandemx12m.dem
unwm icu

```
**20191025** is the name of the CoSSC. Change the DEM path to your prefered file and then run the software with

```
tandemxApp.csh tandemxApp.txt unpack geocode
```

The CoSSC processing is only partially implemented in the software. ISCE can process a bistatic interferogram up to the unwrapping step, but it does not have a module to accurately reconstruct the topography from the phase in slant range. Also, the bistatic geometry does not take into account in the range-Doppler equations for the geocoding. Neglecting these corrections is not very important if your topographic change is less than $\sim$50 m, but can produce very obvious errors in the elevation and the geocoding if you have large topographic changes ($>$ 150 m).
