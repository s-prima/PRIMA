from prima import minimize, NonlinearConstraint as NLC, LinearConstraint as LC
import numpy as np
from objective import fun


def test_provide_nonlinear_constraints_alone():
    nlc = NLC(lambda x: np.array([x[0]**2, x[1]**2]), lb=[25]*2, ub=[100]*2)
    x0 = [0, 0]
    res = minimize(fun, x0, constraints=nlc)
    assert np.isclose(res.x[0], 5, atol=1e-6, rtol=1e-6)
    assert np.isclose(res.x[1], 5, atol=1e-6, rtol=1e-6)
    assert np.isclose(res.fun, 1, atol=1e-6, rtol=1e-6)
    assert res.method == "cobyla"


def test_provide_nonlinear_constraints_alone_and_select_COBYLA():
    nlc = NLC(lambda x: np.array([x[0]**2, x[1]**2]), lb=[25]*2, ub=[100]*2)
    x0 = [0, 0]
    res = minimize(fun, x0, constraints=nlc, method="COBYLA")
    assert np.isclose(res.x[0], 5, atol=1e-6, rtol=1e-6)
    assert np.isclose(res.x[1], 5, atol=1e-6, rtol=1e-6)
    assert np.isclose(res.fun, 1, atol=1e-6, rtol=1e-6)
    assert res.method == "cobyla"


def test_provide_linear_constraints_alone():
    lc = LC(np.array([[1, 1],[1, -1]]), lb=[0, 0], ub=[8, 2])
    x0 = [0, 0]
    res = minimize(fun, x0, constraints=lc)
    assert np.isclose(res.x[0], 4.5, atol=1e-6, rtol=1e-6)
    assert np.isclose(res.x[1], 3.5, atol=1e-6, rtol=1e-6)
    assert np.isclose(res.fun, 0.5, atol=1e-6, rtol=1e-6)
    assert res.method == "lincoa"

def test_provide_linear_constraints_alone_and_select_LINCOA():
    lc = LC(np.array([[1, 1],[1, -1]]), lb=[0, 0], ub=[8, 2])
    x0 = [0, 0]
    res = minimize(fun, x0, constraints=lc, method="LINCOA")
    assert np.isclose(res.x[0], 4.5, atol=1e-6, rtol=1e-6)
    assert np.isclose(res.x[1], 3.5, atol=1e-6, rtol=1e-6)
    assert np.isclose(res.fun, 0.5, atol=1e-6, rtol=1e-6)
    assert res.method == "lincoa"


def test_provide_bounds_alone():
    x0 = [0, 0]
    res = minimize(fun, x0, bounds=([0, 3], [0, 3]))
    assert np.isclose(res.x[0], 3, atol=1e-6, rtol=1e-6)
    assert np.isclose(res.x[1], 3, atol=1e-6, rtol=1e-6)
    assert np.isclose(res.fun, 5, atol=1e-6, rtol=1e-6)
    assert res.method == "bobyqa"


def test_provide_bounds_alone_and_select_BOBYQA():
    x0 = [0, 0]
    res = minimize(fun, x0, bounds=([0, 3], [0, 3]), method="BOBYQA")
    assert np.isclose(res.x[0], 3, atol=1e-6, rtol=1e-6)
    assert np.isclose(res.x[1], 3, atol=1e-6, rtol=1e-6)
    assert np.isclose(res.fun, 5, atol=1e-6, rtol=1e-6)
    assert res.method == "bobyqa"


def test_not_providing_bounds_linear_constraints_or_nonlinear_constraints():
    x0 = [0, 0]
    res = minimize(fun, x0)
    assert fun.result_point_and_value_are_optimal(res)
    assert res.method == "newuoa"


def test_not_providing_bounds_linear_constraints_or_nonlinear_constraints_and_select_NEWUOA():
    x0 = [0, 0]
    res = minimize(fun, x0, method="NEWUOA")
    assert fun.result_point_and_value_are_optimal(res)
    assert res.method == "newuoa"


def test_not_providing_bounds_linear_constraints_or_nonlinear_constraints_and_select_UOBYQA():
    x0 = [0, 0]
    res = minimize(fun, x0, method="UOBYQA")
    assert fun.result_point_and_value_are_optimal(res)
    assert res.method == "uobyqa"
