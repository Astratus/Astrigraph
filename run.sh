#!/bin/bash

sed -i 's/goto/Goto/gI' extentions.conf
sed -i 's/gosub/Gosub/gI' extentions.conf
sed -i 's/GoToIf/GotoIf/gI' extentions.conf

./astrigraph.sh
fdp graph.dot -Tpng -o Astrigraph.png
