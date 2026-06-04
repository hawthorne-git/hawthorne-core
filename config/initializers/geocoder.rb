# set the geocoder to timeout after 2 seconds, and raise exceptions
Geocoder.configure(
  timeout: 2,
  always_raise: [SocketError, Timeout::Error]
)