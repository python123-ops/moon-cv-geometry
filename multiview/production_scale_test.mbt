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
