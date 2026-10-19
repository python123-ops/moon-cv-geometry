///|
pub fn confidence_from_success(
  iterations~ : Int,
  success_probability~ : Double,
) -> Double raise @core.GeometryError {
  if iterations < 0 || !finite_probability(success_probability) {
    raise @core.GeometryError::DegenerateInput(
      "confidence parameters are invalid",
    )
  }
  success_after(success_probability, iterations)
}

///|
pub fn required_iterations(
  success_probability~ : Double,
  confidence? : Double = 0.99,
) -> Int raise @core.GeometryError {
  if !finite_probability(success_probability) ||
    success_probability <= 0.0 ||
    !finite_probability(confidence) ||
    confidence <= 0.0 ||
    confidence >= 1.0 {
    raise @core.GeometryError::DegenerateInput(
      "iteration probability parameters are invalid",
    )
  }
  bounded_iterations(success_probability, confidence, 1000000)
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
