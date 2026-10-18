#!/bin/sh

# Start script for the Restreamer bundle

# First run the import program. It will read the db.dir from the config file in order to
# find an old v1.json. This will be converted to the new db format.

if [ -x ./bin/import ]; then
    if ! ./bin/import; then
        exit 1
    fi
fi

# Run the FFmpeg migration program. It backs up saved processes before updating
# their FFmpeg version and any arguments that changed across supported versions.

if [ -x ./bin/ffmigrate ]; then
    if ! ./bin/ffmigrate; then
        exit 1
    fi
fi

# Create a hint for the admin interface if there is no index.html

if ! [ -f "${CORE_STORAGE_DISK_DIR}/index.html" ]; then
    cp /core/ui-root/index.html /core/ui-root/index_icon.svg "${CORE_STORAGE_DISK_DIR}"
fi

# Now run the core with the possibly converted configuration.

exec ./bin/core
