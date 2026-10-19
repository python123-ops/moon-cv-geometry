///|
fn finite_probability(value : Double) -> Bool {
  !value.is_nan() && !value.is_inf() && value >= 0.0 && value <= 1.0
}

///|
fn bounded_probability(value : Double) -> Double {
  if value.is_nan() {
    0.0
  } else {
    value.max(0.0).min(1.0)
  }
}

///|
fn sample_success(ratio : Double, sample_size : Int) -> Double {
  @math.pow(bounded_probability(ratio), sample_size.max(0).to_double())
}

///|
/// log1p/expm1 avoid rounding tiny positive probabilities down to zero.
fn success_after(probability : Double, iterations : Int) -> Double {
  if iterations <= 0 || probability <= 0.0 {
    return 0.0
  }
  if probability >= 1.0 {
    return 1.0
  }
  (-@math.expm1(iterations.to_double() * @math.ln_1p(-probability)))
  .max(0.0)
  .min(1.0)
}

///|
/// At most 31 bisections, even when the requested budget is Int::max_value.
fn bounded_iterations(
  probability : Double,
  confidence : Double,
  maximum : Int,
) -> Int {
  let target = bounded_probability(confidence)
  let cap = maximum.max(1)
  if target <= 0.0 || probability >= 1.0 {
    return 1
  }
  if probability <= 0.0 || success_after(probability, cap) < target {
    return cap
  }
  for low = 1, high = cap; low < high; {
    let middle = low + (high - low) / 2
    if success_after(probability, middle) >= target {
      continue low, middle
    } else {
      continue middle + 1, high
    }
  } nobreak {
    low
  }
}
