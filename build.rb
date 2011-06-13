#!/usr/bin/env ruby
# This script is intended to build installable distribution of Fuse4X
# Possible flags are:
#   --debug       this builds distribuition with debug flags enabled
#
# The final distribuition you can find in ./build

SUBMODULES = %w(kext fuse sshfs framework support)
CWD = File.dirname(__FILE__)

debug = ARGV.include?('--debug')

build_dir = File.join(CWD, 'build')
root_dir = File.expand_path(File.join(build_dir, 'root'))
`sudo rm -rf #{build_dir} && mkdir -p #{root_dir}`

for project in SUBMODULES do
  script = File.join(CWD, '..', project, 'build.rb')
  abort("Module #{project} is not checked out") unless File.exists?(script)

  cmd = "#{script} --root #{root_dir}"
  cmd += ' --debug' if debug
  puts "Running '#{cmd}'"
  system(cmd) or abort("Cannot run script in #{project}")
  puts "\n\n"
end

# fix permissions
system('sudo chown -R root:wheel build/root/')

system('/Developer/Applications/Utilities/PackageMaker.app/Contents/MacOS/PackageMaker --doc fuse4x.pmdoc --out build/Fuse4X.pkg') or abort('Cannot create install package')
