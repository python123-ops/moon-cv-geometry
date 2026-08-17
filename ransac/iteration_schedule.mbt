///|
/// Numerically stable RANSAC iteration estimate.
pub fn schedule_required_iterations(
  sample_size : Int,
  inlier_ratio : Double,
  confidence : Double,
) -> Int {
  if sample_size <= 0 || inlier_ratio >= 1.0 {
    return 1
  }
  if inlier_ratio <= 0.0 {
    return 2147483647
  }
  let mut probability = 1.0
  for _ in 0..<sample_size {
    probability *= inlier_ratio
  }
  let target = confidence.max(0.0).min(0.999999999)
  let mut failure = 1.0
  let mut iterations = 0
  while iterations < 2147483647 && 1.0 - failure < target {
    failure *= 1.0 - probability
    iterations += 1
  }
  iterations.max(1)
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
    confidence: confidence.max(0.0).min(0.999999999),
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
pub fn IterationSchedule::progress(
  schedule : IterationSchedule,
  iteration~ : Int,
  observed_inlier_ratio~ : Double,
  sample_size~ : Int,
) -> ScheduleProgress {
  let ratio = observed_inlier_ratio.max(0.0).min(1.0)
  let limit = schedule.limit_for(ratio, sample_size)
  let used = iteration.max(0).min(schedule.max_iterations)
  let remain = (limit - used).max(0)
  let mut one_sample = 1.0
  for _ in 0..<sample_size {
    one_sample *= ratio
  }
  let mut failure = 1.0
  for _ in 0..<used {
    failure *= 1.0 - one_sample
  }
  let success = 1.0 - failure
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
  for i in 1..<(count + 1) {
    result.push((schedule.max_iterations * i / count).max(1))
  }
  result
}
