///|
/// Aggregate track-level visibility and pixel motion statistics.
pub(all) struct TrackAnalytics {
  track_count : Int
  observation_count : Int
  mean_views : Double
  mean_span : Double
  maximum_span : Double
  duplicate_observations : Int
} derive(Debug, Eq)

///|
pub fn track_analytics(
  observations : ArrayView[TrackObservation],
) -> TrackAnalytics {
  let ids : Array[Int] = []
  for observation in observations {
    if !ids.contains(observation.point_id) {
      ids.push(observation.point_id)
    }
  }
  let mut total_views = 0
  let mut total_span = 0.0
  let mut maximum_span = 0.0
  let mut duplicates = 0
  for id in ids {
    let group = track_observations_for(observations, id)
    total_views += track_view_ids(group).length()
    let mut min_x = 0.0
    let mut max_x = 0.0
    let mut min_y = 0.0
    let mut max_y = 0.0
    for i in 0..<group.length() {
      if i == 0 {
        min_x = group[i].pixel.x
        max_x = group[i].pixel.x
        min_y = group[i].pixel.y
        max_y = group[i].pixel.y
      } else {
        min_x = min_x.min(group[i].pixel.x)
        max_x = max_x.max(group[i].pixel.x)
        min_y = min_y.min(group[i].pixel.y)
        max_y = max_y.max(group[i].pixel.y)
      }
    }
    let span = @core.Vec2::new(x=max_x - min_x, y=max_y - min_y).norm()
    total_span += span
    maximum_span = maximum_span.max(span)
    duplicates += group.length() - track_view_ids(group).length()
  }
  {
    track_count: ids.length(),
    observation_count: observations.length(),
    mean_views: if ids.length() == 0 {
      0.0
    } else {
      total_views.to_double() / ids.length().to_double()
    },
    mean_span: if ids.length() == 0 {
      0.0
    } else {
      total_span / ids.length().to_double()
    },
    maximum_span,
    duplicate_observations: duplicates,
  }
}

///|
pub fn track_pixel_span(observations : ArrayView[TrackObservation]) -> Double {
  if observations.length() == 0 {
    0.0
  } else {
    let mut min_x = observations[0].pixel.x
    let mut max_x = observations[0].pixel.x
    let mut min_y = observations[0].pixel.y
    let mut max_y = observations[0].pixel.y
    for observation in observations {
      min_x = min_x.min(observation.pixel.x)
      max_x = max_x.max(observation.pixel.x)
      min_y = min_y.min(observation.pixel.y)
      max_y = max_y.max(observation.pixel.y)
    }
    @core.Vec2::new(x=max_x - min_x, y=max_y - min_y).norm()
  }
}

///|
pub fn track_pixel_motion(
  observations : ArrayView[TrackObservation],
) -> Array[Double] {
  let result : Array[Double] = []
  if observations.length() < 2 {
    return result
  }
  for i in 0..<(observations.length() - 1) {
    result.push(observations[i + 1].pixel.minus(observations[i].pixel).norm())
  }
  result
}

///|
pub fn track_mean_motion(observations : ArrayView[TrackObservation]) -> Double {
  let values = track_pixel_motion(observations)
  @core.mean(values) catch {
    _ => 0.0
  }
}

///|
pub fn track_max_motion(observations : ArrayView[TrackObservation]) -> Double {
  let mut result = 0.0
  for value in track_pixel_motion(observations) {
    result = result.max(value)
  }
  result
}

///|
pub fn track_motion_is_smooth(
  observations : ArrayView[TrackObservation],
  threshold : Double,
) -> Bool {
  for value in track_pixel_motion(observations) {
    if value > threshold {
      return false
    }
  }
  true
}

///|
pub fn track_view_gap_count(observations : ArrayView[TrackObservation]) -> Int {
  let sorted = track_view_ids(observations)
  if sorted.length() < 2 {
    0
  } else {
    sorted.sort()
    let mut gaps = 0
    for i in 0..<(sorted.length() - 1) {
      gaps += (sorted[i + 1] - sorted[i] - 1).max(0)
    }
    gaps
  }
}

///|
pub fn track_view_density(
  observations : ArrayView[TrackObservation],
  total_views : Int,
) -> Double {
  if total_views <= 0 {
    0.0
  } else {
    track_view_ids(observations).length().to_double() / total_views.to_double()
  }
}

///|
pub fn track_is_repeated(observations : ArrayView[TrackObservation]) -> Bool {
  track_view_ids(observations).length() < observations.length()
}

///|
pub fn track_quality_score2(
  observations : ArrayView[TrackObservation],
  minimum_views : Int,
  minimum_span : Double,
) -> Double {
  let support = if minimum_views <= 0 {
    1.0
  } else {
    (track_view_ids(observations).length().to_double() /
    minimum_views.to_double()).min(1.0)
  }
  let spread = if minimum_span <= 0.0 {
    1.0
  } else {
    (track_pixel_span(observations) / minimum_span).min(1.0)
  }
  support * spread
}

///|
pub fn track_filter_quality(
  observations : ArrayView[TrackObservation],
  minimum_views : Int,
  minimum_span : Double,
) -> Array[Int] {
  let ids : Array[Int] = []
  for observation in observations {
    if !ids.contains(observation.point_id) {
      let group = track_observations_for(observations, observation.point_id)
      if track_quality_score2(group, minimum_views, minimum_span) >= 1.0 {
        ids.push(observation.point_id)
      }
    }
  }
  ids
}

///|
pub fn track_observation_matrix(
  observations : ArrayView[TrackObservation],
) -> ObservationMatrix {
  let ids : Array[Int] = []
  let views : Array[Int] = []
  for observation in observations {
    if !ids.contains(observation.point_id) {
      ids.push(observation.point_id)
    }
    if !views.contains(observation.view_id) {
      views.push(observation.view_id)
    }
  }
  let matrix = ObservationMatrix::new(views=views.length(), tracks=ids.length())
  for observation in observations {
    let mut track_index = 0
    let mut view_index = 0
    for i in 0..<ids.length() {
      if ids[i] == observation.point_id {
        track_index = i
      }
    }
    for i in 0..<views.length() {
      if views[i] == observation.view_id {
        view_index = i
      }
    }
    ignore(matrix.set(view_index, track_index, true))
  }
  matrix
}
