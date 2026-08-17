///|
pub(all) struct TrackTable {
  observations : Array[TrackObservation]
}

///|
pub fn TrackTable::new() -> TrackTable {
  { observations: [] }
}

///|
pub fn TrackTable::add(
  table : TrackTable,
  observation : TrackObservation,
) -> Unit {
  table.observations.push(observation)
}

///|
pub fn TrackTable::observation_count(table : TrackTable) -> Int {
  table.observations.length()
}

///|
pub fn TrackTable::track_count(table : TrackTable) -> Int {
  let ids : Array[Int] = []
  for observation in table.observations {
    if !ids.contains(observation.point_id) {
      ids.push(observation.point_id)
    }
  }
  ids.length()
}

///|
pub fn TrackTable::observations_for(
  table : TrackTable,
  track_id : Int,
) -> Array[TrackObservation] {
  let result : Array[TrackObservation] = []
  for observation in table.observations {
    if observation.point_id == track_id {
      result.push(observation)
    }
  }
  result
}

///|
pub fn TrackTable::is_triangulatable(
  table : TrackTable,
  track_id : Int,
  minimum_views : Int,
) -> Bool {
  let observations = table.observations_for(track_id)
  if observations.length() < minimum_views {
    return false
  }
  let views : Array[Int] = []
  for observation in observations {
    if !views.contains(observation.view_id) {
      views.push(observation.view_id)
    }
  }
  views.length() >= minimum_views
}

///|
pub(all) struct TrackQuality {
  unique_views : Int
  pixel_span : Double
  has_unique_views : Bool
  centroid : @core.Point2
} derive(Debug, Eq)

///|
pub fn track_quality(
  observations : ArrayView[TrackObservation],
) -> TrackQuality {
  if observations.length() == 0 {
    return {
      unique_views: 0,
      pixel_span: 0.0,
      has_unique_views: true,
      centroid: @core.Point2::new(x=0.0, y=0.0),
    }
  }
  let views : Array[Int] = []
  let mut min_x = observations[0].pixel.x
  let mut max_x = observations[0].pixel.x
  let mut min_y = observations[0].pixel.y
  let mut max_y = observations[0].pixel.y
  let mut sum_x = 0.0
  let mut sum_y = 0.0
  let mut unique = true
  for observation in observations {
    if views.contains(observation.view_id) {
      unique = false
    } else {
      views.push(observation.view_id)
    }
    if observation.pixel.x < min_x {
      min_x = observation.pixel.x
    }
    if observation.pixel.x > max_x {
      max_x = observation.pixel.x
    }
    if observation.pixel.y < min_y {
      min_y = observation.pixel.y
    }
    if observation.pixel.y > max_y {
      max_y = observation.pixel.y
    }
    sum_x += observation.pixel.x
    sum_y += observation.pixel.y
  }
  let span = @core.Vec2::new(x=max_x - min_x, y=max_y - min_y).norm()
  {
    unique_views: views.length(),
    pixel_span: span,
    has_unique_views: unique,
    centroid: @core.Point2::new(
      x=sum_x / observations.length().to_double(),
      y=sum_y / observations.length().to_double(),
    ),
  }
}

///|
pub fn deduplicate_track(
  observations : ArrayView[TrackObservation],
) -> Array[TrackObservation] {
  let result : Array[TrackObservation] = []
  let views : Array[Int] = []
  for observation in observations {
    if !views.contains(observation.view_id) {
      views.push(observation.view_id)
      result.push(observation)
    }
  }
  result
}
