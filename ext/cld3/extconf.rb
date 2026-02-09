# Copyright 2017 Akihiko Odaki <akihiko.odaki@gmail.com>
# All Rights Reserved.
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
#==============================================================================

require "mkmf"

def ln_fallback(source, destination)
  FileUtils.ln(source, destination)
rescue
  begin
    FileUtils.ln_s(source, destination)
  rescue
    FileUtils.cp(source, destination)
  end
end

FileUtils.mkdir_p("script_span")

[
  "fixunicodevalue.h",
  "generated_ulscript.h",
  "getonescriptspan.h",
  "integral_types.h",
  "offsetmap.h",
  "port.h",
  "stringpiece.h",
  "text_processing.h",
  "utf8acceptinterchange.h",
  "utf8prop_lettermarkscriptnum.h",
  "utf8repl_lettermarklower.h",
  "utf8scannot_lettermarkspecial.h",
  "utf8statetable.h"
].each {|name|
  ln_fallback("#{name}", "script_span/#{name}")
}

# Check if we're building from git (source files in ext/src subdirectory)
# or from a prepared gem package (files in current directory)
if File.exist?("ext/src/nnet_language_identifier.h")
  # Building from git - add include path and copy/link source files
  $INCFLAGS << " -I$(srcdir)/ext/src"
  $INCFLAGS << " -I$(srcdir)/cld_3/protos"
  
  # List of source files from ext/src that need to be compiled
  source_files = [
    "base.cc",
    "embedding_feature_extractor.cc",
    "embedding_network.cc",
    "feature_extractor.cc",
    "feature_types.cc",
    "fml_parser.cc",
    "language_identifier_features.cc",
    "lang_id_nn_params.cc",
    "nnet_language_identifier.cc",
    "registry.cc",
    "relevant_script_feature.cc",
    "sentence_features.cc",
    "task_context.cc",
    "task_context_params.cc",
    "unicodetext.cc",
    "utils.cc",
    "workspace.cc",
    "script_span/fixunicodevalue.cc",
    "script_span/generated_entities.cc",
    "script_span/generated_ulscript.cc",
    "script_span/getonescriptspan.cc",
    "script_span/offsetmap.cc",
    "script_span/text_processing.cc",
    "script_span/utf8statetable.cc"
  ]
  
  # Create symlinks or copies for source files
  source_files.each do |file|
    target = File.basename(file)
    source = File.join("ext/src", file)
    ln_fallback(source, target) unless File.exist?(target)
  end
  
  # Add source files to the build
  $srcs = ["nnet_language_identifier_c.cc"] + source_files.map { |f| File.basename(f) }
  $objs = $srcs.map { |f| f.sub(/\.cc$/, ".o") }
end

$CXXFLAGS += " -fvisibility=hidden -std=c++17"
create_makefile("cld3_ext")
