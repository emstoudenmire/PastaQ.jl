abstract type Optimizer end

"""
SGD
"""
struct Sgd <: Optimizer 
  η::Float64
  γ::Float64
  v::Vector{ITensor}
end

function Sgd(M::Union{MPS,MPO};η::Float64=0.01,γ::Float64=0.0)
  v = ITensor[]
  for j in 1:length(M)
    push!(v,ITensor(zeros(size(M[j])),inds(M[j])))
  end
  return Sgd(η,γ,v)
end

function update!(M::Union{MPS,MPO},∇::Array,opt::Sgd; kwargs...)
  for j in 1:length(M)
    opt.v[j] = opt.γ * opt.v[j] - opt.η * ∇[j]
    M[j] = M[j] + opt.v[j] 
  end
end


"""
ADAGRAD
"""

struct Adagrad <: Optimizer 
  η::Float64
  ϵ::Float64
  ∇²::Vector{ITensor}
end

function Adagrad(M::Union{MPS,MPO};η::Float64=0.01,ϵ::Float64=1E-8)
  ∇² = ITensor[]
  for j in 1:length(M)
    push!(∇²,ITensor(zeros(size(M[j])),inds(M[j])))
  end
  return Adagrad(η,ϵ,∇²)
end

function update!(M::Union{MPS,MPO},∇::Array,opt::Adagrad)
  for j in 1:length(M)
    opt.∇²[j] += ∇[j] .^ 2 
    ∇² = copy(opt.∇²[j])
    ∇² .+= opt.ϵ
    g = sqrt.(∇²)    
    δ = g .^ -1             
    M[j] = M[j] - opt.η * (noprime(∇[j]) ⊙ δ)
  end
end


"""
ADADELTA
"""

struct Adadelta <: Optimizer 
  γ::Float64
  ϵ::Float64
  ∇²::Vector{ITensor}
  Δθ²::Vector{ITensor}
end

function Adadelta(M::Union{MPS,MPO};γ::Float64=0.9,ϵ::Float64=1E-8)
  Δθ² = ITensor[]
  ∇² = ITensor[]
  for j in 1:length(M)
    push!(Δθ²,ITensor(zeros(size(M[j])),inds(M[j])))
    push!(∇²,ITensor(zeros(size(M[j])),inds(M[j])))
  end
  return Adadelta(γ,ϵ,∇²,Δθ²)
end

function update!(M::Union{MPS,MPO},∇::Array,opt::Adadelta; kwargs...)
  for j in 1:length(M)
    # Update square gradients
    opt.∇²[j] = opt.γ * opt.∇²[j] + (1-opt.γ) * ∇[j] .^ 2
    
    # Get RMS signal for square gradients
    ∇² = copy(opt.∇²[j])
    ∇² .+= opt.ϵ
    g1 = sqrt.(∇²)    
    δ1 = g1 .^(-1)

    # Get RMS signal for square updates
    Δθ² = copy(opt.Δθ²[j])
    Δθ² .+= opt.ϵ
    g2 = sqrt.(Δθ²)
    #g2 = sqrt.(opt.Δθ²[j] .+ opt.ϵ)
    Δ = noprime(∇[j]) ⊙ δ1
    Δθ = noprime(Δ) ⊙ g2

    ## Update parameters
    M[j] = M[j] - Δθ

    # Update square updates
    opt.Δθ²[j] = opt.γ * opt.Δθ²[j] + (1-opt.γ) * Δθ .^ 2
  end
end


"""
ADAM
"""

struct Adam <: Optimizer 
  η::Float64
  β₁::Float64
  β₂::Float64
  ϵ::Float64
  ∇::Vector{ITensor}    # m in the paper
  ∇²::Vector{ITensor}   # v in the paper
end

function Adam(M::Union{MPS,MPO};η::Float64=0.001,β₁::Float64=0.9,β₂::Float64=0.999,ϵ::Float64=1E-7)
  ∇ = ITensor[]
  ∇² = ITensor[]
  for j in 1:length(M)
    push!(∇,ITensor(zeros(size(M[j])),inds(M[j])))
    push!(∇²,ITensor(zeros(size(M[j])),inds(M[j])))
  end
  return Adam(η,β₁,β₂,ϵ,∇,∇²)
end

function update!(M::Union{MPS,MPO},∇::Array,opt::Adam; kwargs...)
  t = kwargs[:step]
  for j in 1:length(M)
    # Update square gradients
    opt.∇[j]  = opt.β₁ * opt.∇[j]  + (1-opt.β₁) * ∇[j]
    opt.∇²[j] = opt.β₂ * opt.∇²[j] + (1-opt.β₂) * ∇[j] .^ 2
    
    g1 = opt.∇[j]  ./ (1-opt.β₁^t)
    g2 = opt.∇²[j] ./ (1-opt.β₂^t)
    
    den = sqrt.(g2) 
    den .+= opt.ϵ
    δ = den .^-1
    Δθ = g1 ⊙ δ
    
    # Update parameters
    M[j] = M[j] - opt.η * Δθ
  end
end


"""
ADAMAX
"""

struct Adamax <: Optimizer 
  η::Float64
  β₁::Float64
  β₂::Float64
  ∇::Vector{ITensor}    # m in the paper
  u::Vector{ITensor}   # v in the paper
end

function Adamax(M::Union{MPS,MPO};η::Float64=0.001,β₁::Float64=0.9,β₂::Float64=0.999)
  ∇ = ITensor[]
  u = ITensor[]
  for j in 1:length(M)
    push!(∇,ITensor(zeros(size(M[j])),inds(M[j])))
    push!(u,ITensor(zeros(size(M[j])),inds(M[j])))
  end
  return Adamax(η,β₁,β₂,∇,u)
end

function update!(M::Union{MPS,MPO},∇::Array,opt::Adamax; kwargs...)
  t = kwargs[:step]
  for j in 1:length(M)
    # Update square gradients
    opt.∇[j]  = opt.β₁ * opt.∇[j]  + (1-opt.β₁) * ∇[j]
    opt.u[j]  = max.(opt.β₂ * opt.u[j], abs.(opt.∇[j])) 
    δ = opt.u[j] .^-1
    Δθ = opt.∇[j] ⊙ δ
    # Update parameters
    M[j] = M[j] - (opt.η/(1-opt.β₁^t)) * Δθ
  end
end
