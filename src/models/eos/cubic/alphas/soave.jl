abstract type SoaveAlphaModel <: AlphaModel end

struct SoaveAlphaParam <: EoSParam
    acentricfactor::SingleParam{Float64}
end

@newmodelsimple SoaveAlpha SoaveAlphaModel SoaveAlphaParam

export SoaveAlpha
function SoaveAlpha(components::Vector{String}; userlocations::Vector{String}=String[], verbose::Bool=false)
    params = getparams(components, ["properties/critical.csv"]; userlocations=userlocations, verbose=verbose)
    acentricfactor = SingleParam(params["w"],"acentric factor")
    packagedparams = SoaveAlphaParam(acentricfactor)
    model = SoaveAlpha(packagedparams, verbose=verbose)
    return model
end

function α_function(model::CubicModel,V,T,z,alpha_model::SoaveAlpha)
    Tc = model.params.Tc.values
    ω  = alpha_model.params.acentricfactor.values
    α = @. (1+(0.480+1.547*ω-0.176*ω^2)*(1-√(T/Tc)))^2
    return α
end