///|
/// Flatten a 2D reprojection residual into a solver block.
pub fn residual_block_2d(
  predicted : @core.Point2,
  observed : @core.Point2,
) -> Array[Double] {
  let difference = predicted.minus(observed)
  [difference.x, difference.y]
}

///|
pub fn residual_norm_2d(
  predicted : @core.Point2,
  observed : @core.Point2,
) -> Double {
  predicted.minus(observed).norm()
}

///|
pub fn residual_blocks_2d(
  predicted : ArrayView[@core.Point2],
  observed : ArrayView[@core.Point2],
) -> Array[Double] {
  let result : Array[Double] = []
  let count = predicted.length().min(observed.length())
  for i in 0..<count {
    let block = residual_block_2d(predicted[i], observed[i])
    result.push(block[0])
    result.push(block[1])
  }
  result
}

///|
pub fn residual_norms_2d(
  predicted : ArrayView[@core.Point2],
  observed : ArrayView[@core.Point2],
) -> Array[Double] {
  let result : Array[Double] = []
  let count = predicted.length().min(observed.length())
  for i in 0..<count {
    result.push(residual_norm_2d(predicted[i], observed[i]))
  }
  result
}

///|
pub fn residual_block_3d(
  predicted : @core.Point3,
  observed : @core.Point3,
) -> Array[Double] {
  let difference = predicted.minus(observed)
  [difference.x, difference.y, difference.z]
}

///|
pub fn residual_norm_3d(
  predicted : @core.Point3,
  observed : @core.Point3,
) -> Double {
  predicted.minus(observed).norm()
}

///|
pub fn residual_blocks_3d(
  predicted : ArrayView[@core.Point3],
  observed : ArrayView[@core.Point3],
) -> Array[Double] {
  let result : Array[Double] = []
  let count = predicted.length().min(observed.length())
  for i in 0..<count {
    let block = residual_block_3d(predicted[i], observed[i])
    for value in block {
      result.push(value)
    }
  }
  result
}

///|
pub fn weighted_residual_cost(
  residuals : ArrayView[Double],
  weights : ArrayView[Double],
  loss_scale : Double,
) -> Double {
  let count = residuals.length().min(weights.length())
  let scale = loss_scale.abs().max(0.000000000001)
  let mut cost = 0.0
  for i in 0..<count {
    let normalized = residuals[i] / scale
    cost += normalized * normalized * weights[i].max(0.0)
  }
  cost
}

///|
pub fn cauchy_residual_cost(
  residuals : ArrayView[Double],
  scale : Double,
) -> Double {
  let divisor = scale.abs().max(0.000000000001)
  let mut cost = 0.0
  for residual in residuals {
    let normalized = residual / divisor
    cost += @math.ln(1.0 + normalized * normalized)
  }
  cost
}

///|
pub fn charbonnier_residual_cost(
  residuals : ArrayView[Double],
  epsilon : Double,
) -> Double {
  let e = epsilon.abs().max(0.000000000001)
  let mut cost = 0.0
  for residual in residuals {
    cost += (residual * residual + e * e).sqrt()
  }
  cost
}

///|
pub fn residual_weights_huber(
  residuals : ArrayView[Double],
  scale : Double,
) -> Array[Double] {
  let result : Array[Double] = []
  let threshold = scale.abs().max(0.000000000001)
  for residual in residuals {
    let value = residual.abs()
    result.push(if value <= threshold { 1.0 } else { threshold / value })
  }
  result
}

///|
pub fn residual_weights_tukey(
  residuals : ArrayView[Double],
  scale : Double,
) -> Array[Double] {
  let result : Array[Double] = []
  let threshold = scale.abs().max(0.000000000001)
  for residual in residuals {
    let normalized = residual / threshold
    if normalized.abs() < 1.0 {
      let factor = 1.0 - normalized * normalized
      result.push(factor * factor)
    } else {
      result.push(0.0)
    }
  }
  result
}

///|
pub fn residual_inlier_mask(
  residuals : ArrayView[Double],
  threshold : Double,
) -> Array[Bool] {
  let result : Array[Bool] = []
  for residual in residuals {
    result.push(residual.abs() <= threshold)
  }
  result
}

///|
pub fn residual_inlier_count(
  residuals : ArrayView[Double],
  threshold : Double,
) -> Int {
  let mut count = 0
  for residual in residuals {
    if residual.abs() <= threshold {
      count += 1
    }
  }
  count
}

///|
pub fn residual_inlier_ratio2(
  residuals : ArrayView[Double],
  threshold : Double,
) -> Double {
  if residuals.length() == 0 {
    0.0
  } else {
    residual_inlier_count(residuals, threshold).to_double() /
    residuals.length().to_double()
  }
}

///|
pub fn residual_maximum(residuals : ArrayView[Double]) -> Double {
  let mut maximum = 0.0
  for residual in residuals {
    maximum = maximum.max(residual.abs())
  }
  maximum
}

///|
pub fn residual_mean_absolute(residuals : ArrayView[Double]) -> Double {
  if residuals.length() == 0 {
    0.0
  } else {
    let mut sum = 0.0
    for residual in residuals {
      sum += residual.abs()
    }
    sum / residuals.length().to_double()
  }
}

///|
pub fn residual_rms2(residuals : ArrayView[Double]) -> Double {
  if residuals.length() == 0 {
    0.0
  } else {
    let mut sum = 0.0
    for residual in residuals {
      sum += residual * residual
    }
    (sum / residuals.length().to_double()).sqrt()
  }
}
