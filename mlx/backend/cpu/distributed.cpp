// Copyright © 2024 Apple Inc.

#include <cassert>

#include "mlx/allocator.h"
#include "mlx/backend/cpu/copy.h"
#include "mlx/backend/cpu/encoder.h"
#include "mlx/distributed/primitives.h"

namespace mlx::core::distributed {

std::pair<array, bool> ensure_row_contiguous(const array& arr, Stream stream) {
  if (arr.flags().row_contiguous) {
    return {arr, false};
  } else {
    return {contiguous_copy_cpu(arr, stream), true};
  }
};

void AllReduce::eval_cpu(
    const std::vector<array>& inputs,
    std::vector<array>& outputs) {
  assert(inputs.size() == 1);
  assert(outputs.size() == 1);

  auto donate_or_copy = [s = stream()](const array& in, array& out) {
    if (in.flags().row_contiguous) {
      if (in.is_donatable()) {
        out.copy_shared_buffer(in);
      } else {
        out.set_data(allocator::malloc(out.nbytes()));
      }
      return in;
    } else {
      array arr_copy = contiguous_copy_cpu(in, s);
      out.copy_shared_buffer(arr_copy);
      return arr_copy;
    }
  };

  auto in = donate_or_copy(inputs[0], outputs[0]);
  switch (reduce_type_) {
    case Sum:
      distributed::detail::all_sum(group(), in, outputs[0], stream());
      break;
    case Max:
      distributed::detail::all_max(group(), in, outputs[0], stream());
      break;
    case Min:
      distributed::detail::all_min(group(), in, outputs[0], stream());
      break;
    default:
      throw std::runtime_error(
          "Only all reduce sum, min and max are supported for now");
  }
}

void AllGather::eval_cpu(
    const std::vector<array>& inputs,
    std::vector<array>& outputs) {
  assert(inputs.size() == 1);
  assert(outputs.size() == 1);

  auto [in, copied] = ensure_row_contiguous(inputs[0], stream());
  outputs[0].set_data(allocator::malloc(outputs[0].nbytes()));
  distributed::detail::all_gather(group(), in, outputs[0], stream());
  if (copied) {
    auto& enc = cpu::get_command_encoder(stream());
    enc.add_temporary(in);
  }
}

void Send::eval_cpu(
    const std::vector<array>& inputs,
    std::vector<array>& outputs) {
  assert(inputs.size() == 1);
  assert(outputs.size() == 1);

  auto [in, copied] = ensure_row_contiguous(inputs[0], stream());
  distributed::detail::send(group(), in, dst_, stream());
  outputs[0].copy_shared_buffer(inputs[0]);
  if (copied) {
    auto& enc = cpu::get_command_encoder(stream());
    enc.add_temporary(in);
  }
}

void Recv::eval_cpu(
    const std::vector<array>& inputs,
    std::vector<array>& outputs) {
  assert(inputs.size() == 0);
  assert(outputs.size() == 1);

  outputs[0].set_data(allocator::malloc(outputs[0].nbytes()));
  distributed::detail::recv(group(), outputs[0], src_, stream());
}

} // namespace mlx::core::distributed
