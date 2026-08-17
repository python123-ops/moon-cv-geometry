///|
test "iteration schedule grows with confidence and outliers" {
  let low = schedule_required_iterations(8, 0.8, 0.95)
  let high = schedule_required_iterations(8, 0.5, 0.99)
  assert_true(high > low)
  let schedule = IterationSchedule::new(max_iterations=1000, confidence=0.99)
  assert_eq(
    schedule.limit_for(0.8, 8),
    schedule_required_iterations(8, 0.8, 0.99).min(1000),
  )
  assert_eq(schedule.limit_for(1.0, 8), 1)
}

///|
test "schedule clamps invalid inputs and reports progress" {
  let schedule = IterationSchedule::new(max_iterations=25, confidence=0.99)
  assert_eq(schedule.limit_for(0.0, 8), 25)
  assert_eq(schedule.limit_for(1.2, 8), 1)
  let p = schedule.progress(
    iteration=5,
    observed_inlier_ratio=0.7,
    sample_size=4,
  )
  assert_true(p.iterations_remaining > 0)
  assert_true(p.best_ratio == 0.7)
}
