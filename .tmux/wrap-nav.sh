#!/bin/sh
# Smart wrap navigation: jump to neighbor window, land on edge-most pane,
# and keep vertical intent (top vs bottom) from the pane you came from.
# Usage: wrap-nav.sh left|right

dir="$1"

# Remember whether we were in the top or bottom half of the current window
set -- $(tmux display -p "#{window_height} #{pane_top} #{pane_bottom}")
win_h=$1
top=$2
bottom=$3
center=$(( (top + bottom) / 2 ))
pref="top"
[ "$center" -ge $(( win_h / 2 )) ] && pref="bottom"

pick_pane() {
  direction="$1"
  panes="$2"
  if [ "$direction" = "left" ]; then
    extreme=$(printf "%s\n" "$panes" | awk '{print $3}' | sort -nr | head -1) # max pane_right
    [ -z "$extreme" ] && echo "1" && return
    if [ "$pref" = "top" ]; then
      printf "%s\n" "$panes" | awk -v mr="$extreme" '($3==mr){print $0}' | sort -k4,4n | head -1 | awk '{print $1}'
    else
      printf "%s\n" "$panes" | awk -v mr="$extreme" '($3==mr){print $0}' | sort -k5,5nr | head -1 | awk '{print $1}'
    fi
  else
    extreme=$(printf "%s\n" "$panes" | awk '{print $2}' | sort -n | head -1) # min pane_left
    [ -z "$extreme" ] && echo "1" && return
    if [ "$pref" = "top" ]; then
      printf "%s\n" "$panes" | awk -v ml="$extreme" '($2==ml){print $0}' | sort -k4,4n | head -1 | awk '{print $1}'
    else
      printf "%s\n" "$panes" | awk -v ml="$extreme" '($2==ml){print $0}' | sort -k5,5nr | head -1 | awk '{print $1}'
    fi
  fi
}

case "$dir" in
  left)
    tmux select-window -t :- 2>/dev/null || exit 0
    panes=$(tmux list-panes -F "#{pane_index} #{pane_left} #{pane_right} #{pane_top} #{pane_bottom}")
    p=$(pick_pane left "$panes")
    tmux select-pane -t "${p:-1}"
    ;;
  right)
    tmux select-window -t :+ 2>/dev/null || exit 0
    panes=$(tmux list-panes -F "#{pane_index} #{pane_left} #{pane_right} #{pane_top} #{pane_bottom}")
    p=$(pick_pane right "$panes")
    tmux select-pane -t "${p:-1}"
    ;;
  *)
    exit 0
    ;;
esac
