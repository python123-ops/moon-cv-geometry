///|
/// Summary of valid depth support in a frame or reconstruction tile.
pub(all) struct DepthQuality {
  valid_count : Int
  total_count : Int
  valid_ratio : Double
  span : Double
} derive(Debug, Eq)

///|
pub fn depth_quality(
  depths : ArrayView[Double],
  minimum~ : Double,
  maximum~ : Double,
) -> DepthQuality {
  let mut count = 0
  let mut min_value = 0.0
  let mut max_value = 0.0
  for depth in depths {
    if depth >= minimum && depth <= maximum && depth == depth {
      if count == 0 {
        min_value = depth
        max_value = depth
      } else {
        min_value = min_value.min(depth)
        max_value = max_value.max(depth)
      }
      count += 1
    }
  }
  {
    valid_count: count,
    total_count: depths.length(),
    valid_ratio: if depths.length() == 0 {
      0.0
    } else {
      count.to_double() / depths.length().to_double()
    },
    span: if count == 0 {
      0.0
    } else {
      max_value - min_value
    },
  }
}

///|
/// Map valid depths to [0, 1]; invalid values retain the caller marker.
pub fn normalize_depths(
  depths : ArrayView[Double],
  invalid_value~ : Double,
) -> Array[Double] {
  if depths.length() == 0 {
    return []
  }
  let mut minimum = depths[0]
  let mut maximum = depths[0]
  for depth in depths {
    if depth == depth {
      minimum = minimum.min(depth)
      maximum = maximum.max(depth)
    }
  }
  let span = maximum - minimum
  let result : Array[Double] = []
  for depth in depths {
    if depth != depth || span <= 0.0 {
      result.push(invalid_value)
    } else {
      result.push((depth - minimum) / span)
    }
  }
  result
}

///|
pub fn count_depth_holes(depths : ArrayView[Double], minimum : Double) -> Int {
  let mut holes = 0
  for depth in depths {
    if depth != depth || depth < minimum {
      holes += 1
    }
  }
  holes
}

///|
pub fn clamp_depths(
  depths : ArrayView[Double],
  minimum : Double,
  maximum : Double,
) -> Array[Double] {
  let result : Array[Double] = []
  for depth in depths {
    result.push(depth.max(minimum).min(maximum))
  }
  result
}

///|
pub fn depth_percentile(
  depths : ArrayView[Double],
  percentile : Double,
) -> Double raise @core.GeometryError {
  let valid : Array[Double] = []
  for depth in depths {
    if depth == depth && depth > 0.0 {
      valid.push(depth)
    }
  }
  @core.percentile_range(valid, percentile, percentile).min
}
