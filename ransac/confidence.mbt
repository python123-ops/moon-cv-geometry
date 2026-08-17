///|
pub fn confidence_from_success(
  iterations~ : Int,
  success_probability~ : Double,
) -> Double raise @core.GeometryError {
  if iterations < 0 || success_probability < 0.0 || success_probability > 1.0 {
    raise @core.GeometryError::DegenerateInput(
      "confidence parameters are invalid",
    )
  }
  let mut failure = 1.0
  for _ in 0..<iterations {
    failure *= 1.0 - success_probability
  }
  1.0 - failure
}

///|
pub fn required_iterations(
  success_probability~ : Double,
  confidence? : Double = 0.99,
) -> Int raise @core.GeometryError {
  if success_probability <= 0.0 ||
    success_probability > 1.0 ||
    confidence <= 0.0 ||
    confidence >= 1.0 {
    raise @core.GeometryError::DegenerateInput(
      "iteration probability parameters are invalid",
    )
  }
  let mut failure = 1.0 - success_probability
  let mut result = 1
  while result < 1000000 && failure > 1.0 - confidence {
    failure *= 1.0 - success_probability
    result += 1
  }
  result
}

///|
pub fn inlier_ratio_from_mask(mask : InlierMask) -> Double {
  consensus_ratio(mask)
}

///|
pub fn residual_mean_for_mask(
  residuals : ArrayView[Double],
  mask : InlierMask,
) -> Double raise @core.GeometryError {
  if residuals.length() != mask.length() {
    raise @core.GeometryError::DegenerateInput(
      "residual and mask lengths differ",
    )
  }
  let mut total = 0.0
  let mut count = 0
  for i in 0..<residuals.length() {
    if mask.is_inlier(i) {
      total += residuals[i]
      count += 1
    }
  }
  if count == 0 {
    raise @core.GeometryError::NotEnoughPoints("mask has no inliers")
  }
  total / Double::from_int(count)
}
