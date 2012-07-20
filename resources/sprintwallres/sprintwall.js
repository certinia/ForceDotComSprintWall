/*
	Copyright 2012 FinancialForce.com.

	This file is part of SprintWall.

	SprintWall is free software: you can redistribute it and/or modify
	it under the terms of the GNU General Public License as published by
	the Free Software Foundation, either version 3 of the License, or
	(at your option) any later version.

	SprintWall is distributed in the hope that it will be useful,
	but WITHOUT ANY WARRANTY; without even the implied warranty of
	MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
	GNU General Public License for more details.

	You should have received a copy of the GNU General Public License
	along with SprintWall.  If not, see <http://www.gnu.org/licenses/>.
*/

var $j = jQuery.noConflict();
$j(document).ready(function() {
	populateSprintList();
	
	var d = new Date();
	if( d.getDate() == 5 && d.getMonth() == 7 ) {
		$j('#header span').text('Sprint Wall - All Your Tasks Are Belong To Us!');
	}
	
	$j('#taskCategory').parent().append('&nbsp;<span id="categoryColour" class="nocategory">&nbsp;&nbsp;&nbsp;&nbsp;</span>');
	
	$j('#taskCategory')
		.append('<option value="">-- None --</option>')
		.append('<option value="Analysis">Analysis</option>')
		.append('<option value="Design">Design</option>')
		.append('<option value="Development">Development</option>')
		.append('<option value="QA">QA</option>')
		.append('<option value="Documentation">Documentation</option>')
		.append('<option value="Bug">Bug</option>')
		.change( function() {
			var category = $j(this).val().toLowerCase();
			if( category == '' ) {
				category = 'nocategory';
			}
			$j('#categoryColour').removeClass().addClass( category );
		});
		
	$j('#taskPriority')
		.append('<option value="">-- None --</option>')
		.append('<option value="P1">P1</option>')
		.append('<option value="P2">P2</option>')
		.append('<option value="P3">P3</option>')
		.append('<option value="P4">P4</option>');
		
	$j('#categoryList')
		.append('<option value="All">-- All --</option>')
		.append('<option value="">-- No Category --</option>')
		.append('<option value="Analysis">Analysis</option>')
		.append('<option value="Design">Design</option>')
		.append('<option value="Development">Development</option>')
		.append('<option value="QA">QA</option>')
		.append('<option value="Documentation">Documentation</option>')
		.append('<option value="Bug">Bug</option>');
	
	$j('#taskOwner').append('<option value="">-- None --</option>');
	
	SprintWallController.getPeople( function( result, event ) {
		if( event.status ) {
			$j('#personList').removeAttr( 'disabled' ).find('option').remove().end();
			$j('#personList')
				.append('<option value="all">-- Anybody --</option>')
				.append('<option value="">-- No Owner --</option>');
			
			$j.each(result, function(index, person) {
				$j('#taskOwner').append('<option value="' + person.Id + '">' + person.Name + '</option>');
				$j('#personList').append('<option value="' + person.Id + '">' + person.Name + '</option>');
			});
		}
	});
	
	SprintWallController.getTeams( function( result, event ) {
		if (event.status) {
        	// clear out the sprint list
        	$j('#teamList').removeAttr( 'disabled' ).find('option').remove().end();
        	
        	if( result.length == 0 ) {
        		$j('#teamList').append( '<option value="nowt">No Teams</option>' ).attr( 'disabled', 'disabled' );
        	}
        	else {
        		$j('#teamList').append('<option value="" selected>-- All teams --</option>');
        		$j.each(result, function(index, team) { 
            		$j('#teamList').append('<option value="' + team.Id + '">' + team.Name + '</option>');
            	});
            	
            	var myTeam = $j.cookie('last_team');
            	if( myTeam != null ) {
            		$j('#teamList').val( myTeam );
            	}
            }
        } else {
        	showError( event.message );
        }
	});
	
	$j('#sprintList').change(function(){
		loadSprint();
	});
	
	$j('#teamList').change(function(){
		// store the current team
		var teamId = $j('#teamList').val();
		$j.cookie( 'last_team', teamId, { expires: 365 } );
		
		loadSprint();
	});
	
	$j('#personList').change(function(){
		loadSprint();
	});
	
	$j('#categoryList').change(function(){
		loadSprint();
	});
	
	$j('#refreshBtn').click(function(){
		loadSprint();
		return false;
	});
	
	$j('#helpBtn').click( function() {
		$j('#helpPage').dialog({
			title: "Need help? Don't worry, you've come to the right place!",
			height: 420,
			width: 600,
			modal: true,
			draggable: true,
			resizable: false,
			open: function(event, ui) { $j(".ui-dialog-titlebar-close").show(); }
		});
	});
	
	// question mark brings up help - unless we're showing a dialog already
	$j(document).bind('keyup', function(evt) {
		if( evt.keyCode == 191 && !isDialogShowing() ) {
			$j('#helpBtn').click();
		}
	});
	
	// spin up our polling job to check for changes to tasks
	poll();
});

function poll() {
	setTimeout(function() {
		if( isDialogShowing() ) {
			// skip this one - we're in the middle of showing a dialog
			poll();
		} else {
			var data = getSprintTaskData();
			if( data === undefined ) {
				// no data loaded so no point making the server round trip
				poll();
			} else {
				// poll salesforce and see if any changes have happened - make sure we pass in our filters
				var personId = $j('#personList').val();
				var categoryName = $j('#categoryList').val();
				SprintWallController.getChanges( personId, categoryName, data, applyServerChanges );
			}
		}
	}, 3000 );
}

function applyServerChanges( result, event ) {
	if( event.status ) {
		if( result.length > 0 ) {
			// we have some tasks
			$j.each(result, function(index, task) {
				if( task.ChangeAction == 'd' ) {
					// task was deleted
					$j('#' + task.Id).remove();
					storeTaskData( task.StoryId, task.Id, '-1' );
				}
				if( task.ChangeAction == 'c' ) {
					// task has changed - update
					updateTaskOnPage( task );
				}
				if( task.ChangeAction == 'a' ) {
					// new task, put it in the right place
					$j('#' + task.StoryId + ' .' + taskStatus( task ) ).append( taskAll( task, task.StoryId ) );
					storeTaskData( task.StoryId, task.Id, task.Version );
				}
			});
			
			// make sure the task buttons are all wired up and dragging enabled
			enableDragging();
			wireTaskViewButtonsUp();
		}
	}
	
	// initiate the next poll
	poll();
}

function isDialogShowing() {
	if( $j("#editTask").parents(".ui-dialog").is(":visible") == true ||
		$j("#msg").parents(".ui-dialog").is(":visible") == true ||
		$j("#error").parents(".ui-dialog").is(":visible") == true ) {
		return true;
	}
	return false;
}

function loadSprint() {
	var sprintId = $j('#sprintList').val();
	var teamId = $j.cookie( 'last_team' );
	var personId = $j('#personList').val();
	var categoryName = $j('#categoryList').val();
	
	if( sprintId == '' ) {
		return;
	}

	// clear out the main
	$j('#main').empty();	
	
	showMsg( 'Loading...', 'The sprint is currently being loaded...', true );
	SprintWallController.getSprint( sprintId, teamId, personId, categoryName, loadedSprint );
}

function loadedSprint( result, event ) {
	if( event.status ) {
		
		// clear out our store of stories and tasks
		clearTaskData();
		
		if( result.Stories.length == 0 ) {
			$j('#main').append( '<p>There are no stories to display!</p>' ); 
		} else {
			var html = 
				'<table id="sprintWall"><thead><tr class="headerRow">' +
				'	<th class="controlCol"></th>' +
				'	<th class="storyCol">Story</th>' +
				'	<th id="notStartedH">Not Started</th>' +
				'	<th id="inProgressH">In Progress</th>' +
				'	<th id="completeH">Complete</th>' +
				'	<th id="blockedH">Blocked</th>' +
				'</tr></thead>';
		
			$j.each(result.Stories, function(index, story) {
				var notStarted = [];
				var inProgress = [];
				var complete = [];
				var blocked = [];
				
				$j.each(story.Tasks, function(index, task) {
					if( task.Status == 'Not Started' )
						notStarted.push( task );	
					else if( task.Status == 'In Progress' )
						inProgress.push( task );
					else if( task.Status == 'Completed' )
						complete.push( task );
					else if( task.Status == 'Blocked' )
						blocked.push( task );
						
					storeTaskData( task.StoryId, task.Id, task.Version );
				});
				
				var lists = '';
				lists = addTasksToList( notStarted, lists, 'notStarted', story );
				lists = addTasksToList( inProgress, lists, 'inProgress', story );
				lists = addTasksToList( complete, lists, 'complete', story );
				lists = addTasksToList( blocked, lists, 'blocked', story );
				
				html += '<tr class="contracted" id="' + story.Id + '"><td><a class="expandContract" href="" title="Expand"><img src="' + arrowOutImg + '" alt="" /></a></td><td><div class="story">' + getStoryMeta( story ) + '</div></td>' + lists + '</tr>';
			});
			
			html += '</table>';
			
			$j('#main').append( html );
			
			enableDragging();
			
			wireTaskViewButtonsUp();
			
			$j('#sprintWall').stickyTableHeaders();
			
			$j('.story .add a').click( addTask );
			
			$j('.expandContract').click( expandOrContract );
			
			// we may have refreshed - let's expand any stories that were expanded before we refreshed
			$j('#sprintWall tr').each(function(index) {
				if( isStoryExpanded( $j(this).attr('id') ) ) {
					$j(this).find('a.expandContract').click();
				}
			});
		}
	}
	else {
		showError( event.message );
	}
	
	hideMsg();
}

function clearTaskData() {
	$j('#db').removeData( 'taskState' );
}

function storeTaskData( storyId, taskId, taskVersion ) {
	var taskState = $j('#db').data( 'taskState' );
	if( taskState === undefined ) {
		taskState = [];
	}
	
	if( taskState[storyId] === undefined ) {
		taskState[storyId] = [];
	}
	
	taskState[storyId][taskId] = taskVersion;
	
	$j('#db').data( 'taskState', taskState );
}

function getSprintTaskData() {
	var taskState = $j('#db').data( 'taskState' );
	if( taskState === undefined ) {
		return undefined;
	}
	
	var stories = [];
	
	for( var storyId in taskState ) {
		if( storyId == "remove" ) {
			continue;
		}
		
		var story = { "Id" : storyId, "Tasks" : [] };
		
		for( var taskId in taskState[storyId] ) {
			if( taskId == "remove" ) {
				continue;
			}
			var version = taskState[storyId][taskId];
			if( version != "-1" ) {
				story.Tasks.push( { "Id" : taskId, "Version" : taskState[storyId][taskId] } );
			}
		}
		
		stories.push( story );
	}
	
	return stories;
}

function expandOrContract() {
	if( $j(this).attr('title') == 'Expand' ) {
		$j(this).attr('title', 'Contract' );
		$j(this).find('img').attr('src', arrowInImg );
		$j(this).parent().parent().removeClass( 'contracted' );
		storyExpanded( $j(this).parent().parent(), true ); 
	} else {
		$j(this).attr('title', 'Expand' );
		$j(this).find('img').attr('src', arrowOutImg );
		$j(this).parent().parent().addClass( 'contracted' );
		storyExpanded( $j(this).parent().parent(), false );
	}
	return false;
}

function storyExpanded( storyElement, expanded ) {
	// store the fact that we've expanded or contracted so we can remember when the filters refresh
	var state = $j('#db').data( 'storyState' );
	if( state === undefined ) {
		state = [];
	}
	
	state[storyElement.attr('id')] = expanded;
	
	$j('#db').data( 'storyState', state );
}

function isStoryExpanded( storyId ) {
	var state = $j('#db').data( 'storyState' );
	if( state !== undefined ) {
		if( state[storyId] === undefined ) {
			return false;
		}
		return state[storyId];
	}
}

function enableDragging() {
	$j('.statusList').sortable({
		revert: 0,
		connectWith: '.statusList',
		receive: function( event, ui ) {
			var sourceList = ui.sender;
			var destList = ui.item.parent();

			var sourceStoryId = sourceList.parent().attr('id');
			var destStoryId = destList.parent().attr('id');
			
			if( sourceStoryId != destStoryId ) {
				// we only let you move tasks within the same story - no story swapping for now
				$j(ui.sender).sortable('cancel');
				return;
			}
			
			// figure out the status class
			var newStatus = '';
			var classes = destList.attr('class').split(/\s+/);
			for(var i = 0; i < classes.length; i++) {
				var className = classes[i];
				if( className == 'notStarted' ) {
					newStatus = 'Not Started';
					break;
				}
				else if( className == 'inProgress' ) {
					newStatus = 'In Progress';
					break;
				}
				else if( className == 'complete' ) {
					newStatus = 'Completed';
					break;
				}
				else if( className == 'blocked' ) {
					newStatus = 'Blocked';
					break;
				}
			}
			
			// get the old status
			var oldClasses = sourceList.attr('class').split(/\s+/);
			var oldStatus = oldClasses[1];
			
			SprintWallController.changeTaskStatus( ui.item.attr('id'), newStatus, function(result, event) {
				if( event.status ) {
					// do nothing
				} else {
					// move the task back from whence it came
					$j(ui.sender).sortable('cancel');
					showError( event.message );
				}
			});
		}
	});
}

function addTask() {
	// set the data
	$j('#taskId').val( '' );
	$j('#taskTitle').val( '' );
	$j('#taskDesc').val( '' );
	$j('#taskEst').val( '' );
	$j('#taskRem').val( '' );
	$j('#taskCategory').val( '' ).change();
	$j('#taskOwner').val( '' );
	$j('#taskPriority').val( '' );
	$j('#taskStoryId').val( $j(this).parent().parent().parent().parent().attr('id') );
	
	// now spin up the dialog
	$j("#editTask").dialog({
		title: 'New Task',
		height: 375,
		width: 600,
		modal: true,
		draggable: true,
		resizable: false,
		buttons: [
		    {
		        text: "Create",
		        click: taskCreatedOk
		    },
		    {
		        text: "Cancel",
		        click: function() { $j(this).dialog("close"); }
		    }
		]
	});
	
	return false;
}

function taskCreatedOk() {
	showMsg( 'Loading...', 'Creating task...', true );
	
	if( $j('#taskEst').val() == '' ) {
		$j('#taskEst').val( 0 );
	}
	if( $j('#taskRem').val() == '' ) {
		$j('#taskRem').val( 0 );
	}
	
	SprintWallController.updateTask( 
		{
			"Id" : '',
			"Title" : $j('#taskTitle').val(),
			"Description" : $j('#taskDesc').val(),
			"Estimate" : $j('#taskEst').val(),
			"Remaining" : $j('#taskRem').val(),
			"Category" : $j('#taskCategory').val(),
			"OwnerId" : $j('#taskOwner').val(),
			"Priority" : $j('#taskPriority').val(),
			"StoryId" : $j('#taskStoryId').val()
		},
		function( result, event ) {
			if( event.status ) {
				var task = result;
				
				$j('#editTask').dialog("close");
				
				// now create the task based on what we got back
				$j('#' + task.StoryId + ' .notStarted').append( taskAll( task, task.StoryId ) );
				
				// and wire everything up
				enableDragging();
				wireTaskViewButtonsUp();
				
				// and store this task in our lookup to check for changes
				storeTaskData( task.StoryId, task.Id, task.Version );
			} else {
				showError( event.message );
			}
		});
	
	hideMsg();
}

function wireTaskViewButtonsUp() {
	$j('.task .edit a').click( function() {
		var taskId = $j(this).parent().parent().attr('id');
		showMsg( 'Loading...', 'The task is currently being loaded...', true );
		SprintWallController.getTaskForEdit( taskId, gotTaskForEdit );
		return false;
	});
	
	// todo: hook up column maximising
	/*$j('#sprintWall th').click( function() {
		if( $j(this).attr('id') == '' ) {
			
		}
	});*/
}

function gotTaskForEdit( result, event ) {
	if( event.status ) {
		var task = result;
		
		// set the data
		$j('#taskId').val( task.Id );
		$j('#taskTitle').val( task.Title );
		$j('#taskDesc').val( task.Description );
		$j('#taskEst').val( task.Estimate );
		$j('#taskRem').val( task.Remaining );
		$j('#taskCategory').val( task.Category ).change();
		$j('#taskOwner').val( task.OwnerId );
		$j('#taskPriority').val( task.Priority );
		$j('#taskStoryId').val( task.StoryId );
		$j('#taskVersion').val( task.Version );
		
		// now spin up the dialog
		$j("#editTask").dialog({
			title: 'Editing Task: ' + task.Name,
			height: 375,
			width: 600,
			modal: true,
			draggable: true,
			resizable: false,
			buttons: [
			    {
			        text: "Save",
			        click: taskEditedOk
			    },
			    {
			        text: "Cancel",
			        click: function() { $j(this).dialog("close"); }
			    }
			]
		});
		
	} else {
		showError( event.message );
	}
	
	hideMsg();
}

function taskEditedOk() {
	showMsg( 'Loading...', 'Saving task...', true );
	
	if( $j('#taskEst').val() == '' ) {
		$j('#taskEst').val( 0 );
	}
	if( $j('#taskRem').val() == '' ) {
		$j('#taskRem').val( 0 );
	}
	
	SprintWallController.updateTask( 
		{
			"Id" : $j('#taskId').val(),
			"Title" : $j('#taskTitle').val(),
			"Description" : $j('#taskDesc').val(),
			"Estimate" : $j('#taskEst').val(),
			"Remaining" : $j('#taskRem').val(),
			"Category" : $j('#taskCategory').val(),
			"OwnerId" : $j('#taskOwner').val(),
			"Priority" : $j('#taskPriority').val(),
			"Version" : $j('#taskVersion').val()
		},
		function( result, event ) {
			if( event.status ) {
				var task = result;
				$j('#editTask').dialog("close");
				
				// now update the task based on what we got back 
				updateTaskOnPage( task );
				wireTaskViewButtonsUp();
			} else {
				showError( event.message );
			}
		});
	
	hideMsg();
	return false;
}

function updateTaskOnPage( task ) {
	$j('#' + task.Id).html( taskContent( task, task.StoryId ) );
	$j('#' + task.Id).removeClass('development design qa analysis documentation nocategory bug').addClass(taskCategory(task));
	
	// check if the status has changed
	var status = taskStatus( task );
	var classes = $j('#' + task.Id).parent().attr('class').split(/\s+/);
	if( status != classes[1] ) {
		$j('#' + task.Id).appendTo( $j('#' + task.StoryId + ' .' + status) );
	}
	
	// update the task version in our local store
	storeTaskData( task.StoryId, task.Id, task.Version );
}

function getStoryMeta( story ) {
	var html = prop( 'number', story.StoryNumber );
	html += prop( 'name', story.Name );
	
	if( story.Theme !== undefined ) {
		html += prop( 'theme', story.Theme );
		if( story.ThemePriority !== undefined ) {
			html += prop( 'themepriority', story.ThemePriority );
		}
	}

	html += prop( 'team', story.Team );
	html += prop( 'pointsalloc', story.PointsAlloc );
	html += prop( 'view', '<a href="/' + story.Id + '" target="_blank" title="View"><img src="' + zoomImg + '" alt="" /></a>' );
	html += prop( 'add', '<a href="#" title="Add task"><img src="' + addImg + '" alt="" /></a>' );
	
	return html;
}

function prop( key, val ) {
	return '<div class="' + key + '">' + val + '</div>';
}

function addTasksToList( list, html, name, story ) {
	html += '<td class="statusList ' + name + '">';
	$j.each( list, function(index, task) {
		html += taskAll( task, story.Id );
	}); 
	
	html += '</td>';
	return html;
}

function taskAll( task, storyId ) {
	var html = '<div class="task ' + taskCategory( task ) + '" id="' + task.Id + '">';
	html += taskContent( task, storyId );
	html += '</div>';
	return html;
}

function taskCategory( task ) {
	if( task.Category == 'Development' ) {
		return 'development';
	} else if( task.Category == 'Design' ) {
		return 'design';
	} else if( task.Category == 'Analysis' ) {
		return 'analysis';
	} else if( task.Category == 'QA' ) {
		return 'qa';
	} else if( task.Category == 'Documentation' ) {
		return 'documentation';
	} else if( task.Category == 'Bug' ) {
		return 'bug';
	}
	
	return 'nocategory';
}

function taskStatus( task ) {
	if( task.Status == 'Not Started' )
		return 'notStarted';
	if( task.Status == 'In Progress' )
		return 'inProgress';
	if( task.Status == 'Completed' )
		return 'complete';
	if( task.Status == 'Blocked' )
		return 'blocked';
	return 'notStarted';
}

function taskContent( task, storyId ) {
	var html = prop( 'name', task.Name );
	html += prop( 'title', task.Title );
	
	if( task.Description !== undefined ) {
		html += prop( 'description', task.Description );
	}
	
	html += prop( 'taskStoryId', storyId );
	
	var owner = 'No owner';
	if( task.Owner !== undefined )
	{
		owner = task.Owner;
	}
	
	html += prop( 'ownerinfo', '<img src="' + userAddImg + '" alt="" />' + prop( 'owner', owner ) ); 
	html += prop( 'estimate', task.Estimate );
	html += prop( 'remaining', task.Remaining );
	html += prop( 'edit', '<a href="#" title="Edit"><img src="' + cogImg + '" alt="" /></a>' );
	html += prop( 'view', '<a href="/' + task.Id + '" target="_blank" title="View"><img src="' + zoomImg + '" alt="" /></a>' );
	
	return html;
}

function populateSprintList() {
	// get the project lists
	SprintWallController.getSprints( function(result, event) {
        if (event.status) {
        	// clear out the sprint list
        	$j('#sprintList').removeAttr( 'disabled' ).find('option').remove().end();
        	
        	if( result.length == 0 ) {
        		$j('#sprintList').append( '<option value="nowt">No Sprints</option>' ).attr( 'disabled', 'disabled' );
        	}
        	else {
				var canPrime = false;
				var primedSprintId = undefined;
				var match = location.search.match(new RegExp("[?&]"+'sprintId'+"=([^&]+)(&|$)"));
				if( match != null ) {
					primedSprintId = match[1];
				}
	
        		$j('#sprintList').append('<option value="" selected>Choose a sprint</option>');
        		$j.each(result, function(index, sprint) { 
            		$j('#sprintList').append('<option value="' + sprint.Id + '">' + sprint.Name + '</option>');
					if( primedSprintId !== undefined && sprint.Id.substring( 0, 15 ) == primedSprintId ) {
						// need to use the full long Id
						primedSprintId = sprint.Id;
						canPrime = true;
					}
            	});

				if( canPrime ) {
					$j('#sprintList').val( primedSprintId );
					$j('#sprintList').change();
				}
            }
        } else {
        	showError( event.message );
        }
    }, {escape:true});
}

function showMsg( title, msg, isBusy ) {
	if( isBusy ) msg = '<img style="vertical-align:middle;" src="/img/loading.gif" alt="" /> ' + msg;
	$j('#msg').attr( 'title', title ).html( '<p>' + msg + '</p>' ).dialog({
		autoOpen: true,
		height: 140,
		modal: true,
		draggable: false,
		resizable: false,
		closeOnEscape: false,
		open: function(event, ui) { $j(".ui-dialog-titlebar-close").hide(); }
	}).dialog( 'open' );
}

function hideMsg() {
	$j('#msg').dialog( 'close' );
}

function showError( err ) {
	$j("#error").attr( 'title', 'An error has occurred!' ).html( "<p>" + err + "</p>" ).dialog({
		height: 140,
		modal: true,
		draggable: false,
		resizable: false,
		open: function(event, ui) { $j(".ui-dialog-titlebar-close").show(); }
	});
}