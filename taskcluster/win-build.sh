#!/bin/bash

set -xe

package_option=$1

source $(dirname "$0")/tc-tests-utils.sh

source ${DS_ROOT_TASK}/DeepSpeech/tf/tc-vars.sh

BAZEL_TARGETS="
//native_client:libdeepspeech.so
"

if [ "${package_option}" = "--cuda" ]; then
    BAZEL_ENV_FLAGS="TF_NEED_CUDA=1 ${TF_CUDA_FLAGS}"
    BAZEL_BUILD_FLAGS="${BAZEL_CUDA_FLAGS} ${BAZEL_EXTRA_FLAGS} ${BAZEL_OPT_FLAGS}"
    PROJECT_NAME="DeepSpeech-GPU"
elif [ "${package_option}" = "--tflite" ]; then
    PROJECT_NAME="DeepSpeech-TFLite"
    BAZEL_BUILD_FLAGS="--define=runtime=tflite ${BAZEL_OPT_FLAGS} ${BAZEL_EXTRA_FLAGS}"
    BAZEL_ENV_FLAGS="TF_NEED_CUDA=0"
else
    PROJECT_NAME="DeepSpeech"
    BAZEL_BUILD_FLAGS="${BAZEL_OPT_FLAGS} ${BAZEL_EXTRA_FLAGS}"
    BAZEL_ENV_FLAGS="TF_NEED_CUDA=0"
fi

SYSTEM_TARGET=host-win

do_bazel_build

if [ "${package_option}" = "--cuda" ]; then
    cp ${DS_ROOT_TASK}/DeepSpeech/tf/bazel-bin/native_client/liblibdeepspeech.so.ifso ${DS_ROOT_TASK}/DeepSpeech/tf/bazel-bin/native_client/libdeepspeech.so.if.lib
fi

export PATH=$PATH:$(cygpath ${ChocolateyInstall})/bin:'/c/Program Files/nodejs/'

do_deepspeech_binary_build

# Those are the versions available on NuGet.org
export SUPPORTED_PYTHON_VERSIONS="3.5.4 3.6.8 3.7.6 3.8.1"
if [ "${runtime}" = "tflite" ]; then
  do_deepspeech_python_build "--tflite"
else
  do_deepspeech_python_build "${package_option}"
fi

do_deepspeech_nodejs_build "${package_option}"

do_deepspeech_netframework_build

do_deepspeech_netframework_wpf_example_build

do_nuget_build "${PROJECT_NAME}"

shutdown_bazel
