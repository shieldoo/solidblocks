#!/usr/bin/env bash

set -eu -o pipefail

DIR="$(cd "$(dirname "$0")" ; pwd -P)"

source "${DIR}/solidblocks-shell/lib/download.sh"
source "${DIR}/solidblocks-shell/lib/software.sh"
source "${DIR}/solidblocks-shell/lib/file.sh"
source "${DIR}/solidblocks-shell/lib/log.sh"

VERSION="${GITHUB_REF_NAME:-snapshot}"

COMPONENTS="solidblocks-terraform solidblocks-hetzner-nuke solidblocks-shell solidblocks-cloud-init solidblocks-hetzner solidblocks-debug-container solidblocks-sshd solidblocks-minio solidblocks-rds-postgresql"

function ensure_environment {
  software_set_export_path
}

function task_build {
    for component in ${COMPONENTS}; do
      (
        cd "${DIR}/${component}"
        VERSION=${VERSION} "./do" build
      )
    done

    task_build_documentation
}

function task_clean_aws {
  docker run \
    --rm \
    -v $(pwd)/contrib/aws-nuke.yaml:/home/aws-nuke/config.yml \
    quay.io/rebuy/aws-nuke:v2.22.1 \
    --access-key-id "$(pass solidblocks/aws/admin/access_key)" \
    --secret-access-key "$(pass solidblocks/aws/admin/secret_access_key)" \
    --config /home/aws-nuke/config.yml \
    --no-dry-run \
    --force

}

function task_clean_hetzner {
  export HCLOUD_TOKEN="${HCLOUD_TOKEN:-$(pass solidblocks/hetzner/hcloud_api_token)}"

  docker run \
    --rm \
    -e HCLOUD_TOKEN="${HCLOUD_TOKEN}" \
    --pull always \
    ghcr.io/pellepelster/solidblocks-hetzner-nuke:v0.1.16 nuke
}

function task_clean {
    task_clean_aws
    task_clean_hetzner

    rm -rf "${DIR}/build"
    rm -rf "${DIR}/doc/generated"
    rm -rf "${DIR}/doc/snippets"

    for component in ${COMPONENTS}; do
        (
          cd "${DIR}/${component}"
          "./do" clean
        )
    done
}

function task_test {
    if [[ "${SKIP_TESTS:-}" == "true" ]]; then
      exit 0
    fi

    for component in ${COMPONENTS}; do
      (
        cd "${DIR}/${component}"
        VERSION=${VERSION} "./do" test
      )
    done
}

function task_format {
    for component in ${COMPONENTS}; do
      (
        cd "${DIR}/${component}"
        VERSION=${VERSION} "./do" format
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

function prepare_documentation_env {
  local versions="$(grep  'VERSION=\".*\"' "${DIR}/solidblocks-shell/lib/software.sh")"
  for version in ${versions}; do
    eval "export ${version}"
  done
  export SOLIDBLOCKS_VERSION="${VERSION}"
}

function task_build_documentation {
    ensure_environment

    rm -rf "${DIR}/doc/snippets"
    mkdir -p "${DIR}/doc/snippets"

    if [[ -n "${CI:-}" ]]; then
      rsync -rv --exclude=".terraform" --exclude="*.tfstate*" --exclude=".terraform.lock.hcl" ${DIR}/*/snippets/* "${DIR}/doc/snippets"
    else
      rsync -rv --exclude=".terraform" --exclude="*.tfstate*" --exclude=".terraform.lock.hcl" ${DIR}/*/snippets/* "${DIR}/doc/snippets"
      rsync -rv --exclude=".terraform" --exclude="*.tfstate*" --exclude=".terraform.lock.hcl" ${DIR}/*/build/snippets/* "${DIR}/doc/snippets"
    fi

    export VERSION="$(semver get release)"
    mkdir -p "${DIR}/build/documentation"
    (
      cd "${DIR}/build/documentation"
      cp -r ${DIR}/doc/* ./
      prepare_documentation_env
      hugo
    )
}

function task_serve_documentation {
    ensure_environment
    (
      cd "${DIR}/doc"

      prepare_documentation_env
      hugo serve --baseURL "/"
    )
}

function task_bootstrap() {
  git submodule update --init --recursive
  software_ensure_shellcheck
  software_ensure_hugo
  software_ensure_semver
}

function task_release_check() {
  local previous_tag="$(git --no-pager tag | sed '/-/!{s/$/_/}' | sort -V | sed 's/_$//' | tail -1)"
  local previous_version="${previous_tag#v}"
  local version="$(semver get release)"

  task_build
  task_build_documentation

  echo "checking for previous version '${previous_version}'"

  if git --no-pager grep "${previous_version}" | grep -v CHANGELOG.md | grep -v README.md; then
    echo "previous version '${previous_version}' found in repository"
    exit 1
  fi

  echo "checking changelog for current version '${version}'"
  if ! grep "${version}" "${DIR}/CHANGELOG.md"; then
    echo "version '${version}' not found in changelog"
    exit 1
  fi

  if [[ $(git diff --stat) != '' ]]; then
    echo "repository '${DIR}' is dirty"
    exit 1
  fi
}

function task_release {

  # ensure terraform-docs is available
  terraform-docs --version

  if [[ ! -f ".semver.yaml" ]]; then
    semver init --release v0.0.1
  fi

  task_release_check

  local version="$(semver get release)"
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

case "${ARG}" in
  bootstrap) ;;
  *) ensure_environment ;;
esac

case ${ARG} in
  build) task_build "$@" ;;
  clean) task_clean "$@" ;;
  clean-aws) task_clean_aws "$@" ;;
  clean-hetzner) task_clean_hetzner "$@" ;;
  clean-cloud-resources) task_clean_hetzner && task_clean_aws "$@" ;;
  test) task_test "$@" ;;
  format) task_format "$@" ;;
  build-documentation) task_build_documentation "$@" ;;
  serve-documentation) task_serve_documentation "$@" ;;
  release) task_release "$@" ;;
  release-docker) task_release_docker "$@" ;;
  release-check) task_release_check "$@" ;;
  bootstrap) task_bootstrap "$@" ;;
  *) task_usage ;;
esac