## Introduction

This model, written in Python, expands upon the Richards Equation for the movement of water through unsaturated soils to include preferential flow. Preferential flow occurs when there are cracks or holes in the soil due to, for example, plowing that breaks up aggregates, roots, or wormholes, allowing uneven movement of water through porous media like soils (Cornell University, 2021). The cracks and holes allow for faster water flow than the bulk of the soil. These areas also allow for deeper penetration of water, which could have implications for groundwater quality (Cornell University, 2021).

The code extends the Richards equation to model two fractions in the soil: 1. Fast flow zone, and 2. Slow flow zone. The total flow through porous soil media is determined by the flow in these two domains, modeled using a staggered grid scheme. In this way, the dual porosity concept was implemented where the fast and slow flow zones are described separately; this is appropriate as these zones could have different soil properties. The model couples the preferential flow and unsaturated flow processes to investigate how water flows through porous media under various conditions using different scenarios.  

## Theory and Basic Equations
### Darcy's Law
Concepts that drive the rate of water flow through porous media, such as capillary pressure, hydraulic head and fluid potential, are related to the energy gradient in Darcy’s Law (Pinder and Celia, 2006). The model uses the extended form of Darcy’s law for groundwater flow, as it describes the simultaneous flow of non-homogeneous phases (Mayer, 2005). The modeled system has non-homogeneous phases because it is a porous medium where two immiscible phases are present; this is needed to create capillary pressure that retains water (Mayer, 2005). The extended form of Darcy’s equation is:

$$q_{\alpha} = \frac{\textbf{k}k_{r\alpha}}{\mu_{\alpha}}(\mathbf{\nabla}p_{\alpha}-\rho_{\alpha}\textbf{g})$$

where $q_{\alpha}$ is the water discharge rate in $\frac{L^2}{T}$, \textbf{k} is the permeability in $L^2$, $k_{r\alpha}$ is the relative permeability (dimensionless), $\mu_{\alpha}$ is the dynamic viscosity in Pascals\cdot T, $(\mathbf{\nabla}p_{\alpha}-\rho_{\alpha}\textbf{g})$ is the pressure gradient. Note that L indicates a length-based unit like meters and T indicates a time-based unit like seconds. 
