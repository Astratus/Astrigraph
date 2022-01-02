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
# Keep track of two arrays. Link arrays based on array Index. Loop through them testing if connection already exists.
function add_extention_to_context {
  local Context=$1
  local Extention=$2
  local AlreadyAdded=0
  local ArrayIndexes

  # If the given context doesn't have any connections yet, add connection.
  echo "trying to add $Extention to $Context"
  if [[ ! " ${linkcontextarray[*]} " =~ " ${Context} " ]]; then
    echo "Context has no connections just adding it"
    linkcontextarray+=("${Context}")
    linkextentionarray+=("${Extention}")

  # Given context has atleast one connection already. Check if connection already exists.
  else
    echo "Context already has connections"
    echo "checking ${linkcontextarray[@]} for ${Context}"
    # Get a list of array indexes where context already exists.
    for i in "${!linkcontextarray[@]}"; do

    echo "Checking if ${linkcontextarray[$i]} = ${Context}"
    # Where the given Context is already in the array add it's array index number to ArrayIndexes.
    if [[ ${linkcontextarray[$i]} == ${Context} ]]; then
      echo "${linkcontextarray[$i]} = ${Context} index is ${i}"
      ArrayIndexes+=("${i}")
     else
       echo "${linkcontextarray[$i]} does not = ${Context}"
    fi
    done

    echo "${linkcontextarray[@]} contains ${Context} at all these indexes ${ArrayIndexes[@]}"
    # For each index number in ArrayIndexes
    for x in "${!ArrayIndexes[@]}"
    do
      echo "Checking if ${linkextentionarray[$x]} is equal to ${Extention}"
      # check if corrisponding linkextentionarray matches given Exention. if true set AlreadySet.
      if [[ "${linkextentionarray[$x]}" == "${Extention}" ]]; then
        echo "${linkextentionarray[$x]} is equal to ${Extention}"
        # Extention/node already mapped to Context/Cluster
        AlreadyAdded=1
      fi
    done

    # If AlreadyAdded is not 1. Add it.
    if [[ "${AlreadyAdded}" == 0 ]]; then
      echo "Adding ${Extention} to $Context"
      linkcontextarray+=("$Context")
      linkextentionarray+=("$Extention")
      echo "${linkcontextarray[@]} shoud now contain $Context"
      echo "${linkextentionarray[@]} should now contain $Extention"
    fi
  fi
  }

# For gosub and goto processing. Given source context & source Extention & Con Params & ConType
# ConParams are the params given to the gosub or goto. In other words it's What's in the ()
# ConType is set to either "gosub" or "goto" accordingly
function add_Go_connection_to_graph {
local SourceContext=$1
local SourceExtention=$2
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
  ConSourceContext+=("${SourceContext}")
  ConSourceExtention+=("${SourceExtention}")
  ConDestContext+=("${SourceContext}")
  ConDestExtention+=(`echo ${ConParams} | cut -d ',' -f 1`)
  ConCommand+=${ConType}
  ;;

  2)
  #echo "Connecting to another exention in a differnet context"
  ConSourceContext+=("${SourceContext}")
  ConSourceExtention+=("${SourceExtention}")
  ConDestContext+=(`echo ${ConParams} | cut -d ',' -f 1`)
  ConDestExtention+=(`echo ${ConParams} | cut -d ',' -f 2`)
  ConCommand+=(${ConType})
  ;;

esac
}

# Get the array index of a connection. Since we are using the array index as the node name, we need to be able to look this up.
function get_index_of_connection {
local Context=$1
local Extention=$2
local ArrayIndexes

# Where the given Context is already in the array add it's array index number to ArrayIndexes.
for i in "${!linkcontextarray[@]}"; do
  if [[ "${linkcontextarray[$i]}" == "${Context}" ]]; then
    ArrayIndexes+="$i"
  fi
done

# For each index number in ArrayIndexes.
# Check if corrisponding linkextentionarray matches given Exention. if true set AlreadySet.
for i in "${!ArrayIndexes[@]}"; do
  if [[ "${linkextentionarray[$i]}" == "${Extention}" ]]; then
    # Return index of connection
    return $i
  fi
done
}

# For gotoif processing. Given source context & source extention & ConParams.
# ConParams are the params given to the gotoif. In other words it's What's in the ()
function add_GotoIf_To_graph {
  local SourceContext=$1
  local SourceExtention=$2
  local ConParams=$3
# Need to finish

}
# End of Functions

# line one at a time. Line is stored in $p
while read p; do

	# Get the first char from the line
	FirstChar=${p::1}

	# Get the first 3 chars from a line
	First3Char=${p::3}

	# Based on the char of the first char of the line...
	case ${FirstChar} in

	# If the first char is a open bracket, this must be a context declaration.
	\[)
    # cut off the brackets and put the context name in var context
		context=`echo $p | sed 's/\[//g' | sed 's/\]//g'`

    # if this context name is not already in the contextarray then add it.
		if [[ ! " ${contextarray[*]} " =~ " ${context} " ]]; then
		contextarray+=("${context}")
		fi
		;;

	# if the first char is a semi colon check if start of comment block. Set var InCommentBlock accordingly.
	\;)
		# if the first 3 chars are ";--" set the InComment var so we know we are in a comment block.
    if [[ ${First3Char} = "\;--" ]]; then
			InCommentBlock=1
		fi
		;;

  # if the first charactor is a "-" check if end of a comment block. Set var InCommentBlock accordingly.
  \-)
    if [[ $First3Char = "--\;" ]]; then
      InCommentBlock=0
    fi
    ;;

  # If the first charactor is an "e" this must be the start of a extention declaration
	e)
    echo "e processing for $p"
    # Set var exten to the exention.
    # cut off "exten" and "=>" | cut off everything after the first ","
		exten=`echo $p | cut -d " " -f 3 | cut -d "," -f 1`
    echo "Exten is $exten in context $context"

    # Add extention to contexts
    add_extention_to_context ${context} ${exten}

    # Check if line contains ",Goto("
		if  [[ "$p" == *",Goto("* ]]; then
      echo "goto processing $p"
      #Grab everything after goto and remove ()
      ConParams=`echo $p | awk 'BEGIN{FS="Goto"}{print $2}' | sed 's/(//g' | sed 's/)//g'`
      ConType="Goto"

      echo "Context is $context exten is $exten ConType is $ConType con params are $ConParams"

      add_Go_connection_to_graph $context $exten $ConParams $ConType
    fi

    # Check if line contains ",GotoIf("
    if  [[ "$p" == *",GotoIf("* ]]; then
      echo "gotoif processing $p"

      # Get everything after GotoIf(
      ConParams=`echo $p | awk 'BEGIN{FS="GotoIf\("}{print $2}'`

      # Strip last char of string which should be the )
      LenConParams=${#ConParams}
      #echo "$ConParams is $LenConParams long in $p"
      LenConParams=$(expr ${LenConParams} - 1)
      ConParams=${ConParams:0:${LenConParams}}

      add_GotoIf_To_graph $context $exten $ConParams
    fi

    # Check if line contains ",Gosub("
    if [[ "$p" == *",Gosub("* ]]; then
      echo "gosub processing $p"
      # Grab everything after gosub and remove ()
      ConParams=`echo $p | awk 'BEGIN{FS="Gosub"}{print $2}' | sed 's/(//g' | sed 's/)//g'`
      ConType="Gosub"

      add_Go_connection_to_graph $context $exten $ConParams $ConType
    fi

		;;

	s)
  echo "s processing fpr $p"
  # Check if line contains ",Goto("
  if  [[ "$p" == *",Goto("* ]]; then
    echo "Goto processing for $p"
    #Grab everything after goto and remove ()
    ConParams=`echo $p | awk 'BEGIN{FS="Goto"}{print $2}' | sed 's/(//g' | sed 's/)//g'`
    ConType="Goto"
    echo "Context is $context exten is $exten ConType is $ConType con params are $ConParams"

    add_Go_connection_to_graph $context $exten $ConParams $ConType
  fi

  # Check if line contains ",GotoIf("
  if  [[ "$p" == *",GotoIf("* ]]; then
    echo "gotoif processing for $p"
    # Get everything after GotoIf(
    ConParams=`echo $p | awk 'BEGIN{FS="GotoIf"}{print $2}'`

    # Strip last char of string which should be the )
    LenConParams=${#ConParams}
    #echo "$ConParams is $LenConParams long in $p"
    LenConParams=$(expr $LenConParams - 1)
    ConParams=${ConParams:0:$LenConParams}

    add_GotoIf_To_graph $context $exten $ConParams
  fi

  # Check if line contains ",Gosub("
  if [[ "$p" == *",Gosub("* ]]; then
    echo "Gosub processing for $p"
    # Grab everything after gosub and remove ()
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
sed -i 's/GotoIF/GotoIf/g' extentions.conf
sed -i 's/GotoIf/GotoIf/g' extentions.conf

# Load extentions.conf into this mess and get going.
done < extentions.conf

# echo all contexts from array
# echo ${contexts[*]}

# Start building graph
echo "digraph astrigraph {" > graph.dot
echo " " >> graph.dot

# For each context, create a subgraph
for i in "${!contextarray[@]}"; do

  # Start subgraph with style and label
  echo "subgraph cluster_${i} {" >> graph.dot
  echo "label = \"${contextarray[$i]}\";" >> graph.dot
  echo "style=filled;" >> graph.dot
  echo "color=lightgrey;" >> graph.dot
  echo "node [style=filled,color=white];" >> graph.dot

  # For each value in linkcontext array. Check if context name matches, if so add array index (to be the node name) and the exention (to be the node label).
  # The reason we are using the index as the node name is because node names must be uniqe accross all subgraphs.
  for x in "${!linkcontextarray[@]}"; do
    if [[ "${linkcontextarray[$x]}" == "${contextarray[$i]}" ]]; then
      echo "$x [label=\"${linkextentionarray[$x]}\"];" >> graph.dot
    fi
  done

  # End of subgraph
  echo '}' >> graph.dot
  echo " " >> graph.dot

# End of all subgraphs
done
echo " " >> graph.dot

# Create edges/connectionsfor inner context connections first
for i in "${!contextarray[@]}"; do
  for x in "${!ConSourceContext[@]}"; do
    if [[ ${contextarray[$i]} == ${ConSourceContext[$x]} ]] && [[ ${contextarray[$i]} == ${ConDestContext[$x]} ]]; then
      get_index_of_connection ${ConSourceContext[$x]} ${ConSourceExtention[$x]}
      ConSource=$?
      get_index_of_connection ${ConDestContext[$x]} ${ConDestExtention[$x]}
      ConDest=$?
      echo "${ConSource} --> ${ConDest};" >> graph.dot
    fi
  done
done

# Create edges/connections for all other connections
for i in "${!contextarray[@]}"; do
  for x in "${!ConSourceContext[@]}"; do
    if [[ ${contextarray[$i]} == ${ConSourceContext[$x]} ]] && [[ ${contextarray[$i]}" != "${ConDestContext[$x]} ]]; then
      get_index_of_connection ${ConSourceContext[$x]} ${ConSourceExtention[$x]}
      ConSource=$?
      get_index_of_connection ${ConDestContext[$x]} ${ConDestExtention[$x]}
      ConDest=$?
      echo "$ConSource --> $ConDest;" >> graph.dot
    fi
  done
done
echo '}' >> graph.dot


echo "contextarray is ${contextarray[@]}"
echo "ConSourceContext is ${ConsourceContext[@]}"
echo "linkcontextarray is ${linkcontextarray[@]}"
echo "linkextentionarray is ${linkextentionarray[@]}"
