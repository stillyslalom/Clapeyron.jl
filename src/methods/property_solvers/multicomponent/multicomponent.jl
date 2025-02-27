include("rachford_rice.jl")
include("bubble_pressure.jl")
include("azeotrope_pressure.jl")
include("LLE_pressure.jl")
include("VLLE.jl")
include("crit_mix.jl")
include("UCST_mix.jl")
include("UCEP.jl")
#include("PT_flash.jl")
export bubble_pressure, LLE_pressure, VLLE_mix, crit_mix, azeotrope_pressure, UCEP_mix, UCST_mix
