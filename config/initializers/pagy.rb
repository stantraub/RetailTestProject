Pagy::OPTIONS[:limit] = 50

# Raise before any query when ?page= is past the last page (ApplicationController
# redirects to the last page). Otherwise a huge value becomes an OFFSET larger
# than bigint and Postgres errors.
Pagy::OPTIONS[:raise_range_error] = true
Pagy::OPTIONS.freeze
