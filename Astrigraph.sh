#!/bin/bash

# Go line by line
# Case statement looking at the first charactor and go from there...

# This will be considered a single digraph in graphviz.
# Need a list of all uniqe Contexts. They will be expressed as subgraphs in graphviz.
# Need a list of all uniqe Extentions per context. Extentions will be expressed as node/node labels in graphviz. Extentions/nodes must belong to contexts/subgraphs.
# Need a list of all Exention connections. Goto and Gosub connect extentions in seperate or same contexts. They will be considered connections/edges with labels in graphviz.
# Labels on connections/edges, will be the Goto or Gosub command as they appear in the dialplan.

# Define add_exention_to_context function
# Given a Content and Extention. Make a list of uniqe connections.
# Keep track of two arrays. Link arrays based array Index. Loop through them testing if connection already exists.
function add_extention_to_context {
  local Context=$1
  local Extention=$2
  local AlreadyAdded=0

  # If the given context doesn't have any connections yet, add connection.
  if [[ ! " ${linkcontextarray[*]} " =~ " ${Context} " ]]; then
    linkcontextarray+=("$Context")
    linkextentionarray+=("$Extention")

  # Given context has atleast one connection already. Check if connection already exists.
  else

    # Get a list of array indexes where context already exists.
    # For each value already in linkcontextarray
    for i in "${!linkcontextarray[@]}"; do

    # Where the given Context is already in the array add it's array index number to ArrayIndexes.
    if [[ "${linkcontextarray[$i]}" == "${Context}" ]]; then
       ArrayIndexes+="${i}"
    fi

    # For each index number in ArrayIndexes
    for i in "${ArrayIndexes[@]}"
    do

      # check if corrisponding linkextentionarray matches given Exention. if true set AlreadySet.
      if [[ "$linkextentionarray[$i]" == "$Exention" ]]; then

        # Extention/node already mapped to Context/Cluster
        AlreadyAdded=1
      fi
    # Done looking through linkextentionarray
    done

    # Done looking through linkcontextarray
    done

    # If AlreadyAdded is not 1. Add it.
    if [[ "$AlreadyAdded" != 1 ]]; then
      linkcontextarray+=("$Context")
      linkextentionarray+=("$Extention")

    # Reset AlreadyAdded for next run.
    else
      AlreadyAdded=0
    fi
  fi
  }

function add_Go_connection_to_graph {
local SourceContext=$1
local SourceExention=$2
local ConParams=$3
local ConType=$4

#Remove everthing except commas from ConParams
local JustCommas="${ConParams//[^,]}"

# The length of the string/var should be the number of commas in ConParams. Process based on that.
case ${#JustCommas} in

  0)
  # "Not connecting to another extention, ignoring"
  ;;

  1)
  #echo "Connecting to another exention in the same context"
  ConSourceContext+=("$SourceContext")
  ConSourceExtention+=("$SourceExention")
  ConDestContext+=("$SourceContext")
  ConDestExtention+=`echo $ConParams | cut -d ',' -f 1`
  ConCommand+=$ConType
  ;;

  2)
  #echo "Connecting to another exention in a differnet context"
  ConSourceContext+=("$SourceContext")
  ConSourceExtention+=("$SourceExention")
  ConDestContext+=`echo $ConParams | cut -d ',' -f 1`
  ConDestExtention+=`echo $ConParams | cut -d ',' -f 2`
  ConCommand+=$ConType
  ;;

esac
}

function add_GotoIf_To_graph {
  local SourceContext=$1
  local SourceExention=$2
  local ConParams=$3



}

# Get the array index of a connection. Since we are using the array index as the node name, we need to be able to look this up.
function get_index_of_connection {
local Context=$1
local Extention=$2

for i in "${!linkcontextarray[@]}"; do

# Where the given Context is already in the array add it's array index number to ArrayIndexes.
if [[ "${linkcontextarray[$i]}" == "${Context}" ]]; then
   ArrayIndexes+="${i}"
fi

# For each index number in ArrayIndexes
for i in "${ArrayIndexes[@]}"
do

  # check if corrisponding linkextentionarray matches given Exention. if true set AlreadySet.
  if [[ "$linkextentionarray[$i]" == "$Exention" ]]; then

    # Return index of connection
    return $i
  fi
# Done looking through linkextentionarray
done

# Done looking through linkcontextarray
done
}

# echo every line one at a time
while read p; do

	# Get the first char from the line
	FirstChar=${p::1}

	# Get the first 3 chars from a line
	First3Char=${p::3}

	# Based on the char of the first char of the line...
	case $FirstChar in

	# If the first char is a open bracket, this must be a context declaration.
	\[)
    # cut off the brackets and put the context name in var context
		context=`echo $p | sed 's/\[//g' | sed 's/\]//g'`

    # if this context name is not already in the contextarray then add it.
		if [[ ! " ${contextarray[*]} " =~ " ${context} " ]]; then
		contextarray+=("$context")
		fi
		;;

	# if the first char is a semi colon check if start of comment block. Set var InCommentBlock accordingly.
	\;)
		# if the first 3 chars are ";--" set the InComment var so we know we are in a comment block.
    if [[ $First3Char = "\;--" ]]; then
			InCommentBlock=1
		fi
		;;

  # if the first charactor is a "-" check if end of a comment block. Set var InCommentBlock accordingly.
  -)
    if [[ $First3Char = "--\;" ]]; then
      InCommentBlock=0
    fi
    ;;

  # If the first charactor is an "e" this must be the start of a extention declaration
	e)

    # Set var exten to the exention.
    # cut off "exten" and "=>" | cut off everything after the first ","
		exten=`echo $p | cut -d " " -f 3 | cut -d "," -f 1`

    # Add extention to contexts
    add_extention_to_context $context $exten

    # Check if line contains ",Goto("
		if  [[ ! -z `echo $p | grep -i ',Goto('` ]]; then
      ConParams=`echo $p | awk 'BEGIN{FS="Goto"}{print $2}' | sed 's/(//g' | sed 's/)//g'`
      ConType="Goto"
      add_Go_connection_to_graph $context $exten $ConParams $ConType
    fi

    # Check if line contains ",GotoIf("
    if  [[ ! -z `echo $p | grep -i ',GotoIf('` ]]; then
      ConParams=`echo $p | awk 'BEGIN{FS="GotoIf"}{print $2}'`

      # Get length of ConParams minus 1
      LenConParams=${#ConParams}
      echo "$ConParams is $LenConParams long in $p"
      LenConParams=$(expr $LenConParams - 1)

      # Strip last char of string which should be the )
      ConParams=${ConParams:1:$LenConParams}

      add_GotoIf_To_graph $context $exten $ConParams
    fi

    # Check if line contains ",Gosub("
    if [[ ! -z `echo $p | grep -i ',Gosub('` ]]; then
      ConParams=`echo $p | awk 'BEGIN{FS="Gosub"}{print $2}' | sed 's/(//g' | sed 's/)//g'`
      ConType="Gosub"
      add_Go_connection_to_graph $context $exten $ConParams $ConType
    fi

		;;

	s)
  # Check if line contains ",Goto("
  if  [[ ! -z `echo $p | grep -i ',Goto('` ]]; then
    ConParams=`echo $p | awk 'BEGIN{FS="Goto"}{print $2}' | sed 's/(//g' | sed 's/)//g'`
    ConType="Goto"
    add_Go_connection_to_graph $context $exten $ConParams $ConType
  fi

  # Check if line contains ",GotoIf("
  if  [[ ! -z `echo $p | grep -i ',GotoIf('` ]]; then
    ConParams=`echo $p | awk 'BEGIN{FS="GotoIf"}{print $2}'`

    # Get length of ConParams minus 1
    LenConParams=${#ConParams}
    echo "$ConParams is $LenConParams long in $p"
    LenConParams=$(expr $LenConParams - 1)

    # Strip last char of string which should be the )
    ConParams=${ConParams:1:$LenConParams}

    add_GotoIf_To_graph $context $exten $ConParams
  fi

  # Check if line contains ",Gosub("
  if [[ ! -z `echo $p | grep -i ',Gosub('` ]]; then
    ConParams=`echo $p | awk 'BEGIN{FS="Gosub"}{print $2}' | sed 's/(//g' | sed 's/)//g'`
    ConType="Gosub"
    add_Go_connection_to_graph $context $exten $ConParams $ConType
  fi
		;;

	esac

# Clean up extentions.conf with proper syntax before we go...
sed -i 's/goto/Goto/g' extentions.conf
sed -i 's/GoTo/Goto/g' extentions.conf
sed -i 's/goTo/Goto/g' extentions.conf

sed -i 's/gosub/Gosub/g' extentions.conf
sed -i 's/goSub/Gosub/g' extentions.conf
sed -i 's/GoSub/Gosub/g' extentions.conf

sed -i 's/GoToIf/GotoIf/g' extentions.conf
sed -i 's/Gotoif/GotoIf/g' extentions.conf
sed -i 's/GoToif/GotoIf/g' extentions.conf
sed -i 's/GoToIf/GotoIf/g' extentions.conf
sed -i 's/goToif/GotoIf/g' extentions.conf
sed -i 's/gotoIf/GotoIf/g' extentions.conf
sed -i 's/gotoif/GotoIf/g' extentions.conf

# Load extentions.conf into this mess and get going.
done <extentions.conf

# echo all contexts from array
# echo ${contexts[*]}

# Start building graph
echo "digraph astrigraph {" > graph.dot
echo " " >> graph.dot

# For each context, create a subgraph
for i in "${contextarray[@]}"; do

  # Start subgraph with style and label
  echo "subgraph $contextarray[$i] {" >> graph.dot
  echo "label = \"$contextarray[$i]\"" >> graph.dot
  echo "style=filled;" >> graph.dot
  echo "color=lightgrey;" >> graph.dot
  echo "node [style=filled,color=white];" >> graph.dot

  # For each value in linkcontext array. Check if context name matches, if so add array index (to be the node name) and the exention (to be the node label).
  # The reason we are using the index as the node name is because node names must be uniqe accross all subgraphs.
  for x in "$linkcontextarray[@]"; do
    if [[ "$linkcontextarray[$x]" == "$contextarray[$i]" ]]; then
      echo "$x [label=$linkextentionarray[$x] ];" >> graph.dot
    fi
  done

  # End of subgraph
  echo '}' >> graph.dot
  echo " " >> graph.dot

# End of all subgraphs
done
echo " " >> graph.dot

# Create edges/connectionsfor inner context connections first
for i in "$contextarray[@]"; do
  for x in "$ConSourceContext[@]"; do
  #  if [[ "$contextarray[$i]" == "$ConSourceContext[$x]" ]] && [[ "$contextarray[$i]" == "$ConDestContext[$x]" ]]; then
      get_index_of_connection $ConSourceContext[$x] $ConSourceExtention[$x]
      ConSource=$?
      get_index_of_connection $ConDestContext[$x] $ConDestExtention[$x]
      ConDest=$?
      echo "$ConSource --> $ConDest;" >> graph.dot
  #  fi
  done
done

# Create edges/connections for all other connections
for i in "$contextarray[@]"; do
  for x in "$ConSourceContext[@]"; do
    if [[ "$contextarray[$i]" == "$ConSourceContext[$x]" ]] && [[ "$contextarray[$i]" != "$ConDestContext[$x]" ]]; then
      get_index_of_connection $ConSourceContext[$x] $ConSourceExtention[$x]
      ConSource=$?
      get_index_of_connection $ConDestContext[$x] $ConDestExtention[$x]
      ConDest=$?
      echo "$ConSource --> $ConDest;" >> graph.dot
    fi
  done
done
echo '}' >> graph.dot
