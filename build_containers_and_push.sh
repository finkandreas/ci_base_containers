#!/bin/bash

set -e

function echo_run() {
    echo "$@"
    "$@"
}

for spackver in "v0.18.1" "v0.19.0" ; do
    for baseimg in docker.io/ubuntu:22.04 ; do
        SPACK_DOCKER_TAG=$(echo $spackver | sed -e 's/^v//')
        OS_DOCKER_TAG=$(basename "$baseimg" | sed -e 's/://')
        DOCKER_TAG=finkandreas/spack:${SPACK_DOCKER_TAG}-${OS_DOCKER_TAG}
        BASE_TAG_NAME=finkandreas/spack:base-${OS_DOCKER_TAG}
        echo_run podman build -f docker/Dockerfile_spack_baseimage_${OS_DOCKER_TAG} --format docker --build-arg BASEIMG=$baseimg --build-arg SPACK_VER=$spackver -t ${DOCKER_TAG} .
        echo_run podman build -f docker/Dockerfile_base_helper --format docker --build-arg BASEIMG=$baseimg -t ${BASE_TAG_NAME} .
        echo_run podman push "${BASE_TAG_NAME}"
        echo_run podman push "${DOCKER_TAG}"

        # do the same for cuda base images
        for cudaver in "11.7.1" ; do
            cuda_baseimg=docker.io/nvidia/cuda:${cudaver}-devel-${OS_DOCKER_TAG}
            CUDA_BASE_TAG_NAME=finkandreas/spack:base-cuda${cudaver}-${OS_DOCKER_TAG}
            CUDA_DOCKER_TAG=finkandreas/spack:${SPACK_DOCKER_TAG}-cuda${cudaver}-${OS_DOCKER_TAG}
            echo_run podman build -f docker/Dockerfile_spack_baseimage_${OS_DOCKER_TAG} --format docker --build-arg BASEIMG=$cuda_baseimg --build-arg SPACK_VER=$spackver -t ${CUDA_DOCKER_TAG} .
            echo_run podman build -f docker/Dockerfile_base_helper --format docker --build-arg BASEIMG=$cuda_baseimg -t ${CUDA_BASE_TAG_NAME} .
            echo_run podman push $CUDA_BASE_TAG_NAME
            echo_run podman push $CUDA_DOCKER_TAG
        done
    done
done

