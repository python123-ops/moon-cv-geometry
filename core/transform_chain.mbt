///|
pub(all) struct TransformChain {
  transforms : Array[RigidTransform]
} derive(Debug, Eq)

///|
pub fn TransformChain::new(
  transforms : ArrayView[RigidTransform],
) -> TransformChain {
  { transforms: transforms.to_owned(), }
}

///|
pub fn TransformChain::length(chain : TransformChain) -> Int {
  chain.transforms.length()
}

///|
pub fn TransformChain::is_empty(chain : TransformChain) -> Bool {
  chain.transforms.length() == 0
}

///|
pub fn TransformChain::apply(chain : TransformChain, point : Point3) -> Point3 {
  for value = point, i = 0; i < chain.transforms.length(); {
    continue chain.transforms[i].apply(value), i + 1
  } nobreak {
    value
  }
}

///|
pub fn TransformChain::inverse(chain : TransformChain) -> TransformChain {
  let result : Array[RigidTransform] = []
  for i = chain.transforms.length() - 1; i >= 0; {
    if i >= 0 {
      result.push(chain.transforms[i].inverse())
    }
    continue i - 1
  } nobreak {
    TransformChain::new(result)
  }
}

///|
pub fn TransformChain::append(
  chain : TransformChain,
  transform : RigidTransform,
) -> TransformChain {
  let result = chain.transforms.copy()
  result.push(transform)
  TransformChain::new(result)
}

///|
pub fn TransformChain::compose(chain : TransformChain) -> RigidTransform {
  for value = RigidTransform::identity(), i = 0; i < chain.transforms.length(); {
    continue value.compose(chain.transforms[i]), i + 1
  } nobreak {
    value
  }
}

///|
pub fn transform_points(
  chain : TransformChain,
  points : ArrayView[Point3],
) -> Array[Point3] {
  let result : Array[Point3] = []
  for point in points {
    result.push(chain.apply(point))
  }
  result
}

///|
pub fn transform_vectors(
  chain : TransformChain,
  vectors : ArrayView[Vec3],
) -> Array[Vec3] {
  let rotation = chain.compose().rotation
  let result : Array[Vec3] = []
  for vector in vectors {
    result.push(rotation.mul_vec3(vector))
  }
  result
}
