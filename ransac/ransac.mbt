///|
pub(all) struct RansacConfig {
  iterations : Int
  threshold : Double
  min_inliers : Int
  seed : UInt
} derive(Debug, Eq)

///|
pub extend RansacConfig with @debug.Debug::{to_repr}

///|
pub extend RansacConfig with Eq::{equal, not_equal}

///|
pub fn RansacConfig::new(
  iterations? : Int = 128,
  threshold? : Double = 2.0,
  min_inliers? : Int = 4,
  seed? : UInt = 1U,
) -> RansacConfig {
  { iterations, threshold, min_inliers, seed, }
}

///|
pub(all) struct InlierMask {
  values : Array[Bool]
} derive(Debug, Eq)

///|
pub extend InlierMask with @debug.Debug::{to_repr}

///|
pub extend InlierMask with Eq::{equal, not_equal}

///|
pub(all) struct RansacResult[T] {
  model : T
  inliers : InlierMask
  inlier_count : Int
  score : Double
} derive(Debug, Eq)

///|
pub fn[T : Eq] RansacResult::equal(
  self : RansacResult[T],
  other : RansacResult[T],
) -> Bool {
  Eq::equal(self, other)
}

///|
pub fn[T : Eq] RansacResult::not_equal(
  self : RansacResult[T],
  other : RansacResult[T],
) -> Bool {
  !Eq::equal(self, other)
}

///|
pub fn[T : @debug.Debug] RansacResult::to_repr(
  self : RansacResult[T],
) -> @debug.Repr {
  @debug.Debug::to_repr(self)
}

///|
pub fn InlierMask::length(mask : InlierMask) -> Int {
  mask.values.length()
}

///|
pub fn InlierMask::is_inlier(
  mask : InlierMask,
  index : Int,
) -> Bool raise @core.GeometryError {
  if index < 0 || index >= mask.values.length() {
    raise @core.GeometryError::DegenerateInput("inlier index is out of range")
  }
  mask.values[index]
}

///|
pub fn[T] RansacResult::inlier_ratio(result : RansacResult[T]) -> Double {
  let total = result.inliers.length()
  if total == 0 {
    0.0
  } else {
    Double::from_int(result.inlier_count) / Double::from_int(total)
  }
}

///|
fn lcg_next(state : UInt) -> UInt {
  state * 1664525U + 1013904223U
}

///|
fn pick_index(state : UInt, len : Int) -> Int {
  (state % len.reinterpret_as_uint()).reinterpret_as_int()
}

///|
fn sample_four(len : Int, seed : UInt, iter : Int) -> (Int, Int, Int, Int) {
  let selected : Array[Int] = []
  let mut state = seed + iter.reinterpret_as_uint() * 747796405U
  for _ in 0..<4 {
    state = lcg_next(state)
    // Choose a rank among the unselected indices, then map back to the population.
    let mut index = pick_index(state, len - selected.length())
    let ordered = selected.copy()
    ordered.sort()
    for used in ordered {
      if index >= used {
        index += 1
      }
    }
    selected.push(index)
  }
  (selected[0], selected[1], selected[2], selected[3])
}

///|
fn make_four(
  points : ArrayView[@core.Point2],
  indices : (Int, Int, Int, Int),
) -> Array[@core.Point2] {
  let (i0, i1, i2, i3) = indices
  [points[i0], points[i1], points[i2], points[i3]]
}

///|
fn make_eight(
  points : ArrayView[@core.Point2],
  start : Int,
) -> Array[@core.Point2] {
  [
    points[start],
    points[(start + 1) % points.length()],
    points[(start + 2) % points.length()],
    points[(start + 3) % points.length()],
    points[(start + 4) % points.length()],
    points[(start + 5) % points.length()],
    points[(start + 6) % points.length()],
    points[(start + 7) % points.length()],
  ]
}

///|
pub fn estimate_homography_ransac(
  src : ArrayView[@core.Point2],
  dst : ArrayView[@core.Point2],
  config? : RansacConfig = RansacConfig::new(),
) -> RansacResult[@multiview.Homography] raise @core.GeometryError {
  if src.length() != dst.length() || src.length() < 4 {
    raise @core.GeometryError::NotEnoughPoints(
      "homography RANSAC needs at least four paired points",
    )
  }
  let config = config.validated(data_size=src.length())
  if !@core.points2_are_finite(src) || !@core.points2_are_finite(dst) {
    raise @core.GeometryError::DegenerateInput(
      "RANSAC coordinates must be finite",
    )
  }
  let mut best : RansacResult[@multiview.Homography]? = None
  for iter in 0..<config.iterations {
    let indices = sample_four(src.length(), config.seed, iter)
    try
      @multiview.estimate_homography_from_four(
        make_four(src, indices),
        make_four(dst, indices),
      )
    catch {
      _ => ()
    } noraise {
      model => {
        let mask : Array[Bool] = []
        let mut count = 0
        let mut score = 0.0
        for i in 0..<src.length() {
          let error = try
            @multiview.homography_reprojection_error(model, src[i], dst[i])
          catch {
            _ => None
          } noraise {
            value => Some(value)
          }
          let ok = match error {
            Some(value) =>
              !value.is_nan() && !value.is_inf() && value <= config.threshold
            None => false
          }
          mask.push(ok)
          if ok {
            count += 1
            score += error.unwrap()
          }
        }
        let candidate = RansacResult::{
          model,
          inliers: InlierMask::{ values: mask, },
          inlier_count: count,
          score,
        }
        best = Some(prefer_candidate(candidate, best))
      }
    }
  }
  match best {
    Some(result) if result.inlier_count >= config.min_inliers => result
    _ =>
      raise @core.GeometryError::DegenerateInput(
        "RANSAC could not find enough homography inliers",
      )
  }
}

///|
pub fn estimate_fundamental_ransac(
  left : ArrayView[@core.Point2],
  right : ArrayView[@core.Point2],
  config? : RansacConfig = RansacConfig::new(),
) -> RansacResult[@multiview.FundamentalMatrix] raise @core.GeometryError {
  if left.length() != right.length() || left.length() < 2 {
    raise @core.GeometryError::NotEnoughPoints(
      "fundamental RANSAC needs paired points",
    )
  }
  let config = config.validated(data_size=left.length())
  if !@core.points2_are_finite(left) || !@core.points2_are_finite(right) {
    raise @core.GeometryError::DegenerateInput(
      "RANSAC coordinates must be finite",
    )
  }
  if left.length() < 8 {
    let model = @multiview.estimate_fundamental_from_translation(
      @core.Vec3::new(x=1.0, y=0.0, z=0.0),
    )
    score_fundamental(model, left, right, config)
  } else {
    let mut best : RansacResult[@multiview.FundamentalMatrix]? = None
    for iter in 0..<config.iterations {
      let start = pick_index(
        lcg_next(config.seed + iter.reinterpret_as_uint() * 747796405U),
        left.length(),
      )
      try
        @multiview.estimate_fundamental(
          make_eight(left, start),
          make_eight(right, start),
        )
      catch {
        _ => ()
      } noraise {
        model => {
          let initial = RansacResult::{
            model,
            inliers: InlierMask::{ values: [], },
            inlier_count: -1,
            score: 1.0e100,
          }
          let previous = match best {
            Some(result) => result
            None => initial
          }
          best = Some(
            score_fundamental_candidate(model, left, right, config, previous),
          )
        }
      }
    }
    match best {
      Some(result) if result.inlier_count >= config.min_inliers => result
      _ =>
        raise @core.GeometryError::DegenerateInput(
          "RANSAC could not find enough fundamental inliers",
        )
    }
  }
}

///|
fn score_fundamental_candidate(
  model : @multiview.FundamentalMatrix,
  left : ArrayView[@core.Point2],
  right : ArrayView[@core.Point2],
  config : RansacConfig,
  best : RansacResult[@multiview.FundamentalMatrix],
) -> RansacResult[@multiview.FundamentalMatrix] {
  let mask : Array[Bool] = []
  let mut count = 0
  let mut score = 0.0
  for i in 0..<left.length() {
    let error = try @multiview.sampson_error(model, left[i], right[i]) catch {
      _ => None
    } noraise {
      value => Some(value.sqrt())
    }
    let ok = match error {
      Some(value) =>
        !value.is_nan() && !value.is_inf() && value <= config.threshold
      None => false
    }
    mask.push(ok)
    if ok {
      count += 1
      score += error.unwrap()
    }
  }
  if count > best.inlier_count ||
    (count == best.inlier_count && score < best.score) {
    RansacResult::{
      model,
      inliers: InlierMask::{ values: mask, },
      inlier_count: count,
      score,
    }
  } else {
    best
  }
}

///|
fn score_fundamental(
  model : @multiview.FundamentalMatrix,
  left : ArrayView[@core.Point2],
  right : ArrayView[@core.Point2],
  config : RansacConfig,
) -> RansacResult[@multiview.FundamentalMatrix] raise @core.GeometryError {
  let empty = RansacResult::{
    model,
    inliers: InlierMask::{ values: [], },
    inlier_count: -1,
    score: 1.0e100,
  }
  let result = score_fundamental_candidate(model, left, right, config, empty)
  if result.inlier_count < config.min_inliers {
    raise @core.GeometryError::DegenerateInput(
      "RANSAC could not find enough fundamental inliers",
    )
  }
  result
}

///|
fn[T] prefer_candidate(
  candidate : RansacResult[T],
  best : RansacResult[T]?,
) -> RansacResult[T] {
  match best {
    Some(previous) if previous.inlier_count > candidate.inlier_count ||
      (
        previous.inlier_count == candidate.inlier_count &&
        previous.score <= candidate.score
      ) => previous
    _ => candidate
  }
}
