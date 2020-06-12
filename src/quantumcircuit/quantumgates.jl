# Identity
function gate_I()
  return [1.0 0.0;
          0.0 1.0]
end

# Pauli X
function gate_X()
  return [0.0 1.0;
          1.0 0.0]
end

# Pauli Y
function gate_Y()
  return [0.0+0.0im -1.0im;
          1.0im      0.0+0.0im]
end

# Pauli Z
function gate_Z()
  return [1.0  0.0;
          0.0 -1.0]
end

const inv_sqrt2 = 0.7071067811865475

# Hadamard
function gate_H()
  return [inv_sqrt2  inv_sqrt2;
          inv_sqrt2 -inv_sqrt2]
end

# S gate
function gate_S()
  return [1.0+0.0im 0.0im;
          0.0im     1.0im]
end

# T gate
function gate_T()
  return [1.0+0.0im  0.0im;
          0.0im      inv_sqrt2 + inv_sqrt2*im]
end

# Rotation around X axis
function gate_Rx(; θ::Float64)
  return [cos(θ/2.)     -im*sin(θ/2.);
          -im*sin(θ/2.)     cos(θ/2.)]
end

# Rotation around Y axis
function gate_Ry(; θ::Float64)
  return [cos(θ/2.)     -sin(θ/2.);
          sin(θ/2.)     cos(θ/2.)]
end

# Rotation around Z axis
function gate_Rz(; ϕ::Float64)
  return [exp(-im*ϕ/2.)  0;
          0              exp(im*ϕ/2.)]
end

# Rotation around generic axis
function gate_Rn(; θ::Float64,
                   ϕ::Float64,
                   λ::Float64)
  return [cos(θ/2.)                -exp(im*λ) * sin(θ/2.);
          exp(im*ϕ) * sin(θ/2.)    exp(im*(ϕ+λ)) * cos(θ/2.)]
end

# Swap gate
function gate_Sw()
  return [1 0 0 0;
          0 0 1 0;
          0 1 0 0;
          0 0 0 1]
end

# Controlled-X
function gate_Cx()
  return [1 0 0 0;
          0 1 0 0;
          0 0 0 1;
          0 0 1 0]
  #return [1 0 0 0;
  #        0 0 0 1;
  #        0 0 1 0;
  #        0 1 0 0]
end

# Controlled-Y
function gate_Cy()
  #return [1 0 0 0;
  #        0 0 0 -im;
  #        0 0 1 0;
  #        0 im 0 0]
  return [1 0 0 0;
          0 1 0 0;
          0 0 0 -im;
          0 0 im 0]
end

# Controlled-Z
function gate_Cz()
  return [1 0 0 0;
          0 1 0 0;
          0 0 1 0;
          0 0 0 -1]
end

# State preparation: |0> -> |+>
function prep_Xp()
  return gate_H()
end

# State preparation: |0> -> |->
function prep_Xm()
  return [ inv_sqrt2  inv_sqrt2;
          -inv_sqrt2  inv_sqrt2]
end

# State preparation: |0> -> |r>
function prep_Yp()
  return [inv_sqrt2+0.0im   inv_sqrt2+0.0im;
          inv_sqrt2*im     -inv_sqrt2*im]
end

# State preparation: |0> -> |l>
function prep_Ym()
  return [ inv_sqrt2+0.0im  inv_sqrt2+0.0im;
          -inv_sqrt2*im     inv_sqrt2*im]
end

# State preparation: |0> -> |0>
function prep_Zp()
  return gate_I()
end

# State preparation: |0> -> |1>
function prep_Zm()
  return gate_X()
end

# Measurement rotation: |sX> -> |sZ>
function meas_X()
  return gate_H()
end

# Measurement rotation: |sY> -> |sZ>
function meas_Y()
  return [inv_sqrt2+0.0im -inv_sqrt2*im;
          inv_sqrt2+0.0im  inv_sqrt2*im]
end

# Measurement rotation: |sZ> -> |sZ>
function meas_Z()
  return gate_I()
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
                     reverse_order=true,
                     kwargs...)

  if reverse_order
    is = IndexSet(reverse(site_inds)...)
  else
    is = IndexSet(site_inds...)
  end
  return itensor(quantumgates[gate_id](; kwargs...), is'..., is...)
end

measprojections = Dict()
measprojections["X+"] = complex([inv_sqrt2;inv_sqrt2]) 
measprojections["X-"] = complex([inv_sqrt2;-inv_sqrt2])
measprojections["Y+"] = complex([inv_sqrt2;im*inv_sqrt2])
measprojections["Y-"] = complex([inv_sqrt2;-im*inv_sqrt2])
measprojections["Z+"] = complex([1;0])
measprojections["Z-"] = complex([0;1])


function measproj(proj_id::String,
                  site_ind::Index)
  return itensor(measprojections[proj_id], site_ind)
end


