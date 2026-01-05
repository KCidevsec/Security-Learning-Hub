#!/bin/bash
# fix-permissions.sh
# Continuously monitors and fixes permissions on uploaded PHP files
# Runs as root to be able to change permissions on files owned by MySQL

echo "Starting permission fixer daemon..."

while true; do
    # Find all PHP files in /var/www/html (except the main files)
    for file in /var/www/html/*.php; do
        if [ -f "$file" ]; then
            filename=$(basename "$file")
            # Skip our main application files
            if [ "$filename" != "index.php" ] && [ "$filename" != "check.php" ]; then
                # Change ownership to www-data and make readable
                chown www-data:www-data "$file" 2>/dev/null
                chmod 644 "$file" 2>/dev/null
                echo "Fixed permissions for: $file"
            fi
        fi
    done
    
    # Sleep for 1 second before checking again
    sleep 1
done