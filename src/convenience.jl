# Define CryptoContext for convenience
"""
    CryptoContext{T}

Type alias for `CxxWrap.StdLib.SharedPtr{CryptoContextImpl{T}}`.

The crypto context is the central object in OpenFHE that facilitates all essential
cryptographic operations such as key generation, encryption/decryption, arithmetic
operations on plaintexts and ciphertexts etc.

In OpenFHE, a crypto context is always created from a set of `CCParams` parameters using
`GenCryptoContext`.

See also: [`CCParams`](@ref), [`GenCryptoContext`](@ref)
"""
const CryptoContext{T} = CxxWrap.StdLib.SharedPtr{CryptoContextImpl{T}}

"""
    Ciphertext{T}

Type alias for `CxxWrap.StdLib.SharedPtr{CiphertextImpl{T}}`.

The ciphertext object holds homomorphically encrypted data that can be used for encrypted
computations. It is created either by encrypting a [`Plaintext`](@ref) object or by
performing arithmetic with existing ciphertexts.

See also: [`Plaintext`](@ref), [`Encrypt`](@ref)
"""
const Ciphertext{T} = CxxWrap.StdLib.SharedPtr{CiphertextImpl{T}}

"""
    Plaintext


Type alias for `CxxWrap.StdLib.SharedPtr{PlaintextImpl}`.

The plaintext object can hold unencrypted data. It is created either by encoding raw data
(e.g., through [`MakeCKKSPackedPlaintext`](@ref)) or by decrypting a [`Ciphertext`](@ref)
object using [`Decrypt`](@ref).

See also: [`Ciphertext`](@ref), [`Decrypt`](@ref)
"""
const Plaintext = CxxWrap.StdLib.SharedPtr{PlaintextImpl}

# Print contents of Plaintext types using internal implementation
Base.print(io::IO, plaintext::Plaintext) = print(io, _to_string(plaintext))

"""
    PublicKey{T}

Type alias for `CxxWrap.StdLib.SharedPtr{PublicKeyImpl{T}}`.

Public keys can be used to encrypt [`Plaintext`](@ref) data into [`Ciphertext`](@ref)
objects. They are part of a `KeyPair` that contains both a public and a private key. Key
pairs can be created from a [`CryptoContext`](@ref) by calling [`KeyGen`](@ref).

See also: [`KeyGen`](@ref), [`KeyPair`](@ref)
"""
const PublicKey{T} = CxxWrap.StdLib.SharedPtr{PublicKeyImpl{T}}

"""
    PrivateKey{T}

Type alias for `CxxWrap.StdLib.SharedPtr{PrivateKeyImpl{T}}`.

Private keys can be used to decrypt [`Ciphertext`](@ref) data into [`Plaintext`](@ref)
objects. They are part of a `KeyPair` that contains both a public and a private key. Key
pairs can be created from a [`CryptoContext`](@ref) by calling [`KeyGen`](@ref).

See also: [`KeyGen`](@ref), [`KeyPair`](@ref)
"""
const PrivateKey{T} = CxxWrap.StdLib.SharedPtr{PrivateKeyImpl{T}}

# Convenience methods to avoid having to dereference smart pointers
for (WrappedT, fun) in [
    :(Ciphertext{DCRTPoly}) => :GetLevel,
    :(CryptoContext{DCRTPoly}) => :Enable,
    :(CryptoContext{DCRTPoly}) => :GetRingDimension,
    :(CryptoContext{DCRTPoly}) => :KeyGen,
    :(CryptoContext{DCRTPoly}) => :EvalMultKeyGen,
    :(CryptoContext{DCRTPoly}) => :EvalRotateKeyGen,
    :(CryptoContext{DCRTPoly}) => :MakeCKKSPackedPlaintext,
    :(CryptoContext{DCRTPoly}) => :Encrypt,
    :(CryptoContext{DCRTPoly}) => :EvalAdd,
    :(CryptoContext{DCRTPoly}) => :EvalSub,
    :(CryptoContext{DCRTPoly}) => :EvalMult,
    :(CryptoContext{DCRTPoly}) => :EvalRotate,
    :(CryptoContext{DCRTPoly}) => :Decrypt,
    :(CryptoContext{DCRTPoly}) => :EvalBootstrapSetup,
    :(CryptoContext{DCRTPoly}) => :EvalBootstrapKeyGen,
    :(CryptoContext{DCRTPoly}) => :EvalBootstrap,
    :(Plaintext) => :SetLength,
    :(Plaintext) => :GetLogPrecision,
    :(Plaintext) => :GetRealPackedValue,
]
    @eval function $fun(arg::$WrappedT, args...; kwargs...)
        $fun(arg[], args...; kwargs...)
    end
end


# Convenience `show` methods to hide wrapping-induced ugliness
# Note: remember to add tests to `test/test_convenience.jl` if you add something here
for (T, str) in [
    :(CCParams{<:CryptoContextCKKSRNS}) => "CCParams{CryptoContextCKKSRNS}()",
    :(CryptoContextCKKSRNS) => "CryptoContextCKKSRNS()",
    :(CryptoContext{DCRTPoly}) => "CryptoContext{DCRTPoly}()",
    :(Ciphertext{DCRTPoly}) => "Ciphertext{DCRTPoly}()",
    :(Plaintext) => "Plaintext()",
    :(PublicKey{DCRTPoly}) => "PublicKey{DCRTPoly}()",
    :(PrivateKey{DCRTPoly}) => "PrivateKey{DCRTPoly}()",
    :(DecryptResult) => "DecryptResult()",
]
    @eval function Base.show(io::IO, ::$T)
        print(io, $str)
    end
end


# More convenience methods

"""
    MakeCKKSPackedPlaintext(crypto_context::CryptoContext, value::Vector{Float64};
                            scale_degree = 1,
                            level = 1,
                            params = C_NULL,
                            num_slots = 0)

Encode a vector of real numbers `value` into a CKKS-packed [`Plaintext`](@ref) using the
given `crypto_context`.
Please refer to the OpenFHE documentation for details on the remaining arguments.

See also: [`CryptoContext`](@ref), [`Plaintext`](@ref)
"""
function MakeCKKSPackedPlaintext(context::CxxWrap.CxxWrapCore.CxxRef{OpenFHE.CryptoContextImpl{OpenFHE.DCRTPoly}},
                                 value::Vector{Float64};
                                 scale_degree = 1,
                                 level = 0,
                                 params = OpenFHE.CxxWrap.StdLib.SharedPtr{OpenFHE.ILDCRTParams{OpenFHE.ubint{UInt64}}}(),
                                 num_slots = 0)
    MakeCKKSPackedPlaintext(context, CxxWrap.StdVector(value), scale_degree, level, params, num_slots)
end

"""
    EvalRotateKeyGen(crypto_context::CryptoContext,
                     private_key::PrivateKey,
                     index_list::Vector{<:Integer};
                     public_key::PublicKey = C_NULL)

Generate rotation keys for use with [`EvalRotate`](@ref) using the `private_key` and for the
rotation indices in `index_list. The keys are stored in the  given `crypto_context`.
Please refer to the OpenFHE documentation for details on the remaining arguments.

See also: [`CryptoContext`](@ref), [`PrivateKey`](@ref), [`PublicKey`](@ref), [`EvalRotate`](@ref)
"""
function EvalRotateKeyGen(context::CxxWrap.CxxWrapCore.CxxRef{OpenFHE.CryptoContextImpl{OpenFHE.DCRTPoly}},
                          privateKey,
                          indexList::Vector{<:Integer};
                          publicKey = OpenFHE.CxxWrap.StdLib.SharedPtr{OpenFHE.PublicKeyImpl{OpenFHE.DCRTPoly}}())
    EvalRotateKeyGen(context, privateKey, CxxWrap.StdVector(Int32.(indexList)), publicKey)
end

"""
    EvalBootstrapSetup(crypto_context::CryptoContext;
                       level_budget::Vector{<:Integer} = [5, 4],
                       dim1::Vector{<:Integer} = [0, 0],
                       slots = 0,
                       correction_factor = 0,
                       precompute = true)

Set up a given `crypto_context` for bootstrapping. Supported for CKKS only.
Please refer to the OpenFHE documentation for details on the remaining arguments.

See also: [`CryptoContext`](@ref), [`EvalBootstrapKeyGen`](@ref), [`EvalBootstrap`](@ref)
"""
function EvalBootstrapSetup(context::CxxWrap.CxxWrapCore.CxxRef{OpenFHE.CryptoContextImpl{OpenFHE.DCRTPoly}};
                            level_budget = [5, 4],
                            dim1 = [0, 0],
                            slots = 0,
                            correction_factor = 0,
                            precompute = true)
    EvalBootstrapSetup(context,
                       CxxWrap.StdVector(UInt32.(level_budget)),
                       CxxWrap.StdVector(UInt32.(dim1)),
                       slots,
                       correction_factor,
                       precompute)
end

"""
    EvalBootstrap(crypto_context::CryptoContext, ciphertext::Ciphertext;
                  num_iterations = 1,
                  precision = 0)

Return a refreshed `ciphertext` for a given `crypto_context`. Supported for CKKS only.
Please refer to the OpenFHE documentation for details on the remaining arguments.

See also: [`CryptoContext`](@ref), [`PrivateKey`](@ref), [`EvalBootstrapSetup`](@ref), [`EvalBootstrap`](@ref)
"""
function EvalBootstrap(context::CxxWrap.CxxWrapCore.CxxRef{OpenFHE.CryptoContextImpl{OpenFHE.DCRTPoly}},
                       ciphertext;
                       num_iterations = 1,
                       precision = 0)
    EvalBootstrap(context, ciphertext, num_iterations, precision)
end

"""
    Decrypt(crypto_context::CryptoContext, ciphertext::Ciphertext, private_key::PrivateKey, plaintext::Plaintext)
    Decrypt(crypto_context::CryptoContext, private_key::PrivateKey, ciphertext::Ciphertext, plaintext::Plaintext)

Decrypt a `ciphertext` with the given `private_key` and store the result in `plaintext`,
using the parameters of the given `crypto_context`.

See also: [`CryptoContext`](@ref), [`PrivateKey`](@ref), [`Ciphertext`](@ref), [`Plaintext`](@ref), [`Encrypt`](@ref)
"""
function Decrypt(context::CxxWrap.CxxWrapCore.CxxRef{OpenFHE.CryptoContextImpl{OpenFHE.DCRTPoly}},
                 key_or_cipher1,
                 key_or_cipher2,
                 result::CxxWrap.CxxWrapCore.SmartPointer{<:PlaintextImpl})
    Decrypt(context, key_or_cipher1, key_or_cipher2, CxxPtr(result))
end

"""
    OpenFHE.DecryptResult

Return type of the [`Decrypt`](@ref) operation. This type does not actually hold any data
but only information on whether the decryption succeeded. It is currently not used by
OpenFHE.jl and no functions are implemented.

See also: [`Decrypt`](@ref)
"""
DecryptResult

"""
    GetBootstrapDepth(level_budget::Vector{<:Integer}, secret_key_distribution::SecretKeyDist)

Compute and return the bootstrapping depth for a given `level_budget` and a
`secret_key_distribution`.

See also: [`SecretKeyDist`](@ref)
"""
function GetBootstrapDepth(level_budget::Vector{<:Integer}, secret_key_distribution)
    Int(GetBootstrapDepth(CxxWrap.StdVector(UInt32.(level_budget)), secret_key_distribution))
end

