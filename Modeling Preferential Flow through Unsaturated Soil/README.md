## Introduction

This model, written in Python, expands upon the Richards Equation for the movement of water through unsaturated soils to include preferential flow. Preferential flow occurs when there are cracks or holes in the soil due to, for example, plowing that breaks up aggregates, roots, or wormholes, allowing uneven movement of water through porous media like soils (Cornell University, 2021). The cracks and holes allow for faster water flow than the bulk of the soil. These areas also allow for deeper penetration of water, which could have implications for groundwater quality (Cornell University, 2021).

The code extends the Richards equation to model two fractions in the soil: 1. Fast flow zone, and 2. Slow flow zone. The total flow through porous soil media is determined by the flow in these two domains, modeled using a staggered grid scheme. In this way, the dual porosity concept was implemented where the fast and slow flow zones are described separately; this is appropriate as these zones could have different soil properties. The model couples the preferential flow and unsaturated flow processes to investigate how water flows through porous media under various conditions using different scenarios.  

## Theory and Basic Equations
### Darcy's Law
Concepts that drive the rate of water flow through porous media, such as capillary pressure, hydraulic head and fluid potential, are related to the energy gradient in Darcy’s Law (Pinder and Celia, 2006). The model uses the extended form of Darcy’s law for groundwater flow, as it describes the simultaneous flow of non-homogeneous phases (Mayer, 2005). The modeled system has non-homogeneous phases because it is a porous medium where two immiscible phases are present; this is needed to create capillary pressure that retains water (Mayer, 2005). The extended form of Darcy’s equation is:

$$q_{\alpha} = \frac{\textbf{k}k_{r\alpha}}{\mu_{\alpha}}(\mathbf{\nabla}p_{\alpha}-\rho_{\alpha}\textbf{g})$$

where $q_{\alpha}$ is the water discharge rate in $\frac{L^2}{T}$, $\textbf{k}$ is the permeability in $L^2$, $k_{r\alpha}$ is the relative permeability (dimensionless), $\mu_{\alpha}$ is the dynamic viscosity in Pascals $\cdot$ T, $(\mathbf{\nabla}p_{\alpha}-\rho_{\alpha}\textbf{g})$ is the pressure gradient. Note that L indicates a length-based unit like meters and T indicates a time-based unit like seconds. 

### Effective Saturation, Van Genuchten, and Relative Permeability

The Van Genuchten and effective saturation equations are needed to calculate the relative permeability, $k_{r\alpha}$. The Van Genuchten equation models the soil's water retention by relating the water content to the soil’s empirical parameters (Mayer, 2005; Pinder and Celia, 2006).

$$S_{eff}(h_c)= 
\begin{cases}
    [1+(\alpha h_{c})^n]^{-m}   ,& h_{c}>0\\
    1,                           & h_{c}\leq 0
\end{cases}$$

where $\alpha$ is an empirical parameter of the soil in $L^{-1}$ which is the point on the water retention curve where $S_{eff}=0$. $h_{c}$ is the capillary pressure head in length-based unit. $n$ and $m$ are empirical soil parameters where $n=\frac{1}{1-m}$ and $m=1-(\frac{1}{n})$ (Mayer, 2005). With $S_{eff}$ known using the equation above, the volumetric water content, $\theta_{w}$ $(L^3 L^{-3})$, can be calculated via the effective saturation equation as shown in the following equation.

$$S_{eff} = \frac{\theta_{w}-\theta_{res}}{\theta_{sat}-\theta_{res}}$$

while the relative permeability can be found by the following equation (Pinder and Celia, 2006)

$$k_{rw} = (S_{eff})^3$$

### Richard's Equation
The pressure head form of the Richards Equation is as follows. 

$$[C(h_{w}) + S_{w}S^w_{s}]\frac{\delta h_{w}}{\delta t} - \mathbf{\nabla} \cdot [K^w_{sat} k_{rw}(\mathbf{\nabla} h_{w} + \mathbf{\nabla}z)]=0$$

where $K^w_{sat}$ is the saturated hydraulic conductivity in $\frac{L}{T}$, $h_{w}$ is the water pressure head, and $z$ is the depth. Note that negative $z$ indicates a direction from top to bottom of the soil column (away from the surface into deeper layers). $C(h_{w})$ is the differential water capacity which equals $\frac{\delta \theta_{w}}{\delta h_{w}}$. $S_{w}$ is known as the water storage which equals $\frac{\theta_{w}}{\theta_{sat}}$. 

$S^w_{s}$ is the storativity coefficient which is the specific water capacity of the soil, given by the following equation.

$$S^w_{s} = \rho_{w} g (C_v+\epsilon \beta_w)$$

where $C_v$ is the compressibility of the soil, $\epsilon$ is the porosity of the soil, $\beta_w$ is the compressibility of water, $\rho_w$ is the density of water, and $g$ is gravitational acceleration.    

### Dual Porosity Concept
In the dual porosity model, the fast flow fraction can have different soil properties than the slow flow fraction; a Darcy’s Law-based water flow is considered for both porosity systems by using a "first-order coupling term" (Gerke and Van Genuchten, 1993). In this model, the densities of both the solid and liquid phases are constant, and temperature, air pressure, and solute concentration effects are considered to be negligible (Gerke and Van Genuchten, 1993).

The fast and slow flows are modeled based on the extended form of Darcy’s Law.

$$q_{w} = -K_{sat}k_{rel}(\theta_{w}) ({\Delta} h_w+\mathbf{\nabla}z)$$

where $q_w$, $K_{sat}$, $k_{rel}$, and $h_w$ are unique to the respective fast flow and slow flow domains. The hydraulic conductivity, $-K_{sat}k_{rel}$, is a function of the water content. 

In the model, the flows in both the fast and slow zones are coupled by the exchange for water term $Q_{exchange}$. 

$$Q_{exchange} = -k_{ex}(h_{w,fast}-h_{w,slow})$$

where $k_{ex}$ is the rate of exchange of water between the two porosities and $h_w$ is the water pressure head for the fast and slow zones. $k_{ex}$ is a resistance term and expected to be large if there is a barrier like a worm's slimy paste that keeps the holes in place; this interface presents a higher resistivity. Since it is an empirical parameter, it is determined by trial and error. The $Q_{exchange}$ term has the same magnitude at all times for both flow zones, but with different signs in each respective soil fraction. The saturated water content is denoted by the following equation.

$$\theta_{sat} = \theta_{sat,fast} + \theta_{sat,slow}$$

where $\theta_{sat,fast} = \beta \theta_{sat}$ and $\theta_{sat,slow} = (1-\beta) \theta_{sat}$. $\beta$ is the fraction of porosity associated with the fast flow.

The water mass balances for both the fast and slow flow zones, respectively, are as follows.

$$\frac{\delta \theta_{w,fast}}{\delta t} + \mathbf{\nabla} \cdot q_{w,fast} + Q_{exchange} =0$$

$$\frac{\delta \theta_{w,slow}}{\delta t} + \mathbf{\nabla} \cdot q_{w,slow} - Q_{exchange} =0$$

If the $h_{w,fast}$ > $h_{h,slow}$, then the $Q_{exchange}$ is negative, indicating that the water flows from the fast flow zone to slow flow zone.
