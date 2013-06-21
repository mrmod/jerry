# Jerry
Jerry was a race car driver. Never did win no checkered flags, but never did come in last.

Jerry allows an admin to:

* Maintain a list of authorized nodes
* Search for nodes
* Retrieve node inventory
* Run Puppet on a node
* *Assign classes to nodes (pending)*
* *Assign parameters to classes (pending)*
* *Carry out Puppet runs on collections of nodes (pending)*
* *Create node roles (pending)*

----

Jerry provides the following roles:

<dl>
  <dt>Observer</dt>
    <dd>Can see what curators have created</dd>
    <dd>Can see the progress of tasks in progress</dd>
  <dt>Curator/Creator</dt>
    <dd>Creates or edits classifications</dd>
    <dd>Can search inventories and for nodes</dd>
  <dt>Operator</dt>
    <dd>Can issue runs, search for nodes, or get inventory information</dd>
<dt>Admin</dt>
  <dd> <strong>Curator</strong> + <strong>Operator</strong></dd>
</dl>

## What's missing

* Reporting analysis tools are missing
* Any kind of batching or fact matching
* All regex features
* Multi-node runs

### Feature priority

1. Multi-node runs
1. Regex features
1. Batching and fact matching

## Projects we use
* [Gumby](http://gumbyframework.com/)
* [Sinatra](http://www.sinatrarb.com/)
* [Haml](http://haml.info/)
* [RightJS](http://rightjs.org/)

Uh, and the two other packaged Javascript frameworks.

## Warranty and Such

This "software" is not safe for anyone and will break anything it touches. Don't use it unless you like bad things.
