#!/bin/bash

TMP_FILE="${CMDLOG_DIR?}/.tmp"
TODAY_FILE="$CMDLOG_DIR/log-$(date +%Y-%m-%d.txt)"
DIFF_DIR="$CMDLOG_DIR/.diff"
DIFF_TMP="$DIFF_DIR/tmp"
MERGE_FILE="$CMDLOG_DIR/.merge"
EDITOR="vim"

case ${1?} in
  entry)
    shift
    if [ -e $TMP_FILE -a ! -e $CMDLOG_DIR/.pause ] ; then
      CMDTXT=${1?}
      RESULT=${2?}
      [ $RESULT -eq 130 ] && exit 0
      read -a CMDARR <<< "$CMDTXT"
      CMDBIN="${CMDARR[0]}"
      [[ "$CMDBIN" =~ (ls|echo|log|cat|less|help|clear) ]] && exit 0
      if [ $RESULT -eq 0 ] ; then
        echo $CMDTXT >> $TMP_FILE
      else
        echo "$CMDTXT    # exit($RESULT)" >> $TMP_FILE
      fi
      if [ -e $MERGE_FILE ] ; then
        echo ": <<'OUTPUT'" >> $TMP_FILE
        echo "# ----------------------------------------------------------" >> $TMP_FILE
        cat $MERGE_FILE     >> $TMP_FILE
        echo "# ----------------------------------------------------------" >> $TMP_FILE
        echo "OUTPUT # END" >> $TMP_FILE
        rm $MERGE_FILE
      fi
    fi
    ;;

  start)
    shift
    [ -e $TMP_FILE ] && exit 1
    DESC=${1}
    while [ -z "$DESC" ] ; do
      read -p "Description: " DESC
    done
    echo "##########################################################################################" >> $TMP_FILE
    echo "## $(date)" >> $TMP_FILE
    echo "## \"$DESC\"" >> $TMP_FILE
    echo "##########################################################################################" >> $TMP_FILE
    echo >> $TMP_FILE
    rm $CMDLOG_DIR/.pause 2> /dev/null
    echo "CMDLOG started"
    ;;

  stop)
    if [ -e $TMP_FILE ] ; then
      echo >> $TMP_FILE
      cat $TMP_FILE >> $TODAY_FILE
      rm $TMP_FILE
    fi
    ;;

  pause|p)
    if [ -e $CMDLOG_DIR/.pause ] ; then
      rm $CMDLOG_DIR/.pause
      echo "CMDLOG resumed"
    else
      touch $CMDLOG_DIR/.pause
      echo "CMDLOG paused"
    fi
    ;;

  clear)
    [ -e $TMP_FILE ] && cat /dev/null > $TMP_FILE
    echo "CMDLOG cleared"
    ;;

  cancel)
    [ -e $TMP_FILE ] && rm $TMP_FILE
    ;;

  review|r)
    if [ -e $TMP_FILE ] ; then
      vi $TMP_FILE
    elif [ -e $TODAY_FILE ] ; then
      vi $TODAY_FILE
    fi
    ;;

  edit)
    [ -e $CMDLOG_DIR/.pause ] && echo "ERROR: Cannot edit file in paused mode." && exit 1
    shift
    FILEPATH="${1?FIlepath required}"
    cd $(dirname $FILEPATH)
    FILEDIR="$(pwd)"
    FILENAME="$(basename $FILEPATH)"
    FILE=$FILEDIR/$FILENAME
    [ ! -e $DIFF_DIR ] && mkdir $DIFF_DIR
    ORIG_FILE=$DIFF_DIR/$(echo $FILE | sha1sum | cut -f1 -d' ')-$FILENAME.orig
    #[ -e $FILE -a ! -e $ORIG_FILE ] && cp -a $FILE $ORIG_FILE
    if [ -e $FILE ] ; then
      cat $FILE > $DIFF_TMP.src
    else
      cat /dev/null > $DIFF_TMP.src
    fi
    $EDITOR $FILE || exit 1
    #[ ! -e $ORIG_FILE -a -e $FILE ] && touch $ORIG_FILE
    #diff --label $FILE $ORIG_FILE $FILE > $DIFF_TMP.diff0
    diff --label $FILE $DIFF_TMP.src $FILE > $DIFF_TMP.diff1 
    #diff -q $DIFF_TMP.diff0 $DIFF_TMP.diff1 &> /dev/null
    #if [ $? -eq 0 ] ; then
      # First change.
    #  cat $DIFF_TMP.diff0 >> $MERGE_FILE
    #else
      # Nth change.
    #  echo >> $MERGE_FILE
    #  echo "# RECENT CHANGE" >> $MERGE_FILE
    #  echo >> $MERGE_FILE
      cat $DIFF_TMP.diff1 >> $MERGE_FILE
    #  echo >> $MERGE_FILE
    #  echo "# FROM ORIGINAL" >> $MERGE_FILE
    #  echo >> $MERGE_FILE
    #  cat $DIFF_TMP.diff0 >> $MERGE_FILE
    #  echo >> $MERGE_FILE
    #fi
    echo >> $TMP_FILE
    $0 entry "$EDITOR $FILE" 0
    echo >> $TMP_FILE
    ;;

  capture|cap)
    while IFS= read -r line ; do
      printf "%s\n" "$line"
      printf "%s\n" "$line" >> $MERGE_FILE
    done < /proc/${$}/fd/0
    ;;

  note)
    shift
    [ ! -e $TMP_FILE ] && exit 1
    NOTE=${1}
    while [ -z "$NOTE" ] ; do
      read -p "Note: " NOTE
    done
    echo >> $TMP_FILE
    echo "##" >> $TMP_FILE
    echo "## NOTE:" >> $TMP_FILE
    echo "## $NOTE" >> $TMP_FILE
    echo "##" >> $TMP_FILE
    echo >> $TMP_FILE
    echo "CMDLOG note saved"
    ;;

  status)
    if [ -e $TMP_FILE -a ! -e $CMDLOG_DIR/.pause ] ; then
      echo "CMDLOG is logging" 
    elif [ -e $TMP_FILE ] ; then
      echo "CMDLOG is paused"
    else
      echo "CMDLOG is stopped"
    fi 
    ;;
  screen-status)
    if [ -e $TMP_FILE -a ! -e $CMDLOG_DIR/.pause ] ; then
      echo -e "\005{wg}  LOGGING  \005{-}" 
    elif [ -e $TMP_FILE ] ; then
      echo -e "\005{ky}  PAUSED  \005{-}"
    else
      echo -e "\005{wr}  NOT LOGGING  \005{-}"
    fi 
    ;;
esac
