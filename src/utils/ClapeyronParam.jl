abstract type ClapeyronParam end


"""
    SingleParam{T}

Struct designed to contain single parameters. Basically a vector with some extra info.

## Creation:
```julia-repl
julia> mw = SingleParam("molecular weight",["water","ammonia"],[18.01,17.03])
SingleParam{Float64}("molecular weight") with 2 components:
 "water" => 18.01
 "ammonia" => 17.03

julia> mw.values
2-element Vector{Float64}:
 18.01
 17.03

julia> mw.components
2-element Vector{String}:
 "water"
 "ammonia"

julia> mw2 = SingleParam(mw,"new name")
SingleParam{Float64}("new name") with 2 components:
 "water" => 18.01
 "ammonia" => 17.03

julia> has_oxigen = [true,false]; has_o = SingleParam(mw2,has_oxigen)
SingleParam{Bool}("new name") with 2 components:
 "water" => true
 "ammonia" => false

```

## Example usage in models:

```
function molecular_weight(model,molar_frac)
    mw = model.params.mw.values
    res = zero(eltype(molarfrac))
    for i in @comps #iterating through all components
        res += molar_frac[i]*mw[i]
    end
    return res
end
```
"""
struct SingleParam{T} <: ClapeyronParam
    name::String
    components::Array{String,1}
    values::Array{T,1}
    ismissingvalues::Array{Bool,1}
    sourcecsvs::Array{String,1}
    sources::Array{String,1}
end

function Base.show(io::IO, param::SingleParam)
    print(io, typeof(param), "(\"", param.name, "\")[")
    for component in param.components
        component != first(param.components) && print(io, ",")
        print(io, "\"", component, "\"")
    end
    print(io, "]")
end

function Base.show(io::IO, ::MIME"text/plain", param::SingleParam)
    len = length(param.values)
    print(io, typeof(param), "(\"", param.name)
    println(io, "\") with ", len, " component", ifelse(len==1, ":", "s:"))
    i = 0
    for (name, val, miss) in zip(param.components, param.values, param.ismissingvalues)
        i += 1
        if i > 1
            println(io)
        end
        if miss == false
            if typeof(val) <: AbstractString
                print(io, " \"", name, "\" => \"", val, "\"")
            else
                print(io, " \"", name, "\" => ", val)
            end
        else
            print(io, " \"", name, " => -")
        end
    end
end

function SingleParam(x::SingleParam{T},name=x.name) where T
    return SingleParam(name, x.components,deepcopy(x.values), deepcopy(x.ismissingvalues), x.sourcecsvs, x.sources)
end

#a barebones constructor, in case we dont build from csv
function SingleParam(
    name::String,
    components::Vector{String},
    values::Vector{T},
    sourcecsvs = String[],
    sources = String[]
    ;default = _zero(T)) where T
    _values,_ismissingvalues = defaultmissing(values,default)
    TT = eltype(_values)
    return  SingleParam{TT}(name,components, _values, _ismissingvalues, sourcecsvs, sources)
end

function SingleParam(x::SingleParam, v::Vector)
    _values,_ismissingvalues = defaultmissing(v)
    return SingleParam(x.name, x.components,_values, _ismissingvalues , x.sourcecsvs, x.sources)
end
"""
    PairParam{T}

Struct designed to contain pair data. used a matrix as underlying data storage.

## Creation:
```julia-repl
julia> kij = PairParam("interaction params",["water","ammonia"],[0.1 0.0;0.1 0.0])
PairParam{Float64}["water", "ammonia"]) with values:
2×2 Matrix{Float64}:
 0.1  0.0
 0.1  0.0

julia> kij.values
2×2 Matrix{Float64}:
 0.1  0.0
 0.1  0.0

julia> kij.diagvalues
2-element view(::Vector{Float64}, 
1:3:4) with eltype Float64:
 0.1
 0.0
```

## Example usage in models:

```julia
#lets compute ∑xᵢxⱼkᵢⱼ
function alpha(model,x)
    kij = model.params.kij.values
    ki = model.params.kij.diagvalues
    res = zero(eltype(molarfrac))
    for i in @comps 
        @show ki[i] #diagonal values
        for j in @comps 
            res += x[i]*x[j]*kij[i,j]
        end
    end
    return res
end
```
"""
struct PairParam{T} <: ClapeyronParam
    name::String
    components::Array{String,1}
    values::Array{T,2}
    diagvalues::SubArray{T, 1, Vector{T}, Tuple{StepRange{Int64, Int64}}, true}
    ismissingvalues::Array{Bool,2}
    sourcecsvs::Array{String,1}
    sources::Array{String,1}
end

function PairParam(name::String,
                    components::Array{String,1},
                    values::Array{T,2},
                    sourcecsvs::Array{String,1} = String[], 
                    sources::Array{String,1} = String[]) where T
    
    _values,_ismissingvalues = defaultmissing(values)
    diagvalues = view(_values, diagind(_values))

    return PairParam{T}(name, components,_values, diagvalues, _ismissingvalues, sourcecsvs, sources)
end

function PairParam(x::PairParam,name::String=x.name)
    values = deepcopy(x.values)
    diagvalues = view(values,diagind(values))
    return PairParam(name, x.components,values ,diagvalues, deepcopy(x.ismissingvalues), x.sourcecsvs, x.sources)
end

function PairParam(x::SingleParam,name::String=x.name)
    pairvalues = singletopair(x.values,missing)
    for i in 1:length(x.values)
        if x.ismissingvalues[i]
            pairvalues[i,i] = missing
        end
    end
    _values,_ismissingvalues = defaultmissing(pairvalues)
    diagvalues = view(_values, diagind(_values))
    return PairParam(name, x.components, _values,diagvalues,_ismissingvalues,x.sourcecsvs, x.sources)
end

function PairParam(x::PairParam, v::Matrix,name::String=x.name)
    return PairParam(name, x.components,deepcopy(v), x.sourcecsvs, x.sources)
end
function PairParam(x::SingleParam, v::Vector,name::String=x.name)
    pairvalues = singletopair(v,missing)
    return PairParam(x.name, x.components, pairvalues,x.sourcecsvs, x.sources)
end
function PairParam(x::SingleParam, v::Matrix,name::String=x.name)
    return PairParam(x.name, x.components, deepcopy(v),x.sourcecsvs, x.sources)
end

#barebones constructor by list of pairs.


function Base.show(io::IO,mime::MIME"text/plain",param::PairParam)
    print(io,"PairParam{",string(typeof(param)),"}")
    show(io,param.components)
    println(io,") with values:")
    show(io,mime,param.values)
end

function Base.show(io::IO,param::PairParam)
    print(io,"PairParam(",param.name)
    print(io,"\"",param.name,"\"",")[")
    for (name,val,miss,i) in zip(param.components,param.values,param.ismissingvalues,1:length(param.values))
        i != 1 && print(io,",")
        if miss == false
            print(io,name,"=",val)
        else
            print(io,name,"=","-")
        end
    end
    print(io,"]")
end
"""
    AssocParam{T}

Struct holding association parameters.
"""
struct AssocParam{T} <: ClapeyronParam
    name::String
    components::Array{String,1}
    values::Array{Array{T,2},2}
    ismissingvalues::Array{Array{Bool,2},2}
    allcomponentsites::Array{Array{String,1},1}
    sourcecsvs::Array{String,1}
    sources::Array{String,1}
end

function AssocParam(x::AssocParam{T}) where T
    return PairParam{T}(x.name,x.components, deepcopy(x.values), deepcopy(x.ismissingvalues), x.allcomponentsites, x.sourcecsvs, x.sources)
end

function AssocParam{T}(x::AssocParam, v::Matrix{Matrix{T}}) where T
    return AssocParam{T}(x.name, x.components,deepcopy(v), deepcopy(x.ismissingvalues), x.allcomponentsites, x.sourcecsvs, x.sources)
end

function Base.show(io::IO,mime::MIME"text/plain",param::AssocParam{T}) where T
    print(io,"AssocParam{",string(T),"}")
    show(io,param.components)
    println(io,") with values:")
    show(io,mime,param.values)
end

function Base.show(io::IO,param::AssocParam)
    print(io,"AssocParam(",param.name)
    print(io,"\"",param.name,"\"",")[")
    for (name,val,miss,i) in zip(param.components,param.values,param.ismissingvalues,1:length(param.values))
        i != 1 && print(io,",")
        if miss == false
            print(io,name,"=",val)
        else
            print(io,name,"=","-")
        end
    end
    print(io,"]")
end
const PARSED_GROUP_VECTOR_TYPE =  Vector{Tuple{String, Vector{Pair{String, Int64}}}}

"""
    GroupParam

Struct holding group parameters.contains:
* `components`: a list of all components
* `groups`: a list of groups names for each component
* `i_groups`: a list containing the number of groups for each component
* `n_groups`: a list of the group multiplicity of each group corresponding to each group in `i_groups`
* `flattenedgroups`: a list of all unique groups--the parameters correspond to this list
* `n_flattenedgroups`: the group multiplicities corresponding to each group in `flattenedgroups`
* `i_flattenedgroups`: an iterator that goes through the indices for each flattened group

You can create a group param by passing a `Vector{Tuple{String, Vector{Pair{String, Int64}}}}.
For example:
```julia-repl
julia> grouplist = [
           ("ethanol", ["CH3"=>1, "CH2"=>1, "OH"=>1]), 
           ("nonadecanol", ["CH3"=>1, "CH2"=>18, "OH"=>1]),
           ("ibuprofen", ["CH3"=>3, "COOH"=>1, "aCCH"=>1, "aCCH2"=>1, "aCH"=>4])];

julia> groups = GroupParam(grouplist)
GroupParam with 3 components:
 "ethanol": "CH3" => 1, "CH2" => 1, "OH" => 1
 "nonadecanol": "CH3" => 1, "CH2" => 18, "OH" => 1    
 "ibuprofen": "CH3" => 3, "COOH" => 1, "aCCH" => 1, "aCCH2" => 1, "aCH" => 4

julia> groups.flattenedgroups
7-element Vector{String}:
 "CH3"
 "CH2"
 "OH"
 "COOH"
 "aCCH"
 "aCCH2"
 "aCH"

julia> groups.i_groups
3-element Vector{Vector{Int64}}:
 [1, 2, 3]
 [1, 2, 3]
 [1, 4, 5, 6, 7]

julia> groups.n_groups
3-element Vector{Vector{Int64}}:
 [1, 1, 1]
 [1, 18, 1]
 [3, 1, 1, 1, 4]

julia> groups.n_flattenedgroups
 3-element Vector{Vector{Int64}}:
 [1, 1, 1, 0, 0, 0, 0]
 [1, 18, 1, 0, 0, 0, 0]
 [3, 0, 0, 1, 1, 1, 4]
```

if you have CSV with group data, you can also pass those, to automatically query the missing groups in your input vector:

```julia-repl
julia> grouplist = [
           "ethanol", 
           ("nonadecanol", ["CH3"=>1, "CH2"=>18, "OH"=>1]),
           ("ibuprofen", ["CH3"=>3, "COOH"=>1, "aCCH"=>1, "aCCH2"=>1, "aCH"=>4])];

           julia> groups = GroupParam(grouplist, ["SAFT/SAFTgammaMie/SAFTgammaMie_groups.csv"])
           GroupParam with 3 components:
            "ethanol": "CH2OH" => 1, "CH3" => 1
            "nonadecanol": "CH3" => 1, "CH2" => 18, "OH" => 1    
            "ibuprofen": "CH3" => 3, "COOH" => 1, "aCCH" => 1, "aCCH2" => 1, "aCH" => 4
```
In this case, `SAFTGammaMie` files support the second order group `CH2OH`.

"""
struct GroupParam <: ClapeyronParam
    components::Array{String,1}
    groups::Array{Array{String,1},1}
    n_groups::Array{Array{Int,1},1}
    i_groups::Array{Array{Int,1},1}
    flattenedgroups::Array{String,1}
    n_flattenedgroups::Array{Array{Int,1},1}
    i_flattenedgroups::UnitRange{Int}
    sourcecsvs::Array{String,1}
end

function GroupParam(input::PARSED_GROUP_VECTOR_TYPE,sourcecsvs::Vector{String}=String[],options::ParamOptions = ParamOptions())
    components = [first(i) for i ∈ input]
    raw_groups =  [last(i) for i ∈ input]
    groups = [first.(grouppairs) for grouppairs ∈ raw_groups]
    n_groups = [last.(grouppairs) for grouppairs ∈ raw_groups]
    flattenedgroups = unique!(reduce(vcat,groups))
    i_groups = [[findfirst(isequal(group), flattenedgroups) for group ∈ componentgroups] for componentgroups ∈ groups]
    len_flattenedgroups = length(flattenedgroups)
    i_flattenedgroups = 1:len_flattenedgroups
    n_flattenedgroups = [zeros(Int,len_flattenedgroups) for _ ∈ 1:length(input)]
    for i in length(input)
        setindex!.(n_flattenedgroups,n_groups,i_groups)
    end

    return GroupParam(components, 
    groups, 
    n_groups,
    i_groups, 
    flattenedgroups,
    n_flattenedgroups, 
    i_flattenedgroups,
    sourcecsvs)
end

function Base.show(io::IO, mime::MIME"text/plain", param::GroupParam)
    print(io,"GroupParam ")
    len = length(param.components)
    println(io,"with ", len, " component", ifelse(len==1, ":", "s:"))
    
    for i in 1:length(param.components)
        
        print(io, " \"", param.components[i], "\": ")
        firstloop = true
        for j in 1:length(param.n_groups[i])
            firstloop == false && print(io, ", ")
            print(io, "\"", param.groups[i][j], "\" => ", param.n_groups[i][j])
            firstloop = false
        end
        i != length(param.components) && println(io)
    end 
end

function Base.show(io::IO, param::GroupParam)
    print(io,"GroupParam[")
    len = length(param.components)
    
    for i in 1:length(param.components)
        
        print(io, "\"", param.components[i], "\" => [")
        firstloop = true
        for j in 1:length(param.n_groups[i])
            firstloop == false && print(io, ", ")
            print(io, "\"", param.groups[i][j], "\" => ", param.n_groups[i][j])
            firstloop = false
        end
        print(io,']')
        i != length(param.components) && print(io,", ")
    end
    print(io,"]")
end

"""
    SiteParam

Struct holding site parameters.
Is built by parsing all association parameters in the input CSV files.
It has the following fields:
* `components`: a list of all components (or groups in Group Contribution models)
* `sites`: a list containing a list of all sites corresponding to each component (or group) in the components field
* `n_sites`: a list of the site multiplicities corresponding to each site in `flattenedsites`
* `flattenedsites`: a list of all unique sites
* `i_sites`: an iterator that goes through the indices corresponding  to each site in `flattenedsites`
* `n_flattenedsites`: the site multiplicities corresponding to each site in `flattenedsites`
* `i_flattenedsites`: an iterator that goes through the indices for each flattened site

Let's explore the sites in a 3-component `SAFTGammaMie` model:

```julia

julia> model3 = SAFTgammaMie([    
                "ethanol",
                ("nonadecanol", ["CH3"=>1, "CH2"=>18, "OH"=>1]),     
                ("ibuprofen", ["CH3"=>3, "COOH"=>1, "aCCH"=>1, "aCCH2"=>1, "aCH"=>4])
                               ])

SAFTgammaMie{BasicIdeal} with 3 components:
 "ethanol"
 "nonadecanol"
 "ibuprofen"
Contains parameters: segment, shapefactor, lambda_a, lambda_r, sigma, epsilon, epsilon_assoc, bondvol 

julia> model3.sites
SiteParam with 8 sites:
 "CH2OH": "H" => 1, "e1" => 2     
 "CH3": (no sites)
 "CH2": (no sites)
 "OH": "H" => 1, "e1" => 2        
 "COOH": "e2" => 2, "H" => 1, "e1" => 2
 "aCCH": (no sites)
 "aCCH2": (no sites)
 "aCH": (no sites)

julia> model3.sites.flattenedsites
3-element Vector{String}:
 "H"
 "e1"
 "e2"

julia> model3.sites.i_sites       
8-element Vector{Vector{Int64}}:
 [1, 2]
 []
 []
 [1, 2]
 [1, 2, 3]
 []
 []
 []

julia> model3.sites.n_sites       
8-element Vector{Vector{Int64}}:
 [1, 2]
 []
 []
 [1, 2]
 [2, 1, 2]
 []
 []
 []
```
"""
struct SiteParam <: ClapeyronParam
    components::Array{String,1}
    sites::Array{Array{String,1},1}
    n_sites::Array{Array{Int,1},1}
    i_sites::Array{Array{Int,1},1}
    flattenedsites::Array{String,1}
    n_flattenedsites::Array{Array{Int,1},1}
    i_flattenedsites::UnitRange{Int}
    sourcecsvs::Array{String,1}
end


function Base.show(io::IO, mime::MIME"text/plain", param::SiteParam)
    print(io,"SiteParam ")
    len = length(param.components)
    println(io,"with ", len, " site", ifelse(len==1, ":", "s:"))
    
    for i in 1:length(param.components)
        
        print(io, " \"", param.components[i], "\": ")
        firstloop = true
        if length(param.n_sites[i]) == 0
            print(io,"(no sites)")
        end
        for j in 1:length(param.n_sites[i])
            firstloop == false && print(io, ", ")
            print(io, "\"", param.sites[i][j], "\" => ", param.n_sites[i][j])
            firstloop = false
        end
        i != length(param.components) && println(io)
    end 
end

function Base.show(io::IO, param::SiteParam)
    print(io,"SiteParam[")
    len = length(param.components)
    
    for i in 1:length(param.components)
        
        print(io, "\"", param.components[i], "\" => [")
        firstloop = true
    
        for j in 1:length(param.n_sites[i])
            firstloop == false && print(io, ", ")
            print(io, "\"", param.sites[i][j], "\" => ", param.n_sites[i][j])
            firstloop = false
        end
        print(io,']')
        i != length(param.components) && print(io,", ")
    end
    print(io,"]")
end


function SiteParam(pairs::Dict{String,SingleParam{Int}},allcomponentsites)
    arbitraryparam = first(values(pairs))
    components = arbitraryparam.components
    sites = allcomponentsites
    
    sourcecsvs = String[]
    for x in values(pairs)
        vcat(sourcecsvs,x.sourcecsvs)  
    end
    if length(sourcecsvs) >0
        unique!(sourcecsvs)
    end
    n_sites = [[pairs[sites[i][j]].values[i] for j ∈ 1:length(sites[i])] for i ∈ 1:length(components)]  # or groupsites
    length_sites = [length(componentsites) for componentsites ∈ sites]
    i_sites = [1:length_sites[i] for i ∈ 1:length(components)]
    flattenedsites = unique!(reduce(vcat,sites,init = String[]))
    len_flattenedsites = length(flattenedsites)
    i_flattenedsites = 1:len_flattenedsites
    n_flattenedsites = [zeros(Int,len_flattenedsites) for _ ∈ 1:length(components)]
    for i in length(components)
        setindex!.(n_flattenedsites,n_sites,i_sites)
    end
    return SiteParam(components, 
    sites, 
    n_sites,
    i_sites, 
    flattenedsites,
    n_flattenedsites, 
    i_flattenedsites,
    sourcecsvs)
end

function SiteParam(input::PARSED_GROUP_VECTOR_TYPE,sourcecsvs::Vector{String}=String[])
    components = [first(i) for i ∈ input]
    raw_sites =  [last(i) for i ∈ input]
    sites = [first.(sitepairs) for sitepairs ∈ raw_sites]
    n_sites = [last.(sitepairs) for sitepairs ∈ raw_sites]
    flattenedsites = unique!(reduce(vcat,sites,init = String[]))
    i_sites = [[findfirst(isequal(site), flattenedsites) for site ∈ componentsites] for componentsites ∈ sites]
    len_flattenedsites = length(flattenedsites)
    i_flattenedsites = 1:len_flattenedsites
    n_flattenedsites = [zeros(Int,len_flattenedsites) for _ ∈ 1:length(input)]
    for i in length(input)
        setindex!.(n_flattenedsites,n_sites,i_sites)
    end

    return SiteParam(components, 
    sites, 
    n_sites,
    i_sites, 
    flattenedsites,
    n_flattenedsites, 
    i_flattenedsites,
    sourcecsvs)
end

function SiteParam(components::Vector{String})
    n = length(components)
    return SiteParam(
    components,
    [String[] for _ ∈ 1:n],
    [Int[] for _ ∈ 1:n],
    [Int[] for _ ∈ 1:n],
    String[],
    [Int[] for _ ∈ 1:n],
    1:0,
    String[])
end

paramvals(param::ClapeyronParam) = param.values
paramvals(x) = x





