///|
/// Huber loss with an explicit transition scale.
pub fn huber_loss2(residual~ : Double, delta? : Double = 1.0) -> Double {
  let value = residual.abs()
  if value <= delta {
    0.5 * value * value
  } else {
    delta * (value - 0.5 * delta)
  }
}

///|
pub fn huber_weight2(residual : Double, delta : Double) -> Double {
  let value = residual.abs()
  if value <= delta || value == 0.0 {
    1.0
  } else {
    delta / value
  }
}

///|
pub fn cauchy_loss2(residual : Double, scale : Double) -> Double {
  let normalized = residual / scale.abs().max(0.000000000001)
  @math.ln(1.0 + normalized * normalized)
}

///|
pub fn cauchy_weight2(residual : Double, scale : Double) -> Double {
  let normalized = residual / scale.abs().max(0.000000000001)
  1.0 / (1.0 + normalized * normalized)
}

///|
pub fn tukey_loss2(residual : Double, cutoff : Double) -> Double {
  let normalized = residual / cutoff.abs().max(0.000000000001)
  if normalized.abs() < 1.0 {
    let factor = 1.0 - normalized * normalized
    cutoff * cutoff / 6.0 * (1.0 - factor * factor * factor)
  } else {
    cutoff * cutoff / 6.0
  }
}

///|
pub fn tukey_weight2(residual : Double, cutoff : Double) -> Double {
  let normalized = residual / cutoff.abs().max(0.000000000001)
  if normalized.abs() < 1.0 {
    let factor = 1.0 - normalized * normalized
    factor * factor
  } else {
    0.0
  }
}

///|
pub fn geman_mcclure_loss2(residual : Double, scale : Double) -> Double {
  let square = residual * residual
  let denominator = square + scale * scale
  if denominator <= 0.0 {
    0.0
  } else {
    square / denominator
  }
}

///|
pub fn geman_mcclure_weight2(residual : Double, scale : Double) -> Double {
  let square = residual * residual
  let denominator = square + scale * scale
  if denominator <= 0.0 {
    0.0
  } else {
    scale * scale / denominator
  }
}

///|
pub fn pseudo_huber_loss2(residual : Double, delta : Double) -> Double {
  let normalized = residual / delta.abs().max(0.000000000001)
  delta * delta * ((1.0 + normalized * normalized).sqrt() - 1.0)
}

///|
pub fn pseudo_huber_weight2(residual : Double, delta : Double) -> Double {
  let normalized = residual / delta.abs().max(0.000000000001)
  1.0 / (1.0 + normalized * normalized).sqrt()
}

///|
pub fn robust_loss_batch(
  residuals : ArrayView[Double],
  scale : Double,
) -> Array[Double] {
  let result : Array[Double] = []
  for residual in residuals {
    result.push(huber_loss2(residual~, delta=scale))
  }
  result
}

///|
pub fn robust_weight_batch(
  residuals : ArrayView[Double],
  scale : Double,
) -> Array[Double] {
  let result : Array[Double] = []
  for residual in residuals {
    result.push(huber_weight2(residual, scale))
  }
  result
}

///|
pub fn robust_loss_sum(residuals : ArrayView[Double], scale : Double) -> Double {
  let mut result = 0.0
  for loss in robust_loss_batch(residuals, scale) {
    result += loss
  }
  result
}

///|
pub fn robust_loss_mean(
  residuals : ArrayView[Double],
  scale : Double,
) -> Double {
  if residuals.length() == 0 {
    0.0
  } else {
    robust_loss_sum(residuals, scale) / residuals.length().to_double()
  }
}

///|
pub fn robust_weighted_residual(residual : Double, weight : Double) -> Double {
  residual * weight.max(0.0).sqrt()
}

///|
pub fn robust_weighted_batch(
  residuals : ArrayView[Double],
  weights : ArrayView[Double],
) -> Array[Double] {
  let result : Array[Double] = []
  let count = residuals.length().min(weights.length())
  for i in 0..<count {
    result.push(robust_weighted_residual(residuals[i], weights[i]))
  }
  result
}
