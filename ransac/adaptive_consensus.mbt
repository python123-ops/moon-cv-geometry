///|
/// Update an inlier estimate without restarting a running solver.
pub fn update_inlier_ratio(
  previous : Double,
  observed : Int,
  total : Int,
  momentum? : Double = 0.25,
) -> Double {
  if total <= 0 {
    return previous.max(0.0).min(1.0)
  }
  let current = observed.to_double() / total.to_double()
  let alpha = momentum.max(0.0).min(1.0)
  previous.max(0.0).min(1.0) * (1.0 - alpha) + current * alpha
}

///|
pub(all) struct AdaptiveConsensus {
  mut ratio : Double
  threshold : Double
  mut iterations : Int
}

///|
pub fn AdaptiveConsensus::new(threshold~ : Double) -> AdaptiveConsensus {
  { ratio: 0.0, threshold: threshold.max(0.0), iterations: 0 }
}

///|
pub fn AdaptiveConsensus::update(
  state : AdaptiveConsensus,
  residuals : ArrayView[Double],
) -> Unit {
  let mut count = 0
  for residual in residuals {
    if @core.abs(residual) <= state.threshold {
      count += 1
    }
  }
  state.ratio = update_inlier_ratio(state.ratio, count, residuals.length())
  state.iterations += 1
}

///|
pub fn AdaptiveConsensus::ratio(state : AdaptiveConsensus) -> Double {
  state.ratio
}

///|
pub fn AdaptiveConsensus::iterations(state : AdaptiveConsensus) -> Int {
  state.iterations
}

///|
pub fn AdaptiveConsensus::should_stop(
  state : AdaptiveConsensus,
  minimum_ratio : Double,
  minimum_iterations : Int,
) -> Bool {
  state.iterations >= minimum_iterations && state.ratio >= minimum_ratio
}

///|
pub fn adaptive_threshold(
  residuals : ArrayView[Double],
  floor : Double,
  multiplier : Double,
) -> Double raise @core.GeometryError {
  if residuals.length() == 0 {
    raise @core.GeometryError::NotEnoughPoints(
      "adaptive threshold needs residuals",
    )
  }
  let mut sum = 0.0
  for residual in residuals {
    sum += @core.abs(residual)
  }
  (sum / residuals.length().to_double() * multiplier).max(floor)
}
