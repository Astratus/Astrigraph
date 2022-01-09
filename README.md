# Astrigraph

Astrigraph is bash script that can take a asterisk dialplan and turn it into a graphviz graph. 
Asterisk dialplan - https://wiki.asterisk.org/wiki/display/AST/Contexts%2C+Extensions%2C+and+Priorities
Graphviz package - https://pkgs.org/download/graphviz

My reasons for building this are:
To first most have fun learning bash. 
To have a script i can run on any linux box that can generate a rough idea of what is going on in the dialplan.
This can be very useful when trying to wrap your head around a huge dialplan that you may have to change. 

Downsides:
Variables can be used in the dialplan, make it hard to build a graph based on information you don't have. So this graphs will never be complete.
The extention.conf doesn't tell you what context/extention calls will come in on. So these graphs will never have a start point. 
Includes can be used in the dialplan. I'm not showing those in the graph. I don't know how to show this type of one way relationship in a graph... If someone has an idea... let me know...

Upsides:
We might be able to get make some assumptions and get some variables to appear in the graph.
