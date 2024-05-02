# SLIM Reconstruction
3D Reconstruction code for Squeezed Light field Microscopy (SLIM) using Richardson-Lucy Deconvolution

## Example usage:
0. Examine _User parameters_ section in __RL_SLF_Recon.m__ for correct file path, save path, PSF and SLIM hardware configurations. Current script should have already configured all parameters right.  
1. Run __RL_SLF_Recon.m__ to reconstruct the 3D fluorescent beads data
2. Find results in _examples/beads/Recon_RL/_ and evaluate the tiff stack with ImageJ (or others).

## Included testing data
- /examples/beads/data/beads_100ms_ROI_1455_320_LED/ss_single_1.tiff: fluorescent beads with 29 sub-apertures and under LED illumination
- /examples/beads/PSF_320/0.tiff.tif: an example PSF at z=0

## Testing environment
Tested on Matlab 2022a, 2023a. GPU is highly recommended. 

## Reference
Wang, Zhaoqiang, et al. "Kilohertz volumetric imaging of in-vivo dynamics using squeezed light field microscopy." bioRxiv (2024)

## todo
More testing data and GUI interface





