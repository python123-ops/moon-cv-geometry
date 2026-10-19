///|
test "track table aggregates observations by feature" {
  let table = @multiview.TrackTable::new()
  table.add(
    @multiview.TrackObservation::new(
      point_id=7,
      view_id=0,
      pixel=@core.Point2::new(x=1.0, y=2.0),
    ),
  )
  table.add(
    @multiview.TrackObservation::new(
      point_id=7,
      view_id=1,
      pixel=@core.Point2::new(x=1.1, y=2.1),
    ),
  )
  table.add(
    @multiview.TrackObservation::new(
      point_id=9,
      view_id=0,
      pixel=@core.Point2::new(x=5.0, y=6.0),
    ),
  )
  assert_eq(table.track_count(), 2)
  assert_eq(table.observation_count(), 3)
  assert_eq(table.observations_for(7).length(), 2)
  assert_true(table.is_triangulatable(7, 2))
}

///|
test "track quality identifies duplicate views and spread" {
  let observations = [
    @multiview.TrackObservation::new(
      point_id=1,
      view_id=0,
      pixel=@core.Point2::new(x=0.0, y=0.0),
    ),
    @multiview.TrackObservation::new(
      point_id=1,
      view_id=0,
      pixel=@core.Point2::new(x=0.1, y=0.1),
    ),
    @multiview.TrackObservation::new(
      point_id=1,
      view_id=2,
      pixel=@core.Point2::new(x=10.0, y=2.0),
    ),
  ]
  let q = @multiview.track_quality(observations)
  assert_eq(q.unique_views, 2)
  assert_true(q.pixel_span > 10.0)
  assert_false(q.has_unique_views)
}
