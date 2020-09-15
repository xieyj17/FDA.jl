module FDA

using BSplines

struct basisobj
    basis_type
    basis
end

struct fdobj
    basis_type
    basis
    coefs
end

function second_order_diff(f, x, h)
    n = f(x+h) - 2*f(x) + f(x-h)
    return n / (h^2)
end

function estimate_R_mat(basis_type, basis, Psi_matrix, argvals, nderiv)
    dpsi = zeros(length(basis), length(argvals))
    if basis_type == "BSpline"
        for i in 1:length(argvals)
            tpsi = Psi_matrix[i,:]
            tid = [j for j in 1:length(tpsi) if tpsi[j]!=0]
            t_time = argvals[i]
            temp_deriv = bsplines(basis, t_time, BSplines.Derivative(nderiv))
            for k in tid
                dpsi[k, i] = temp_deriv[:,1][k]
            end
        end
    elseif basis_type == "Fourier"
        h = (argvals[2] - argvals[1])/10
        for i in 1:length(basis)
            tf = basis[i]
            temp_deriv = [second_order_diff(tf, t, h) for t in argvals]
            dpsi[i,:] = temp_deriv
        end
    end

    R_matrix = dpsi * transpose(dpsi)
    R_matrix = R_matrix ./ length(argvals)
    return R_matrix
end


function gen_bspline_basis(range_eval, nbasis, order=4)
    nbreaks = nbasis - order + 2
    break_points = range(range_eval[1], range_eval[2]; length = nbreaks)
    basis = BSplineBasis(order, break_points)
    r = basisobj("BSpline", basis)
    return r
end


function gen_fourier_basis(range_eval, nbasis)
    normalizer = (range_eval[2] - range_eval[1])
    basis = []

    function tf1(t)
        return 1/normalizer
    end

    push!(basis, tf1)

    n = Int(ceil((nbasis-1)/2))
    for i in 1:n
        function tfa(t)
            return sin(2*pi*i*t/normalizer)
        end
        push!(basis, tfa)
        function tfb(t)
            return cos(2*pi*i*t/normalizer)
        end
        push!(basis, tfb)
    end
    basis = basis[1:nbasis]

    r = basisobj("Fourier", basis)
end


function get_coef_mat(argvals, basisobj, lambda, nderiv)
    basis = basisobj.basis
    basis_type = basisobj.basis_type
    if basis_type == "BSpline"
        Psi_matrix = basismatrix(basis, argvals)
        R_matrix = estimate_R_mat(basis_type, basis, Psi_matrix, argvals, nderiv)
    elseif basis_type == "Fourier"
        Psi_matrix = zeros(length(argvals), length(basis))
        for i in 1:length(basis)
            tf = basis[i]
            Psi_matrix[:,i] = tf.(argvals)
            R_matrix = estimate_R_mat(basis_type, basis, Psi_matrix, argvals, nderiv)
        end
    end

    coef_mat = inv(transpose(Psi_matrix) * Psi_matrix .+ R_matrix .* lambda) *
            transpose(Psi_matrix)
    return coef_mat

end


function Data2fd(argvals, y, basisobj;
    lambda=3e-8/(maximum(argvals) - minimum(argvals)),
    nderiv=2)

    basis_type = basisobj.basis_type
    basis = basisobj.basis

    coefs = zeros(length(basis), ncol(y))
    coef_mat = get_coef_mat(argvals, basisobj,lambda, nderiv)
    for i in 1:ncol(y)
        coefs[:,i] = coef_mat * y[:,i]
    end

    res = fdobj(basis_type, basis, coefs)
    return res
end


function eval_fd(eval_grid, fdobj)
    basis = fdobj.basis
    coefs = fdobj.coefs
    if fdobj.basis_type == "BSpline"
        Psi_matrix = basismatrix(basis, eval_grid)
    elseif fdobj.basis_type == "Fourier"
        Psi_matrix = zeros(length(eval_grid), length(basis))
        for i in 1:length(basis)
            tf = basis[i]
            Psi_matrix[:,i] = tf.(eval_grid)
        end
    end
    obs = Psi_matrix * coefs
    return obs
end


end
