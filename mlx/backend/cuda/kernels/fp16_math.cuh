// Copyright © 2025 Apple Inc.

#pragma once

#include <cuda_bf16.h>
#include <cuda_fp16.h>
#include <cuda/std/limits>
#include <cuda/std/type_traits>

namespace mlx::core::cu {

///////////////////////////////////////////////////////////////////////////////
// Additional C++ operator overrides between half types and native types.
///////////////////////////////////////////////////////////////////////////////

template <typename T, typename U>
constexpr bool is_integral_except =
    cuda::std::is_integral_v<T> && !cuda::std::is_same_v<T, U>;

template <typename T, typename U>
constexpr bool is_arithmetic_except =
    cuda::std::is_arithmetic_v<T> && !cuda::std::is_same_v<T, U>;

#define MLX_DEFINE_HALF_OP(HALF, HALF2FLOAT, FLOAT2HALF, OP)          \
  template <                                                          \
      typename T,                                                     \
      typename = cuda::std::enable_if_t<is_integral_except<T, HALF>>> \
  __forceinline__ __device__ HALF operator OP(HALF x, T y) {          \
    return FLOAT2HALF(HALF2FLOAT(x) OP static_cast<float>(y));        \
  }                                                                   \
  template <                                                          \
      typename T,                                                     \
      typename = cuda::std::enable_if_t<is_integral_except<T, HALF>>> \
  __forceinline__ __device__ HALF operator OP(T x, HALF y) {          \
    return FLOAT2HALF(static_cast<float>(x) OP HALF2FLOAT(y));        \
  }

#define MLX_DEFINE_HALF_CMP(HALF, HALF2FLOAT, OP)                       \
  template <                                                            \
      typename T,                                                       \
      typename = cuda::std::enable_if_t<is_arithmetic_except<T, HALF>>> \
  __forceinline__ __device__ bool operator OP(HALF x, T y) {            \
    return HALF2FLOAT(x) OP static_cast<float>(y);                      \
  }                                                                     \
  template <                                                            \
      typename T,                                                       \
      typename = cuda::std::enable_if_t<is_arithmetic_except<T, HALF>>> \
  __forceinline__ __device__ bool operator OP(T x, HALF y) {            \
    return static_cast<float>(y) OP HALF2FLOAT(x);                      \
  }

MLX_DEFINE_HALF_OP(__half, __half2float, __float2half, +)
MLX_DEFINE_HALF_OP(__half, __half2float, __float2half, -)
MLX_DEFINE_HALF_OP(__half, __half2float, __float2half, *)
MLX_DEFINE_HALF_OP(__half, __half2float, __float2half, /)
MLX_DEFINE_HALF_OP(__nv_bfloat16, __bfloat162float, __float2bfloat16, +)
MLX_DEFINE_HALF_OP(__nv_bfloat16, __bfloat162float, __float2bfloat16, -)
MLX_DEFINE_HALF_OP(__nv_bfloat16, __bfloat162float, __float2bfloat16, *)
MLX_DEFINE_HALF_OP(__nv_bfloat16, __bfloat162float, __float2bfloat16, /)
MLX_DEFINE_HALF_CMP(__half, __half2float, <)
MLX_DEFINE_HALF_CMP(__half, __half2float, >)
MLX_DEFINE_HALF_CMP(__half, __half2float, <=)
MLX_DEFINE_HALF_CMP(__half, __half2float, >=)
MLX_DEFINE_HALF_CMP(__half, __half2float, ==)
MLX_DEFINE_HALF_CMP(__half, __half2float, !=)
MLX_DEFINE_HALF_CMP(__nv_bfloat16, __bfloat162float, <)
MLX_DEFINE_HALF_CMP(__nv_bfloat16, __bfloat162float, >)
MLX_DEFINE_HALF_CMP(__nv_bfloat16, __bfloat162float, <=)
MLX_DEFINE_HALF_CMP(__nv_bfloat16, __bfloat162float, >=)
MLX_DEFINE_HALF_CMP(__nv_bfloat16, __bfloat162float, ==)
MLX_DEFINE_HALF_CMP(__nv_bfloat16, __bfloat162float, !=)

#undef MLX_DEFINE_HALF_OP
#undef MLX_DEFINE_HALF_CMP

} // namespace mlx::core::cu
