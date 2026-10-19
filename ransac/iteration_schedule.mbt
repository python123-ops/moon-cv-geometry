///|
/// Numerically stable RANSAC iteration estimate.
pub fn schedule_required_iterations(
  sample_size : Int,
  inlier_ratio : Double,
  confidence : Double,
) -> Int {
  let target = bounded_probability(confidence).min(0.999999999)
  bounded_iterations(
    sample_success(inlier_ratio, sample_size),
    target,
    2147483647,
  )
}

///|
pub(all) struct IterationSchedule {
  max_iterations : Int
  confidence : Double
}

///|
pub fn IterationSchedule::new(
  max_iterations~ : Int,
  confidence~ : Double,
) -> IterationSchedule {
  {
    max_iterations: max_iterations.max(1),
    confidence: bounded_probability(confidence).min(0.999999999),
  }
}

///|
pub fn IterationSchedule::limit_for(
  schedule : IterationSchedule,
  inlier_ratio : Double,
  sample_size : Int,
) -> Int {
  schedule_required_iterations(sample_size, inlier_ratio, schedule.confidence).min(
    schedule.max_iterations,
  )
}

///|
pub(all) struct ScheduleProgress {
  iteration : Int
  iterations_remaining : Int
  best_ratio : Double
  expected_success : Double
} derive(Debug, Eq)

///|
pub extend ScheduleProgress with @debug.Debug::{to_repr}

///|
pub extend ScheduleProgress with Eq::{equal, not_equal}

///|
pub fn IterationSchedule::progress(
  schedule : IterationSchedule,
  iteration~ : Int,
  observed_inlier_ratio~ : Double,
  sample_size~ : Int,
) -> ScheduleProgress {
  let ratio = bounded_probability(observed_inlier_ratio)
  let limit = schedule.limit_for(ratio, sample_size)
  let used = iteration.max(0).min(schedule.max_iterations)
  let remain = (limit - used).max(0)
  let success = success_after(sample_success(ratio, sample_size), used)
  {
    iteration: used,
    iterations_remaining: remain,
    best_ratio: ratio,
    expected_success: success.max(0.0).min(1.0),
  }
}

///|
/// Generate deterministic checkpoints for progress reporting and early stopping.
pub fn schedule_checkpoints(
  schedule : IterationSchedule,
  count : Int,
) -> Array[Int] {
  let result : Array[Int] = []
  if count <= 0 {
    return result
  }
  for index in 0..<count {
    let checkpoint = schedule.max_iterations.to_int64() *
      (index + 1).to_int64() /
      count.to_int64()
    result.push(checkpoint.to_int().max(1))
  }
  result
}
