Software can be installed with the help of the helper script. A typical `Dockerfile` would be:

```Dockerfile
FROM docker.io/finkandreas/spack:0.19.1-ubuntu22.04 as builder

ARG NUM_PROCS

RUN spack-install-helper \
    daint-mc \
    "trilinos@13.4.0 cxxstd=17 +amesos2 +belos ~epetra +intrepid2 +mumps +openmp +suite-sparse +superlu-dist +shards +nox" \
    "petsc +hypre ~complex +mumps +openmp +suite-sparse +superlu-dist" \
    "slepc ~arpack" \
    "hypre" \
    "cmake" \
    "py-numpy" \
    "swig" \
    "git" \
    "yaml-cpp" \
    "openblas" \
    "suite-sparse@5.13.0"

# end of builder container, now we are ready to copy necessary files

# copy only relevant parts to the final container
FROM docker.io/finkandreas/spack:base-ubuntu22.04

# it is important to keep the paths, otherwise your installation is broken
# all these paths are created with the above `spack-install-helper` invocation
COPY --from=builder /opt/spack-environment /opt/spack-environment
COPY --from=builder /opt/software /opt/software
COPY --from=builder /opt/._view /opt/._view
COPY --from=builder /etc/profile.d/z10_spack_environment.sh /etc/profile.d/z10_spack_environment.sh

# Some boilerplate to get all paths correctly - fix_spack_install is part of the base image
# and makes sure that all important things are being correctly setup
RUN fix_spack_install

# Finally install software that is needed, e.g. compilers
# It is also possible to build compilers via spack and let all dependencies be handled by spack
RUN apt-get -yqq update && apt-get -yqq upgrade \
 && apt-get -yqq install build-essential gfortran \
 && rm -rf /var/lib/apt/lists/*
```
