= Puppet Control (name needs work)

Puppet Control allows an admin to
* Add nodes to a list of authorized nodes
* Assign classes to nodes
* Assign parameters to classes
* Create node *roles*
* Search for nodes
* Retrieve node inventory
* Carry out Puppet runs on collections of nodes

Puppet Control provides the following roles
[Observer]
  * Can see what curators have created
  * Can see the progress of tasks in progress
[Curator/Creator]
  * Creates or edits classifications
  * Can search inventories and for nodes
[Operator]
  * Can issue runs, search for nodes, or get inventory information
[Admin]
  * *Curator* + *Operator*

= What's missing

Reporting analysis tools are missing. Too much to do for a first revision

= Feature priority

1. Authorize nodes
1. Search for nodes (mcollective ping)
1. Inventory nodes

= Design guide

A user must login before doing anything. This is a single page action.
 
The main screen displays a grid of options as N cubes. When a cube is clicked, we head to that administrative action. 

== Common Elements

Any administrative action screen is topped with a flat bar of *Start* and then each available administrative action.

[False Claims Warning]
 This will not be available in the first release

== Authorize Nodes

Authorize nodes presents a node addition form with a text field and a flat button *Add* in a cube on the left. On the right, a cube with recently added hosts is listed. A search bar tops this cube. On the right side of the cube are a tab for Sort with the top of the tab being ascending, the bottom being descending.

[ToDo]
 * Nodes in the right cube should be deletable

== Search for Nodes

Presents a cube with various common facts. Once a fact key is selected a text box for a value is presented in a second cube on the right with a *Search* flat button. 

A fact key called 'All' is available and is the default selection for discovering all nodes.

The search results are ordered by discovery time into the right cube with the familiar ascending / descending tab model. Times are displayed as:
* somehost.com (23ms)

[ToDo]
* Allow multiple fact keys and values to be specified

== Inventory Nodes

The familiar two cube model returns. The left cube allows a hostname to be specified with an *Inventory* flat button. 

