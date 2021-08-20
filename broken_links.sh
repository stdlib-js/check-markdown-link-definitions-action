#
# Find all URLs in a directory and check if they are broken.
#

# Check if the first argument is a directory:
if [ ! -d "$1" ]; then
    # If not, use the current directory:
    DIR="$(pwd)"
else
    # If it is, use the first argument:
    DIR="$1"
fi

# Find all files in the directory:
FILES=$(find $DIR -type f)

# Define list of broken links:
BROKEN_LINKS=""

# Loop through all files
for FILE in $FILES; do
    # Find all URLs in the file
    URLS=`grep -Eo "https?://[^ ]*" "$FILE"`
    # Loop through all URLs
    for URL in $URLS; do
        # Check if the URL is broken
        STATUS=`curl -I -s -o /dev/null -w "%{http_code}" "$URL"`
        # If the status is not 200, add the URL to the list of broken links
        if [ "$STATUS" != "200" ]; then
            BROKEN_LINKS="$BROKEN_LINKS$URL\n"
        fi
    done
done

# Print the list of broken links to the console
echo -e $BROKEN_LINKS