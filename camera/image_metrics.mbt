///|
/// Valid image support summary for projected measurements.
pub(all) struct ImageSupport {
  total : Int
  valid_count : Int
  invalid_count : Int
  valid_ratio : Double
  margin_min : Double
} derive(Debug, Eq)

///|
pub fn image_support_mask(
  size : ImageSize,
  pixels : ArrayView[@core.Point2],
) -> ImageSupport {
  let mut valid = 0
  let mut margin = 0.0
  for pixel in pixels {
    let current = image_margin(pixel, size)
    if current >= 0.0 {
      valid += 1
      if valid == 1 {
        margin = current
      } else {
        margin = margin.min(current)
      }
    }
  }
  {
    total: pixels.length(),
    valid_count: valid,
    invalid_count: pixels.length() - valid,
    valid_ratio: if pixels.length() == 0 {
      0.0
    } else {
      valid.to_double() / pixels.length().to_double()
    },
    margin_min: if valid == 0 {
      0.0
    } else {
      margin
    },
  }
}

///|
pub fn image_support_ratio(
  size : ImageSize,
  pixels : ArrayView[@core.Point2],
) -> Double {
  image_support_mask(size, pixels).valid_ratio
}

///|
pub fn border_distance(size : ImageSize, pixel : @core.Point2) -> Double {
  image_margin(pixel, size)
}

///|
pub fn image_margin_histogram(
  size : ImageSize,
  pixels : ArrayView[@core.Point2],
  bins : Int,
) -> Array[Int] {
  let result : Array[Int] = []
  for _ in 0..<bins.max(0) {
    result.push(0)
  }
  let maximum = size.width.min(size.height).to_double() / 2.0
  if maximum <= 0.0 {
    return result
  }
  for pixel in pixels {
    let margin = image_margin(pixel, size)
    if margin >= 0.0 && result.length() > 0 {
      let index = (margin / maximum * result.length().to_double())
        .to_int()
        .min(result.length() - 1)
      result[index] += 1
    }
  }
  result
}

///|
pub(all) struct DepthHistogram {
  bins : Array[Int]
  total : Int
  valid : Int
  minimum : Double
  maximum : Double
} derive(Debug, Eq)

///|
pub fn depth_histogram(
  depths : ArrayView[Double],
  bins~ : Int,
  minimum~ : Double,
  maximum~ : Double,
) -> DepthHistogram {
  let counts : Array[Int] = []
  for _ in 0..<bins.max(0) {
    counts.push(0)
  }
  let mut valid = 0
  for depth in depths {
    if depth == depth &&
      depth >= minimum &&
      depth <= maximum &&
      counts.length() > 0 {
      let width = (maximum - minimum).max(0.000000000001)
      let index = ((depth - minimum) / width * counts.length().to_double())
        .to_int()
        .min(counts.length() - 1)
        .max(0)
      counts[index] += 1
      valid += 1
    }
  }
  { bins: counts, total: depths.length(), valid, minimum, maximum }
}

///|
pub fn depth_histogram_peak(histogram : DepthHistogram) -> Int {
  let mut index = 0
  for i in 1..<histogram.bins.length() {
    if histogram.bins[i] > histogram.bins[index] {
      index = i
    }
  }
  index
}

///|
pub fn depth_histogram_entropy(histogram : DepthHistogram) -> Double {
  if histogram.valid == 0 {
    return 0.0
  }
  let mut entropy = 0.0
  for count in histogram.bins {
    if count > 0 {
      let probability = count.to_double() / histogram.valid.to_double()
      entropy -= probability * @math.ln(probability)
    }
  }
  entropy
}

///|
pub fn depth_valid_mask(
  depths : ArrayView[Double],
  minimum : Double,
  maximum : Double,
) -> Array[Bool] {
  let result : Array[Bool] = []
  for depth in depths {
    result.push(depth == depth && depth >= minimum && depth <= maximum)
  }
  result
}

///|
pub fn depth_valid_indices(
  depths : ArrayView[Double],
  minimum : Double,
  maximum : Double,
) -> Array[Int] {
  let result : Array[Int] = []
  for i in 0..<depths.length() {
    if depths[i] == depths[i] && depths[i] >= minimum && depths[i] <= maximum {
      result.push(i)
    }
  }
  result
}

///|
pub fn depth_percentile2(
  depths : ArrayView[Double],
  probability : Double,
) -> Double raise @core.GeometryError {
  let valid : Array[Double] = []
  for depth in depths {
    if depth == depth && depth > 0.0 {
      valid.push(depth)
    }
  }
  @core.quantile_linear(valid, probability)
}

///|
pub fn depth_trimmed_mean(
  depths : ArrayView[Double],
  minimum : Double,
  maximum : Double,
) -> Double {
  let mut sum = 0.0
  let mut count = 0
  for depth in depths {
    if depth == depth && depth >= minimum && depth <= maximum {
      sum += depth
      count += 1
    }
  }
  if count == 0 {
    0.0
  } else {
    sum / count.to_double()
  }
}

///|
pub fn project_visibility_mask(points : ArrayView[@core.Point3]) -> Array[Bool] {
  let result : Array[Bool] = []
  for point in points {
    result.push(point.z > 0.000000000001)
  }
  result
}

///|
pub fn project_visibility_indices(
  points : ArrayView[@core.Point3],
) -> Array[Int] {
  let result : Array[Int] = []
  for i in 0..<points.length() {
    if points[i].z > 0.000000000001 {
      result.push(i)
    }
  }
  result
}

///|
pub fn visible_point_depths(points : ArrayView[@core.Point3]) -> Array[Double] {
  let result : Array[Double] = []
  for point in points {
    if point.z > 0.000000000001 {
      result.push(point.z)
    }
  }
  result
}
