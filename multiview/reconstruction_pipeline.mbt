///|
/// Summary of feature tracks suitable for multi-view reconstruction.
pub(all) struct ReconstructionTrackReport {
  total_tracks : Int
  triangulatable_tracks : Int
  total_observations : Int
  mean_views : Double
  maximum_views : Int
} derive(Debug, Eq)

///|
pub fn reconstruction_track_report(
  observations : ArrayView[TrackObservation],
  minimum_views~ : Int,
) -> ReconstructionTrackReport {
  let ids : Array[Int] = []
  for observation in observations {
    if !ids.contains(observation.point_id) {
      ids.push(observation.point_id)
    }
  }
  let mut triangulatable = 0
  let mut total_views = 0
  let mut maximum = 0
  for id in ids {
    let views : Array[Int] = []
    for observation in observations {
      if observation.point_id == id && !views.contains(observation.view_id) {
        views.push(observation.view_id)
      }
    }
    total_views += views.length()
    maximum = maximum.max(views.length())
    if views.length() >= minimum_views {
      triangulatable += 1
    }
  }
  {
    total_tracks: ids.length(),
    triangulatable_tracks: triangulatable,
    total_observations: observations.length(),
    mean_views: if ids.length() == 0 {
      0.0
    } else {
      total_views.to_double() / ids.length().to_double()
    },
    maximum_views: maximum,
  }
}

///|
pub fn track_observations_for(
  observations : ArrayView[TrackObservation],
  point_id : Int,
) -> Array[TrackObservation] {
  let result : Array[TrackObservation] = []
  for observation in observations {
    if observation.point_id == point_id {
      result.push(observation)
    }
  }
  result
}

///|
pub fn track_view_ids(observations : ArrayView[TrackObservation]) -> Array[Int] {
  let result : Array[Int] = []
  for observation in observations {
    if !result.contains(observation.view_id) {
      result.push(observation.view_id)
    }
  }
  result
}

///|
pub fn track_baseline_support(
  observations : ArrayView[TrackObservation],
) -> Int {
  track_view_ids(observations).length()
}

///|
pub fn select_tracks_by_support(
  observations : ArrayView[TrackObservation],
  minimum_views : Int,
) -> Array[Int] {
  let ids : Array[Int] = []
  for observation in observations {
    if !ids.contains(observation.point_id) &&
      track_view_ids(track_observations_for(observations, observation.point_id)).length() >=
      minimum_views {
      ids.push(observation.point_id)
    }
  }
  ids
}

///|
pub fn select_tracks_by_pixel_span(
  observations : ArrayView[TrackObservation],
  minimum_span : Double,
) -> Array[Int] {
  let ids : Array[Int] = []
  for observation in observations {
    if !ids.contains(observation.point_id) {
      let group = track_observations_for(observations, observation.point_id)
      let mut min_x = observation.pixel.x
      let mut max_x = observation.pixel.x
      let mut min_y = observation.pixel.y
      let mut max_y = observation.pixel.y
      for item in group {
        min_x = min_x.min(item.pixel.x)
        max_x = max_x.max(item.pixel.x)
        min_y = min_y.min(item.pixel.y)
        max_y = max_y.max(item.pixel.y)
      }
      if @core.Vec2::new(x=max_x - min_x, y=max_y - min_y).norm() >=
        minimum_span {
        ids.push(observation.point_id)
      }
    }
  }
  ids
}

///|
pub fn deduplicate_observations(
  observations : ArrayView[TrackObservation],
) -> Array[TrackObservation] {
  let result : Array[TrackObservation] = []
  let keys : Array[(Int, Int)] = []
  for observation in observations {
    let key = (observation.point_id, observation.view_id)
    if !keys.contains(key) {
      keys.push(key)
      result.push(observation)
    }
  }
  result
}

///|
pub fn observation_centroid(
  observations : ArrayView[TrackObservation],
) -> @core.Point2 raise @core.GeometryError {
  let points : Array[@core.Point2] = []
  for observation in observations {
    points.push(observation.pixel)
  }
  @core.polygon_centroid(points)
}

///|
pub fn observation_pixel_rms(
  observations : ArrayView[TrackObservation],
) -> Double raise @core.GeometryError {
  let center = observation_centroid(observations)
  if observations.length() == 0 {
    raise @core.GeometryError::NotEnoughPoints(
      "observation RMS needs observations",
    )
  }
  let mut sum = 0.0
  for observation in observations {
    let distance = observation.pixel.minus(center).norm()
    sum += distance * distance
  }
  (sum / observations.length().to_double()).sqrt()
}

///|
pub fn track_consistency_score(
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
  let span = observation_pixel_rms(observations) catch { _ => 0.0 }
  let spread = if minimum_span <= 0.0 {
    1.0
  } else {
    (span / minimum_span).min(1.0)
  }
  support * spread
}

///|
pub(all) struct TriangulationGate {
  minimum_views : Int
  minimum_baseline : Double
  maximum_reprojection : Double
} derive(Debug, Eq)

///|
pub fn TriangulationGate::new(
  minimum_views~ : Int,
  minimum_baseline~ : Double,
  maximum_reprojection~ : Double,
) -> TriangulationGate {
  {
    minimum_views: minimum_views.max(2),
    minimum_baseline: minimum_baseline.max(0.0),
    maximum_reprojection: maximum_reprojection.max(0.0),
  }
}

///|
pub fn triangulation_gate_accepts(
  gate : TriangulationGate,
  view_count : Int,
  baseline : Double,
  reprojection : Double,
) -> Bool {
  view_count >= gate.minimum_views &&
  baseline >= gate.minimum_baseline &&
  reprojection <= gate.maximum_reprojection
}

///|
pub fn triangulation_depth_is_valid(
  depth : Double,
  minimum : Double,
  maximum : Double,
) -> Bool {
  depth == depth && depth >= minimum && depth <= maximum
}

///|
pub fn triangulation_depth_mask(
  depths : ArrayView[Double],
  minimum : Double,
  maximum : Double,
) -> Array[Bool] {
  let result : Array[Bool] = []
  for depth in depths {
    result.push(triangulation_depth_is_valid(depth, minimum, maximum))
  }
  result
}

///|
pub fn triangulation_depth_indices(
  depths : ArrayView[Double],
  minimum : Double,
  maximum : Double,
) -> Array[Int] {
  let result : Array[Int] = []
  for i in 0..<depths.length() {
    if triangulation_depth_is_valid(depths[i], minimum, maximum) {
      result.push(i)
    }
  }
  result
}
