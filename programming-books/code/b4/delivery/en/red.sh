# The same pipeline, after someone removes ends_at
$ sh ci.sh; echo "exit code: $?"
type check: ok
contract tests: ok
breaking changes: FAILED
1 breaking changes:
- POST /bookings 201: response field removed "ends_at"
pipeline failed at: breaking changes
exit code: 1
