///|
test "point cloud quality report scores reconstruction" {
  let points = [
    @core.Point3::new(x=0.0, y=0.0, z=1.0),
    @core.Point3::new(x=1.0, y=0.0, z=2.0),
    @core.Point3::new(x=0.0, y=1.0, z=-1.0),
  ]
  let report = PointCloudReport::from_points(points)
  assert_true(report.total == 3)
  assert_true(report.positive_depth == 2)
  assert_true(report.depth_span() > 0.0)
  assert_true(report.positive_ratio() > 0.6)
}

///|
test "reprojection summary combines residual vectors" {
  let summary = reprojection_summary(
    [0.1, 0.2, 0.3, 5.0],
    outlier_threshold=1.0,
  )
  assert_true(summary.inliers == 3)
  assert_true(summary.outliers == 1)
  assert_true(summary.rms > 0.0)
}

///|
test "view graph finds connected components" {
  let graph = ViewGraph::new(4)
  graph.add_edge(0, 1)
  graph.add_edge(1, 2)
  graph.add_edge(3, 3)
  assert_true(graph.component_count() == 2)
  assert_true(graph.has_edge(0, 1))
  assert_false(graph.has_edge(0, 3))
}
