#   Unit "train-test.jl" of the PosDefManifoldML Package for Julia language
#   v 0.0.1 - last update 28th of September 2019
#
#   MIT License
#   Copyright (c) 2019,
#   Saloni Jain, Indian Institute of Technology, Kharagpur, India
#   Marco Congedo, CNRS, Grenobe, France:
#   https://sites.google.com/site/marcocongedo/home

# ? CONTENTS :
#   This unit implements training-test procedures for Riemannian
#   machine learning classifiers.

"""
```
function fit!(model :: MLmodel,
              𝐏Tr     :: ℍVector,
              yTr     :: Vector;
           w  :: Vector= [],
           ✓w :: Bool  = true,
           ⏩ :: Bool  = true)
```

Fit a machine learning model [ML model](@ref),
with training data `𝐏Tr`, of type
[ℍVector](https://marco-congedo.github.io/PosDefManifold.jl/dev/MainModule/#%E2%84%8DVector-type-1),
and corresponding labels `yTr`, of type [IntVector](@ref).
Return the fitted model.

Only the [`MDM`](@ref) model is supported for the moment being.

**MDM model**

For this model, fitting involves computing a mean of all the
matrices in each class. Those class means are computed according
to the metric specified by the [`MDM`](@ref) constructor.

See method (3) of the [mean](https://marco-congedo.github.io/PosDefManifold.jl/dev/riemannianGeometry/#Statistics.mean)
function for the meaning of the optional keyword arguments
`w`, `✓w` and `⏩`, to which they are passed.

Note that the MDM model can be created and fitted in one pass using
a specia [`MDM`](@ref) constructor.

**See**: [notation & nomenclature](@ref), [the ℍVector type](@ref).

**See also**: [`predict`](@ref), [`CVscore`](@ref).

**Examples**
```
using PosDefManifoldML

# generate some data
𝐏Tr, 𝐏Te, yTr, yTe=gen2ClassData(10, 30, 40, 60, 80, 0.25)

# create an MDM model
model = MDM(Fisher)

# fit (train) the model
fit!(model, 𝐏Tr, yTr)

# using a special constructor you don't need the fit! function:
𝐏Tr, 𝐏Te, yTr, yTe=gen2ClassData(10, 30, 40, 60, 80, 0.25)
model=MDM(Fisher, 𝐏Tr, yTr)
```

"""
function fit!(model :: MLmodel,
              𝐏Tr     :: ℍVector,
              yTr     :: Vector;
           w  :: Vector= [],
           ✓w :: Bool  = true,
           ⏩ :: Bool  = true)

    nk=length(𝐏Tr)
    errMsg1="the lengths of the data and label vectors do not match."
    if nk ≠ length(yTr)
        @error 📌*", fit! function: "*errMsg1
        return
    end

    if isa(model, MDM)
        nc = length(unique!(copy(yTr))) # number of classes
        𝐏 = [ℍ[] for i = 1:nc]
        W = [Float64[] for i = 1:nc]
        for j = 1:nk push!(𝐏[Int(yTr[j])], 𝐏Tr[j]) end
        if !isempty(w) for j = 1:nk push!(W[Int(yTr[j])], w[j]) end end
        model.means = ℍVector([getMeans(model.metric, 𝐏[l], w = W[l], ✓w=✓w, ⏩=⏩) for l=1:nc])
        return model
    else
        # for other model for which a fit! method exists you may use this code
        # Z = projectOnTS(𝐏Tr)
        # fit!(model.clf, Z, yTr)
        # etc, e.g., println(score(model.clf, Z, yTr))
    end
end



"""
```
function predict(model  :: MLmodel,
                 𝐏Te    :: ℍVector,
                 what   :: Symbol = :labels;
               verbose :: Bool = true,
               ⏩     :: Bool = true)
```
Given a [ML model](@ref) `model` trained (fitted) on ``z`` classes
and a testing set of ``k`` positive definite matrices `𝐏Te` of type
[ℍVector](https://marco-congedo.github.io/PosDefManifold.jl/dev/MainModule/#%E2%84%8DVector-type-1),

If `verbose` is true (default) information is printed in the REPL.
This option is included to allow repeated calls to this function
without crowding the REPL.

It f `⏩` is true (default), computations are multi-threaded whenever possible.

if `what` is `:labels` or `:l` (default), return
the predicted **class labels** for each matrix in `𝐏Te` as an [IntVector](@ref);

if `what` is `:probabilities` or `:p`, return the predicted **probabilities**
for each matrix in `𝐏Te` to belong to a all classes, as a ``k``-vector
of ``z`` vectors holding reals in ``(0, 1)`` (probabilities).

if `what` is `:f` or `:functions`, return the **output function** of the model
(see below).

Only the [`MDM`](@ref) model is supported for the moment being.

**MDM model**

For this model, the predicted class 'label' of an unlabeled matrix is the
serial number of the class whose mean is the closest to the matrix
(minimum distance to mean).
The labels are '1' for class 1, '2' for class 2, etc.

The 'probabilities' are obtained passing to a
[softmax function](https://en.wikipedia.org/wiki/Softmax_function)
minus the squared distances of each unlabeled matrix to all class means.

The ratio of these squared distance to their geometric mean gives
the 'functions'.

**See**: [notation & nomenclature](@ref), [the ℍVector type](@ref).

**See also**: [`fit!`](@ref), [`CVscore`](@ref).

**Examples**
```
using PosDefManifoldML

# generate some data
𝐏Tr, 𝐏Te, yTr, yTe=gen2ClassData(10, 30, 40, 60, 80)

# craete and fit an MDM model
model=MDM(Fisher, 𝐏Tr, yTr)

# predict labels
predict(model, 𝐏Te, :l)

# predict probabilities
predict(model, 𝐏Te, :p)

# output functions
predict(model, 𝐏Te, :f)

```
"""
function predict(model  :: MLmodel,
                 𝐏Te    :: ℍVector,
                 what   :: Symbol = :labels;
            verbose :: Bool = true,
            ⏩     :: Bool = true)

    if what ∉ (:l, :labels, :p, :probabilities, :f, :functions)
        @error 📌*", predict function: the `what` symbol is not supported."
        return
    end

    # add if isa(model, xxx) for other binary models here !
    # if isa(model, MDM) && length(model.means)>2 && what ∈(:f, :fucntions) && verbose
    # @error 📌*", predict function: the predicted functions cannot be returned for a model with more than 2 classes. Use another `what` symbol."
    # end

    if      what ∈(:f, :fucntions)      whatStr="functions"
    elseif  what ∈(:l, :labels)         whatStr="labels"
    elseif  what ∈(:p, :probabilities)  whatStr="probabilities of belonging to each class"
    end


    if isa(model, MDM)
        D = getDistances(model.metric, model.means, 𝐏Te, ⏩=⏩)
        (z, k)=size(D)
        verbose && println(titleFont, "\nPredicted ",whatStr,":\n", defaultFont)
        if     what == :functions || what == :f
               gmeans=[PosDefManifold.mean(Fisher, D[:, j]) for j = 1:k]
               func(j::Int)=[D[i, j]/gmeans[j] for i=1:z]
               return [func(j) for j = 1:k]
        elseif what == :labels || what == :l
               return [findmin(D[:,j])[2] for j = 1:k]
        elseif what == :probabilities || what == :p
               return [softmax(-D[:,j]) for j = 1:k]
        end
    end
    # elseif to add more models
end


"""
```
function CVscore(model :: MLmodel,
                 𝐏Tr   :: ℍVector,
                 yTr   :: Vector,
                 nCV   :: Int = 5;
            scoring   :: Symbol = :b,
            confusion :: Bool   = false,
            shuffle   :: Bool   = false)
```
Cross-validation: Given an ℍVector `𝐏Tr` holding `k` Hermitian matrices,
a Vector `yTr` holding the `k` labels for these matrices,
the number of cross-validations `nCV` and an [ML model](@ref) `model`,
retrun a vector `scores` of `nCV` accuracies, one for each cross-validation.

If `scoring= :b` (default) the balanced accuracy is computed.
Any other value will make the function returning the regular accuracy.

If `confusion=true` (dafault=false), return the 2-tuple `C, scores`,
where `C` is a `nCV`-vector of the confusion matrices
for each cross-validation set, otherwise return only `scores`.

**See**: [notation & nomenclature](@ref), [the ℍVector type](@ref).

**See also**: [`fit!`](@ref), [`predict`](@ref).

**Examples**
```
using PosDefManifoldML

# generate some data
𝐏Tr, 𝐏Te, yTr, yTe=gen2ClassData(10, 30, 40, 60, 80)

# craete and fit an MDM model
model=MDM(Fisher, 𝐏Tr, yTr)

# perform cross-validation
CVscore(model, 𝐏Te, yTe, 5)
```
"""
function CVscore(model :: MLmodel,
                 𝐏Tr   :: ℍVector,
                 yTr   :: Vector,
                 nCV   :: Int = 5;
            scoring   :: Symbol = :b,
            confusion :: Bool   = false,
            shuffle   :: Bool   = false)

     if isa(model, MDM)
         return CV_mdm(model.metric, 𝐏Tr, yTr, nCV;
                    scoring=scoring, confusion=confusion, shuffle=shuffle)
         # elseif
         # add code for other models for which a CVscore method is supported
         # e.g., return (CV(model.clf, logMap(𝐏Tr), y, cv = ncv))
     end
end
