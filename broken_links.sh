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
FILES=$(find $DIR -name '*.md' -type f)

# Define list of broken links:
BROKEN_LINKS=""

# Loop through all files...
for FILE in $FILES; do
    echo "Checking $FILE for broken links..."
    # Find all URLs in the file:
    URLS=`grep -Po "(?<=\]: )https?://[^ ]*" "$FILE"`
    echo Number of links in $FILE: `echo $URLS | wc -w`
    # Loop through all URLs...
    for URL in $URLS; do
        # Check if the URL is broken:
        STATUS=`curl -I -s -o /dev/null -w "%{http_code}" "$URL"`
        # If the status is 200, 301, or 302, add the URL to the list of broken links:
        if [ "$STATUS" != "200" ] && [ "$STATUS" != "301" ] && [ "$STATUS" != "302" ]; then
            echo "Status code for $URL: $STATUS \u274C"
            ## Add the URL to the list of broken links if not already there:
            if [[ $BROKEN_LINKS != *"$URL"* ]]; then
                BROKEN_LINKS="$BROKEN_LINKS $URL\n"
            fi
        else
            echo "Status code for $URL: $STATUS \u2705"
        fi
    done
done

# Print the list of broken links to the console
echo "::set-output name=links::$(echo -e $BROKEN_LINKS)"