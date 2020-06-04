" STANDARD GATES "

# Identity
function gate_I(i::Index)
  return itensor([1 0;
                  0 1],i',i)
end

function gate_X(i::Index)
  return itensor([0 1;
                  1 0],i',i)
end

function gate_Y(i::Index)
  return itensor([0 -im;
                  im  0],i',i)
end

function gate_Z(i::Index)
  return itensor([1  0;
                  0 -1],i',i)
end

function gate_H(i::Index)
  return (1/sqrt(2.))*itensor([1  1;
                               1 -1],i',i)
end

function gate_S(i::Index)
  return itensor([1  0;
                  0 im],i',i)
end

function gate_T(i::Index)
  return itensor([1  0;
                  0 exp(im*π/4)],i',i)
end

function gate_Rx(i::Index; θ::Float64)
  gate = [cos(θ/2.)     -im*sin(θ/2.);
          -im*sin(θ/2.)     cos(θ/2.)]
  return itensor(gate,i',i)
end

function gate_Ry(i::Index; θ::Float64)
  gate = [cos(θ/2.)     -sin(θ/2.);
          sin(θ/2.)     cos(θ/2.)]
  return itensor(gate,i',i)
end

function gate_Rz(i::Index; ϕ::Float64)
  gate = [exp(-im*ϕ/2.)  0;
          0              exp(im*ϕ/2.)]
  return itensor(gate,i',i)
end

function gate_Rn(i::Index; θ::Float64,
                           ϕ::Float64,
                           λ::Float64)
  gate = [cos(θ/2.)                -exp(im*λ) * sin(θ/2.);
          exp(im*ϕ) * sin(θ/2.)    exp(im*(ϕ+λ)) * cos(θ/2.)]
  return itensor(gate,i',i)
end

function gate_Sw(i::Index,j::Index)
  gate = reshape([1 0 0 0;
                  0 0 1 0;
                  0 1 0 0;
                  0 0 0 1],(2,2,2,2))
  return itensor(gate,i',j',i,j)
end

function gate_Cx(i::Index,j::Index)
  gate = reshape([1 0 0 0;
                  0 0 0 1;
                  0 0 1 0;
                  0 1 0 0],(2,2,2,2))
  return itensor(gate,i',j',i,j)
end

function gate_Cy(i::Index,j::Index)
  gate = reshape([1 0 0 0;
                  0 0 0 -im;
                  0 0 1 0;
                  0 im 0 0],(2,2,2,2))
  return itensor(gate,i',j',i,j)
end

function gate_Cz(i::Index,j::Index)
  gate = reshape([1 0 0 0;
                  0 1 0 0;
                  0 0 1 0;
                  0 0 0 -1],(2,2,2,2))
  return itensor(gate,i',j',i,j)
end

function prep_Xp(i::Index)
  return gate_H(i)
end

function prep_Xm(i::Index)
  return (1/sqrt(2.))*itensor([1  1;
                              -1  1],i',i)
end

function prep_Yp(i::Index)
  return (1/sqrt(2.))*itensor([1   1;
                               im -im],i',i)
end

function prep_Ym(i::Index)
  return (1/sqrt(2.))*itensor([1   1;
                              -im im],i',i)
end

function prep_Zp(i::Index)
  return gate_I(i)
end

function prep_Zm(i::Index)
  return gate_X(i)
end

function meas_X(i::Index)
  return gate_H(i)
end

function meas_Y(i::Index)
  return (1/sqrt(2.))*itensor([1 -im;
                               1 im],i',i)
end

function meas_Z(i::Index)
  return gate_I(i)
end

# A global dictionary of gate functions
quantumgates = Dict()

# Default gates
quantumgates["I"]  = gate_I
quantumgates["X"]  = gate_X
quantumgates["Y"]  = gate_Y
quantumgates["Z"]  = gate_Z
quantumgates["H"]  = gate_H
quantumgates["S"]  = gate_S
quantumgates["T"]  = gate_T
quantumgates["Rx"] = gate_Rx
quantumgates["Ry"] = gate_Ry
quantumgates["Rz"] = gate_Rz
quantumgates["Rn"] = gate_Rn
quantumgates["Sw"] = gate_Sw
quantumgates["Cx"] = gate_Cx
quantumgates["Cy"] = gate_Cy
quantumgates["Cz"] = gate_Cz

quantumgates["pX+"] = prep_Xp
quantumgates["pX-"] = prep_Xm
quantumgates["pY+"] = prep_Yp
quantumgates["pY-"] = prep_Ym
quantumgates["pZ+"] = prep_Zp
quantumgates["pZ-"] = prep_Zm

quantumgates["mX"] = meas_X
quantumgates["mY"] = meas_Y
quantumgates["mZ"] = meas_Z

"""
    quantumgate(gate_id::String,
                site_inds::Index...;
                kwargs...)

Make the specified gate with the specified indices.

# Example
```julia
i = Index(2; tags = "i")
quantumgate("X", i)
```
"""
function quantumgate(gate_id::String,
                     site_inds::Index...;
                     kwargs...)
  return quantumgates[gate_id](site_inds...; kwargs...)
end
