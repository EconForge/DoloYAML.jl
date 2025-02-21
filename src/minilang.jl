# ------------------------- #
# Discrete Transition types #
# ------------------------- #

to_vector(tab::Number) = [tab]
to_matrix(tab::Number) = reshape([tab], 1, 1)
to_matrix(tab::Array) = hcat([Array{Float64}(e) for e in tab]...)
to_matrix(tab::Array{Array{Float64,1},1}) = cat([e' for e in tab]...; dims=1)

function _build_exogenous_entry(data::AbstractDict, calib::ModelCalibration)

    if data[:tag] == :Product
        p1 = _build_exogenous_entry(data[:p1], calib)
        p2 = _build_exogenous_entry(data[:p2], calib)
        return ProductProcess(p1,p2)
    elseif data[:tag] == :MarkovChain
        # need to extract/clean up P and Q
        values = eval_with(calib, data[:values])
        states_values = to_matrix(values)
        transitions = eval_with(calib, data[:transitions])
        Π = to_matrix(transitions)
        return MarkovChain(Π, states_values)
    elseif data[:tag] == :VAR1
        # need to extract rho an dSigma
        rho = eval_with(calib, data[:ρ])
        Sigma = eval_with(calib, data[:Σ])
        N = eval_with(calib, get(data, :N, 10))  # TODO: should default be 10??
        # rho = to_matrix(rho)
        Sigma = to_matrix(Sigma)
        N = to_vector(N)
        return VAR1(rho, Sigma)
    elseif data[:tag] == :Normal
        # need to extract rho an dSigma
        Sigma = eval_with(calib, data[:Sigma])
        Sigma = to_matrix(Sigma)
        if size(Sigma, 1) != size(Sigma, 2)
            sz = size(Sigma)
            msg = "Covariance matrix must be square. Found a $sz matrix"
            throw(DimensionMismatch(msg))
        end
        return Normal(Sigma)
    elseif data[:tag] == :DeathProcess
        # need to extract rho an dSigma
        mu = eval_with(calib, data[:mu])
        return DeathProcess(mu)
    elseif data[:tag] == :PoissonProcess
        # need to extract rho an dSigma
        mu = eval_with(calib, data[:mu])
        K = eval_with(calib, data[:K])
        return PoissonProcess(mu, K)
    elseif data[:tag] == :AgingProcess
        # need to extract rho an dSigma
        mu = eval_with(calib, data[:mu])
        K = eval_with(calib, data[:K])
        return AgingProcess(mu, K)
    end
    m = "don't know how to handle exogenous process of type $(data[:tag])"
    error(m)
end
