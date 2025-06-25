# Helper to ensure resource cleanup between tests

Spec.after_each do
  # Force cleanup of any lingering resource managers
  # This helps prevent memory issues between tests
  GC.collect
end
