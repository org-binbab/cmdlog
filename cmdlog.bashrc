export CMDLOG_DIR="/root/cmdlog"
export PROMPT_COMMAND='RETRN_VAL=$?; [ -e $CMDLOG_DIR/.tmp ] && $CMDLOG_DIR/cmdlog.sh entry "$(history 1 | sed "s/^[0-9 :-]*//" )" $RETRN_VAL'
alias log="$CMDLOG_DIR/cmdlog.sh"
