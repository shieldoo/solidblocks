#!/usr/bin/env bash

set -eu -o pipefail

DIR="$(cd "$(dirname "$0")" ; pwd -P)"

source "${DIR}/solidblocks-shell/lib/download.sh"
source "${DIR}/solidblocks-shell/lib/software.sh"
source "${DIR}/solidblocks-shell/lib/file.sh"
source "${DIR}/solidblocks-shell/lib/log.sh"

VERSION="${GITHUB_REF_NAME:-snapshot}"
COMPONENTS="solidblocks-debug-container solidblocks-sshd solidblocks-shell solidblocks-minio solidblocks-rds-postgresql"

function ensure_environment {
  software_ensure_shellcheck
  software_ensure_hugo
  software_ensure_semver
  software_set_export_path
}

function task_build {
    for component in ${COMPONENTS}; do
        cd "${DIR}/${component}"
        VERSION=${VERSION} "./do" build
    done
    mkdir -p "${DIR}/doc/generated"
    cp -rv ${DIR}/*/build/documentation/* "${DIR}/doc/generated"
}

function task_test {
    for component in ${COMPONENTS}; do
      (
        cd "${DIR}/${component}"
        VERSION=${VERSION} "./do" test
      )
    done
}

function task_release_docker {
    for component in ${COMPONENTS}; do
      (
        cd "${DIR}/${component}"
        VERSION=${VERSION} "./do" release-docker
      )
    done
}

function task_build_documentation {
    ensure_environment
    export VERSION="$(semver get release)"
    mkdir -p "${DIR}/build/documentation"
    (
      cd "${DIR}/build/documentation"

      cp -r ${DIR}/doc/* ./

      source "${DIR}/solidblocks-shell/lib/software.sh"
      sed -i "s/__TERRAFORM_VERSION__/${TERRAFORM_VERSION}/g" content/shell/software/_index.md
      sed -i "s/__CONSUL_VERSION__/${CONSUL_VERSION}/g" content/shell/software/_index.md
      sed -i "s/__HUGO_VERSION__/${HUGO_VERSION}/g" content/shell/software/_index.md
      sed -i "s/__SHELLCHECK_VERSION__/${SHELLCHECK_VERSION}/g" content/shell/software/_index.md
      sed -i "s/__SEMVER_VERSION__/${SEMVER_VERSION}/g" content/shell/software/_index.md
      sed -i "s/__TERRAGRUNT_VERSION__/${TERRAGRUNT_VERSION}/g" content/shell/software/_index.md
      sed -i "s/__SOLIDBLOCKS_VERSION__/${VERSION}/g" content/rds/_index.md
      hugo
    )

  sed "/__BOOTSTRAP_SOLIDBLOCKS_MINIMAL_SKELETON__/e cat ${DIR}/solidblocks-shell/build/documentation/shell_minimal_skeleton_do" "${DIR}/README_template.md" | grep -v "__BOOTSTRAP_SOLIDBLOCKS_MINIMAL_SKELETON__" > "${DIR}/README.md"

}

function task_serve_documentation {
    ensure_environment
    (
      cd "${DIR}/doc"
      hugo serve --baseURL "/"
    )
}

function task_release {
  ensure_environment
  task_build_documentation

  if [[ ! -f ".semver.yaml" ]]; then
    semver init --release v0.0.1
  fi

  local version="$(semver get release)"

  git add README.md || true
  git commit --allow-empty -m "release ${version}"

  git tag -a "${version}" -m "${version}"
  git push --tags

  semver up release
  git add .semver.yaml
  git commit -m "bump version to $(semver get release)"
  git push
}


function task_usage {
  echo "Usage: $0 ..."
  exit 1
}

ARG=${1:-}
shift || true

case ${ARG} in
  build) task_build "$@" ;;
  test) task_test "$@" ;;
  build-documentation) task_build_documentation "$@" ;;
  serve-documentation) task_serve_documentation "$@" ;;
  release) task_release "$@" ;;
  release-docker) task_release_docker "$@" ;;
  *) task_usage ;;
esac