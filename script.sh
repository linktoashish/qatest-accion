#!/bin/bash

# CONFIG
BINARY="./qatest-linux-amd64"
OUTFILE="output1236.log"
SEQFILE=".sequence_index"
START=1
count=0
MAX_ITERATIONS=${1:-2000} # Set a maximum number of iterations

echo "Max iterations set to: $MAX_ITERATIONS" # Set a maximum number of iterations

# Check if the binary exists and has execute permissions
if [[ ! -f "$BINARY" || ! -x "$BINARY" ]]; then
    if [[ ! -f "$BINARY" ]]; then
        echo "Error: Binary file ($BINARY) does not exist."
    fi
    if [[ ! -x "$BINARY" ]]; then
        echo "Error: Binary file ($BINARY) does not have execute permissions."
    fi
    exit 1
fi



# Check if sequence file exists, else create it with read/write permissions
if [[ ! -f "$SEQFILE" ]]; then
    # Create the file if it doesn't exist
    touch "$SEQFILE"
    
    # Check if the file was created successfully
    if [[ $? -ne 0 ]]; then
        echo "Error: Failed to create sequence file ($SEQFILE)."
        exit 1
    fi

    # Set read and write permissions on the file
    chmod 600 "$SEQFILE"  # Owner can read and write, no permissions for others
    echo "$START" > "$SEQFILE"  # Initialize with the starting sequence (1)
fi

# Check read and write permissions on the .sequence file
if [[ ! -r "$SEQFILE" || ! -w "$SEQFILE" ]]; then
    echo "Error: No read/write permission for the sequence file ($SEQFILE)."
    exit 1
fi

# Read the sequence value from the file
SEQUENCE=$(cat "$SEQFILE")

 #If the sequence is 0, start from 1
if [[ "$SEQUENCE" -eq 0 ]]; then
    SEQUENCE=$START
     > "$OUTFILE"
fi

# Clear output file if starting fresh
if [[ "$SEQUENCE" -eq $START ]]; then
    > "$OUTFILE"
    write_mode=">"
else
    write_mode=">>"
fi

i=$SEQUENCE
# Run the binary from the last sequence number
while true; do
    result=$($BINARY run)
   
    # Write result to output file (overwrite first time, then append)
    if [[ "$write_mode" == ">" ]]; then
        echo "$result" > "$OUTFILE"
        write_mode=">>"
    else
        echo "$result" >> "$OUTFILE"
    fi

    echo "$i" > "$SEQFILE"
    
    if [[ "$result" == "END" ]]; then

        echo "0" > "$SEQFILE"
        break
    fi
    
    ((i++))
    ((count++))
    
   # Prevent infinite loop by limiting the number of iterations
    if (( count >= MAX_ITERATIONS )); then
        echo "Max iterations reached. Exiting..."
        break
    fi
done
# Summary
echo "Summary of outputs:"
awk '
/^fizz$/ {fizz++}
/^buzz$/ {buzz++}
/^fizzbuzz$/ {fizzbuzz++}
/^END$/ {end++}
/^$/ {blank++}
{ total++ }
END {
    print "fizz:", fizz
    print "buzz:", buzz
    print "fizzbuzz:", fizzbuzz
    print "blank:", blank
    print "END:", end
    print "fizz/total:", fizz "/" total
}' "$OUTFILE"

# Final sequence position (should be reset to 0)
echo "Last sequence position: 0"
