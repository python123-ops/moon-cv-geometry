///|
/// Production track-window utilities for temporal filtering and keyframe selection.
pub(all) struct TrackWindowSummary {
  observations : Int
  views : Int
  tracks : Int
  mean_motion : Double
  maximum_motion : Double
  temporal_span : Int
} derive(Debug, Eq)

///|
pub fn track_window_summary(
  observations : ArrayView[TrackObservation],
) -> TrackWindowSummary {
  let ids = track_view_ids(observations)
  let tracks = track_analytics(observations)
  let mut minimum = 0
  let mut maximum = 0
  let mut initialized = false
  for observation in observations {
    if !initialized {
      minimum = observation.view_id
      maximum = observation.view_id
      initialized = true
    } else {
      minimum = minimum.min(observation.view_id)
      maximum = maximum.max(observation.view_id)
    }
  }
  {
    observations: observations.length(),
    views: ids.length(),
    tracks: tracks.track_count,
    mean_motion: track_mean_motion(observations),
    maximum_motion: track_max_motion(observations),
    temporal_span: if initialized {
      maximum - minimum
    } else {
      0
    },
  }
}

///|
pub fn track_window_sort_by_view(
  observations : ArrayView[TrackObservation],
) -> Array[TrackObservation] {
  let result = observations.to_owned()
  result.sort_by(fn(left, right) {
    if left.view_id == right.view_id {
      left.point_id.compare(right.point_id)
    } else {
      left.view_id.compare(right.view_id)
    }
  })
  result
}

///|
pub fn track_window_sort_by_point(
  observations : ArrayView[TrackObservation],
) -> Array[TrackObservation] {
  let result = observations.to_owned()
  result.sort_by(fn(left, right) {
    if left.point_id == right.point_id {
      left.view_id.compare(right.view_id)
    } else {
      left.point_id.compare(right.point_id)
    }
  })
  result
}

///|
pub fn track_window_limit_views(
  observations : ArrayView[TrackObservation],
  first_view : Int,
  last_view : Int,
) -> Array[TrackObservation] {
  let result : Array[TrackObservation] = []
  for observation in observations {
    if observation.view_id >= first_view && observation.view_id <= last_view {
      result.push(observation)
    }
  }
  result
}

///|
pub fn track_window_limit_points(
  observations : ArrayView[TrackObservation],
  first_point : Int,
  last_point : Int,
) -> Array[TrackObservation] {
  let result : Array[TrackObservation] = []
  for observation in observations {
    if observation.point_id >= first_point && observation.point_id <= last_point {
      result.push(observation)
    }
  }
  result
}

///|
pub fn track_window_group_by_view(
  observations : ArrayView[TrackObservation],
  view_id : Int,
) -> Array[TrackObservation] {
  let result : Array[TrackObservation] = []
  for observation in observations {
    if observation.view_id == view_id {
      result.push(observation)
    }
  }
  result
}

///|
pub fn track_window_group_by_point(
  observations : ArrayView[TrackObservation],
  point_id : Int,
) -> Array[TrackObservation] {
  track_observations_for(observations, point_id)
}

///|
pub fn track_window_view_counts(
  observations : ArrayView[TrackObservation],
) -> Array[Int] {
  let views = track_view_ids(observations)
  let result : Array[Int] = []
  for view in views {
    result.push(track_window_group_by_view(observations, view).length())
  }
  result
}

///|
pub fn track_window_point_counts(
  observations : ArrayView[TrackObservation],
) -> Array[Int] {
  let ids : Array[Int] = []
  let result : Array[Int] = []
  for observation in observations {
    if !ids.contains(observation.point_id) {
      ids.push(observation.point_id)
    }
  }
  for id in ids {
    result.push(track_window_group_by_point(observations, id).length())
  }
  result
}

///|
pub fn track_window_view_balance(
  observations : ArrayView[TrackObservation],
) -> Double {
  let counts = track_window_view_counts(observations)
  if counts.length() == 0 {
    return 0.0
  }
  let stats = @core.streaming_summary(
    counts.map(fn(value) { value.to_double() }),
  )
  if stats.mean <= 0.0 {
    0.0
  } else {
    1.0 / (1.0 + stats.variance.sqrt() / stats.mean)
  }
}

///|
pub fn track_window_consistent_motion(
  observations : ArrayView[TrackObservation],
  tolerance : Double,
) -> Bool {
  let sorted = track_window_sort_by_point(observations)
  let mut previous_point = -1
  let mut previous_view = -1
  let mut previous_pixel = @core.Point2::new(x=0.0, y=0.0)
  let mut initialized = false
  for observation in sorted {
    if initialized &&
      observation.point_id == previous_point &&
      observation.view_id == previous_view + 1 {
      if observation.pixel.minus(previous_pixel).norm() > tolerance.max(0.0) {
        return false
      }
    }
    previous_point = observation.point_id
    previous_view = observation.view_id
    previous_pixel = observation.pixel
    initialized = true
  }
  true
}

///|
pub fn track_window_interpolate(
  a : TrackObservation,
  b : TrackObservation,
  view_id : Int,
) -> TrackObservation {
  let denominator = (b.view_id - a.view_id).to_double()
  let amount = if denominator == 0.0 {
    0.0
  } else {
    (view_id - a.view_id).to_double() / denominator
  }
  TrackObservation::new(
    point_id=a.point_id,
    view_id~,
    pixel=@core.Point2::new(
      x=a.pixel.x + (b.pixel.x - a.pixel.x) * amount,
      y=a.pixel.y + (b.pixel.y - a.pixel.y) * amount,
    ),
  )
}

///|
pub fn track_window_interpolate_gap(
  observations : ArrayView[TrackObservation],
  point_id : Int,
  start_view : Int,
  end_view : Int,
) -> Array[TrackObservation] {
  let group = track_window_sort_by_view(
    track_window_group_by_point(observations, point_id),
  )
  let result : Array[TrackObservation] = []
  if group.length() == 0 {
    return result
  }
  let mut left = group[0]
  for right in group[1:] {
    let begin = left.view_id.max(start_view)
    let end = right.view_id.min(end_view)
    if right.view_id - left.view_id > 1 {
      for view in (begin + 1)..<end {
        result.push(track_window_interpolate(left, right, view))
      }
    }
    left = right
  }
  result
}

///|
pub fn track_window_append_unique(
  target : Array[TrackObservation],
  observations : ArrayView[TrackObservation],
) -> Unit {
  for observation in observations {
    let mut found = false
    for existing in target {
      if existing.point_id == observation.point_id &&
        existing.view_id == observation.view_id {
        found = true
      }
    }
    if !found {
      target.push(observation)
    }
  }
}

///|
pub fn track_window_deduplicate(
  observations : ArrayView[TrackObservation],
) -> Array[TrackObservation] {
  let result : Array[TrackObservation] = []
  track_window_append_unique(result, observations)
  result
}

///|
pub fn track_window_retain_best(
  observations : ArrayView[TrackObservation],
  maximum_per_point : Int,
) -> Array[TrackObservation] {
  let result : Array[TrackObservation] = []
  let ids : Array[Int] = []
  for observation in observations {
    if !ids.contains(observation.point_id) {
      ids.push(observation.point_id)
    }
  }
  for id in ids {
    let group = track_window_sort_by_view(
      track_window_group_by_point(observations, id),
    )
    let limit = maximum_per_point.max(0).min(group.length())
    for i in 0..<limit {
      result.push(group[i])
    }
  }
  result
}

///|
pub fn track_window_keyframe_score(
  observations : ArrayView[TrackObservation],
  minimum_tracks : Int,
) -> Double {
  let summary = track_window_summary(observations)
  let support = if minimum_tracks <= 0 {
    1.0
  } else {
    (summary.tracks.to_double() / minimum_tracks.to_double()).min(1.0)
  }
  support *
  track_window_view_balance(observations) *
  (1.0 / (1.0 + summary.mean_motion))
}

///|
pub fn track_window_select_keyframes(
  observations : ArrayView[TrackObservation],
  minimum_tracks : Int,
  threshold : Double,
) -> Array[Int] {
  let views = track_view_ids(observations)
  let result : Array[Int] = []
  for view in views {
    if track_window_keyframe_score(
        track_window_group_by_view(observations, view),
        minimum_tracks,
      ) >=
      threshold {
      result.push(view)
    }
  }
  result
}

///|
pub fn track_window_temporal_gaps(
  observations : ArrayView[TrackObservation],
) -> Array[Int] {
  let views = track_view_ids(observations)
  let sorted = views
  sorted.sort()
  let result : Array[Int] = []
  for i in 0..<(sorted.length() - 1).max(0) {
    let gap = sorted[i + 1] - sorted[i] - 1
    if gap > 0 {
      result.push(gap)
    }
  }
  result
}

///|
pub fn track_window_gap_penalty(
  observations : ArrayView[TrackObservation],
) -> Double {
  let gaps = track_window_temporal_gaps(observations)
  let mut total = 0
  for gap in gaps {
    total += gap
  }
  total.to_double()
}

///|
pub fn track_window_reliability(
  observations : ArrayView[TrackObservation],
  minimum_views : Int,
  maximum_motion : Double,
) -> Double {
  let summary = track_window_summary(observations)
  let support = if minimum_views <= 0 {
    1.0
  } else {
    (summary.views.to_double() / minimum_views.to_double()).min(1.0)
  }
  let motion = if maximum_motion <= 0.0 {
    0.0
  } else {
    (1.0 - summary.mean_motion / maximum_motion).max(0.0).min(1.0)
  }
  support * motion * (1.0 / (1.0 + track_window_gap_penalty(observations)))
}
