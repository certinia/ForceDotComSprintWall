# force.com Sprint Wall

<a href="https://githubsfdeploy.herokuapp.com?owner=financialforcedev&repo=ForceDotComSprintWall">
  <img alt="Deploy to Salesforce"
       src="https://raw.githubusercontent.com/afawcett/githubsfdeploy/master/src/main/webapp/resources/img/deploy.png">
</a>

A drag and drop, live updating sprint wall built on the force.com platform using jQuery, jQuery UI and Javascript remoting to produce a web application in the mould of [Trello](http://trello.com) and [SeeNowDo](http://www.seenowdo.com). Note that I built a version of this for [FinancialForce.com](http://www.financialforce.com) to help manage their sprints in distributed teams scattered across the globe.

It's intended as more of an example of what you can do on the force.com platform rather than a stand alone application.

## Getting Started

Spin up an empty Salesforce.com developer org and push the contents of this repository into that org (note that the 'resources' folder contains the extracted contents of the 'sprintwallres' static resource). To create some test data to get you started execute the following in the developer console in the org:

	CreateTestData.CleanAndCreateData();

Once up and running you can go directly to the 'Sprint Wall' tab and you'll see something like this (once you expand a story by clicking the green 'expand' button):

> ![The Sprint Wall](https://github.com/financialforcedev/ForceDotComSprintWall/raw/master/sprintwall.png)

You can drag and drop tasks between states (i.e. their respective columns) and that will update the 'Agile Task' 'Status' field behind the scenes. Click the magnifying glass on a task to view the underlying Salesforce object. Note that if you open the sprint wall in multiple browsers (or better still, multiple people have it open at the same time) then tasks moved between states will live update in front of your eyes within a couple of seconds. Likewise if someone changes the descriptions, owners, etc of agile tasks then those changes will automagically appear for anybody looking at the wall. If you click the 'cog' icon you can edit a task in a popup like so:

> ![An Agile Task](https://github.com/financialforcedev/ForceDotComSprintWall/raw/master/agiletaskedit.png)

Note that the category is colour coded so if you change the category (or someone else does) then the colour of the agile task 'card' will change to match.

## Things You Might Want To Do Next (Exercises For The Reader)

Agile tasks have two related objects called 'Agile Task Hours History' and 'Agile Task Hours Remaining History' that are automatically updated to keep track of initial estimate, the amount of time remaining each day and so forth so you can potentially generate burndown charts from the data. I'll leave that as an exercise for the reader.

Infinite scrolling would also be useful if a large number of stories are likely to be shown at once - there is a hard limit in the 'ALM Settings' custom setting but in the case of this example it wasn't necessary to support a very large number of stories due to the size of the team.

Finally, if you change the agile tasks order in a single column that order is not preserved (so if a new agile task is created by someone else it will appear at the bottom of the column on your wall). The order of agile tasks was not a requirement but wouldn't be difficult to accommodate.

Unit testing for the Javascript code. Enough said!

## About Me

My name is John Conners, I write software and you can find out all about me here:

> [John's Adventures](http://johnsadventures.com)

If you have any questions, thoughts or suggestions please [contact me](http://johnsadventures.com/contact/).

## Licensing

This code has been released under the GNU General Public License. See the associated [license.txt](https://github.com/financialforcedev/ForceDotComSprintWall/blob/master/license.txt) file for more details.

## Included Libraries / Components

 - [jQuery](http://jquery.com)
 - [jQuery UI](http://jqueryui.com)
 - [jQuery Cookie Plugin](https://github.com/carhartl/jquery-cookie)
 - [jQuery Hotkeys Plugin](http://github.com/tzuryby/hotkeys)
 - [jQuery Sticky Table Headers Plugin](https://github.com/jmosbech/StickyTableHeaders)
 - [jQuery UI Touch Punch](http://touchpunch.furf.com/)
 - [famfamfam Silk Icons](http://www.famfamfam.com/lab/icons/silk/)
