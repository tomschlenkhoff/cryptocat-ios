# --------------------------------------------------------------------------------------------------
# --- config

# -- binary paths
PLIST_BUDDY_BIN_PATH = "/usr/libexec/PlistBuddy"
GIT_BIN_PATH = "/usr/local/git/bin/git"

# --------------------------------------------------------------------------------------------------
# --- helper methods

# -- helper methods to write/read into a plist
def write_into_plist_with_key_value(plist_path, key, value)
  `#{PLIST_BUDDY_BIN_PATH} -c "Add :#{key} string" #{plist_path}`
  `#{PLIST_BUDDY_BIN_PATH} -c "Set :#{key} #{value}" #{plist_path}`
end

def read_key_from_plist_path(plist_path, key)
  return `#{PLIST_BUDDY_BIN_PATH} -c "Print :#{key}" #{plist_path}`.chomp
end

def escape_filepath(path)
  return path.gsub(" ", "\\ ").gsub("(", "\\(").gsub(")", "\\)")
end

# --------------------------------------------------------------------------------------------------
# --- actual script

# -- build the git commands
git_sha_cmd = "#{GIT_BIN_PATH} rev-parse --short HEAD"
git_tag_cmd = "#{GIT_BIN_PATH} describe --tags --abbrev=0"

# -- get the sha of the current commit and the latest git tag
latest_sha             = `#{git_sha_cmd}`.chomp
latest_tag             = `#{git_tag_cmd}`.chomp
latest_tag_clean       =  latest_tag.gsub(/\.|a/, "").chomp

# -- get built product paths
app_name = "#{ENV['FULL_PRODUCT_NAME']}"
dsym_name = "#{ENV['DWARF_DSYM_FILE_NAME']}"
plist_path = escape_filepath("#{ENV['BUILT_PRODUCTS_DIR']}/#{ENV['INFOPLIST_PATH']}")
settings_plist_path = escape_filepath("#{ENV['BUILT_PRODUCTS_DIR']}/#{app_name}/Settings.bundle/Root.plist")
dsym_plist_path = escape_filepath("#{ENV['BUILT_PRODUCTS_DIR']}/#{dsym_name}/Contents/Info.plist")
puts "App plist path : #{plist_path}"
puts "Settings plist path : #{settings_plist_path}"
puts "Dsym plist path : #{dsym_plist_path}"

# -- write the new versions in app plist
write_into_plist_with_key_value(plist_path, "CFBundleVersion", latest_tag_clean)
write_into_plist_with_key_value(plist_path, "CFBundleShortVersionString", latest_tag)
write_into_plist_with_key_value(plist_path, "TBBundleGitCommitSHA", latest_sha)

# -- write the new versions in the Settings.bundle plist
# -- App is at index 1 (2nd element in the plist)
write_into_plist_with_key_value(settings_plist_path, "PreferenceSpecifiers:1:DefaultValue", "#{latest_tag} (#{latest_sha})")

# -- write versions in dsym plist
write_into_plist_with_key_value(dsym_plist_path, "CFBundleVersion", latest_tag_clean)
write_into_plist_with_key_value(dsym_plist_path, "CFBundleShortVersionString", latest_tag)

# -- logging
puts "Bumped to #{latest_tag} (#{latest_tag_clean} | #{latest_sha}) into #{plist_path}"
puts "--"
puts "Plist now reads :"
puts " - CFBundleShortVersionString : #{read_key_from_plist_path(plist_path, 'CFBundleShortVersionString')}"
puts " - CFBundleVersion : #{read_key_from_plist_path(plist_path, 'CFBundleVersion')}"
puts " - TBBundleGitCommitSHA : #{read_key_from_plist_path(plist_path, 'TBBundleGitCommitSHA')}"
