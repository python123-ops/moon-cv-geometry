///|
/// Quality gates for large multi-view track tables.
pub(all) struct TrackQualityBatchSummary {
  tracks : Int
  observations : Int
  accepted : Int
  rejected : Int
  mean_score : Double
  best_score : Double
} derive(Debug, Eq)

///|
pub fn track_quality_batch_ids(
  observations : ArrayView[TrackObservation],
) -> Array[Int] {
  let result : Array[Int] = []
  for observation in observations {
    if !result.contains(observation.point_id) {
      result.push(observation.point_id)
    }
  }
  result
}

///|
pub fn track_quality_batch_scores(
  observations : ArrayView[TrackObservation],
  minimum_views : Int,
  minimum_span : Double,
) -> Array[Double] {
  let result : Array[Double] = []
  for id in track_quality_batch_ids(observations) {
    result.push(
      track_quality_score2(
        track_observations_for(observations, id),
        minimum_views,
        minimum_span,
      ),
    )
  }
  result
}

///|
pub fn track_quality_batch_summary(
  observations : ArrayView[TrackObservation],
  minimum_views : Int,
  minimum_span : Double,
  threshold : Double,
) -> TrackQualityBatchSummary {
  let scores = track_quality_batch_scores(
    observations, minimum_views, minimum_span,
  )
  let mut accepted = 0
  let mut total = 0.0
  let mut best = 0.0
  for score in scores {
    if score >= threshold {
      accepted += 1
    }
    total += score
    best = best.max(score)
  }
  {
    tracks: scores.length(),
    observations: observations.length(),
    accepted,
    rejected: scores.length() - accepted,
    mean_score: if scores.length() == 0 {
      0.0
    } else {
      total / scores.length().to_double()
    },
    best_score: best,
  }
}

///|
pub fn track_quality_batch_accepted_ids(
  observations : ArrayView[TrackObservation],
  minimum_views : Int,
  minimum_span : Double,
  threshold : Double,
) -> Array[Int] {
  let result : Array[Int] = []
  for id in track_quality_batch_ids(observations) {
    if track_quality_score2(
        track_observations_for(observations, id),
        minimum_views,
        minimum_span,
      ) >=
      threshold {
      result.push(id)
    }
  }
  result
}

///|
pub fn track_quality_batch_rejected_ids(
  observations : ArrayView[TrackObservation],
  minimum_views : Int,
  minimum_span : Double,
  threshold : Double,
) -> Array[Int] {
  let result : Array[Int] = []
  for id in track_quality_batch_ids(observations) {
    if track_quality_score2(
        track_observations_for(observations, id),
        minimum_views,
        minimum_span,
      ) <
      threshold {
      result.push(id)
    }
  }
  result
}

///|
pub fn track_quality_batch_mean_span(
  observations : ArrayView[TrackObservation],
) -> Double {
  let ids = track_quality_batch_ids(observations)
  if ids.length() == 0 {
    0.0
  } else {
    let mut total = 0.0
    for id in ids {
      total += track_pixel_span(track_observations_for(observations, id))
    }
    total / ids.length().to_double()
  }
}

///|
pub fn track_quality_batch_max_span(
  observations : ArrayView[TrackObservation],
) -> Double {
  let mut result = 0.0
  for id in track_quality_batch_ids(observations) {
    result = result.max(
      track_pixel_span(track_observations_for(observations, id)),
    )
  }
  result
}

///|
pub fn track_quality_batch_mean_views(
  observations : ArrayView[TrackObservation],
) -> Double {
  let ids = track_quality_batch_ids(observations)
  if ids.length() == 0 {
    0.0
  } else {
    let mut total = 0
    for id in ids {
      total += track_view_ids(track_observations_for(observations, id)).length()
    }
    total.to_double() / ids.length().to_double()
  }
}

///|
pub fn track_quality_batch_view_support(
  observations : ArrayView[TrackObservation],
  minimum : Int,
) -> Double {
  let ids = track_quality_batch_ids(observations)
  if ids.length() == 0 {
    0.0
  } else {
    let mut accepted = 0
    for id in ids {
      if track_view_ids(track_observations_for(observations, id)).length() >=
        minimum {
        accepted += 1
      }
    }
    accepted.to_double() / ids.length().to_double()
  }
}

///|
pub fn track_quality_batch_motion_support(
  observations : ArrayView[TrackObservation],
  maximum : Double,
) -> Double {
  let ids = track_quality_batch_ids(observations)
  if ids.length() == 0 {
    0.0
  } else {
    let mut accepted = 0
    for id in ids {
      if track_max_motion(track_observations_for(observations, id)) <= maximum {
        accepted += 1
      }
    }
    accepted.to_double() / ids.length().to_double()
  }
}

///|
pub fn track_quality_batch_filter(
  observations : ArrayView[TrackObservation],
  minimum_views : Int,
  minimum_span : Double,
  threshold : Double,
) -> Array[TrackObservation] {
  let accepted = track_quality_batch_accepted_ids(
    observations, minimum_views, minimum_span, threshold,
  )
  let result : Array[TrackObservation] = []
  for observation in observations {
    if accepted.contains(observation.point_id) {
      result.push(observation)
    }
  }
  result
}

///|
pub fn track_quality_batch_reject(
  observations : ArrayView[TrackObservation],
  minimum_views : Int,
  minimum_span : Double,
  threshold : Double,
) -> Array[TrackObservation] {
  let rejected = track_quality_batch_rejected_ids(
    observations, minimum_views, minimum_span, threshold,
  )
  let result : Array[TrackObservation] = []
  for observation in observations {
    if rejected.contains(observation.point_id) {
      result.push(observation)
    }
  }
  result
}

///|
pub fn track_quality_batch_balance(
  observations : ArrayView[TrackObservation],
) -> Double {
  let counts = track_window_view_counts(observations)
  if counts.length() == 0 {
    0.0
  } else {
    let mut minimum = counts[0]
    let mut maximum = counts[0]
    for count in counts {
      minimum = minimum.min(count)
      maximum = maximum.max(count)
    }
    if maximum <= 0 {
      0.0
    } else {
      minimum.to_double() / maximum.to_double()
    }
  }
}

///|
pub fn track_quality_batch_duplicate_ratio(
  observations : ArrayView[TrackObservation],
) -> Double {
  if observations.length() == 0 {
    0.0
  } else {
    track_analytics(observations).duplicate_observations.to_double() /
    observations.length().to_double()
  }
}

///|
pub fn track_quality_batch_temporal_density(
  observations : ArrayView[TrackObservation],
) -> Double {
  let summary = track_window_summary(observations)
  if summary.temporal_span <= 0 {
    1.0
  } else {
    summary.views.to_double() / (summary.temporal_span + 1).to_double()
  }
}

///|
pub fn track_quality_batch_score(
  observations : ArrayView[TrackObservation],
  minimum_views : Int,
  minimum_span : Double,
) -> Double {
  let summary = track_quality_batch_summary(
    observations, minimum_views, minimum_span, 0.5,
  )
  summary.mean_score *
  track_quality_batch_balance(observations) *
  (1.0 - track_quality_batch_duplicate_ratio(observations))
}

///|
pub fn track_quality_batch_is_usable(
  observations : ArrayView[TrackObservation],
  minimum_views : Int,
  minimum_span : Double,
  threshold : Double,
) -> Bool {
  track_quality_batch_score(observations, minimum_views, minimum_span) >=
  threshold
}

///|
pub fn track_quality_batch_csv(summary : TrackQualityBatchSummary) -> String {
  summary.tracks.to_string() +
  "," +
  summary.observations.to_string() +
  "," +
  summary.accepted.to_string() +
  "," +
  summary.rejected.to_string() +
  "," +
  summary.mean_score.to_string() +
  "," +
  summary.best_score.to_string()
}

///|
pub fn track_quality_batch_merge(
  left : TrackQualityBatchSummary,
  right : TrackQualityBatchSummary,
) -> TrackQualityBatchSummary {
  let tracks = left.tracks + right.tracks
  let observations = left.observations + right.observations
  {
    tracks,
    observations,
    accepted: left.accepted + right.accepted,
    rejected: left.rejected + right.rejected,
    mean_score: if tracks == 0 {
      0.0
    } else {
      (
        left.mean_score * left.tracks.to_double() +
        right.mean_score * right.tracks.to_double()
      ) /
      tracks.to_double()
    },
    best_score: left.best_score.max(right.best_score),
  }
}

///|
pub fn track_quality_batch_window(
  observations : ArrayView[TrackObservation],
  first_view : Int,
  last_view : Int,
  minimum_views : Int,
  minimum_span : Double,
) -> Double {
  track_quality_batch_score(
    track_window_limit_views(observations, first_view, last_view),
    minimum_views,
    minimum_span,
  )
}

///|
pub fn track_quality_batch_stable_windows(
  observations : ArrayView[TrackObservation],
  window : Int,
  minimum_views : Int,
  minimum_span : Double,
  threshold : Double,
) -> Array[Int] {
  let views = track_view_ids(observations)
  let result : Array[Int] = []
  for view in views {
    if track_quality_batch_window(
        observations,
        view,
        view + window.max(1) - 1,
        minimum_views,
        minimum_span,
      ) >=
      threshold {
      result.push(view)
    }
  }
  result
}
