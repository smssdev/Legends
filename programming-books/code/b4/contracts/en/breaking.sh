# What would break if we published the next version
$ node breaking.ts openapi.yaml openapi.next.yaml
3 breaking changes:
- POST /bookings: new required request field "phone"
- POST /bookings 201: response field removed "ends_at"
- POST /bookings 201: "status" new value clients may not handle: no_show
