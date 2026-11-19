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

Goal: an empty application on each side, reached through the same edge, switched by one commit, checked by one smoke test. Images are still imported locally (S2 publishes them).

- [ ] **S01-01 Prove that Spring Modulith checks modules that come from jars** · shared, modulith
  A spike before the layout depends on it: two small modules in jars of their own, a modulith application that depends on both. `ApplicationModules.of(...).verify()` must see both modules and fail on a dependency the modules do not allow. If it cannot, the cores move into the modulith repository as source modules and the services depend on them from there; decision 2 is updated either way.
  Done when: the spike's test fails on a forbidden dependency and passes without it; the result is written into decision 2.
- [ ] **S01-02 Add the domain cores, empty** · shared
  `shared/domain/ff-domain-{standards,warehousing,transportation,routing}`: packages, a `package-info.java` naming each core's allowed dependencies (only standards), and each core's Flyway location `db/migration/<area>` with its own history table `<area>_flyway_history` (decision 3).
  Done when: `./build.sh` in shared installs the four jars.
- [ ] **S01-03 Add the modulith application** · modulith
  `logistics-app`: depends on the four cores, base web, security and persistence; one Flyway run per area; `ModularityTest` verifies the modules. Health groups `liveness`, `readiness`, `release`.
  Port: `platform/ff-logistics/ff-logistics-app` (application class, `release`, `caller`, application.yml).
  Done when: the tests pass, and the app starts against the cluster's PostgreSQL from the IDE.
- [ ] **S01-04 Add the three services and their gateway** · services
  `warehousing`, `transportation`, `routing`: each one Spring Boot application with one core and its Flyway run. `gateway`: an nginx with one route table, `/api/v1/wms/**` → warehousing, `/api/v1/tms/**` → transportation, `/api/v1/geo/**` → routing.
  Done when: each service's tests pass, and `docker run` of the gateway answers `/api/v1/*/` health through to stubs.
- [ ] **S01-05 Add the edge Service** · runtime
  One Service `edge` on NodePort 30081 selecting the label `ff-logistic/edge: "true"`. The modulith's pods carry it; on the services side only the gateway's pods do. The edge never changes when the implementation does.
  Done when: `curl localhost:8081/actuator/health` answers from whichever side is running.
- [ ] **S01-06 Add the switch** · runtime
  `deploy/implementation.yaml` (`active: modulith`) and an ApplicationSet with a Git file generator: it renders the Applications of the active implementation only, each multi-source (chart from runtime, values from its repository), with the resources finalizer so a switch prunes the other side.
  Done when: changing `active` to `services` and back, by commit, replaces the workloads and keeps the database untouched.
- [ ] **S01-07 Run the same smoke test after every switch** · runtime
  A PostSync Job of the switch Application calls the edge: health, an authenticated call with a token from the identity service, the release group. The same Job for both sides.
  Done when: the Job succeeds after a switch in each direction, and fails when the edge has nothing behind it.
- [ ] **S01-08 Describe the switch** · docs
  Architecture page: the switch, the edge, the label; a walkthrough page that starts each sprint's walkthrough from the edge.

## S2 — CI, images and progressive delivery

Goal: no image built by hand. Every repository builds and tests in CI, publishes to GHCR and writes its own image tags.

- [ ] **S02-01 Build base in CI** · base
  Build and test on every push and pull request; Testcontainers through Docker on the runner.
- [ ] **S02-02 Build and publish shared** · shared
  Checks out and installs base first, then builds the domain cores, identity and analytics loader; publishes `ghcr.io/ffetih/ff-logistic-shared/<app>`; commits the tag into `deploy/apps/<app>/image-local.yaml` of the same repository.
  Port: `.github/workflows/ci.yml`.
- [ ] **S02-03 Build and publish the modulith** · modulith
  Installs base and shared's domain cores first, then the same publish-and-tag steps.
- [ ] **S02-04 Build and publish the services** · services
  A matrix over the three services and the gateway.
- [ ] **S02-05 Release both sides by canary, with analysis** · modulith, services
  The chart's Rollout and AnalysisTemplate (already in runtime) switched on for the modulith and for each service: four pods for the modulith (25 % steps are whole pods), two for each service.
  Done when: a new image on each side goes through its steps and is promoted only after the analysis passes; a broken release health aborts it.
- [ ] **S02-06 Make the images public and drop the pull secret** · all
  New GHCR packages start private.

## S3 — Standards and warehousing

Goal: the first business area on both sides from one core. The walkthrough's warehouse part runs on either.

- [ ] **S03-01 Port the standards** · shared
  `ff-domain-standards`: GS1 (SSCC, GLN check digits), ISO 6346 container codes, transport modes, the EN 16258 / ISO 14083 emissions calculator, `GeoDistance`.
  Port: `…/logistics/standards`.
- [ ] **S03-02 Port the warehousing core** · shared
  Warehouses, bins, ASNs, receiving and palletizing; its REST API under `/api/v1/wms`; its migrations in `db/migration/warehousing` with history `warehousing_flyway_history`.
  Port: `…/logistics/wms`, `V*__wms_*.sql`.
- [ ] **S03-03 Run warehousing in the modulith** · modulith
- [ ] **S03-04 Run warehousing as a service** · services
- [ ] **S03-05 One walkthrough, two implementations** · docs
  The warehouse walkthrough against the edge; run it, switch, run it again: same answers, same rows.

## S4 — Transportation and the flows between areas

Goal: the comparison becomes real. In the reference, the areas hardly talk to each other; here they do, through ports (decision 7):

| Flow | Kind | Modulith | Services |
| :--- | :--- | :--- | :--- |
| Transportation asks routing for a leg's road distance | query | method call | HTTP with timeout and a haversine fallback |
| A shipment delivered to a warehouse opens its receiving at warehousing | event | Modulith event | Kafka, outbox |
| A completed route stop with e-POD delivers the shipment | event | Modulith event | Kafka, outbox |

- [ ] **S04-01 Port the transportation core with its ports** · shared
  Shipments, legs, the lifecycle, the footprint; the ports `DistanceLookup` and the events `ShipmentProgressed`, `ShipmentDelivered`.
  Port: `…/logistics/tms`.
- [ ] **S04-02 Wire the flows in-process** · modulith
  Adapters as Spring beans and `@ApplicationModuleListener`s; the Modulith event registry.
- [ ] **S04-03 Wire the flows over the network** · services
  An HTTP client adapter with timeouts and fallback; Kafka for events through the Spring Modulith event registry as outbox; consumers that are idempotent and order by `occurredAt`; a dead-letter topic per consumer.
- [ ] **S04-04 One shipment through both** · docs
  The walkthrough from booking to delivery, with a sequence diagram per side.
- [ ] **S04-05 First failure drills** · docs
  Stop routing on the services side: what does booking do? Stop Kafka on each side: what is lost, what waits? Written down with the observed behaviour.

## S5 — Routing and documents

- [ ] **S05-01 Port the routing core** · shared
  Territories, route plans, time windows; Timefold over a road matrix (OSRM, haversine fallback).
  Port: `…/logistics/geo`.
- [ ] **S05-02 Run routing on both sides** · modulith, services
- [ ] **S05-03 Add document links** · shared, modulith, services, runtime
  Presigned, write-once RustFS links: e-CMR in transportation, e-POD in routing; the storage settings on both sides.
  Port: `base/ff-base-storage` use from S7 of the reference.

## S6 — Events out and analytics

- [ ] **S06-01 Port the analytics loader** · shared
  The loader, its database, the dead-letter topic.
  Port: `platform/ff-analytics/analytics-loader` (S08-03 of the reference).
- [ ] **S06-02 Lock the analytics tables to the tenant and roll them up per month** · shared, runtime
  Port: S08-04 and S08-05 of the reference.
- [ ] **S06-03 Publish the same events from both sides, checked by one contract test** · shared, modulith, services
  The topic names and message examples live in shared; both sides run the same contract test against what they publish.
  Done when: a delivery made on either side lands in `shipment_deliveries`, and the loader cannot tell which side sent it.

## S7 — The comparison

Goal: numbers instead of opinions.

- [ ] **S07-01 Add a load script against the edge** · runtime
  k6 in the cluster: the walkthrough as a scenario, run against whichever side is active.
- [ ] **S07-02 Measure both sides** · docs
  Memory at rest and under load, startup to ready, p50/p95 per request type, pods and CPU.
- [ ] **S07-03 Run the failure drills on both sides** · docs
  Database away, Kafka away, one area away, a slow area: what the user sees, what is lost, what recovers by itself.
- [ ] **S07-04 Count the cost of a change** · docs
  Three real changes (a new field, a new rule in one area, a new flow between areas): files, repositories, pull requests, deployments, on each side.
- [ ] **S07-05 Write the comparison guide** · docs

## S8–S13 — Built once, against the edge

Outline; each sprint is detailed when it starts. They talk to the edge and the topics, so they do not care which side is active.

- **S8 Reporting and Superset**: tenant-scoped guest tokens, dashboards as code. Port: S9 of the reference plan.
- **S9 Console**: one origin behind nginx, sign-in through identity, warehouse and shipment pages, routes on a map, embedded dashboards.
- **S10 Partner gateway: Northfield**: inbox and outbox, OAuth2 and REST in, SOAP status out, one instance per round.
- **S11 Partner gateway: Corvane**: EDIFACT over SFTP with Camel, CONTRL before acceptance.
- **S12 Tracing**: one trace across the edge, the areas, Kafka and the outbox, the clearest picture of the difference: one process versus four.
- **S13 Multi-cluster, Workflows and Events**: a staging cluster, promotion by commit, the monthly rollup as a CronWorkflow, a workflow started by a Kafka event.
