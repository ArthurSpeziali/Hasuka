module Version.Config where

shortVersion = "0.8"
version = "0.8.2"
package = "jhc"
libdir  = "/home/bruns/.local/lib"
datadir = "/home/bruns/.local/share"
host    = "x86_64-unknown-linux-gnu"
libraryInstall = "/home/bruns/.local/share/jhc-0.8"
confDir = "/home/bruns/.local/etc/jhc-0.8"

ho_version, version_major, version_minor, version_patch :: Int
ho_version = 14
version_major = 0
version_minor = 8
version_patch = 2
revision = show $ (version_major*100 + version_minor :: Int)*100 + version_patch
