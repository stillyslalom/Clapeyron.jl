# @info("Loading Plots...")
using Plots
# @info("Loading CSV...")
# using CSV, DataFrames
# @info("Loading Dataframes...")
#### Struct that contains paramaters for PCSAFT ####
struct PCSAFTParam
    segment::Dict
    sigma::Dict
    epsilon::Dict
    epsilon_assoc::Dict
    Bond_vol::Dict
    k::Dict # keys are tuples of every pair
end


#### Types for SAFT models ####
abstract type Saft end

abstract type PCSAFTFamily <: Saft end

struct PCSAFT <: PCSAFTFamily; components; sites; parameters::PCSAFTParam end

segment = Dict()
sigma = Dict()
epsilon = Dict()
epsilon_assoc = Dict()
Bond_vol = Dict()

k = Dict()
components = ["carbon dioxide"]

#### Database lookup ####
# method = "PCSAFT"
# include("Database.jl")
for k_ in components
    # _, dF = lookup(k_, method)
    # println(dF)
    i = 1
    segment[i] = 1.5255
    sigma[i,i] = 3.23*1e-10
    epsilon[i,i] = 188.9
    epsilon_assoc[1,1,1,2] = 2899.5
    epsilon_assoc[1,1,2,1] = 2899.5
    epsilon_assoc[1,1,1,1] = 0
    epsilon_assoc[1,1,2,2] = 0
    Bond_vol[1,1,1,2] = 0.035176
    Bond_vol[1,1,2,1] = 0.035176
    Bond_vol[1,1,1,1] = 0
    Bond_vol[1,1,2,2] = 0
    #= for kk in intersect(keys(all_data["Binary_k"][k]), components) =#

    k[(i,i)] = 0
end


model = PCSAFT([1],[1,2], PCSAFTParam(segment, sigma, epsilon,epsilon_assoc,Bond_vol, k)) # changed comp to [1, 2]
#### Functions relevant to PCSAFT ####
include("Ideal.jl")
include("PCSAFT.jl")
include("Methods.jl")

EoS(z,v,T)    = 8.314*z[1]*T*(a_ideal(model,z,v,T)+a_res(model,z,v,T))
# println(d(model,[1],1e-3,298,1))
# println(g_hsij(model,[1],1e-3,298,1,1))
# println(X_assoc(model,[1],1e-3,298))
# println(a_assoc(model,[1],1e-3,298))
(T_c,p_c,v_c) = Pcrit(EoS,model)
println(T_c)
temperature  = range(220,T_c,length=100)
# z  = ones(size(temperature))
# pressure = 101325*ones(size(temperature))
(P_sat,v_l,v_v) = Psat(EoS,model,temperature)
# H_vap=Enthalpy_of_vapourisation(EoS,model,temperature)
# plt = plot(temperature,H_vap)
# P_exp = [1,1.1,1.2,1.3,1.4,1.5,1.6,1.7,1.785,1.785,1.8,1.9,2,2.1,2.2,2.3,2.4,2.5,2.6,2.7,2.8,2.9,3,3.1,3.2,3.3,3.4,3.5,3.6,3.7,3.8,3.9,4,4.1,4.2,4.3,4.4,4.5,4.6,4.7,4.8,4.9,5]
# V_exp = [0.0018779,0.0016869,0.0015272,0.0013916,0.0012749,0.0011733,0.0010839,0.0010045,0.00094353,4.21E-05,4.21E-05,4.21E-05,4.20E-05,4.20E-05,4.20E-05,4.20E-05,4.20E-05,4.20E-05,4.19E-05,4.19E-05,4.19E-05,4.19E-05,4.19E-05,4.19E-05,4.18E-05,4.18E-05,4.18E-05,4.18E-05,4.18E-05,4.18E-05,4.17E-05,4.17E-05,4.17E-05,4.17E-05,4.17E-05,4.17E-05,4.17E-05,4.16E-05,4.16E-05,4.16E-05,4.16E-05,4.16E-05,4.16E-05]
# plt = plot!(V_exp[1:2:end],P_exp[1:2:end]*1e6,xaxis=:log,fmt=:png,seriestype = :scatter)
# T_exp = [220,230,240,250,260,270,280,290,300]
# P_exp = [0.59913,0.89291,1.2825,1.785,2.4188,3.2033,4.1607,5.3177,6.7131]*1e6
# plt = plot(1 ./temperature,P_sat,yaxis=:log,color=:black)
# plt = plot!([1 ./T_c],[p_c],yaxis=:log,seriestype = :scatter,color=:black)
# plt = plot!(1 ./T_exp,P_exp,yaxis=:log,seriestype = :scatter,color=:red)
plt = plot(0.0320419 ./v_l,temperature,color=:black)
plt = plot!(0.0320419 ./v_v,temperature,color=:black)
plt = plot!(0.0320419 ./[v_c],[T_c],color=:black,seriestype = :scatter)
#
# display(plt)
