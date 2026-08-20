///|
/// Geometric step schedule for deterministic calibration refinement.
pub fn calibration_step_schedule(
  initial~ : Double,
  decay~ : Double,
  count~ : Int,
) -> Array[Double] {
  let result : Array[Double] = []
  let mut step = initial.abs()
  let factor = decay.max(0.0).min(1.0)
  for _ in 0..<count.max(0) {
    result.push(step)
    step *= factor
  }
  result
}

///|
pub fn calibration_temperature_schedule(
  initial : Double,
  cooling : Double,
  count : Int,
) -> Array[Double] {
  calibration_step_schedule(initial~, decay=cooling, count~)
}

///|
pub fn calibration_iteration_budget(
  levels : Int,
  iterations_per_level : Int,
) -> Int {
  levels.max(0) * iterations_per_level.max(0)
}

///|
pub fn calibration_level_of_iteration(
  iteration : Int,
  iterations_per_level : Int,
  levels : Int,
) -> Int {
  if iterations_per_level <= 0 || levels <= 0 {
    0
  } else {
    (iteration.max(0) / iterations_per_level).min(levels - 1)
  }
}

///|
pub fn calibration_progress(iteration : Int, total : Int) -> Double {
  if total <= 0 {
    0.0
  } else {
    iteration.max(0).min(total).to_double() / total.to_double()
  }
}

///|
pub fn calibration_should_stop(
  iteration : Int,
  total : Int,
  loss : Double,
  target : Double,
) -> Bool {
  iteration >= total || loss <= target
}

///|
pub fn calibration_loss_delta(previous : Double, current : Double) -> Double {
  previous - current
}

///|
pub fn calibration_improvement_ratio(
  previous : Double,
  current : Double,
) -> Double {
  if previous.abs() <= 0.000000000001 {
    0.0
  } else {
    (previous - current) / previous.abs()
  }
}

///|
pub fn calibration_has_converged(
  losses : ArrayView[Double],
  tolerance : Double,
  window : Int,
) -> Bool {
  if losses.length() < 2 || window <= 0 || losses.length() < window + 1 {
    false
  } else {
    let start = losses.length() - window - 1
    let improvement = losses[start] - losses[losses.length() - 1]
    improvement.abs() <= tolerance
  }
}

///|
pub fn calibration_best_loss(losses : ArrayView[Double]) -> Double {
  if losses.length() == 0 {
    0.0
  } else {
    let mut result = losses[0]
    for loss in losses {
      result = result.min(loss)
    }
    result
  }
}

///|
pub fn calibration_loss_history_append(
  history : Array[Double],
  loss : Double,
  capacity : Int,
) -> Unit {
  history.push(loss)
  if capacity > 0 {
    while history.length() > capacity {
      let _ = history.remove(0)
    }
  }
}
