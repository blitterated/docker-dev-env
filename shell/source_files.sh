# Quick and dirty logging function for source_files below
function log_ts {
  echo "$(date +'%Y-%m-%d %T'): $1"
}

# The source_files function will source shell configuration script files
# found in a given directory in sorted order.
function source_files {

  # Bail out if no directory argument given
  if [ "$#" -lt 1 ]; then log_ts "No directory supplied"; return 1; fi

  SOURCE_DIR=$1

  # Check for existence of argument
  if [ -e "${SOURCE_DIR}" ]; then
    log_ts "'${SOURCE_DIR}' exists"
  else
    log_ts "'${SOURCE_DIR}' does not exist"
    return 0
  fi

  # Check that it's a directory
  if [ -d "${SOURCE_DIR}" ]; then
    log_ts "'${SOURCE_DIR}' is a directory"
  else
    log_ts "'${SOURCE_DIR}' is not a directory"
    return 0
  fi

  # Get a list of all files in the directory.
  SOURCE_FILES=$(ls -q1A $SOURCE_DIR | sort)

  # Check if the directory is empty or not
  if [ ! -z "$SOURCE_FILES" ]; then
    log_ts "'${SOURCE_DIR}' contains files"
  else
    log_ts "'${SOURCE_DIR}' is empty"
    return 0
  fi

  # Loop over each file and source it
  # Assume that they're all sourceable without error.
  # Also, swap out the Input Field Separator setting (IFS) for a newline until the loop completes.
  OLD_IFS=$IFS
  IFS=$'\n'
  for file in ${SOURCE_FILES}; do
    log_ts "sourcing '${SOURCE_DIR}/${file}'"
    source "${SOURCE_DIR}/${file}"
  done
  IFS=$OLD_IFS
}
