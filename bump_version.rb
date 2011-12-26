#!/usr/bin/env ruby

# The script accepts 2 parameters, the old version and the new version
# bump_version.rb 0.8.1 0.8.2
# It bumps version and then creates tags fuse4x_X_X_X in submodules.

ARGV.length == 1 or abort('Exactly 1 parameter (version) expected')
new_version = ARGV[0]
new_version =~ /^\d+\.\d+(\.\d+)?$/ or abort("Argument (#{new_version}) does not look like a valid version")

# Get the old version from build.rb
File.read('build.rb') =~ /^FUSE4X_VERSION = '(\d+\.\d+(\.\d+)?)'$/
old_version = $1

# sshfs has a separate release cycle
SUBMODULES = %w(fuse4x kext fuse framework support fuse4x.github.com)


for project in SUBMODULES do
  system("cd ../#{project} && git diff --exit-code HEAD") or abort("Project #{project} contains local changes")
end

# Bump version
versions = [
  ['fuse/include/fuse_version.h', "^#define FUSE4X_VERSION_LITERAL #{old_version}$", 1],
  ['kext/common/fuse_version.h', "^#define FUSE4X_VERSION_LITERAL #{old_version}$", 1],
  ['fuse4x/build.rb', "^FUSE4X_VERSION = '#{old_version}'$", 1],
  ['fuse4x/Info.plist', "<string>#{old_version}</string>", 1],
  ['kext/kext-Info.plist', "<string>#{old_version}</string>", 2],
  ['support/fuse4x.fs-Info.plist', "<string>#{old_version}</string>", 1]
]

for pair in versions do
  filename,regexp,required_count = *pair
  filename = '../' + filename

  count = 0
  text = File.read(filename)
  text.gsub!(Regexp.new(regexp)) {|match|
    count = count + 1
    match.sub(old_version, new_version)
  }

  if count != required_count then
    puts "In file #{filename}, string '#{regexp}' should be matched #{required_count} times but #{count} contained"
  end

  File.open(filename, "w") {|file| file.puts text}
end


tagname = 'fuse4x_' + new_version.gsub('.', '_')
for project in SUBMODULES do
  `cd ../#{project}; git commit -am "Bump version from #{old_version} to #{new_version}"; git tag #{tagname}`
end
