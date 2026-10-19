///|
test "iteration counts use the minimum sufficient number of trials" {
  assert_eq(
    @ransac.required_iterations(success_probability=0.5, confidence=0.75),
    2,
  )
  assert_eq(
    @ransac.adaptive_iteration_bound(
      inlier_ratio=0.5,
      sample_size=1,
      confidence=0.75,
    ),
    2,
  )
  assert_eq(@ransac.schedule_required_iterations(1, 0.5, 0.75), 2)
  assert_eq(@ransac.adaptive_required_iterations(0.5, 1, 0.75, 100), 2)
  for ratio in [0.2, 0.5, 0.8] {
    for size in [1, 2, 4] {
      for target in [0.9, 0.95, 0.99] {
        let p = @ransac.sample_probability(inlier_ratio=ratio, sample_size=size)
        let mut failure = 1.0
        let mut expected = 0
        while failure > 1.0 - target && expected < 10000 {
          failure *= 1.0 - p
          expected += 1
        }
        assert_eq(
          @ransac.adaptive_required_iterations(ratio, size, target, 10000),
          expected,
        )
        assert_eq(
          @ransac.required_iterations(success_probability=p, confidence=target),
          expected,
        )
      }
    }
  }
}

///|
test "tiny probabilities and huge budgets remain bounded and informative" {
  assert_eq(@ransac.schedule_required_iterations(8, 0.001, 0.99), 2147483647)
  assert_eq(
    @ransac.schedule_required_iterations(2147483647, 0.5, 0.99),
    2147483647,
  )
  assert_eq(@ransac.required_iterations(success_probability=1.0e-30), 1000000)
  assert_eq(
    @ransac.adaptive_required_iterations(0.0, 8, 0.99, 2147483647),
    2147483647,
  )
  let confidence = @ransac.confidence_from_success(
    iterations=2147483647,
    success_probability=1.0e-20,
  )
  assert_true(confidence > 2.1e-11 && confidence < 2.2e-11)
  assert_eq(
    @ransac.confidence_from_success(iterations=0, success_probability=1.0),
    0.0,
  )
  assert_eq(
    @ransac.confidence_from_success(
      iterations=2147483647,
      success_probability=1.0,
    ),
    1.0,
  )
  assert_eq(
    @ransac.expected_successes(
      iterations=2147483647,
      inlier_ratio=0.0,
      sample_size=2147483647,
    ),
    0.0,
  )
}

///|
test "probability APIs reject NaN and infinity" {
  let infinity = 1.0e308 * 1.0e308
  for invalid in [infinity, -infinity, infinity - infinity] {
    try @ransac.required_iterations(success_probability=invalid) catch {
      @core.GeometryError::DegenerateInput(_) => ()
      _ => fail("unexpected error")
    } noraise {
      _ => fail("expected invalid probability")
    }
    try
      @ransac.confidence_from_success(iterations=5, success_probability=invalid)
    catch {
      @core.GeometryError::DegenerateInput(_) => ()
      _ => fail("unexpected error")
    } noraise {
      _ => fail("expected invalid probability")
    }
    try @ransac.sample_probability(inlier_ratio=invalid, sample_size=2) catch {
      @core.GeometryError::DegenerateInput(_) => ()
      _ => fail("unexpected error")
    } noraise {
      _ => fail("expected invalid ratio")
    }
    try
      @ransac.adaptive_iteration_bound(
        inlier_ratio=0.5,
        sample_size=2,
        confidence=invalid,
      )
    catch {
      @core.GeometryError::DegenerateInput(_) => ()
      _ => fail("unexpected error")
    } noraise {
      _ => fail("expected invalid confidence")
    }
  }
}

///|
test "schedule checkpoints do not overflow and progress handles large counts" {
  let schedule = @ransac.IterationSchedule::new(
    max_iterations=2147483647,
    confidence=0.99,
  )
  assert_eq(@ransac.schedule_checkpoints(schedule, 3), [
    715827882, 1431655764, 2147483647,
  ])
  let progress = schedule.progress(
    iteration=2147483647,
    observed_inlier_ratio=0.5,
    sample_size=4,
  )
  assert_eq(progress.iterations_remaining, 0)
  assert_eq(progress.expected_success, 1.0)
  assert_eq(@ransac.schedule_checkpoints(schedule, 0), [])
}

///|
test "homography RANSAC survives a degenerate first four point prefix" {
  let src = [
    @core.Point2::new(x=0.0, y=0.0),
    @core.Point2::new(x=1.0, y=0.0),
    @core.Point2::new(x=2.0, y=0.0),
    @core.Point2::new(x=3.0, y=0.0),
    @core.Point2::new(x=0.0, y=1.0),
    @core.Point2::new(x=1.0, y=1.0),
    @core.Point2::new(x=2.0, y=1.0),
    @core.Point2::new(x=3.0, y=1.0),
  ]
  let dst = src.map(p => @core.Point2::new(x=p.x + 10.0, y=p.y + 20.0))
  let config = @ransac.RansacConfig::new(
    iterations=64,
    threshold=0.000001,
    min_inliers=8,
    seed=7U,
  )
  let first = @ransac.estimate_homography_ransac(src, dst, config~)
  let second = @ransac.estimate_homography_ransac(src, dst, config~)
  assert_eq(first.inlier_count, 8)
  assert_true(first.inliers == second.inliers)
  assert_true(@core.almost_equal(first.score, second.score))
}

///|
test "RANSAC validates configuration before estimating models" {
  let points = [
    @core.Point2::new(x=0.0, y=0.0),
    @core.Point2::new(x=1.0, y=0.0),
    @core.Point2::new(x=0.0, y=1.0),
    @core.Point2::new(x=1.0, y=1.0),
  ]
  let infinity = 1.0e308 * 1.0e308
  for
    config in [
      @ransac.RansacConfig::new(iterations=0),
      @ransac.RansacConfig::new(threshold=infinity),
      @ransac.RansacConfig::new(threshold=infinity - infinity),
      @ransac.RansacConfig::new(min_inliers=5),
    ] {
    try @ransac.estimate_homography_ransac(points, points, config~) catch {
      @core.GeometryError::DegenerateInput(_) => ()
      _ => fail("unexpected error")
    } noraise {
      _ => fail("expected invalid config")
    }
    try @ransac.estimate_fundamental_ransac(points, points, config~) catch {
      @core.GeometryError::DegenerateInput(_) => ()
      _ => fail("unexpected error")
    } noraise {
      _ => fail("expected invalid config")
    }
  }
}
