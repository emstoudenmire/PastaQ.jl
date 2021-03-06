using PastaQ
using ITensors
using Random
using HDF5

Random.seed!(1234)
N = 4   # Number of qubits
depth=4 # Depth of the quantum circuit
gates = randomcircuit(N,depth)

ψ = runcircuit(N, gates)
U = runcircuit(N, gates; process = true)
ρ = runcircuit(N, gates; noise = ("amplitude_damping", (γ = 0.01,)))
Λ = runcircuit(N, gates; process = true, noise = ("amplitude_damping", (γ = 0.01,)))

Random.seed!(1234)
nshots = 100
data, ψ = getsamples(N, gates, nshots)
savedata(data, ψ, "../examples/data/qst_circuit_test.h5")

data, ρ = getsamples(N, gates, nshots;
                     noise = ("amplitude_damping", (γ = 0.01,)))
savedata(data, ρ, "../examples/data/qst_circuit_noisy_test.h5")

data_in, data_out, U = getsamples(N,gates,nshots;
                                  process=true)
savedata(data_in, data_out, U, "../examples/data/qpt_circuit_test.h5")

data_in, data_out, Λ = getsamples(N,gates,nshots;
                                  process = true,
                                  noise = ("amplitude_damping", (γ = 0.01,)))
savedata(data_in, data_out, Λ, "../examples/data/qpt_circuit_noisy_test.h5")


Random.seed!(1234)
data, Ψ = loaddata("../examples/data/qst_circuit_test.h5")
N = length(Ψ)     # Number of qubits
χ = maxlinkdim(Ψ) # Bond dimension of variational MPS
ψ0 = randomstate(Ψ; χ = χ, σ = 0.1)
opt = SGD(η = 0.01)
ψ = tomography(data, ψ0;
               optimizer = opt,
               batchsize = 100,
               epochs = 2,
               target = Ψ)

data, ϱ = loaddata("../examples/data/qst_circuit_noisy_test.h5")
N = length(ϱ)     # Number of qubits
χ = maxlinkdim(ϱ) # Bond dimension of variational LPDO
ξ = 2             # Kraus dimension of variational LPDO
ρ0 = randomstate(ϱ; mixed = true, χ = χ, ξ = ξ, σ = 0.1)
opt = SGD(η = 0.01)

ρ = tomography(data, ρ0;
               optimizer = opt,
               batchsize = 100,
               epochs = 2,
               target = ϱ)

Random.seed!(1234)
data_in, data_out, U = loaddata("../examples/data/qpt_circuit_test.h5"; process = true)
N = length(U)     # Number of qubits
χ = maxlinkdim(U) # Bond dimension of variational MPS
V0 = randomprocess(U; χ = χ)
opt = SGD(η = 0.1)
V = tomography(data_in, data_out, V0;
               optimizer = opt,
               batchsize = 100,
               epochs = 2,
               target = U)

# Noisy circuit
Random.seed!(1234)
data_in, data_out, ϱ = loaddata("../examples/data/qpt_circuit_noisy_test.h5"; process = true)
N = length(ϱ)
χ = 8
ξ = 2
Λ0 = randomprocess(ϱ; mixed = true, χ = χ, ξ = ξ, σ = 0.1)
opt = SGD(η = 0.1)
Λ = tomography(data_in, data_out, Λ0;
               optimizer = opt,
               mixed = true,
               batchsize = 10,
               epochs = 2,
               target = ϱ)
@show Λ
