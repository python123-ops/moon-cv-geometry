///|
/// Stable export helpers for track audit and downstream analytics.
pub fn track_observation_csv(observation : TrackObservation) -> String {
  observation.point_id.to_string() +
  "," +
  observation.view_id.to_string() +
  "," +
  observation.pixel.x.to_string() +
  "," +
  observation.pixel.y.to_string()
}

///|
pub fn track_observations_csv(
  observations : ArrayView[TrackObservation],
) -> String {
  let mut result = "point_id,view_id,x,y"
  for observation in observations {
    result += "\n" + track_observation_csv(observation)
  }
  result
}

///|
pub fn track_observation_checksum(observation : TrackObservation) -> Double {
  observation.point_id.to_double() * 31.0 +
  observation.view_id.to_double() * 17.0 +
  observation.pixel.x * 7.0 +
  observation.pixel.y * 13.0
}

///|
pub fn track_checksum(observations : ArrayView[TrackObservation]) -> Double {
  let mut result = 0.0
  for i in 0..<observations.length() {
    result += (i + 1).to_double() * track_observation_checksum(observations[i])
  }
  result
}

///|
pub fn track_view_first(observations : ArrayView[TrackObservation]) -> Int {
  if observations.length() == 0 {
    0
  } else {
    let mut result = observations[0].view_id
    for observation in observations {
      result = result.min(observation.view_id)
    }
    result
  }
}

///|
pub fn track_view_last(observations : ArrayView[TrackObservation]) -> Int {
  let mut result = 0
  for observation in observations {
    result = result.max(observation.view_id)
  }
  result
}

///|
pub fn track_point_first(observations : ArrayView[TrackObservation]) -> Int {
  if observations.length() == 0 {
    0
  } else {
    let mut result = observations[0].point_id
    for observation in observations {
      result = result.min(observation.point_id)
    }
    result
  }
}

///|
pub fn track_point_last(observations : ArrayView[TrackObservation]) -> Int {
  let mut result = 0
  for observation in observations {
    result = result.max(observation.point_id)
  }
  result
}

///|
pub fn track_view_span(observations : ArrayView[TrackObservation]) -> Int {
  track_view_last(observations) - track_view_first(observations)
}

///|
pub fn track_point_span(observations : ArrayView[TrackObservation]) -> Int {
  track_point_last(observations) - track_point_first(observations)
}

///|
pub fn track_density(observations : ArrayView[TrackObservation]) -> Double {
  let views = track_view_span(observations) + 1
  let points = track_point_span(observations) + 1
  if views <= 0 || points <= 0 {
    0.0
  } else {
    observations.length().to_double() / (views * points).to_double()
  }
}

///|
pub fn track_has_view(
  observations : ArrayView[TrackObservation],
  view : Int,
) -> Bool {
  for observation in observations {
    if observation.view_id == view {
      return true
    }
  }
  false
}

///|
pub fn track_has_point(
  observations : ArrayView[TrackObservation],
  point : Int,
) -> Bool {
  for observation in observations {
    if observation.point_id == point {
      return true
    }
  }
  false
}

///|
pub fn track_count_view(
  observations : ArrayView[TrackObservation],
  view : Int,
) -> Int {
  let mut result = 0
  for observation in observations {
    if observation.view_id == view {
      result += 1
    }
  }
  result
}

///|
pub fn track_count_point(
  observations : ArrayView[TrackObservation],
  point : Int,
) -> Int {
  let mut result = 0
  for observation in observations {
    if observation.point_id == point {
      result += 1
    }
  }
  result
}

///|
pub fn track_duplicate_pair_count(
  observations : ArrayView[TrackObservation],
) -> Int {
  let mut result = 0
  for i in 0..<observations.length() {
    for j in (i + 1)..<observations.length() {
      if observations[i].point_id == observations[j].point_id &&
        observations[i].view_id == observations[j].view_id {
        result += 1
      }
    }
  }
  result
}

///|
pub fn track_unique_pair_ratio(
  observations : ArrayView[TrackObservation],
) -> Double {
  if observations.length() == 0 {
    0.0
  } else {
    1.0 -
    track_duplicate_pair_count(observations).to_double() /
    observations.length().to_double()
  }
}

///|
pub fn track_pixel_centroid(
  observations : ArrayView[TrackObservation],
) -> @core.Point2 {
  if observations.length() == 0 {
    @core.Point2::new(x=0.0, y=0.0)
  } else {
    let mut x = 0.0
    let mut y = 0.0
    for observation in observations {
      x += observation.pixel.x
      y += observation.pixel.y
    }
    @core.Point2::new(
      x=x / observations.length().to_double(),
      y=y / observations.length().to_double(),
    )
  }
}

///|
pub fn track_pixel_radius(observations : ArrayView[TrackObservation]) -> Double {
  let center = track_pixel_centroid(observations)
  let mut result = 0.0
  for observation in observations {
    result = result.max(observation.pixel.minus(center).norm())
  }
  result
}

///|
pub fn track_pixel_density(
  observations : ArrayView[TrackObservation],
) -> Double {
  let radius = track_pixel_radius(observations)
  if radius <= 0.0 {
    0.0
  } else {
    observations.length().to_double() / (3.141592653589793 * radius * radius)
  }
}

///|
pub fn track_export_quality(
  observations : ArrayView[TrackObservation],
  minimum_views : Int,
  maximum_motion : Double,
) -> Double {
  track_unique_pair_ratio(observations) *
  track_view_density(observations, track_view_span(observations) + 1) *
  track_quality_batch_score(observations, minimum_views, maximum_motion)
}
