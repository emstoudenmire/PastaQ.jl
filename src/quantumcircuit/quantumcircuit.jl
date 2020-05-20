# Quantum circuit
function initializecircuit(N::Int)
  sites = [Index(2; tags="Site, n=$s") for s in 1:N]
  U = MPO(sites, "Id")
  return U
end

function initializequbits(N::Int)
  if (N==1)
    site = Index(2,tags="Site, n=1")
    m = itensor([1. 0.],site)
    psi = MPS([m])
  else
    sites = [Index(2; tags="Site, n=$s") for s in 1:N]
    psi = productMPS(sites, [1 for i in 1:length(sites)])
  end
  return psi
end

function applygate!(M::MPS,
                   gate_id::String,
                   site::Int;
                   kwargs...)
  site_ind = firstind(M[site],"Site")
  gate = quantumgate(gate_id, site_ind; kwargs...)
  M[site] = gate * M[site]
  noprime!(M[site])
end

function applygate!(M::MPS,gate::ITensor{2})
  site_tag = tags(firstind(gate,"Site"))[2]
  site = parse(Int,String(site_tag)[end])
  M[site] = gate * M[site]
  noprime!(M[site])
end

function applygate!(M::MPS,
                   gate_id::String,
                   site::Array;
                   cutoff = 1e-10,
                   kwargs...)
  
  @assert(abs(site[1]-site[2])==1)

  site_ind1 = firstind(M[site[1]],"Site")
  site_ind2 = firstind(M[site[2]],"Site")
  gate = quantumgate(gate_id,site_ind1,site_ind2; kwargs...)
  
  orthogonalize!(M,site[1])

  blob = M[site[1]] * M[site[2]]
  blob = gate * blob
  noprime!(blob)
  
  if site[1]==1
    row_ind = firstind(blob,tags="n=$(site[1])")
    U,S,V = svd(blob,row_ind,cutoff=cutoff)
    M[site[1]] = U*S
    M[site[2]] = V
  elseif site[1] == length(M)-1
    row_ind = firstind(blob,tags="n=$(site[2])")
    U,S,V = svd(blob,row_ind,cutoff=cutoff)
    M[site[1]] = V
    M[site[2]] = U*S
  else
    row_ind = (commonind(M[site[1]],M[site[1]-1]),
               firstind(blob,tags="n=$(site[1])"))
    U,S,V = svd(blob,row_ind,cutoff=cutoff)
    M[site[1]] = U*S
    M[site[2]] = V
  end
end

function applygate!(M::MPS, gate::ITensor{4}; cutoff = 1e-10)
  site_tags = (tags(inds(gate,plev=1)[1])[2],tags(inds(gate,plev=1)[2])[2])
  s1 = parse(Int,String(site_tags[1])[end])
  s2 = parse(Int,String(site_tags[2])[end])
  @assert(abs(s1-s2)==1)
  orthogonalize!(M,s1)
  blob = M[s1] * M[s2]
  blob = gate * blob
  noprime!(blob)
  if s1==1
    row_ind = firstind(blob,tags="n=$s1")
    U,S,V = svd(blob,row_ind,cutoff=cutoff)
    M[s1] = U*S
    M[s2] = V
  elseif s1 == length(M)-1
    row_ind = firstind(blob,tags="n=$s2")
    U,S,V = svd(blob,row_ind,cutoff=cutoff)
    M[s1] = V
    M[s2] = U*S
  else
    row_ind = (commonind(M[s1],M[s1-1]),
               firstind(blob,tags="n=$s1"))
    U,S,V = svd(blob,row_ind,cutoff=cutoff)
    M[s1] = U*S
    M[s2] = V
  end
end

#function runcircuit(N::Int,gates::Array;psi=nothing,cutoff=1e-10)
#  if isnothing(psi):
#    psi = initializequbits(N)
#  elseif
#    length(psi) != N
#    throw(ArgumentError("Initial state does not match N"))
#  end
#  
#end
