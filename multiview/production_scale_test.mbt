///|
test "reconstruction pipeline aggregates track observations" {
  let observations = [
    TrackObservation::new(
      point_id=1,
      pixel=@core.Point2::new(x=1.0, y=2.0),
      view_id=0,
    ),
    TrackObservation::new(
      point_id=1,
      pixel=@core.Point2::new(x=1.1, y=2.1),
      view_id=1,
    ),
    TrackObservation::new(
      point_id=2,
      pixel=@core.Point2::new(x=5.0, y=6.0),
      view_id=0,
    ),
  ]
  let report = reconstruction_track_report(observations, minimum_views=2)
  assert_eq(report.total_tracks, 2)
  assert_eq(report.triangulatable_tracks, 1)
}

///|
test "observation matrix and residual blocks preserve dimensions" {
  let matrix = ObservationMatrix::new(views=3, tracks=2)
  ignore(matrix.set(0, 0, true))
  ignore(matrix.set(1, 0, true))
  assert_eq(matrix.track_degree(0), 2)
  let block = residual_block_2d(
    @core.Point2::new(x=1.0, y=2.0),
    @core.Point2::new(x=1.5, y=1.0),
  )
  assert_eq(block.length(), 2)
}

///|
test "view graph and baseline metrics identify connected support" {
  let graph = ViewGraph::new(3)
  graph.add_edge(0, 1)
  graph.add_edge(1, 2)
  assert_eq(graph.component_count(), 1)
  let baseline = baseline_statistics([0.1, 0.2, 0.3])
  assert_true(baseline.mean > 0.0)
}

///|
test "track index and pose graph expose pair support" {
  let index = TrackIndex::new()
  index.insert(1, 0)
  index.insert(1, 1)
  index.insert(2, 1)
  assert_eq(index.track_count(), 2)
  assert_eq(index.pair_count(0, 1), 1)
  let graph = WeightedPoseGraph::new(3)
  graph.connect(0, 1, 2.0)
  assert_true(graph.weight(0, 1) == 2.0)
}

///|
test "track analytics summarize motion and visibility" {
  let observations = [
    TrackObservation::new(
      point_id=1,
      pixel=@core.Point2::new(x=0.0, y=0.0),
      view_id=0,
    ),
    TrackObservation::new(
      point_id=1,
      pixel=@core.Point2::new(x=1.0, y=0.0),
      view_id=1,
    ),
  ]
  let analytics = track_analytics(observations)
  assert_eq(analytics.track_count, 1)
  assert_true(analytics.mean_span > 0.0)
}

///|
test "track windows filter, export, and score observations" {
  let observations = [
    TrackObservation::new(
      point_id=1,
      pixel=@core.Point2::new(x=0.0, y=0.0),
      view_id=0,
    ),
    TrackObservation::new(
      point_id=1,
      pixel=@core.Point2::new(x=1.0, y=0.0),
      view_id=1,
    ),
    TrackObservation::new(
      point_id=2,
      pixel=@core.Point2::new(x=5.0, y=5.0),
      view_id=1,
    ),
  ]
  let summary = track_window_summary(observations)
  assert_eq(summary.tracks, 2)
  assert_true(track_density(observations) > 0.0)
  assert_true(track_observations_csv(observations).contains("point_id"))
  assert_true(track_quality_batch_score(observations, 1, 0.1) >= 0.0)
}

///|
test "track export handles empty tables and duplicate pairs" {
  assert_eq(track_view_first([]), 0)
  assert_eq(track_observations_csv([]), "point_id,view_id,x,y")
  let observation = TrackObservation::new(
    point_id=3,
    pixel=@core.Point2::new(x=1.0, y=2.0),
    view_id=4,
  )
  assert_eq(track_duplicate_pair_count([observation, observation]), 1)
}

///|
test "track quality and temporal APIs cover filtering paths" {
  let observations = [
    TrackObservation::new(
      point_id=1,
      pixel=@core.Point2::new(x=0.0, y=0.0),
      view_id=0,
    ),
    TrackObservation::new(
      point_id=1,
      pixel=@core.Point2::new(x=1.0, y=1.0),
      view_id=2,
    ),
    TrackObservation::new(
      point_id=2,
      pixel=@core.Point2::new(x=3.0, y=3.0),
      view_id=2,
    ),
  ]
  ignore(track_window_sort_by_view(observations))
  ignore(track_window_sort_by_point(observations))
  ignore(track_window_limit_views(observations, 0, 2))
  ignore(track_window_limit_points(observations, 1, 2))
  ignore(track_window_group_by_view(observations, 2))
  ignore(track_window_group_by_point(observations, 1))
  ignore(track_window_view_counts(observations))
  ignore(track_window_point_counts(observations))
  ignore(track_window_view_balance(observations))
  ignore(track_window_consistent_motion(observations, 10.0))
  ignore(track_window_interpolate(observations[0], observations[1], 1))
  ignore(track_window_interpolate_gap(observations, 1, 0, 2))
  ignore(track_window_deduplicate(observations))
  ignore(track_window_retain_best(observations, 2))
  ignore(track_window_select_keyframes(observations, 1, 0.0))
  ignore(track_window_temporal_gaps(observations))
  ignore(track_window_gap_penalty(observations))
  ignore(track_window_reliability(observations, 1, 10.0))
  ignore(track_quality_batch_ids(observations))
  ignore(track_quality_batch_scores(observations, 1, 0.1))
  ignore(track_quality_batch_summary(observations, 1, 0.1, 0.5))
  ignore(track_quality_batch_accepted_ids(observations, 1, 0.1, 0.0))
  ignore(track_quality_batch_rejected_ids(observations, 1, 0.1, 2.0))
  ignore(track_quality_batch_mean_span(observations))
  ignore(track_quality_batch_max_span(observations))
  ignore(track_quality_batch_mean_views(observations))
  ignore(track_quality_batch_view_support(observations, 1))
  ignore(track_quality_batch_motion_support(observations, 10.0))
  ignore(track_quality_batch_filter(observations, 1, 0.1, 0.0))
  ignore(track_quality_batch_reject(observations, 1, 0.1, 2.0))
  ignore(track_quality_batch_balance(observations))
  ignore(track_quality_batch_temporal_density(observations))
  ignore(track_quality_batch_score(observations, 1, 0.1))
  ignore(track_quality_batch_stable_windows(observations, 2, 1, 0.1, 0.0))
  ignore(track_observation_csv(observations[0]))
  ignore(track_checksum(observations))
  ignore(track_pixel_centroid(observations))
  ignore(track_pixel_radius(observations))
  ignore(track_pixel_density(observations))
  ignore(track_export_quality(observations, 1, 10.0))
}
