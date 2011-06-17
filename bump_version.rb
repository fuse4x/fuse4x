#!/usr/bin/env ruby

# The script accepts 2 parameters, the old version and the new version
# bump_version.rb 0.8.1 0.8.2
# It creates tags fuse4x_X_X_X in the current submodules, and then bumps versions
# in the sourcecode plus creates git commits for it.

FUSE4X_VERSION = '(\d+\.\d+\.\d+)'
VERSION_REGEXP = Regexp.new("^#{FUSE4X_VERSION}$")

ARGV.length == 2 or abort('Exactly 2 parameters expected')
old_version,new_version = *ARGV
old_version =~ VERSION_REGEXP or abort("Fisrt argument (#{old_version}) does not look like a valid version")
new_version =~ VERSION_REGEXP or abort("Second argument (#{new_version}) does not look like a valid version")

# sshfs has a separate release cycle
SUBMODULES = %w(fuse4x kext fuse framework support fuse4x.github.com)

# Fisrt tag all modules
tagname = 'fuse4x_' + ARGV[0].gsub('.', '_')
for project in SUBMODULES do
  system("cd ../#{project} && git diff --exit-code HEAD") or abort("Project #{project} contains local changes")
  `cd ../#{project} && git tag #{tagname}`
end

versions = [
  ['fuse/include/fuse_version.h', "^#define FUSE4X_VERSION_LITERAL #{old_version}$", 1],
  ['kext/common/fuse_version.h', "^#define FUSE4X_VERSION_LITERAL #{old_version}$", 1],
  ['fuse4x/build.rb', "^FUSE4X_VERSION = '#{old_version}'$", 1],
  ['fuse4x/fuse4x.pmdoc/01root.xml', "<version>#{old_version}</version>", 1],
  ['fuse4x/fuse4x.pmdoc/01root.xml', "version=\"#{old_version}\"", 2],
  ['kext/kext-Info.plist', "<string>#{old_version}</string>", 2],
  ['support/fuse4x.fs-Info.plist', "<string>#{old_version}</string>", 1]
]

for pair in versions do
  filename,regexp,count = *pair
  filename = '../' + filename

  text = File.read(filename)
  text.gsub!(Regexp.new(regexp)) {|match|
    count = count - 1
    match.sub(old_version, new_version)
  }

  puts "In file #{filename}, string '#{regexp}' should be matched #{count} more times" if (count > 0)

  File.open(filename, "w") {|file| file.puts text}
end


for project in SUBMODULES do
  `cd ../#{project} && git commit -am "Bump version from #{old_version} to #{new_version}"`
end
