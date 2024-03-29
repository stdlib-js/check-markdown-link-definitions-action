#
# Find all URLs in a directory and check if they are broken.
#

# Define a function to map a status code to a human readable string.
#
# $1 - The status code.
#
# Returns a human readable string.
#
function status_code_to_string()
{
    case $1 in
        000)
            echo "Failed"
            ;;
        200)
            echo "OK"
            ;;
        201)
            echo "Created"
            ;;
        202)
            echo "Accepted"
            ;;
        203)
            echo "Non-Authoritative Information"
            ;;
        204)
            echo "No Content"
            ;;
        205)
            echo "Reset Content"
            ;;
        206)
            echo "Partial Content"
            ;;
        207) 
            echo "Multi-Status"
            ;;
        208)
            echo "Already Reported"
            ;;
        226)
            echo "IM Used"
            ;;
        301)
            echo "Moved Permanently"
            ;;
        302)
            echo "Found"
            ;;
        303)
            echo "See Other"
            ;;
        304)
            echo "Not Modified"
            ;;
        305)
            echo "Use Proxy"
            ;;
        306)
            echo "Switch Proxy"
            ;;
        307)
            echo "Temporary Redirect"
            ;;
        308)
            echo "Permanent Redirect"
            ;;
        400)
            echo "Bad Request"
            ;;
        401)
            echo "Unauthorized"
            ;;
        403)
            echo "Forbidden"
            ;;
        404)
            echo "Not Found"
            ;;  
        429)
            echo "Too Many Requests"
            ;;
        *)
            echo "Unknown HTTP Status Code"
            ;;
    esac
}

# Extract from first argument list of status codes that should be treated as a succesful.
SUCCESS_CODES=$1

echo "Status codes to treat as successful: $SUCCESS_CODES"

# Extract from second argument list of status codes that should be treated as a warning.
WARNING_CODES=$2

echo "Status codes to treat as warnings: $WARNING_CODES"

# Extract from third argument regular expression for URLs that should be ignored.
EXCLUDE_REGEX=$3

echo "Regular expression for URLs to exclude: $EXCLUDE_REGEX"

# Check if the third argument is a directory:
if [ ! -d "$4" ]; then
    # If not, use the current directory:
    DIR="$(pwd)"
else
    # If it is, use the fourth argument:
    DIR="$4"
fi

# Find all files in the directory:
FILES=$(find $DIR -name '*.md' -type f)

# Define list of all URLs:
ALL_LINKS="["

# Define list of broken links:
FAILURES="["

# Define a count for the number of broken links:
FAILURES_COUNT=0

# Define list of warnings:
WARNINGS="["

# Define a count for the number of warnings:
WARNINGS_COUNT=0

# Loop through all files...
for FILE in $FILES; do
    echo "Checking $FILE for broken links..."
    
    # Find all URLs in the file:
    LINKS=`grep -Po "^\[[^[]+\]: https?://[^ ]*" "$FILE" | sed 's/ /%20/g'`
    echo Number of links in $FILE: `echo $URLS | wc -w`
    
    # Loop through all URLs...
    for LINK in $LINKS; do
    
        # Extract the URL:
        URL=`echo $LINK | grep -Po "https?://[^ ]*"`
        
        # Extract the identifier by stripping off the leading "[", the trailing "]:":
        ID=`echo $LINK | grep -Po "^\[[^[]+\]:" | sed 's/\[//' | sed 's/\]://'`
        echo "Checking $URL with identifier $ID..."

        # Skip in case URL matches the exclude pattern:
        if [ "$EXCLUDE_REGEX" != "none" ]; then
            if [[ "$URL" =~ $EXCLUDE_REGEX ]]; then
                echo "Skipping $URL"
                continue
            fi
        fi
        # Check if the URL is broken:
        STATUS=`curl -A "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/89.0.4389.82 Safari/537.36" -s -G -o /dev/null -w "%{http_code}" "$URL"`
        STATUS_DESCR=`status_code_to_string $STATUS`

        # If the status is 200, 301, or 302, add the URL to the list of broken links:
        if [[ $SUCCESS_CODES != *"$STATUS"* ]]; then
            # Case: Status code is not in the list of successful code...
            if [[ $WARNING_CODES != *"$STATUS"* ]]; then
                # Case: Status code should be treated as a failure...
                echo -e "Status code for $URL is $STATUS - $STATUS_DESCR \u274C"
                ## Add the URL to the list of broken links if not already there:
                if [[ $FAILURES != *"$URL"* ]]; then
                    # Append comma if not empty:
                    if [ "$FAILURES" != "[" ]; then
                        FAILURES="$FAILURES,"
                    fi
                    FAILURES="$FAILURES { \"url\": \"$URL\", \"code\": $STATUS, \"status\": \"$STATUS_DESCR\", \"file\": \"$FILE\" }"
                    FAILURES_COUNT=$((FAILURES_COUNT+1))
                fi
            else
                # Case: Status code should be treated as a warning...
                echo -e "Status code for $URL is $STATUS - $STATUS_DESCR \u26A0"

                ## Add the URL to the list of warnings if not already there:
                if [[ $WARNINGS != *"$URL"* ]]; then
                    # Append comma if not empty:
                    if [ "$WARNINGS" != "[" ]; then
                        WARNINGS="$WARNINGS,"
                    fi
                    WARNINGS="$WARNINGS { \"url\": \"$URL\", \"code\": $STATUS, \"status\": \"$STATUS_DESCR\", \"file\": \"$FILE\" }"
                    WARNINGS_COUNT=$((WARNINGS_COUNT+1))
                fi
            fi
        else 
            # Case: Status code should be treated as a success...
            echo -e "Status code for $URL is $STATUS - $STATUS_DESCR \u2705"
        fi
        
        # Add the URL to the list of all URLs:
        if [[ $ALL_LINKS != *"$URL"* ]]; then
            # Append comma if not empty:
            if [ "$ALL_LINKS" != "[" ]; then
                ALL_LINKS="$ALL_LINKS,"
            fi
            ALL_LINKS="$ALL_LINKS { \"url\": \"$URL\", \"id\": \"$ID\", \"file\": \"$FILE\" }"
        fi
    done
done

# Add closing bracket to the list of broken links:
FAILURES="$FAILURES ]"

# Add closing bracket to the list of warnings:
WARNINGS="$WARNINGS ]"

# Add closing bracket to the list of all URLs:
ALL_LINKS="$ALL_LINKS ]"

echo "# Summary" >> $GITHUB_STEP_SUMMARY

echo "Total number of broken links: $FAILURES_COUNT" >> $GITHUB_STEP_SUMMARY
echo "Total number of warnings: $WARNINGS_COUNT" >> $GITHUB_STEP_SUMMARY

echo "## Failures" >> $GITHUB_STEP_SUMMARY
echo $FAILURES | md-table -c >> $GITHUB_STEP_SUMMARY

echo "## Warnings" >> $GITHUB_STEP_SUMMARY
echo $WARNINGS | md-table -c >> $GITHUB_STEP_SUMMARY

# Assign the list indicating broken links to the `failures` output variable:
echo "failures=$FAILURES" >> $GITHUB_OUTPUT

# Assign the list indicating warnings to the `warnings` output variable:
echo "warnings=$WARNINGS" >> $GITHUB_OUTPUT

# Assign list of all URLs to the `all_links` output variable:
echo "all_links=$ALL_LINKS" >> $GITHUB_OUTPUT