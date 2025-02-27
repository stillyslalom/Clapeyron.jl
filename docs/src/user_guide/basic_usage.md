# Clapeyron User Guide

Welcome to Clapeyron!

Once Clapeyron is installed, it can be loaded using:

```julia
using Clapeyron
```

We may create a model object by calling the constructor of the respective equation of state. For example,

```julia
model1 = PCSAFT(["methanol"])
model2 = PR(["ethane", "water"])
model3 = GERG2008(["propane","pentane"])
```

We also support group-contribution models like SAFT-*ɣ* Mie. We have a database of species with the number of each group associated with it for easy lookup, but you may also use your own combinations. We use a tuple of the name of the molecule and an array of the group-multiplicity mappings. For example

```julia
model4 = SAFTgammaMie([
        "ethanol",
        ("ibuprofen", ["CH3"=>3, "COOH"=>1, "aCCH"=>1, "aCCH2"=>1, "aCH"=>4])])
```

One can find out more about the information stored within these model objects in the API documentation. In terms of equations of state available, we have the following default models:

**Cubics**:

- `vdW`
- `RK`
  - `SRK`
  - `PSRK`
- `PR`
  - `PR78`
  - `UMRPR`
  - `VTPR`

**SAFT**:

- `ogSAFT`
- `CKSAFT`
  - `sCKSAFT`
- `BACKSAFT`
- `LJSAFT`
- `SAFTVRSW`
- `CPA`
- `softSAFT`
- `PCSAFT`
  - `sPCSAFT`
- `SAFTVRMie`
  - `SAFTVRQMie`
- `SAFTgammaMie`

**Activity coefficient** (N.B. these models only provide VLE properties for mixtures):

- `Wilson`
- `NRTL`
- `UNIQUAC`
- `UNIFAC`
- `COSMOSAC`
  - `COSMOSAC02`
  - `COSMOSAC10`
  - `COSMOSACdsp`

**Empirical**:

- `GERG2008`
- `IAPWS95`
- `PropaneRef`

We also support the `SPUNG` model. One can find out more about each of these equations of state within our background documentation. Nevertheless, all of these equations are compatible with all methods availble in our package. 

There a few optional arguments available for these equations which will be explained below. One of these is specifying the location of the parameter databases, the details of which can be found in our Custom databases documentation.

### Specifying an ideal term

Both SAFT and cubic-type equations of state rely upon an ideal model. By default, Clapeyron uses what we refer to as the `BasicIdeal` model to account for the ideal contribution which does not require any parameters. For properties which only have derivatives with respect to volume or composition (_e.g._ volume, isothermal compressibility, critical points, saturation points), or monoatomic species (_e.g._ noble gases), this is perfectly fine. However, for any other properties or species, the results obtained will most likely be quite poor. This is because this model does not account for the rotational and vibrational modes of the species. To amend this, we provide three additional ideal models to be used instead (more to come):

- Walker and Haslam's ideal correlation (`WalkerIdeal`)
- Joback's ideal correlation (`JobackIdeal`)
- Reid's polynomial correlation (`ReidIdeal`)

These can be specified for any of the SAFT or cubic-type equations of state using:

```julia
model5 = PCSAFT(["carbon dioxide"]; idealmodel = WalkerIdeal)
```

Everything else will work as normal.

### Specifying an alpha function

Both RK and PR cubic equations rely on an alpha function (SRK is technically just RK but with a different alpha function). Whilst we use the defaults for both RK and PR, it is possible to toggle between them. For example:

```julia
model6 = RK(["ethane","propane"];alpha=SoaveAlpha)
```

The above model would be equivalent to a model built by SRK directly. We support the following alpha functions (more to come):

- `RKAlpha`: This is the default alpha function for regular RK .
- `SoaveAlpha`: This is the default alpha function for SRK.
- `PRAlpha`: This is the default alpha function for regular PR.
- `PR78Alpha`: This is the default alpha function for PR78.
- `BMAlpha`: This is the modified alpha function proposed by Boston and Mathias designed to improve estimates above the critical point. This works for both PR and RK.
- `TwuAlpha`: Proposed by Twu _et al._, this alpha function uses species-specific parameters rather than correlation and, thus, is slightly more accurate than regular alpha functions. It was intended to be used with PR and is used in VTPR.
- `MTAlpha`: Proposed by Magoulas and Tassios, this alpha function is essentially like the regular PR alpha function only to a higher order. It is used within UMRPR.

### Specifying a mixing rule

Only relevant to cubic equations of state and mixtures, we can alternate between different mixing rules in case these may result in better predictions. We can toggle between these mixing rules:

```julia
model7 = RK(["ethane","propane"];mixing=KayRule)
```

We currently only support:

- `vdW1fRule`: The standard van der Waals one-fluid mixing rule which is the default in all cubics.

- `KayRule`: Takes an approach closer to the mixing rules used in SAFT.

- `HVRule`: The Huron-Vidal mixing rule with uses information from activity coefficient models to form the mixing rule. It is meant to be more accurate than regular mixing rules. As it requires an activity coefficient model, this must be specified:

  ```julia
  model7 = RK(["methanol","benzene"];mixing=HVRule,activity=Wilson)
  ```

- `MHV1Rule`: The modified Huron-Vidal mixing rule proposed by Michelsen to first order. This has rather significant improvements over the regular mixing rule. Also needs an activity model to be specified.

- `MHV2Rule`: The modified Huron-Vidal mixing rule proposed by Michelsen to second order. This is meant to be an improvement over the first order rule. Also needs an activity model to be specified.

- `WSRule`: The Wong-Sandler mixing rule which also relies on an activity model. The equations are slightly more complicated but it is meant to be an improvement compared to `HVRule`. Also needs an activity model to be specified.

- `LCVMRule`: The Linear Combiniation of Vidal and Michelsen mixing rules is designed for asymmetric mixtures. Also needs an activity model to be specified.

If one goes looking within the source code, they will also find `VTPRRule`, `PSRKRule` and `UMRRule`; these are only intended for use in their respective models and shouldn't be used otherwise. However, it is still possible to toggle between them.

### Specifying a volume translation method

In order to improve the predictions of bulk properties in cubics, without affecting VLE properties, a volume translation method can be used which simply shifts the volume within the cubics by `c`. The default for all cubics is `NoTranslation`, however, we can toggle between the methods:

```julia
model7 = RK(["ethane","propane"];translation=PenelouxTranslation)
```

We support the following methods:

- `PenelouxTranslation`: Used in PSRK.
- `RackettTranslation`: Used in VTPR.
- `MTTranslation`: Used in UMRPR.

Note that not all these methods will be compatible with all species as they require the critical volume of the species.

### Using an Activity coefficient model

Activity coefficient models are primarily designed to obtain accurate estimate of mixture VLE properties _below_ the critical point of all species. Whilst not as flexible as other equations of state, they are computationally cheaper and, generally, more accurate. The activity coefficients are obtained as only a function of temperature and composition ($\gamma (T,\mathbf{x})$), meaning we can simply use modified Raoult's law to obtain the bubble (and dew) point:

``y_ip= x_i\gamma_ip_{\mathrm{sat},i}``

The only problem here is that another model must provide the saturation pressure $p_{\mathrm{sat},i}$. By default, this is chosen to be PR; however, one can toggle this setting as well:

```julia
model3 = UNIFAC(["methanol","benzene"];puremodel=PCSAFT)
```

Everything else will work as normal (so long as the species are also available within the specified pure model).

### Available properties

Once we have our model object, we will be able to call the respective thermodynamic methods to obtain the properties that we are looking for. For example, to find the isobaric heat capacity of a 0.5 mol methanol and 0.5 mol ethanol mixture using PC-SAFT at a pressure of 10 bar and a temperature of 300 K, we just call the `isobaric_heat_capacity(model, p, T, z)` function with the desired model and conditions as parameters.

```julia
Cp = isobaric_heat_capacity(model1, 10e5, 300, [0.5, 0.5])
```

The functions for the physical properties that we currently support are as follows:

- Bulk properties:

  ```julia
  V = volume(model, p, T, z)
  p = pressure(model, V, T, z)
  S = entropy(model, p, T, z)
  mu = chemical_potential(model, p, T, z)
  U = internal_energy(model, p, T, z)
  H = enthalpy(model, p, T, z)
  G = Gibbs_free_energy(model, p, T, z)
  A = Helmholtz_free_energy(model, p, T, z)
  Cv = isochoric_heat_capacity(model, p, T, z)
  Cp = isobaric_heat_capacity(model, p, T, z)
  betaT = thermal_compressibility(model, p, T, z)
  betaS = isentropic_compressibility(model, p, T, z)
  u = speed_of_sound(model, p, T, z)
  alphaV = isobaric_expansitivity(model, p, T, z)
  muJT = joule_thomson_coefficient(model, p, T, z)
  Z = compressibility_factor(model, p, T, z)
  gamma = activity_coefficients(model, p, T, z)
  ```

  All the above functions have two optional arguments (although, technically, z is an optional argument if you're only obtaining properties for a pure species):

  - `phase`: If you already know the phase of the species and want a (minor) speed-up, you can specify it. For example:

    ```julia
    V = volume(model, p, T, z; phase=:liquid)
    ```

    The default value is `:unknown` where it will find both the vapour and liquid roots first and determine which has the lowest Gibbs free energy.

  - `threaded`: This determines whether or not to run the vapour and liquid calculations in parallel or not and is only relevant for when the phases are unknown and non-cubic models. 

    ```
    V = volume(model, p, T, z; threaded=false)
    ```

    The default value is `true`. This shouldn't change the results.

  Note that all of the above functions can be broadcast _i.e._ if `T` is an array, instead of a for loop, we can simply:

  ```julia
  Cp = isobaric_heat_capacity.(model, p, T, z)
  ```

- Vapour-liquid, liquid-liquid and vapour-liquid-liquid equilibrium properties:

  - For pure species:

    ```julia
    (p_sat, V_l_sat, V_v_sat) = sat_pure(model, T)
    H_vap = enthalpy_vap(model, T)
    ```

  - For mixtures:

    ```julia
    (p_sat, V_l_sat, V_v_sat, y) = bubble_pressure(model, T, x)
    (p_LLE, V_l_LLE, V_ll_LLE, xx) = LLE_pressure(model, T, x)
    (p_az, V_l_sat, V_v_sat, x) = azeotrope_pressure(model, T)
    (p_VLLE,V_l_sat, V_ll_sat, V_v_sat, x, xx, y) = VLLE_mix(model, T)
    ```

  All the above arguments take in an optional argument for the initial guess:

  ```julia
  (p_sat, V_l_sat, V_v_sat) = sat_pure(model, T;v0=log10.([V_l0,V_v0]))
  ```

  Although our calculations tend to be quite robust, this argument is generally useful for when one wants to obtain smooth VLE envelopes quicly when making figures. Here, you'd use a for loop where each iteration uses the previous' iteration value as an initial guess (except the first iteration). For example:

  ```julia
  (p_sat, V_l_sat, V_v_sat) = sat_pure(model, T[1])
  for i in 2:length(T)
    A = sat_pure(model,T[i];v0=log10.([V_l_sat[i-1],V_v_sat[i-1]]))
    append!(p_sat,A[1])
    append!(V_l_sat,A[2])
    append!(V_v_sat,A[3])
  end
  ```

- Critical properties:

  - For pure species:

    ```julia
    (T_c, p_c, V_c) = crit_pure(model)
    ```

  - For mixtures:

    ```julia
    (T_c, p_c, V_c) = crit_mix(model, z)
    (p_UCST, V_UCST, x_UCST) = UCST_mix(model, T)
    (T_UCEP, p_UCEP, V_l_UCEP, V_v_UCEP, x, y) = UCEP_mix(model)
    ```

  Like the above functions, for `crit_mix`, you can also specify initial guesses to produce smooth critical curves. 

- Miscellaneous:

  ```julia
  T = inversion_temperature(model, p, z)
  B = second_virial_coefficient(model, T, z)
  ```

`Clapeyron` also supports physical units through the use of `Unitful.jl`.

```julia
using Unitful
import Unitful: bar, °C, mol

Cp2 = isobaric_heat_capacity(model1, 5bar, 25°C, [0.5mol, 0.5mol])
```

Note that if you do not wish to import specific units, you may also just use a Unitful string, `pressure = 20u"psi"`. This is only supported for bulk properties.

## Customisation

Although we provide many models, methods and parameters, Clapeyron also allows for easy customisation in all three of these aspects. To find out more how to customise your models, please read the relevant sections in the documentation.
