#!/usr/bin/env ruby
# This script is intended to build installable distribution of Fuse4X
# Possible flags are:
#   --debug       this builds distribuition with debug flags enabled
#
# The final distribuition you can find in ./build/

SUBMODULES = %w(kext fuse framework support)
CWD = File.dirname(__FILE__)
FUSE4X_VERSION = '0.8.12'
SSHFS_VERSION = '2.3.0' # first two numbers - is the upstream version, third - fuse4x revision

debug = ARGV.include?('--debug')

build_dir = File.join(CWD, 'build')
root_dir = File.expand_path(File.join(build_dir, 'root'))
`sudo rm -rf #{build_dir} && mkdir -p #{root_dir}`

for project in SUBMODULES do
  script = File.join(CWD, '..', project, 'build.rb')
  abort("Module #{project} is not checked out") unless File.exists?(script)

  # remove subproject working directory
  system("rm -rf ../#{project}/build")

  cmd = "#{script} --root #{root_dir} --clean"
  cmd += ' --debug' if debug
  puts "Running '#{cmd}'"
  system(cmd) or abort("Cannot run script in #{project}")
  puts "\n\n"
end

# fix permissions
system('sudo chown -R root:wheel build/root/')

system("/Developer/Applications/Utilities/PackageMaker.app/Contents/MacOS/PackageMaker -m --doc fuse4x.pmdoc --out build/Fuse4X-#{FUSE4X_VERSION}.pkg") or abort('Cannot create install package')



##### BUILD SSHFS ##########
sshfs_dir = File.expand_path(File.join(build_dir, 'sshfs'))
`mkdir -p #{sshfs_dir}`
cmd = "../sshfs/build.rb --root #{sshfs_dir} --clean --static"
cmd += ' --debug' if debug
system(cmd) or abort("Cannot run script in sshfs")
system('sudo chown -R root:wheel build/sshfs/')
system("cd build/sshfs && zip -rq ../sshfs-#{SSHFS_VERSION}.zip .")
