#!/usr/bin/env bash
# Builds every FF Logistic image from the six repositories checked out side by side
# (D:\dev\workspace\ff-logistic) and imports it into the k3d cluster, tagged "local".
# Until CI publishes images (S2), this is how a change reaches the cluster.
#
#   tools/build-local-images.sh              # everything
#   tools/build-local-images.sh modulith     # only the modulith (base and shared are still built)
#   tools/build-local-images.sh services
#
# Needs JDK 25, Docker and k3d. The images' values files (deploy/apps/*/image-local.yaml) say
# tag "local", so a sync after this picks them up; delete the pods, or sync with --force, for
# Kubernetes to start them again from the new image.
set -euo pipefail
cd "$(dirname "$0")/../.."
CLUSTER=${CLUSTER:-ff-logistic}
WHAT=${1:-all}

image() { # repository-path context
  docker build -q -t "ghcr.io/ffetih/$1:local" "$2" >/dev/null
  k3d image import "ghcr.io/ffetih/$1:local" -c "$CLUSTER" >/dev/null
  echo "  imported ghcr.io/ffetih/$1:local"
}

echo "[1/4] base";   base/build.sh -q -DskipTests
echo "[2/4] shared"; shared/build.sh -q -DskipTests
if [ "$WHAT" = all ]; then image ff-logistic-shared/identity shared/identity; fi

if [ "$WHAT" = all ] || [ "$WHAT" = modulith ]; then
  echo "[3/4] modulith"; modulith/build.sh -q -DskipTests
  image ff-logistic-modulith/logistics-app modulith/logistics-app
fi
if [ "$WHAT" = all ] || [ "$WHAT" = services ]; then
  echo "[4/4] services"; services/build.sh -q -DskipTests
  for s in warehousing transportation routing; do image "ff-logistic-services/$s" "services/contexts/$s"; done
  image ff-logistic-services/gateway services/gateway
fi
