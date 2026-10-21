#pragma once

// Contact and slip detection from foot force, joint velocity and IMU.
// TODO: implement Schmitt-trigger contact detection and slip residual.

namespace rak_wbc {
class ContactDetector {
public:
  ContactDetector() = default;
  ~ContactDetector() = default;
};
}  // namespace rak_wbc
