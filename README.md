# parse-submodules
A simple shell utility to parse Git submodule paths and URLs given only the superproject location

## Usage
```bash
$ ./parse_submodules.sh -h
parse-submodules.sh version 0.0.1

Copyright (c) 2021 Konstantin Gizdov

Usage: ./parse-submodules.sh [options] <GIT REPO REMOTE URL> [<GIT REF>]

note: This is work in progress.

    A utility to parse and print out useful information about
    a Git repository's submodule paths and URLs.

helper options:
    -v  verbose mode

    -h  print this help message and exit

```

## Example
```bash
$ ./parse-submodules.sh https://github.com/pytorch/pytorch.git v1.7.1
# Your sources array should look something like:
sources=(
  "${pkgname}::https://github.com/pytorch/pytorch.git#[commit/tag]=v1.7.1"
  https://github.com/seemethere/pybind11.git
  https://github.com/NVlabs/cub.git
  https://github.com/eigenteam/eigen-git-mirror.git
  https://github.com/google/googletest.git
  https://github.com/google/benchmark.git
  https://github.com/protocolbuffers/protobuf.git
  https://github.com/Yangqing/ios-cmake.git
  https://github.com/Maratyszcza/NNPACK.git
  https://github.com/facebookincubator/gloo
  https://github.com/Maratyszcza/pthreadpool.git
  https://github.com/Maratyszcza/FXdiv.git
  https://github.com/Maratyszcza/FP16.git
  https://github.com/Maratyszcza/psimd.git
  https://github.com/facebook/zstd.git
  https://github.com/pytorch/cpuinfo.git
  https://github.com/PeachPy/enum34.git
  https://github.com/Maratyszcza/PeachPy.git
  https://github.com/benjaminp/six.git
  https://github.com/onnx/onnx.git
  https://github.com/onnx/onnx-tensorrt
  https://github.com/shibatch/sleef
  https://github.com/intel/ideep
  https://github.com/NVIDIA/nccl
  https://github.com/google/gemmlowp.git
  https://github.com/pytorch/QNNPACK
  https://github.com/intel/ARM_NEON_2_x86_SSE.git
  https://github.com/pytorch/fbgemm
  https://github.com/houseroad/foxi.git
  https://github.com/01org/tbb
  https://github.com/facebookincubator/fbjni.git
  https://github.com/google/XNNPACK.git
  https://github.com/fmtlib/fmt.git
  https://github.com/pytorch/tensorpipe.git
)
# Put the following in your PKGBUILD prepare function:
prepare() {
  cd "${srcdir}/${pkgname}"
  git submodule init

  git config submodule."third_party/pybind11".url "${srcdir}"/pybind11
  git config submodule."third_party/cub".url "${srcdir}"/cub
  git config submodule."third_party/eigen".url "${srcdir}"/eigen-git-mirror
  git config submodule."third_party/googletest".url "${srcdir}"/googletest
  git config submodule."third_party/benchmark".url "${srcdir}"/benchmark
  git config submodule."third_party/protobuf".url "${srcdir}"/protobuf
  git config submodule."third_party/ios-cmake".url "${srcdir}"/ios-cmake
  git config submodule."third_party/NNPACK".url "${srcdir}"/NNPACK
  git config submodule."third_party/gloo".url "${srcdir}"/gloo
  git config submodule."third_party/NNPACK_deps/pthreadpool".url "${srcdir}"/pthreadpool
  git config submodule."third_party/NNPACK_deps/FXdiv".url "${srcdir}"/FXdiv
  git config submodule."third_party/NNPACK_deps/FP16".url "${srcdir}"/FP16
  git config submodule."third_party/NNPACK_deps/psimd".url "${srcdir}"/psimd
  git config submodule."third_party/zstd".url "${srcdir}"/zstd
  git config submodule."third-party/cpuinfo".url "${srcdir}"/cpuinfo
  git config submodule."third_party/python-enum".url "${srcdir}"/enum34
  git config submodule."third_party/python-peachpy".url "${srcdir}"/PeachPy
  git config submodule."third_party/python-six".url "${srcdir}"/six
  git config submodule."third_party/onnx".url "${srcdir}"/onnx
  git config submodule."third_party/onnx-tensorrt".url "${srcdir}"/onnx-tensorrt
  git config submodule."third_party/sleef".url "${srcdir}"/sleef
  git config submodule."third_party/ideep".url "${srcdir}"/ideep
  git config submodule."third_party/nccl/nccl".url "${srcdir}"/nccl
  git config submodule."third_party/gemmlowp/gemmlowp".url "${srcdir}"/gemmlowp
  git config submodule."third_party/QNNPACK".url "${srcdir}"/QNNPACK
  git config submodule."third_party/neon2sse".url "${srcdir}"/ARM_NEON_2_x86_SSE
  git config submodule."third_party/fbgemm".url "${srcdir}"/fbgemm
  git config submodule."third_party/foxi".url "${srcdir}"/foxi
  git config submodule."third_party/tbb".url "${srcdir}"/tbb
  git config submodule."android/libs/fbjni".url "${srcdir}"/fbjni
  git config submodule."third_party/XNNPACK".url "${srcdir}"/XNNPACK
  git config submodule."third_party/fmt".url "${srcdir}"/fmt
  git config submodule."third_party/tensorpipe".url "${srcdir}"/tensorpipe
  git submodule update --recursive
}
```