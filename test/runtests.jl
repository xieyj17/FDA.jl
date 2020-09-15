using FDA
using Test
using CSV

@testset "FDA.jl" begin
    df = CSV.read("sample.csv")
    y = df[:,2:251];

    temp_basis = gen_fourier_basis([0,1],15)
    argvals = range(0,1;length = 101)
    temp_coefs = Data2fd(argvals, y, temp_basis)

    smooth_curve = eval_fd(argvals, temp_coefs)

    plot(argvals, smooth_curve[:,1], label = "Smoothed curve", lw = 3)
    plot!(argvals, y[:,1],  label = "Observed curve", lw = 3)
end
