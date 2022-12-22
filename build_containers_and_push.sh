#!/bin/bash

set -e

for spackver in "v0.19.0" ; do
    for baseimg in docker.io/ubuntu:22.04 ; do
        SPACK_DOCKER_TAG=$(echo $spackver | sed -e 's/^v//')
        OS_DOCKER_TAG=$(basename "$baseimg" | sed -e 's/://')
        DOCKER_TAG=finkandreas/spack:${SPACK_DOCKER_TAG}-${OS_DOCKER_TAG}
        BASE_RETAG_NAME=finkandreas/spack:base-${OS_DOCKER_TAG}
        docker build -f docker/Dockerfile_spack_baseimage_${OS_DOCKER_TAG}_cpu --build-arg BASEIMG=$baseimg --build-arg SPACK_VER=$spackver -t ${DOCKER_TAG} .
        docker tag $baseimg "$BASE_RETAG_NAME"
        docker push "${BASE_RETAG_NAME}"
        docker push "${DOCKER_TAG}"

        # do the same for cuda base images
        for cudaver in "11.7.1" ; do
            cuda_baseimg=docker.io/nvidia/cuda:${cudaver}-devel-${OS_DOCKER_TAG}
            cuda_rtimg=docker.io/nvidia/cuda:${cudaver}-runtime-${OS_DOCKER_TAG}
            CUDA_BASE_RETAG_NAME=finkandreas/spack:base-cuda${cudaver}-${OS_DOCKER_TAG}
            CUDA_DOCKER_TAG=finkandreas/spack:${SPACK_DOCKER_TAG}-cuda${cudaver}-${OS_DOCKER_TAG}
            docker build -f docker/Dockerfile_spack_baseimage_${OS_DOCKER_TAG}_gpu --build-arg BASEIMG=$cuda_baseimg --build-arg SPACK_VER=$spackver -t ${CUDA_DOCKER_TAG} .
            docker pull $cuda_rtimg
            docker tag $cuda_rtimg $CUDA_BASE_RETAG_NAME
            docker push $CUDA_BASE_RETAG_NAME
            docker push $CUDA_DOCKER_TAG
        done
    done
done

