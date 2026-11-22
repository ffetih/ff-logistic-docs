# Backlog

FF Logistic builds one logistics product twice, as a modular monolith and as microservices, on one platform, and compares them. This file is the plan for all six repositories. The earlier single-repository version, `ff-devops-logistic-app` (sprints S0–S8 done), is the reference to port from: its fixes are folded into the item where the code first appears, so each fix is written once.

## How the work is cut

| Unit | In Git | Rule |
| :--- | :--- | :--- |
| Sprint | branch `sprint/sNN` in every repository it touches → one pull request each → tag `sNN` on each of them | Ends with something running on the local k3d cluster |
| Item | one commit, subject `SNN-MM <what it does>` (S0 used letters: `S00-a`) | The build and its tests pass at every commit |
| Fix found later | a new item in the current sprint | Old sprints are not rewritten |

Each item lists:

- **Repos**: the repositories its commit touches. An item that touches two repositories is one commit in each, with the same subject.
- **Port**: paths in `ff-devops-logistic-app` to start from.
- **Done when**: the test, command or screen that proves it.

Roles: Claude implements and delivers each sprint as one branch per repository. The owner pushes, opens and merges the pull requests, syncs in Argo CD, tests and tags.

## The three rules everything follows

1. **runtime** is what we run but do not write. **shared** is what we write once. **modulith** and **services** are the same business wired two ways ([decisions](modules/ROOT/pages/decisions.adoc)).
2. **The business rules exist once**, in the domain cores. A core states what it needs from another area as a port; each implementation provides the adapters. The cores do not know which implementation runs them.
3. **The outside is identical**: the same URLs on the edge (8081), the same tables in `ff_logistics`, the same Kafka topics and messages. Exactly one implementation is active; one commit switches.

## Runtime

One single-node k3d cluster, `ff-logistic`, in WSL; Argo CD applies everything from Git. Host ports, fixed in `ff-logistic-runtime/deploy/cluster/k3d-config.yaml`:

| Host port | NodePort | Service |
| :---: | :---: | :--- |
| 8080 | 30080 | Argo CD UI |
| 8081 | 30081 | the edge: the active implementation |
| 8085 | 30085 | identity service |
| 8086 | 30086 | analytics loader |
| 8087 | 30087 | partner gateway |
| 8088 | 30088 | Superset |
| 8090 | 30090 | console |
| 8180 | 30180 | Keycloak (for IDE runs) |
| 9000 | 30900 | RustFS S3 API |
| 9094 | 30094 | Kafka external listener (IDE runs) |
| 5432 | 30432 | PostgreSQL |
| 16686 | 30186 | Jaeger UI |

The reference cluster `ff-logistics` uses the same host ports: only one of the two runs at a time.

## Sprints at a glance

| Sprint | Repos | Ends with |
| :--- | :--- | :--- |
| S0 Foundation | all | The platform runs; base and identity build; this hub and its site exist |
| S1 Walking skeleton and the switch | shared, modulith, services, runtime | An empty app on each side behind the edge; one commit switches; the same smoke test passes on both |
| S2 CI, images and progressive delivery | all | Every repository builds in CI; images on GHCR; canary releases on both sides |
| S3 Standards and warehousing | shared, modulith, services | The first area runs on both sides from one core |
| S4 Transportation and the flows between areas | shared, modulith, services | One shipment crosses three areas: in-process on one side, over REST and Kafka on the other |
| S5 Routing and documents | shared, modulith, services | Route planning and e-CMR / e-POD links on both sides |
| S6 Events out and analytics | shared, modulith, services | Deliveries reach the analytics database from either side; RLS and the monthly rollup |
| S7 The comparison | docs, runtime | Measured: memory, startup, latency, failures, change cost. The comparison guide. |
| S8–S13 | shared, runtime | Reporting and Superset, console, partner gateways, tracing, multi-cluster. Built once, against the edge. |

---

## S0 — Foundation

Goal: the platform runs on the cluster, the libraries and the identity service build, and the hub describes the plan.

- [x] **S00-a Add the k3d cluster config** · runtime
- [x] **S00-b Add the Argo CD install** · runtime
- [x] **S00-c Run PostgreSQL** · runtime
- [x] **S00-d Run Keycloak with the logistics realm** · runtime
- [x] **S00-e Run Kafka** · runtime
- [x] **S00-f Run RustFS** · runtime
- [x] **S00-g Add Argo Rollouts and the service chart** · runtime
- [x] **S00-h Add the base BOM, the parent and the libraries** · base
  Port: `base/*`, renamed `ff-base-*`. Spring Modulith is no longer imported by the BOM (see S00-k).
- [x] **S00-i Add and run the identity service** · shared, runtime
  Port: `platform/ff-identity/identity-service`. The image is built locally and imported with `k3d image import` until S2.
- [x] **S00-j Add the documentation hub** · docs
  README with the architecture diagrams, this backlog, the Antora playbook and the hub pages: overview, architecture, decisions.
  Done when: the repository shows the diagrams on GitHub and `./build.sh` builds the site.
- [x] **S00-k Manage Spring Modulith in the BOM again; restore build and Git info** · base, shared
  The Spring Modulith BOM goes back into `ff-base-bom`, so one version serves both sides: the modulith uses all of it, the services use only its event publication registry as their outbox (decision 6). `ff-base-parent` regains `spring-boot-maven-plugin:build-info` (without a build time, which would be the zip epoch) and `git-commit-id-maven-plugin` (with `failOnNoGitDirectory=false`) in its plugin management: applications list them without a version and `/actuator/info` names the build and commit that is running, the first question after a switch; libraries list neither. The identity service drops its own copy of the Git plugin's configuration. `build.sh` and `mvnw` become executable in Git.
  Done when: `./build.sh` installs the BOM with `spring-modulith-bom` managed, and an app built from the parent shows `build` and `git` in `/actuator/info`.
- [x] **S00-l Give every repository an Antora component** · runtime, base, shared, modulith, services, docs
  `docs/antora.yml`, a nav and a start page in each code repository; the hub's component sits at the root of ff-logistic-docs. The playbook reads the six repositories as sibling folders (`../runtime`, …), their working trees included, with edit links to GitHub. The runtime Cluster Guide moves to `docs/modules/ROOT/pages/`.
  Done when: one `./build.sh` in docs produces a site with a component per repository and working cross-references.
- [x] **S00-m Publish the site on GitHub Pages** · docs
  `.github/workflows/pages.yml` checks out the six repositories side by side, builds the playbook and deploys to Pages, on every push to `main` of the docs repository and by hand; the other repositories trigger it with a `repository_dispatch` of type `docs-changed` after a docs change (from S2, when they have CI). Once: Settings > Pages > Source: GitHub Actions. The default UI's sample header and footer are replaced through `supplemental-ui`.
  Done when: `https://ffetih.github.io/ff-logistic-docs/` shows the site.
- [x] **S00-n Keep each application's deploy values next to its code** · shared, runtime
  `deploy/apps/identity` moves from runtime to shared; the `identity` Application becomes multi-source (the chart from runtime, `$values` from shared). One rule for every application from now on: runtime holds the chart and the Application; the values, including the image tag, live in the repository that builds the image. CI then never writes to another repository (S2).
  Done when: `argocd app diff identity` is empty after the move. Merge shared before runtime: until shared has `deploy/apps/identity`, the new Application cannot render.

## S1 — Walking skeleton and the switch

Goal: an empty application on each side, reached through the same edge, switched by one commit, checked by one smoke test. Images are still built locally and imported (`tools/build-local-images.sh`); S2 publishes them.

- [x] **S01-01 Prove that Spring Modulith checks modules that come from jars** · docs
  A spike before the layout depends on it, kept in `spikes/modulith-modules-from-jars` with a `run.sh` that replays it: two modules in jars of their own, an application jar holding an adapter in one module's package. `ApplicationModules.of(...).verify()` finds both modules, counts the adapter as part of its module, and fails on a call into another module's internals, on a dependency the module does not allow, and on a cycle. Decision 2 holds; its record now says so.
  Done when: `run.sh` prints OK for the clean case and the three violations.
- [x] **S01-02 Run each area's migrations with their own history table** · base
  `ff-base-persistence`: a `MigrationArea` bean names an area; `AreaMigrations` runs one Flyway per area at startup, `db/migration/<area>` into `<area>_flyway_history`, in name order, with a baseline row when the area arrives in a database that already holds other areas' tables. Registered as a database initializer, so JPA and `JdbcTemplate` wait for it. `ff.migrations.enabled=false` turns it off (the chart does, in the pods).
  Done when: `AreaMigrationsTest`: two areas in one database, one area alone and then both, an area in a non-empty database, the dependency of `JdbcTemplate` on the migrations.
- [x] **S01-03 Add the application chassis** · base
  `ff-base-app`, what every FF application has on both sides: shared defaults (health groups, probes, virtual threads, schema validation) from `META-INF/ff/app-defaults.yml`, which an application's own settings override; the `release` health group (`ff.release.healthy`); `/api/v1/me`; `FfApplication.run`, which turns the image into the migration Job under the `migrate` profile (no web server, exit when done).
  Port: `release`, `caller`, `application-migrate.yml` and the application class of `ff-logistics-app`.
  Done when: `ChassisTest`: probes and the release group, a release broken on purpose, the caller, defaults overridden, the migrate profile without a web server.
- [x] **S01-04 Add the domain cores, empty** · shared
  `shared/domain/ff-domain-{standards,warehousing,transportation,routing}` under `com.siose.ff.logistics.<area>`: a `package-info.java` naming the module and what it may use (only standards), an `<Area>Area` configuration declaring its `MigrationArea`, and a first script `V1__<area>_begins.sql` so either side can see the area was migrated. `standards` starts with `TransportMode`. The repository gets an aggregator, the Maven Wrapper and `build.sh`.
  Done when: `./build.sh` installs the four jars.
- [x] **S01-05 Add the modulith application** · modulith, runtime
  `logistics-app`: the four cores and the chassis; `ModularityTest` finds the four areas as modules from shared's jars and verifies them. Its Dockerfile and its values (`deploy/apps/logistics-app`, with the edge label). The chart sets `FF_MIGRATIONS_ENABLED=false` in the pods, next to `SPRING_FLYWAY_ENABLED=false`.
  Done when: the tests pass; the jar migrates three areas under `migrate` and exits 0, and as a pod answers `release: UP`, `401` without a token, and its build and commit on `/actuator/info`.
- [x] **S01-06 Add the three services and their gateway** · services
  `contexts/{warehousing,transportation,routing}` (ports 8082, 8083, 8084): one core each and the chassis; each test checks that the service holds and migrates only its own area. `gateway`: nginx-unprivileged with one route table, `/api/v1/wms/**`, `/api/v1/tms/**`, `/api/v1/geo/**` to their service and `/api/v1/me` to transportation, resolving the services per request so it starts before them. Values for all four; only the gateway carries the edge label.
  Done when: the services' tests pass, and nginx with the same configuration routes each path, with its query and `Authorization`, to the right stand-in service.
- [x] **S01-07 Add the edge Service** · runtime
  The `edge` Application (`deploy/platform/edge`, a small Helm chart): one NodePort Service on 30081 (host 8081) selecting `ff-logistic/edge: "true"`, `targetPort: http`. The service chart gains `podLabels`.
  Done when: `curl localhost:8081/actuator/health/readiness` answers from whichever side is running.
- [x] **S01-08 Add the switch** · runtime
  `deploy/implementation.yaml` (`active: modulith`) and the `ff-implementation` ApplicationSet: a matrix of two git generators, the switch file (with `pathParamPrefix`, as both would produce `path`) and `deploy/apps/*` in `ff-logistic-{{ .active }}`. Generated Applications are multi-source, labelled `ff-logistic/implementation`, with the resources finalizer.
  Done when: changing `active` to `services` and back, by commit, replaces the workloads and keeps the database untouched.
- [x] **S01-09 Run the same smoke test after every switch** · runtime
  The edge chart's PostSync Job signs in through the identity service and calls the edge: readiness, `/api/v1/me` without and with a token, and says which side answered (`/actuator/info` exists on the modulith only).
  Done when: the Job succeeds after a switch in each direction, and fails when the edge has nothing behind it.
- [x] **S01-10 Describe the switch** · docs, runtime
  The walkthrough page, the runtime page's switch section, and `tools/build-local-images.sh`, which builds and imports every image from the sibling folders until CI does (S2).
- [x] **S01-11 Write down what the first run taught** · docs
  The walkthrough gains the picture to keep in mind (a railway junction), how to read a sync in three questions, what WSL needs before the first build (its own JDK 25 and git identity), why the switch takes one to three minutes and how not to wait, how to read the latest smoke test only, and the history tables as the first run left them, baseline rows explained.
- [x] **S01-12 Wait for a new Service's route before the smoke test** · runtime, docs
  After switching back to the modulith, its smoke test failed once: the first call timed out (`000`) and the next ones passed. The sync had created the `logistics-app` Service again, and kube-proxy writes a new ClusterIP's rules a moment after the pods are ready; the PostSync Job ran into that gap. Both smoke tests (the service chart's and the edge's) now wait up to 30 s until the Service accepts a connection, whatever it answers, then run each check once.
  Done when: the modulith's sync after a switch passes its smoke test; an edge with nothing behind it still fails, after 30 s.

## S2 — CI, images and progressive delivery

Goal: no image built by hand. Every repository builds and tests in CI, publishes to GHCR and writes its own image tags; both sides release by canary with analysis.

- [x] **S02-01 Add the reusable build and publish workflows** · runtime
  `java-build.yml`: clone and install what the repository builds on (base, shared) from main without their tests, then `./build.sh` with tests; upload the jars with their paths. `java-publish.yml`: build and push the images whose folder or build files changed (all with `force`), as `ghcr.io/ffetih/ff-logistic-<repo>/<name>:<sha>`, then commit the tags into the same repository's `deploy/apps/<name>/image-local.yaml` with `[skip ci]`, unless main has moved on (decision 11).
  Port: `.github/workflows/ci.yml` of the reference.
- [x] **S02-02 Render every application in CI** · runtime
  `ci.yml`: check out shared, modulith and services next to runtime, `helm lint` and `helm template` every `deploy/apps/*` with the chart, every shape the chart can render, the edge chart, and every kustomization.
  Done when: a broken values file in any repository fails runtime's CI on its next run.
- [x] **S02-03 Build and test the base libraries in CI** · base
- [x] **S02-04 Build shared in CI and publish the identity image** · shared
- [x] **S02-05 Build the modulith in CI and publish its image** · modulith
- [x] **S02-06 Build the services in CI and publish their images** · services
  Four images: the three services and the gateway.
- [x] **S02-07 Release both sides by canary, with analysis** · modulith, services
  The modulith: four pods, 25 %, analysis of the release group, 50 %, a pause, 100 %. Each service: two pods, 50 %, analysis, 100 %.
  Done when: a release broken on purpose (`FF_RELEASE_HEALTHY=false`) aborts at its first analysis on each side, and the old pods keep serving.
- [x] **S02-08 Check the site on pull requests and rebuild it nightly** · docs
  The Pages workflow builds pull requests with warnings as failures and deploys nothing for them; a nightly run picks up documentation changes in the other repositories. `tools/build-local-images.sh` stays, for trying a change before pushing it.
- [x] **S02-09 Describe the delivery** · docs
  Decision 11; the walkthrough's S2 part: the flow from a commit to a canary, the packages made public once, the first sync with `--prune`, a canary that aborts, rebuilding after a change in base or shared.
- [x] **S02-10 Fetch Maven with retries and keep it cached** · runtime, docs
  The first run of base's CI failed before compiling anything: the Maven Wrapper's download of Maven from Maven Central failed once, and the re-run passed. `java-build.yml` now keeps `~/.m2/wrapper` in the Actions cache and fetches Maven in a step of its own, with four tries 15 s apart.
- [x] **S02-11 Clone the repositories a build needs next to it** · runtime, shared, docs
  shared's first CI run failed in `KeycloakRealmTest`: it loads runtime's Keycloak realm file by walking up to a sibling `runtime` folder, which exists on the developer's disk and not on the runner (and without Docker the test had always skipped itself, so it first ran on GitHub). A dependency the single repository hid: a test in shared reads a file in runtime. `java-build.yml` now clones what a repository builds on, and the repositories its tests read (`siblings`), next to the checkout under their short names, the same layout as `D:\dev\workspace\ff-logistic`; shared's CI declares `siblings: runtime`.
- [x] **S02-12 Explain the delivery, and what went wrong the first time** · docs
  A Delivery page: Maven, CI and GHCR as workbench, conveyor and warehouse; which run publishes which images; the `gh` loop for a pull request and a forced publish; the six problems of the first run with their cause and rule; the order in which a sprint's repositories are merged; how the documentation site itself is built and published (pull request check, push, nightly, Run workflow). The walkthrough's "first images" now says they come from *Run workflow*, not from a push.


## S3 — Standards and warehousing

Goal: the first business area on both sides from one core. The walkthrough's warehouse part runs on either.

- [x] **S03-01 Port the standards** · shared
  `ff-domain-standards`: GS1 (SSCC, GLN check digits), ISO 6346 container codes, transport modes, the EN 16258 / ISO 14083 emissions calculator, `GeoDistance`.
  Port: `…/logistics/standards`.
- [x] **S03-02 Port the warehousing core** · shared
  Warehouses, bins, ASNs, receiving and palletizing; its REST API under `/api/v1/wms`; its migrations in `db/migration/warehousing` with history `warehousing_flyway_history`.
  Port: `…/logistics/wms`, `V*__wms_*.sql`.
  The package is the area's name (`…logistics.warehousing`); the tables and the URL keep the industry's `wms`. The scripts are V2 and V3 after S1's V1, with `TIMESTAMP WITH TIME ZONE` so that H2 runs them too. The area's 22 tests run here, once, on a test-only Spring Boot application with the same chassis, against the real migrations (the reference built its test tables from the entities instead).
- [x] **S03-03 Run warehousing in the modulith** · modulith
  Nothing to wire: component scanning finds the area. Added: the validation starter (without it `@Valid` checks nothing), and `WarehousingServedTest` for the route, the role, the tenant and validation.
- [x] **S03-04 Run warehousing as a service** · services
  The same two additions as the modulith's.
- [x] **S03-05 One walkthrough, two implementations** · docs
  The warehouse walkthrough against the edge; run it, switch, run it again: same answers, same rows.

## S4 — Transportation, and the first flow between areas

Goal: the comparison becomes real: one area tells another something, in-process on one side, over Kafka on the other, from the same cores.

Flows 1 and 3 (the road distance, the route stop with e-POD) both involve routing, which arrives in S5; they move there. S4 builds flow 2 completely, and with it everything the other two need: the outbox on both sides, Kafka, an idempotent consumer, a dead-letter topic.

- [x] **S04-00 Housekeeping** · docs
  The site's menu in sections (Learn, Reference, Operate); in the Delivery page, wait a few seconds before watching a run, and let GitHub merge a pull request once its checks pass (auto-merge, a required check), set up by hand in each repository.
- [x] **S04-01 Keep each process's outbox in a schema of its own** · base
  `ff-base-events`: the registry's table migrated as the area `outbox` in the process's schema (`ff.events.schema`), unfinished events published again from one pod at a time with a doubling wait, completed ones deleted; `MigrationArea` may name a schema. Decision 12.
  Port: `…/logistics/outbox` of the reference, from the application into a library.
- [x] **S04-02 Port the transportation core** · shared
  Shipments, legs, the lifecycle, the footprint; `ShipmentProgressed` and `ShipmentDelivered` as the area's API; a destination's GLN, which the delivery event carries with the pallet's SSCC and weight. One script for the reference's four. The e-CMR document links come with S5's documents.
  Port: `…/logistics/tms`, `V4`–`V7__tms_*.sql`.
- [x] **S04-03 Open an inbound arrival when a shipment reaches a warehouse** · shared
  Warehousing's half of flow 2, in its own words: `InboundArrivals.open(ShipmentArrival)`, idempotent by shipment, in the shipment's tenant, without a request; `GET /api/v1/wms/arrivals`.
- [x] **S04-04 Wire the flow in-process** · modulith
  The `flows` module: a listener on `ShipmentDelivered` after the commit, through the outbox in the schema `modulith`. Spring Modulith checks that it uses both areas through their APIs only.
- [x] **S04-05 Wire the flow over Kafka** · services
  Transportation sends its events to Kafka through its outbox (schema `transportation`), keyed by the shipment; warehousing reads them in the consumer group `warehousing`, into a type of its own, and opens the arrival; a message it cannot read goes to `….warehousing.dlt`, one that fails otherwise is tried twice first. Tested against a broker in the test JVM.
- [x] **S04-06 One shipment through both** · docs
  A "Try it" page, from booking to the arrival at the dock, on each side; the walkthrough's S4.
- [x] **S04-07 First failure drills** · docs
  On the services side: stop the warehousing service, deliver, start it again; stop Kafka, deliver, start it again. On the modulith: what is there to stop? Written down with what was observed: a "Try it" page. No delivery lost; with Kafka down the event waited in the outbox for four tries, about seven minutes.

## S5 — Routing and documents

- [x] **S05-01 Port the routing core** · shared, base
  Territories, route plans, time windows; Timefold over a road matrix (OSRM, haversine fallback). The reference's `geo` package as `routing`, its `routing` subpackage as `planning`; the settings under `ff.routing`; paths (`/api/v1/geo`) and tables (`geo_*`) as before. Two scripts in one; the proof of delivery waits for S05-05. Timefold's version in the base BOM.
  Port: `…/logistics/geo`.
- [x] **S05-02 Run routing on both sides** · modulith, services
  The same settings on both sides, the straight-line estimate by default (no OSRM in the cluster); the routing service gets the validator the area's requests need. Each side checks that it serves the area.
- [x] **S05-03 Ask routing for a leg's road distance** · shared, modulith, services
  Flow 1: transportation's port `DistanceLookup`; a method call in the modulith, HTTP with a timeout and a haversine fallback on the services side. A road leg may be booked by its ends; the fallback is decided in the core, and the leg records where its distance came from. Routing's API `RoadDistances`, and `GET /api/v1/geo/distance` for the services, with the planner's token passed on.
- [x] **S05-04 Deliver a shipment from a completed route stop** · shared, modulith, services
  Flow 3: routing's event, through the outbox; in-process in the modulith, over Kafka on the services side, with the consumer and dead-letter topic of S04-05. A stop names the shipment it carries; completing it publishes `RouteStopCompleted`; transportation's `ShipmentDeliveries` delivers, once, and flow 2 follows. The routing service gets an outbox of its own (schema `routing`). Spring Modulith's Kafka support reads bytes and converts JSON for the listener: the consumer takes the message type.
- [x] **S05-05 Add document links** · shared, modulith, services, runtime
  Presigned, write-once RustFS links: e-CMR in transportation, e-POD in routing; the storage settings on both sides. The proof of delivery is asked for by stop code, like the completion. ff-base-storage and RustFS's Secret were already in place: no change in runtime.
  Port: `base/ff-base-storage` use from S7 of the reference.
- [x] **S05-06 Write down how a sprint is shipped, and why six repositories** · docs
  The `ship` helper in the Delivery page (it waits for each merge's own run), decision 13, and a "Try it" page for routing with the first run's answers.
- [x] **S05-07 Build a sprint's branches together** · runtime
  A pull request's CI clones a library's branch of the same name when it exists, `main` otherwise: a sprint's pull requests go green together, in any order. Merging still follows the build order.
- [x] **S05-08 Explain a request without a body** · base
  An empty or unreadable request body was answered `400` with no title and no detail (seen in S5's flow-1 run). Now `missing-body` or `unreadable-body`, with the property and the place the parser stopped, from `ff-base-web`'s problem handler. The first version guessed the parser's message format; the second reads Jackson's exception ("Try it: routing talks to transportation", step 7).

- [x] **S05-09 Wrap long lines in code blocks** · docs
  Not done in S5: moved to S06-06.

## S6 — Events out and analytics

- [x] **S06-01 Port the analytics loader** · shared, runtime
  The loader, its database, the dead-letter topic. Named like the services' consumers: group `analytics`, dead-letter topic `….analytics.dlt`. It waits for its database without end instead of setting a delivery aside. Its own database, `ff_logistics_analytics`, is the first use of the chart's database Job.
  Port: `platform/ff-analytics/analytics-loader` (S08-03 of the reference).
- [x] **S06-02 Lock the analytics tables to the tenant and roll them up per month** · shared
  Port: S08-04 and S08-05 of the reference. The tests that need PostgreSQL run against a container, or a server named by `ANALYTICS_TEST_DB_URL`; skipped with neither.
- [x] **S06-03 Publish the same events from both sides, checked by one contract test** · shared, modulith, services
  The topic names and message examples live in shared (`ff-contracts`, decision 14); both sides run the same contract test against what they publish.
  Done when: a delivery made on either side lands in `shipment_deliveries`, and the loader cannot tell which side sent it. Shown with SHP-10013, delivered on the modulith.
- [x] **S06-04 Keep the analytics totals exact** · shared
  Seen on the cluster: three deliveries of 1565.1 kg summed to 4695.299999999999 as doubles. Distances and CO2e are `NUMERIC(12,3)` now, the monthly sums `NUMERIC(15,3)`, and `V4` has every month recounted.
- [ ] **S06-05 Rebuild only the image a new module adds** · runtime
  A new module in a repository's root `pom.xml` rebuilds every image of that repository (shared's `identity`, twice in S6). The change detection could tell a new module from a changed build.
- [ ] **S06-06 Wrap long lines in code blocks** · docs
  Carried over from S05-09.

## S7 — The comparison

Goal: numbers instead of opinions.

- [ ] **S07-01 Add a load script against the edge** · runtime
  k6 in the cluster: the walkthrough as a scenario, run against whichever side is active.
- [ ] **S07-02 Measure both sides** · docs
  Memory at rest and under load, startup to ready, p50/p95 per request type, pods and CPU.
  Both sides, five users, four minutes, recorded in `try-load` (2026-11-21 services, 2026-11-22 modulith). 0% failed on each. Startup not measured.
- [ ] **S07-03 Run the failure drills on both sides** · docs
  Database away, Kafka away, one area away, a slow area: what the user sees, what is lost, what recovers by itself.
  Kafka away during that load, both sides. On the services, arrivals and analytics froze and the outbox drained 412 s after the broker came back. On the modulith, arrivals kept up and analytics caught up 231 s after. Nothing lost, and the caller did not see it either time. PostgreSQL away, both sides (`try-database`): five plans failed at 30 s on each, everything after a successful plan succeeded, and the first readable sample was already caught up, with an empty outbox. Routing away, services side only (`try-routing-away`): no plan failed, it fell back to the straight-line estimate after 1 s, and 7.8 % of the direct distance calls failed at the gateway's 2 s. Deliveries never queued. A slow area, and startup, are still open.
- [ ] **S07-04 Count the cost of a change** · docs
  Three real changes (a new field, a new rule in one area, a new flow between areas): files, repositories, pull requests, deployments, on each side.
- [ ] **S07-05 Write the comparison guide** · docs
  The five runs are side by side in `comparison` (2026-11-22). Startup, a slow area, and the cost of a change are not in it.
- [ ] **S07-06 Ship a sprint with one workflow** · runtime
  The `ship` chain as a workflow in runtime (a release train): started with a branch name, it merges each repository's pull request in the build order and waits for its run. Needs a token that may act on the other repositories. Optional.

## S8–S13 — Built once, against the edge

Outline; each sprint is detailed when it starts. They talk to the edge and the topics, so they do not care which side is active.

- **S8 Reporting and Superset**: tenant-scoped guest tokens, dashboards as code. Port: S9 of the reference plan.
- **S9 Console**: one origin behind nginx, sign-in through identity, warehouse and shipment pages, routes on a map, embedded dashboards.
- **S10 Partner gateway: Northfield**: inbox and outbox, OAuth2 and REST in, SOAP status out, one instance per round.
- **S11 Partner gateway: Corvane**: EDIFACT over SFTP with Camel, CONTRL before acceptance.
- **S12 Tracing**: one trace across the edge, the areas, Kafka and the outbox, the clearest picture of the difference: one process versus four.
- **S13 Multi-cluster, Workflows and Events**: a staging cluster, promotion by commit, the monthly rollup as a CronWorkflow, a workflow started by a Kafka event.
