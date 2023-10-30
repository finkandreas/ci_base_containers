#!/bin/bash

set -e

function echo_run() {
    echo "$@"
    "$@"
}

for spackver in "v0.19.2" "v0.20.2" ; do
    for baseimg in docker.io/ubuntu:22.04 ; do
        SPACK_DOCKER_TAG=$(echo $spackver | sed -e 's/^v//')
        OS_DOCKER_TAG=$(basename "$baseimg" | sed -e 's/://')
        DOCKER_TAG=finkandreas/spack:${SPACK_DOCKER_TAG}-${OS_DOCKER_TAG}
        BASE_TAG_NAME=finkandreas/spack:base-${OS_DOCKER_TAG}
        echo_run podman build -f docker/Dockerfile_spack_baseimage_${OS_DOCKER_TAG} --format docker --pull --build-arg BASEIMG=$baseimg --build-arg SPACK_VER=$spackver -t ${DOCKER_TAG} .
        echo_run podman build -f docker/Dockerfile_base_helper --format docker --pull --build-arg BASEIMG=$baseimg -t ${BASE_TAG_NAME} .
        echo_run podman push "${BASE_TAG_NAME}"
        echo_run podman push "${DOCKER_TAG}"

        # do the same for cuda base images
        for cudaver in "11.7.1" ; do
            cuda_baseimg=docker.io/nvidia/cuda:${cudaver}-devel-${OS_DOCKER_TAG}
            CUDA_BASE_TAG_NAME=finkandreas/spack:base-cuda${cudaver}-${OS_DOCKER_TAG}
            CUDA_DOCKER_TAG=finkandreas/spack:${SPACK_DOCKER_TAG}-cuda${cudaver}-${OS_DOCKER_TAG}
            echo_run podman build -f docker/Dockerfile_spack_baseimage_${OS_DOCKER_TAG} --format docker --pull --build-arg BASEIMG=$cuda_baseimg --build-arg SPACK_VER=$spackver -t ${CUDA_DOCKER_TAG} .
            echo_run podman build -f docker/Dockerfile_base_helper --format docker --pull --build-arg BASEIMG=$cuda_baseimg -t ${CUDA_BASE_TAG_NAME} .
            echo_run podman push $CUDA_BASE_TAG_NAME
            echo_run podman push $CUDA_DOCKER_TAG
        done

        # and for rocm base images
        for rocmver in "5.2.3" ; do #TODO "5.2.4"
            #rocm_baseimg=docker.io/rocm/dev-ubuntu-22.04:${rocmver}-devel-${OS_DOCKER_TAG}
            rocm_baseimg=docker.io/rocm/dev-ubuntu-22.04:${rocmver}-complete
            ROCM_BASE_TAG_NAME=finkandreas/spack:base-rocm${rocmver}-${OS_DOCKER_TAG}
            ROCM_DOCKER_TAG=finkandreas/spack:${SPACK_DOCKER_TAG}-rocm${rocmver}-${OS_DOCKER_TAG}
            echo_run podman build -f docker/Dockerfile_spack_baseimage_${OS_DOCKER_TAG} --format docker --build-arg BASEIMG=$rocm_baseimg --build-arg SPACK_VER=$spackver -t ${ROCM_DOCKER_TAG} .
            echo_run podman build -f docker/Dockerfile_base_helper --format docker --build-arg BASEIMG=$rocm_baseimg -t ${ROCM_BASE_TAG_NAME} .
            echo_run podman push $ROCM_BASE_TAG_NAME
            echo_run podman push $ROCM_DOCKER_TAG
        done
    done
done

