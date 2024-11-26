#!/bin/bash

UNDERLINE_WHITE="\033[4;37m"
RESET="\033[0m"

# Initialize max block height and max peers per node
max_block_height=0
declare -a max_peers

####################################
# CHANGE THE LINES BELOW AS NEEDED #
####################################
# Define the list of IP addresses to watch
nodes=(
  "http://127.0.0.1:12391"
  "http://192.168.1.012:12391"
  "http://192.168.1.123:12391"
  "http://192.168.1.234:12391"
)
# Define the name for each IP address
names=(
  "${UNDERLINE_WHITE}Local${RESET}"
  "${UNDERLINE_WHITE}Alice${RESET}"
  "${UNDERLINE_WHITE}Bobbo${RESET}"
  "${UNDERLINE_WHITE}Crowe${RESET}"
)
# Manually set max peers per node if desired
max_peers[0]=0
max_peers[1]=0
max_peers[2]=0
max_peers[3]=0
# Define time in seconds between each update
delay=5
# Define the max width of the output (not used with jq)
width=150
# Set this to true if more than 99 peers are expected
three_digit_mode=false
####################################
# CHANGE THE LINES ABOVE AS NEEDED #
####################################

# Define ANSI color codes
# Regular Colors
BLACK="\033[0;30m"
RED="\033[0;31m"
GREEN="\033[0;32m"
YELLOW="\033[0;33m"
BLUE="\033[0;34m"
PURPLE="\033[0;35m"
CYAN="\033[0;36m"
WHITE="\033[0;37m"
RESET="\033[0m"  # Resets all attributes
# Bold Colors
BOLD_BLACK="\033[1;30m"
BOLD_RED="\033[1;31m"
BOLD_GREEN="\033[1;32m"
BOLD_YELLOW="\033[1;33m"
BOLD_BLUE="\033[1;34m"
BOLD_PURPLE="\033[1;35m"
BOLD_CYAN="\033[1;36m"
BOLD_WHITE="\033[1;37m"
# Underlined Colors
UNDERLINE_BLACK="\033[4;30m"
UNDERLINE_RED="\033[4;31m"
UNDERLINE_GREEN="\033[4;32m"
UNDERLINE_YELLOW="\033[4;33m"
UNDERLINE_BLUE="\033[4;34m"
UNDERLINE_PURPLE="\033[4;35m"
UNDERLINE_CYAN="\033[4;36m"
UNDERLINE_WHITE="\033[4;37m"
# Background Colors
BG_BLACK="\033[40m"
BG_RED="\033[41m"
BG_GREEN="\033[42m"
BG_YELLOW="\033[43m"
BG_BLUE="\033[44m"
BG_PURPLE="\033[45m"
BG_CYAN="\033[46m"
BG_WHITE="\033[47m"
# High-Intensity Text Colors
INTENSE_BLACK="\033[0;90m"
INTENSE_RED="\033[0;91m"
INTENSE_GREEN="\033[0;92m"
INTENSE_YELLOW="\033[0;93m"
INTENSE_BLUE="\033[0;94m"
INTENSE_PURPLE="\033[0;95m"
INTENSE_CYAN="\033[0;96m"
INTENSE_WHITE="\033[0;97m"
# High-Intensity Background Colors
BG_INTENSE_BLACK="\033[100m"
BG_INTENSE_RED="\033[101m"
BG_INTENSE_GREEN="\033[102m"
BG_INTENSE_YELLOW="\033[103m"
BG_INTENSE_BLUE="\033[104m"
BG_INTENSE_PURPLE="\033[105m"
BG_INTENSE_CYAN="\033[106m"
BG_INTENSE_WHITE="\033[107m"
# Text Effects
RESET="\033[0m"        # Reset all attributes
BOLD="\033[1m"         # Bold text
DIM="\033[2m"          # Dim text
UNDERLINED="\033[4m"   # Underlined text
BLINK="\033[5m"        # Blink
REVERSE="\033[7m"      # Reverse colors (foreground/background swap)
HIDDEN="\033[8m"       # Hidden text


# Check if jq is installed
use_jq=true
if ! command -v jq &> /dev/null; then
  echo "The 'jq' utility is not installed."
  read -p "Would you like to install jq and restart? (y/n): " install_choice
  if [[ "$install_choice" == "y" || "$install_choice" == "Y" ]]; then
    echo "Please install 'jq' using your package manager (e.g., sudo apt-get install jq) and restart this script."
    exit 1
  else
    echo "Proceeding without jq. Output will not be parsed for detailed formatting."
    use_jq=false
  fi
fi

# Initialize the display with placeholders for each node
initialize_display() {
  clear
  for i in "${!nodes[@]}"; do
    printf "\033[%d;0H%b [Initializing...]\n" $((i + 1)) "${names[$i]}"
  done
}

# Function to check if any max peers are higher than 99
check_three_digit_mode() {
  for value in "${max_peers[@]}"; do
    if [ "$value" -gt 99 ]; then
      three_digit_mode=true
      return
    fi
  done
  three_digit_mode=false
}

# Function to fetch and display node status
update_status() {
  local i=$1
  # Fetch the status from the current node in JSON format
  status=$(curl -s --max-time $delay "${nodes[$i]}/admin/status")
  
    if [ -z "$status" ]; then
      # Handle empty status
      isMintingPossible="X"
      isSynchronizing="X"
      if [ "$three_digit_mode" = true ]; then
        peers_display="XXX"
      else
        peers_display="XX"
      fi
      height_display="XXXXXXX"
      # Display with appropriate placeholders
      printf "\033[%d;0H%b: Minting:%b Syncing:%b Peers:%s Height:%s\n" \
        $((i + 1)) "${names[$i]}" "$isMintingPossible" "$isSynchronizing" "$peers_display"/"$peers_display" "$height_display"
    else
      if $use_jq; then
        # Extract relevant data using jq for JSON parsing
        isMintingPossible=$(echo "$status" | jq -r '.isMintingPossible')
        isSynchronizing=$(echo "$status" | jq -r '.isSynchronizing')
        numberOfConnections=$(echo "$status" | jq -r '.numberOfConnections')
        height=$(echo "$status" | jq -r '.height')

        # Handle cases where jq returns null or empty
        [ "$numberOfConnections" == "null" ] || [ -z "$numberOfConnections" ] && numberOfConnections="XX"
        [ "$height" == "null" ] || [ -z "$height" ] && height="XXXXXXX"

        # Update max values if current values are higher
        if [[ "$height" != "XXXXXXX" && "$height" -gt "$max_block_height" ]]; then
          max_block_height="$height"
        fi
        if [[ "$numberOfConnections" != "XX" && "$numberOfConnections" -gt "${max_peers[$i]}" ]]; then
          max_peers[$i]="$numberOfConnections"
        fi

        # Check if we need to switch to three-digit mode
        check_three_digit_mode

        # Format numberOfConnections with leading zeros
        if [ "$numberOfConnections" != "XX" ]; then
          if [ "$three_digit_mode" = true ]; then
            peers_formatted=$(printf "%03d" "$numberOfConnections")
          else
            peers_formatted=$(printf "%02d" "$numberOfConnections")
          fi
        else
          peers_formatted="$numberOfConnections"
        fi

        # Format height to seven digits with leading zeros
        if [ "$height" != "XXXXXXX" ]; then
          height_formatted=$(printf "%07d" "$height")
        else
          height_formatted="$height"
        fi

        # Apply coloring logic for peers
        if [ "$peers_formatted" == "XX" ] || [ "$peers_formatted" == "XXX" ]; then
          peers_display="$peers_formatted"
        else
          if [ "$three_digit_mode" = true ]; then
            max_peer=$(printf "%03d" "${max_peers[$i]}")
          else
            max_peer=$(printf "%02d" "${max_peers[$i]}")
          fi
          if [ "$max_peer" -eq 0 ]; then
            # Avoid division by zero
            peers_display="$peers_formatted"
          else
            peer_ratio=$(echo "scale=2; $numberOfConnections / $max_peer" | bc)
            if (( $(echo "$peer_ratio >= 1" | bc -l) )); then
              peers_display="${CYAN}$peers_formatted/$max_peer${RESET}"
            elif (( $(echo "$peer_ratio >= 0.6667" | bc -l) )); then
              peers_display="${GREEN}$peers_formatted/$max_peer${RESET}"
            elif (( $(echo "$peer_ratio >= 0.3333" | bc -l) )); then
              peers_display="${YELLOW}$peers_formatted/$max_peer${RESET}"
            elif [ "$peers_formatted" == "00" ]; then
              peers_display="${BG_RED}$peers_formatted/$max_peer${RESET}"
            else
              peers_display="${RED}$peers_formatted/$max_peer${RESET}"
            fi
          fi
        fi

        # Apply coloring logic for height
        if [ "$height_formatted" == "XXXXXXX" ]; then
          height_display="$height_formatted"
        else
          height_diff=$((max_block_height - height))
          if [ "$height" -eq "$max_block_height" ]; then
            height_display="${CYAN}$height_formatted${RESET}"
          elif [ "$height_diff" -le 5 ]; then
            height_display="${GREEN}$height_formatted${RESET}"
          elif [ "$height_diff" -le 50 ]; then
            height_display="${YELLOW}$height_formatted${RESET}"
          elif [ "$height_diff" -le 500 ]; then
            height_display="${RED}$height_formatted${RESET}"
          else
            height_display="${BG_RED}$height_formatted${RESET}"
          fi
        fi

        # Convert boolean-like values to Y/N with color
        if [ "$isMintingPossible" == "true" ]; then
          isMintingPossible="${GREEN}Y${RESET}"
        elif [ "$isMintingPossible" == "false" ]; then
          isMintingPossible="${RED}N${RESET}"
        else
          isMintingPossible="X"
        fi

        if [ "$isSynchronizing" == "true" ]; then
          isSynchronizing="${GREEN}Y${RESET}"
        elif [ "$isSynchronizing" == "false" ]; then
          isSynchronizing="${RED}N${RESET}"
        else
          isSynchronizing="X"
        fi

        # Display the status with formatted and colored outputs
        printf "\033[%d;0H%b: Minting:%b Syncing:%b Peers:%b Height:%b\n" \
          $((i + 1)) "${names[$i]}" "$isMintingPossible" "$isSynchronizing" "$peers_display" "$height_display"

      else
        # Fallback to original output format
        printf "\033[%d;0H%s %s\n" $((i + 1)) "${names[$i]}" "${status:0:$width}"
      fi
    fi
}

# Main logic
initialize_display

index=0
while true; do
  # Update the status for the current node
  update_status $index
  
  # Move to the next node in the list (wrap around using modulo)
  index=$(( (index + 1) % ${#nodes[@]} ))

  # Wait before updating the next node
  sleep $delay
done
