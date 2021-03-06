# Copyright 2017 Google Inc. All rights reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
"""A rule for creating a Go Docker image.

The signature of this rule is compatible with go_binary.
"""

load(
    "//docker/contrib/common:lang-image.bzl",
    "dep_layer",
    "app_layer",
)
load("//docker:pull.bzl", "docker_pull")

# It is expected that the Go rules have been properly
# initialized before loading this file to initialize
# go_image.
load("@io_bazel_rules_go//go:def.bzl", "go_binary")

def repositories():
  excludes = native.existing_rules().keys()
  if "go_image_base" not in excludes:
    docker_pull(
      name = "go_image_base",
      registry = "gcr.io",
      repository = "distroless/base",
      # 'latest' circa 2017-07-21
      digest = "sha256:06fcd3edcfeefe13b82fa8bdb9e3f4fa3bf4c7e8fe997bee0230e392f77d0e04",
    )

def go_image(name, base=None, deps=[], layers=[], **kwargs):
  """Constructs a Docker image wrapping a go_binary target.

  Args:
    layers: Augments "deps" with dependencies that should be put into their own layers.
    **kwargs: See go_binary.
  """
  binary_name = name + ".binary"

  if layers:
    print("go_image does not benefit from layers=[], got: %s" % layers)

  go_binary(name=binary_name, deps=deps + layers, **kwargs)

  index = 0
  base = base or "@go_image_base//image"
  for dep in layers:
    this_name = "%s.%d" % (name, index)
    dep_layer(name=this_name, base=base, dep=dep)
    base = this_name
    index += 1

  app_layer(name=name, base=base, binary=binary_name, layers=layers)
