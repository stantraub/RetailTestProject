# Retail Inventory Tracking System

> **Part 1** is my submission: how to run it and the decisions behind it.
> **Part 2**, after the divider, is the original assignment text, unchanged
> (its Setup section is replaced by Part 1).

## Part 1: My submission

### How to run it

Requirements: Ruby 3.2.2 and PostgreSQL 13+ running locally (set `DATABASE_URL`
if your Postgres needs a password).

```bash
bundle install
bin/rails db:create db:migrate db:seed
bin/rails inventory_events:import   # about 30 seconds; also creates the alerts
bin/rails server                    # then open http://localhost:3000
bin/rails test                      # optional: run the tests
```

Run the import once. To start over, run `bin/rails db:seed` and then the import
again.

### Tests

`bin/rails test` runs the suite in a few seconds, on its own database and without
the CSV import. It covers alert detection (for N = 2 and 3), the importers, the
stores, products, brands and alerts pages (including query-count tests that fail
if an N+1 query comes back), and the models and rake task.

### What I built

**Price tracking.** A separate `price_events` table rather than a nullable price
column, because inventory checks and price checks are independent (the cost is a
join to relate price to stock). I renamed `TrackingEvent` to `InventoryEvent` to
match; in Part 2 it means `InventoryEvent`. No price data was provided, so
`db:seed` makes fake prices and `price_events:import` loads real ones from a
CSV. Product and store pages show the latest price.

**Alerts.** An `alerts` table filled by one SQL query that finds a store
reporting "no inventory" N times in a row for a product, ordered by `event_time`
(N defaults to 2, the assignment's rule; a longer streak is one alert). It runs
at the end of the import or with `bin/rails alerts:detect`, and is safe to
re-run. Each alert belongs to the product's brand: the brand's page shows its
recent alerts, and `/alerts` is a paginated list (filterable by brand) with a
detail page.

**Performance.** Fixed N+1 queries, paginated the lists with Pagy, added
indexes, and batched the importer:

| | Before | After |
|---|---|---|
| Import 1M rows | about 22 min | about 34 s |
| Store page | 20,108 queries, 5.5 s | 7 queries, 0.02 s |
| Product page | 4,417 queries, 1.0 s | 7 queries, 0.02 s |

### Engineering choices and scalability

- **Configurable streak length.** N is set with `ALERT_STREAK_LENGTH` or per run
  with `bin/rails "alerts:detect[3]"`. One query handles any N: it numbers the
  "no" checks within each run of consecutive "no"s and alerts where the number
  reaches N, so the cost doesn't depend on N. Checked against a plain Ruby
  recount for N = 2, 3 and 5.
- **It counts checks, not days.** N checks in a row can span days or months. A
  "days out of stock" rule would compare dates instead.
- **At larger scale** the query rescans every event on each run. I would detect on
  write instead (check a store and product's recent events when one is saved)
  and keep one open alert per outage, closed when stock returns.

### Out of scope

- **Notifying the brand.** I read "alert the brand" as a record addressed to the
  brand that the brand can see (its page shows its recent alerts), as the
  assignment asks only for an index and a show page. Nothing is sent. Real
  delivery, such as an email or webhook when an alert is created, would need a
  contact address per brand and a background job, and would be the next step
  after the alert is created.
- **Running detection from the UI.** The app is read-only with no login, so a
  button would let any visitor start a full scan, runs with different N would mix
  alerts from different rules, and in a real system detection is a background
  job, not a user action.

### Known limitations

- The CSV has dates only, so same-day checks are ordered by file position,
  which can affect whether a streak exists.
- Alert detection only adds alerts, so late-arriving older events can leave
  stale ones.

---

## Part 2: Original assignment

> Everything below is the original text, kept for reference. Heading levels are
> one deeper than the original, and its Setup section is replaced by Part 1.

### Project Overview

This project simulates a simplified retail inventory-tracking system. You are provided with:

- A set of **Stores**
- A set of **Brands**
- A set of **Products**
- A large CSV file containing **1,000,000 tracking events**
- A basic importer that reads the CSV and creates `TrackingEvent` records

Your goal is to improve the system, modify one of its key features, and then add a new feature.

You are encouraged to:
- Refactor existing code
- Introduce new endpoints or views
- Improve performance, clarity, and maintainability

There is no single "correct" solution — but there are many poor ones. We want to see how **you** design and implement a real-world improvement inside a Rails application.


### Objectives

#### First Objective: Price Tracking

Currently, the system only tracks if inventory is present via `TrackingEvent`. We want to add a way to track price. An inventory check and price check are separate and can occur without the other happening.

#### Second Objective: Alert System

Build an alert system that creates an alert to the brand if a store has two "no inventory" events in a row for the same product based on event_time. There doesn't need to be a big UI for this—just a basic index and show page like the rest of the app.

#### Third Objective: Performance Improvements

Improve the app's overall performance. This can be done as you work on the first and second objectives or after completing them.

### Technology Stack

- **Ruby**: 3.2.2
- **Rails**: 7.1.6
- **Database**: PostgreSQL 13+

### Evaluation Criteria

You will be evaluated on:
- Code quality and organization
- Database design decisions
- Performance optimizations
- Ability to explain your thinking and decision making

Feel free to make reasonable assumptions where requirements are ambiguous—just document them in your code or a separate notes file.

### Time Expectation

This project should take approximately [2-3 hours] to complete. Focus on demonstrating your problem-solving approach rather than achieving perfection. AI is allowed on this project. 

### Submission

Please submit:
- A link or invite to your Git repository (GitHub, GitLab, etc.)
- A brief README or notes document explaining your key decisions
- Any instructions needed to run your solution
