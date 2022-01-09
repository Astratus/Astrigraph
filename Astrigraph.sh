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
  #echo "trying to add $Extention to $Context"
  if [[ ! *"${Context}"*  =~  " ${linkcontextarray[*]} " ]]; then
    #echo "Context has no connections just adding it"
    linkcontextarray+=("${Context}")
    linkextentionarray+=("${Extention}")
    echo "Adding Extention to Context - Context: " ${linkcontextarray[-1]} " Extention: " ${linkextentionarray[-1]} " at index: " ${#linkcontextarray[@]}
  # Given context has atleast one connection already. Check if connection already exists.
  else
    #echo "Context already has connections"
    #echo "checking ${linkcontextarray[@]} for ${Context}"
    # Get a list of array indexes where context already exists.
    for i in "${!linkcontextarray[@]}"; do

    #echo "Checking if ${linkcontextarray[${i}]} = ${Context}"
    # Where the given Context is already in the array add it's array index number to ArrayIndexes.
    if [[ ${linkcontextarray[${i}]} == ${Context} ]]; then
      #echo "${linkcontextarray[${i}]} = ${Context} index is ${i}"
      ArrayIndexes+=("${i}")
    fi

    done

    #echo "${linkcontextarray[@]} contains ${Context} at all these indexes ${ArrayIndexes[@]}"
    # For each index number in ArrayIndexes
    for x in "${ArrayIndexes[@]}"; do
      #echo "Checking if ${linkextentionarray[${x}]} is equal to ${Extention}"

      # check if corrisponding linkextentionarray matches given Exention. if true set AlreadySet.
      if [[ ${linkextentionarray[${x}]} == ${Extention} ]]; then
        #echo "${linkextentionarray[${x}]} is equal to ${Extention} not adding"
        # Extention/node already mapped to Context/Cluster
        AlreadyAdded=1
        break
      #else
        #echo "${linkextentionarray[${x}]} is not equal to ${Extention} adding"
      fi
    done

    # If AlreadyAdded is not 1. Add it.
    if [[ ${AlreadyAdded} == 0 ]]; then
      #echo "Adding ${Extention} to $Context"
      linkcontextarray+=("$Context")
      linkextentionarray+=("$Extention")
      #echo "${linkcontextarray[@]} shoud now contain $Context"
      #echo "${linkextentionarray[@]} should now contain $Extention"
      echo "Adding Context to Extention Context: " ${linkcontextarray[-1]} " Extention: " ${linkextentionarray[-1]} " at index: " ${#linkcontextarray[@]}
    else
      echo "Extention already exists in context... I don't like this... please start your lines with same where possible ? "
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

#echo "Adding:${ConType} from Context:${SourceContext} extention:${SourceExtention} going to:${ConParams}"

if [[ "${ConParams}" == *"$"* ]]; then
  echo ${ConParams} " contains a var... detected $... Not adding"
  return
fi

#Remove everthing except commas from ConParams
local JustCommas="${ConParams//[^,]}"
#echo "\"${ConParams}\" contains \"${#JustCommas}\" commas"

# The length of the string/var should be the number of commas in ConParams. Process based on that.
case ${#JustCommas} in

  0)
  #echo "\"${ConParams}\" is does not connect to another extention, ignoring"
  ;;

  1)
  #echo "\"${ConParams}\" is connecting to another exention in the same context"
  ConSourceContext+=("${SourceContext}")
  #echo "\"${ConSourceContext[@]}\" should now contain ${SourceContext}"
  ConSourceExtention+=("${SourceExtention}")
  ConDestContext+=("${SourceContext}")
  ConDestExtention+=("`echo ${ConParams} | cut -d ',' -f 1`")
  #echo "\"${ConDestExtention[@]}\" should now contain " "`echo ${ConParams} | cut -d ',' -f 1`"
  ConCommand+=("${ConType}")
  echo "Adding Connection ConSourceContext: " ${ConSourceContext[-1]}  " ConSourceExtention: " ${ConSourceExtention[-1]} " ConDestContext: " ${ConDestContext[-1]} " ConDestExtention: " ${ConDestExtention[-1]} " ConCommand: " ${ConCommand[-1]} " At Index: " ${#ConCommand[@]}

  ;;

  2)
  #echo "${ConParams} is connecting to another exention in a differnet context"
  ConSourceContext+=("${SourceContext}")
  #echo "\"${ConSourceContext[@]}\" should now contain ${SourceContext}"
  ConSourceExtention+=("${SourceExtention}")
  ConDestContext+=("`echo ${ConParams} | cut -d ',' -f 1`")
  ConDestExtention+=("`echo ${ConParams} | cut -d ',' -f 2`")
  ConCommand+=("${ConType}")
  echo "Adding Connection ConSourceContext: " ${ConSourceContext[-1]}  " ConSourceExtention: " ${ConSourceExtention[-1]} " ConDestContext: " ${ConDestContext[-1]} " ConDestExtention: " ${ConDestExtention[-1]} " ConCommand: " ${ConCommand[-1]} " At Index: " ${#ConCommand[@]}

  ;;

  *)
  #echo "${ConParams} is connecting to another exention in a differnet context and passing var/vars"
  ConSourceContext+=("${SourceContext}")
  #echo "\"${ConSourceContext[@]}\" should now contain ${SourceContext}"
  ConSourceExtention+=("${SourceExtention}")
  ConDestContext+=("`echo ${ConParams} | cut -d ',' -f 1`")
  ConDestExtention+=("`echo ${ConParams} | cut -d ',' -f 2`")
  ConCommand+=("${ConType}")
  echo "Adding Connection ConSourceContext: " ${ConSourceExtention[-1]}  " ConSourceExtention: " ${ConSourceExtention[-1]} " ConDestContext: " ${ConDestContext[-1]} " ConDestExtention: " ${ConDestExtention[-1]} " ConCommand: " ${ConCommand[-1]} " At Index: " ${#ConCommand[@]}
  ;;

esac
}

# Get the array index of a connection. Since we are using the array index as the node name, we need to be able to look this up.
function get_index_of_connection {
local Context=$1
local Extention=$2
local ArrayIndexes

#echo "trying to find the index of Context:${Context} Extention:${Extention}"

# Where the given Context is already in the array add it's array index number to ArrayIndexes.
for i in "${!linkcontextarray[@]}"; do
  #echo "Does ${linkcontextarray[${i}]} == ${Context}"
  if [[ ${linkcontextarray[${i}]} == ${Context} ]]; then
    #echo "Yes ${linkcontextarray[${i}]} == ${Context}"
    ArrayIndexes+=("${i}")
    #echo "${ArrayIndexes[@]} should now contain ${i}"
  #else
    #echo "No ${linkcontextarray[${i}]} == ${Context}"
  fi
done

# If ArrayIndexes is not empty.
if [[ -n $ArrayIndexes ]]; then

  # For each index number in ArrayIndexes.
  # Check if corrisponding linkextentionarray matches given Exention. if true set AlreadySet.
  for i in "${ArrayIndexes[@]}"; do
    #echo "Does ${linkextentionarray[${i}]} == ${Extention}"
    if [[ ${linkextentionarray[${i}]} == ${Extention} ]]; then
      # Return index of connection
      #echo "yes ${linkextentionarray[${i}]} == ${Extention}"
      # returning ${i}
      echo ${i}
      break
    fi
  done
fi
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

	# Get the first 3 chars from the line
	First3Char=${p::3}

	# Based on the char of the first char of the line...
	case ${FirstChar} in

	# If the first char is a open bracket, this must be a context declaration.
	\[)
    #echo "[ processing for $p"
    if [[ ${InCommentBlock} != 1 ]]; then

      # cut off the brackets and put the context name in var context
		  context=`echo $p | sed 's/\[//g' | sed 's/\]//g'`
      #echo "We are now in ${context}"

      # if this context name is not already in the contextarray then add it.
		  if [[ ! " ${contextarray[*]} " =~ " ${context} " ]]; then
		    contextarray+=("${context}")
        #echo ${context} " is a new context"
		  fi
    else
      : in comment block
    fi
    ;;

  # If the first charactor is an "e" this must be the start of a extention declaration
	e)

    #echo "e processing for $p"
    if [[ ${InCommentBlock} != 1 ]]; then

    # Set var exten to the exention.
    # cut off "exten" and "=>" | cut off everything after the first ","
		exten=`echo $p | cut -d " " -f 3 | cut -d "," -f 1`
    #echo "Adding Exten:$exten to context:$context"

    # Add extention to contexts
    add_extention_to_context ${context} ${exten}

    # Check if line contains ",Goto("
		if  [[ "$p" == *",Goto("* ]]; then
      #echo "goto processing $p"
      #Grab everything after goto and remove ()
      ConParams=`echo $p | awk 'BEGIN{FS="Goto"}{print $2}' | sed 's/(//g' | sed 's/)//g'`
      ConType="Goto"

      #echo "context:$context exten:$exten ConType:$ConType ConParams:$ConParams"

      add_Go_connection_to_graph $context $exten $ConParams $ConType
    fi

    # Check if line contains ",GotoIf("
    if  [[ "$p" == *",GotoIf("* ]]; then
      #echo "gotoif processing $p"

      # Get everything after GotoIf( . Not sure why it takes so much effort to use ( in awk's field seperator.
      ConParams=`echo $p | awk 'BEGIN{FS="GotoIf\\\("}{print $2}' 2> /dev/null`

      # Strip last char of string which should be the )
      LenConParams=${#ConParams}
      #echo "string \"$ConParams\" is \"$LenConParams\" long "
      LenConParams=$(expr ${LenConParams} - 1)
      ConParams=${ConParams:0:${LenConParams}}

      add_GotoIf_To_graph $context $exten $ConParams
    fi

    # Check if line contains ",Gosub("
    if [[ "$p" == *",Gosub("* ]]; then
      #echo "gosub processing $p"
      # Grab everything after gosub and remove ()
      ConParams=`echo $p | awk 'BEGIN{FS="Gosub"}{print $2}' | sed 's/(//g' | sed 's/)//g'`
      ConType="Gosub"

      add_Go_connection_to_graph $context $exten $ConParams $ConType
    fi
  else
    : in comment block
  fi
		;;

  # If the first charactor is an "s" we must be already in a extention
	s)
  #echo "s processing for $p"
  if [[ ${InCommentBlock} = 1 ]]; then

  # Check if line contains ",Goto("
  if  [[ "$p" == *",Goto("* ]]; then
    #echo "Goto processing for $p"
    #Grab everything after goto and remove ()
    ConParams=`echo $p | awk 'BEGIN{FS="Goto"}{print $2}' | sed 's/(//g' | sed 's/)//g'`
    ConType="Goto"
    #echo "Context is $context exten is $exten ConType is $ConType con params are $ConParams"

    add_Go_connection_to_graph $context $exten $ConParams $ConType
  fi

  # Check if line contains ",GotoIf("
  if  [[ "$p" == *",GotoIf("* ]]; then
    #echo "gotoif processing for $p"
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
    #echo "Gosub processing for $p"
    # Grab everything after gosub and remove ()
    ConParams=`echo $p | awk 'BEGIN{FS="Gosub"}{print $2}' | sed 's/(//g' | sed 's/)//g'`
    ConType="Gosub"

    add_Go_connection_to_graph $context $exten $ConParams $ConType
  fi
else
  : in comment block
fi
		;;

  # if the first char is a semi colon check if start of comment block. Set var InCommentBlock accordingly.
  \;)
    #echo "; processing for $p"
    # if the first 3 chars are ";--" set the InComment var so we know we are in a comment block.
    if [[ ${First3Char} = "\;--" ]]; then
      InCommentBlock=1
    fi
    ;;

  # if the first charactor is a "-" check if end of a comment block. Set var InCommentBlock accordingly.
  \-)
    #echo "- processing for $p"
    if [[ $First3Char = "--\;" ]]; then
      InCommentBlock=0
    fi
    ;;

	esac

# Load extentions.conf into this mess and get going.
done < extentions.conf

# echo all contexts from array
# echo ${contexts[*]}

# Start building graph
echo "digraph astrigraph {" > graph.dot
echo " " >> graph.dot

# For each context, create a subgraph
for i in "${!contextarray[@]}"; do

  # If this context has a connection
  if [[ " ${linkcontextarray[*]} " =~ " ${contextarray[${i}]} " ]]; then

    # Start subgraph with style and label
    echo "subgraph cluster_${i} {" >> graph.dot
    echo "label = \"${contextarray[${i}]}\";" >> graph.dot
    echo "style=filled;" >> graph.dot
    echo "color=lightgrey;" >> graph.dot
    echo "node [style=filled,color=white];" >> graph.dot

    # For each value in linkcontext array. Check if context name matches, if so add array index (to be the node name) and the exention (to be the node label).
    # The reason we are using the index as the node name is because node names must be uniqe accross all subgraphs.
    for x in "${!linkcontextarray[@]}"; do
      if [[ "${linkcontextarray[${x}]}" == "${contextarray[${i}]}" ]]; then
        echo "${x} [label=\"${linkextentionarray[${x}]}\"];" >> graph.dot
      fi
    done

    # End of subgraph
    echo '}' >> graph.dot
  fi

# End of all subgraphs
done
echo " " >> graph.dot

# Create edges/connections for inner context connections first
for i in "${!contextarray[@]}"; do
  for x in "${!ConSourceContext[@]}"; do
    if [[ ${contextarray[${i}]} == ${ConSourceContext[${x}]} ]] && [[ ${contextarray[${i}]} == ${ConDestContext[${x}]} ]]; then
      #echo "Going 1 to connect context:${ConSourceContext[${x}]} Exten:${ConSourceExtention[${x}]} --> Context:${ConDestContext[${x}]} Exten:${ConDestExtention[${x}]}"
      ConSource=$(get_index_of_connection ${ConSourceContext[${x}]} ${ConSourceExtention[${x}]})
      #echo "context: " ${ConSourceContext[${x}]} " Exten: " ${ConSourceExtention[${x}]} " came out to be index " $ConSource
      ConDest=$(get_index_of_connection ${ConDestContext[${x}]} ${ConDestExtention[${x}]})
      #echo "Context: " ${ConDestContext[${x}]} " Exten: " ${ConDestExtention[${x}]} " and out to be index " $ConDest
      if [[ -n $ConDest ]] && [[ -n $ConSource ]]; then
        echo ${ConSource} " -> " ${ConDest} ";" >> graph.dot
      else
            echo "Could not find index for one of " $ConDest " OR " $ConSource
      fi
    fi
  done
done

# Create edges/connections for all other connections
for i in "${!contextarray[@]}"; do
  for x in "${!ConSourceContext[@]}"; do
    if [[ ${contextarray[${i}]} == ${ConSourceContext[${x}]} ]] && [[ ${contextarray[${i}]} != ${ConDestContext[${x}]} ]]; then
      #echo "Going 2 to connect context:${ConSourceContext[${x}]} Exten:${ConSourceExtention[${x}]} --> Context:${ConDestContext[${x}]} Exten:${ConDestExtention[${x}]}"
      ConSource=$(get_index_of_connection ${ConSourceContext[${x}]} ${ConSourceExtention[${x}]})
      #echo "context: " ${ConSourceContext[${x}]} " Exten: " ${ConSourceExtention[${x}]} " came out to be index " ${ConSource}
      ConDest=$(get_index_of_connection ${ConDestContext[${x}]} ${ConDestExtention[${x}]})
      #echo "Context: " ${ConDestContext[${x}]} " Exten: " ${ConDestExtention[${x}]} " and out to be index " ${ConDest}

      if [[ -n $ConDest ]] && [[ -n $ConSource ]]; then
        echo ${ConSource} " -> " ${ConDest} ";" >> graph.dot
      else
          echo "Could not find index for " $ConDest " OR " $ConSource
      fi
    fi
  done
done

# End of building graph
echo '}' >> graph.dot

# For Debugging
#echo "contextarray is \"${contextarray[@]}\""
#echo "ConSourceContext is \"${ConSourceContext[@]}\""
#echo "ConSourceExtention is \"${ConSourceExtention[@]}\""
#echo "ConDestExtention is \"${ConDestExtention[@]}\""
#echo "ConDestContext is \"${ConDestContext[@]}\""
#echo "ConCommand is \"${ConCommand[@]}\""
#echo "linkcontextarray is \"${linkcontextarray[@]}\""
#echo "linkextentionarray is \"${linkextentionarray[@]}\""
