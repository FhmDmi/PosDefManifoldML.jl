# enlr.jl

This unit implements the **elastic net logistic regression (ENLR)**
machine learning model on the tangent space for symmetric positive definite (SDP) matrices, *i.e.*, real PD matrices. This model
features two hyperparameters: a user-defined **alpha** hyperparameter, in range ``[0, 1]``, where ``α=0`` allows a pure **Ridge** LR model and ``α=1`` a pure **lasso** LR model and the **lambda** hyperparameter. When the model is fitted, several models for several values of lambda are created. The 'best' model can be estimated by cross-validation using the [`cvLambda!`](@ref) function.

The lasso model (default) has enjoyed popularity in the field of *brain-computer interaces* due to the [winning score](http://alexandre.barachant.org/challenges/)
obtained in six international data classification competitions.

The ENLR model is implemented using the Julia package *GLMNet.jl*.
See [🎓](@ref) for resources on GLMNet and learn how to use purposefully
this model.

The **fit** and **predict** functions for the ENRL models are reported in the [cv.jl](@ref) unit, since those are shared by all machine learning models. Here it is reported the [`ENLRmodel`](@ref)
abstract type, the [`ENLR`](@ref) structure and the
[`cvLambda!`](@ref) function, which allows to estimate the best model
using cross-validation.

```@docs
ENLRmodel
ENLR
cvLambda!
```
