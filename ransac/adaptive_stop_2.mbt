///|
/// Running consensus state for early stopping and budget control.
pub(all) struct AdaptiveStopState {
  minimum_iterations : Int
  target_ratio : Double
  mut iterations : Int
  mut best_ratio : Double
  mut stable_iterations : Int
} derive(Debug, Eq)

///|
pub extend AdaptiveStopState with @debug.Debug::{to_repr}

///|
pub extend AdaptiveStopState with Eq::{equal, not_equal}

///|
pub fn AdaptiveStopState::new(
  minimum_iterations~ : Int,
  target_ratio~ : Double,
) -> AdaptiveStopState {
  {
    minimum_iterations: minimum_iterations.max(0),
    target_ratio: target_ratio.max(0.0).min(1.0),
    iterations: 0,
    best_ratio: 0.0,
    stable_iterations: 0,
  }
}

///|
pub fn AdaptiveStopState::observe(
  state : AdaptiveStopState,
  inliers~ : Int,
  total~ : Int,
) -> Unit {
  let ratio = if total <= 0 {
    0.0
  } else {
    inliers.max(0).min(total).to_double() / total.to_double()
  }
  state.iterations += 1
  if ratio >= state.best_ratio {
    if ratio == state.best_ratio {
      state.stable_iterations += 1
    } else {
      state.stable_iterations = 0
    }
    state.best_ratio = ratio
  }
}

///|
pub fn AdaptiveStopState::should_stop(state : AdaptiveStopState) -> Bool {
  state.iterations >= state.minimum_iterations &&
  state.best_ratio >= state.target_ratio
}

///|
pub fn AdaptiveStopState::progress(
  state : AdaptiveStopState,
  maximum_iterations : Int,
) -> Double {
  if maximum_iterations <= 0 {
    0.0
  } else {
    state.iterations.min(maximum_iterations).to_double() /
    maximum_iterations.to_double()
  }
}

///|
pub fn AdaptiveStopState::remaining(
  state : AdaptiveStopState,
  maximum_iterations : Int,
) -> Int {
  (maximum_iterations - state.iterations).max(0)
}

///|
pub fn AdaptiveStopState::is_stable(
  state : AdaptiveStopState,
  minimum_repetitions : Int,
) -> Bool {
  state.stable_iterations >= minimum_repetitions
}

///|
pub fn adaptive_confidence(
  ratio : Double,
  sample_size : Int,
  iterations : Int,
) -> Double {
  success_after(sample_success(ratio, sample_size), iterations.max(0))
}

///|
pub fn adaptive_required_iterations(
  ratio : Double,
  sample_size : Int,
  target_confidence : Double,
  maximum : Int,
) -> Int {
  bounded_iterations(
    sample_success(ratio, sample_size),
    target_confidence,
    maximum,
  )
}

///|
pub fn adaptive_budget_schedule(
  initial : Int,
  decay : Double,
  count : Int,
) -> Array[Int] {
  let result : Array[Int] = []
  let mut budget = initial.max(1).to_double()
  for _ in 0..<count.max(0) {
    result.push(budget.to_int().max(1))
    budget *= decay.max(0.0).min(1.0)
  }
  result
}

///|
pub fn adaptive_threshold_schedule(
  initial : Double,
  growth : Double,
  count : Int,
) -> Array[Double] {
  let result : Array[Double] = []
  let mut threshold = initial.max(0.0)
  for _ in 0..<count.max(0) {
    result.push(threshold)
    threshold *= growth.max(1.0)
  }
  result
}
