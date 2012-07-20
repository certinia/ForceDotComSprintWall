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

public with sharing class SprintWallController 
{
	@RemoteAction
	public static List<AgileTaskHelper.Sprint> getSprints()
	{
		List<AgileTaskHelper.Sprint> sprints = new List<AgileTaskHelper.Sprint>();
		
		for( sObject sprint : AgileTaskMapper.getSprints() )
		{
			sprints.add( AgileTaskHelper.sprintFromSObject( sprint, true ) );
		}
		
		return sprints;
	}
	
	@RemoteAction
	public static AgileTaskHelper.Sprint getSprint( String sprintId, String teamId, String personId, String categoryName ) 
	{
		// deal with getting the sprint while the data is still loading
		if( teamId == 'Loading...' )
			teamId = '';
		if( personId == 'Loading...' )
			personId = 'all';
		
		// carry on
		String teamQuery = '';
		if( teamId != '' && teamId != null )
		{
			teamQuery = ' Where Team__c = :teamId ';
		}
		
		String query =
			'Select ' + 
			'	Name, ' + 
			'	Id, ' + 
			'	(Select ' + 
			AgileTaskMapper.getStoryFieldQuery() +
			'	From ' + 
			'		Stories__r ' +
				teamQuery +
			'	Order By ' +
			'		Theme__r.Name, ThemePriority__c, Story_Priority__c, Story_Number__c, Name Asc) ' + 
			'From ' +
			'	Sprint__c ' + 
			'Where ' +
			'	Id = :sprintId ';

		// query for the sprint and stories
		List<sObject> sprints = database.query( query );		
				
		if( sprints.size() == 0 ) {
			throw new AppException( 'Unable to find the selected sprint. Sorry about that.' );
		}
		
		AgileTaskHelper.Sprint fullSprint = AgileTaskHelper.sprintFromSObject( sprints[0], false );
		
		if( ALM_Settings__c.getInstance() != null && ALM_Settings__c.getInstance().Max_Stories_On_Sprint_Wall__c != null )
		{
			Decimal maxStories = ALM_Settings__c.getInstance().Max_Stories_On_Sprint_Wall__c;
			if( maxStories > 0 && fullSprint.Stories.size() > maxStories )
			{
				throw new AppException( 'There are too many stories to display. Please choose a specific team to reduce the stories returned or get John to implement infinite scrolling.' );
			}
		}
		
		// add the stories to the sprint and prepare the task map
		Map<Id,List<AgileTaskHelper.AgileTask>> storyIdToTaskIds = new Map<Id,List<AgileTaskHelper.AgileTask>>();
		for( AgileTaskHelper.Story st : fullSprint.Stories )
		{
			storyIdToTaskIds.put( st.Id, new List<AgileTaskHelper.AgileTask>() );
		}
		
		// query for all the tasks and populate the story to task map
		for( sObject t : AgileTaskMapper.getTasksForStory( storyIdToTaskIds.keySet(), personId, categoryName ) )
		{
			AgileTaskHelper.AgileTask task = AgileTaskHelper.agileTaskFromSObject( t, true );
			storyIdToTaskIds.get( (string)t.get( 'Story__c' ) ).add( task );
		}
		
		// lovely, now add the tasks to the stories and we're all good
		for( AgileTaskHelper.Story st : fullSprint.Stories )
		{
			if( storyIdToTaskIds.containsKey( st.Id ) )
			{
				st.Tasks.addAll( storyIdToTaskIds.get( st.Id ) );
			}
		}
	
		return fullSprint;
	}
	
	@RemoteAction
	public static String changeTaskStatus( string taskId, string status )
	{
		List<sObject> tasks = database.query( 'Select Id,Status__c from Agile_Task__c where Id = :taskId' );
		if( tasks.size() == 0 )
		{
			throw new AppException( 'Unable to find the specified task' );
		}
		
		tasks[0].put( 'Status__c', status );
		update tasks[0];
		
		return taskId;
	}
	
	@RemoteAction
	public static AgileTaskHelper.AgileTask getTaskForEdit( string taskId )
	{
		sObject task = AgileTaskMapper.getTask( taskId );
		if( task == null )
		{
			throw new AppException( 'Unable to find the specificed task' );
		}
		
		return AgileTaskHelper.agileTaskFromSObject( task, false );
	}
	
	@RemoteAction
	public static AgileTaskHelper.AgileTask updateTask( AgileTaskHelper.AgileTask updatedTask )
	{
		Schema.SObjectType taskType = Schema.getGlobalDescribe().get( 'Agile_Task__c' );
        sObject task = taskType.newSObject();
		
		if( updatedTask.Id != null && updatedTask.Id != '' )
		{
			// it's an update
			task = AgileTaskMapper.getTask( updatedTask.Id );
			if( task == null )
			{
				throw new AppException( 'Unable to find the specificed task in the database' );
			}
			
			string version = string.valueOf( task.get( 'Version__c' ) );
			if( version == null )
			{
				version = '1';
			}
			
			if( version != updatedTask.Version )
			{
				throw new AppException( 'Someone else has already updated this task while you were making changes. I\'m afraid they won and you will have to cancel and try again.' );
			}
		}
		else
		{
			task.put( 'Story__c', updatedTask.StoryId );
		}
		
		task.put( 'Title__c', updatedTask.Title );
		task.put( 'Description__c', updatedTask.Description );
		task.put( 'Estimated_Hrs__c', updatedTask.Estimate );
		task.put( 'Remaining_Hrs__c', updatedTask.Remaining );
		task.put( 'Category__c', updatedTask.Category );
		task.put( 'Priority__c', updatedTask.Priority );
		
		if( updatedTask.OwnerId == '' )
		{
			task.put( 'Owner__c', null );
		}
		else
		{
			task.put( 'Owner__c', updatedTask.OwnerId );
		}
		
		upsert task;
		
		// send it back so the UI can update
		return AgileTaskHelper.agileTaskFromSObject( AgileTaskMapper.getTask( task.Id ), true );
	}
	
	@RemoteAction
	public static List<AgileTaskHelper.Person> getPeople()
	{
		List<AgileTaskHelper.Person> people = new List<AgileTaskHelper.Person>();
		
		for( User u : 
				[Select 
					Id,
					Name 
				From
					User
				Where
					IsActive = true and
					// either standard users or the right kind of developer portal profile users
					( UserType = 'Standard' or ( UserType = 'CSPLitePortal' and Profile.Name = 'Developer Portal Profile' ) )
				Order by
					Name Asc] )
		{
			people.add( AgileTaskHelper.personFromSObject( u ) );
		}
		
		return people;
	}
	
	@RemoteAction
	public static List<AgileTaskHelper.Team> getTeams()
	{
		List<AgileTaskHelper.Team> teams = new List<AgileTaskHelper.Team>();
		
		for( sObject team : database.query( 'Select Id,Name from Team__c Order By Name Asc' ) )
		{
			teams.add( AgileTaskHelper.teamFromSObject( team ) );
		}
		
		return teams;
	}
	
	@RemoteAction
	public static List<AgileTaskHelper.AgileTask> getChanges( String ownerId, String categoryName, List<AgileTaskHelper.StorySummary> storiesSummaries )
	{
		List<AgileTaskHelper.AgileTask> updatedTasks = new List<AgileTaskHelper.AgileTask>();
		
		Set<Id> storyIds = new Set<Id>();
		for( AgileTaskHelper.StorySummary story : storiesSummaries )
		{
			storyIds.add( story.Id );
		}
		
		List<sObject> stories = AgileTaskMapper.getStoriesAndTasks( storyIds );
		Map<Id,sObject> storyMap = new Map<Id,sObject>();
		for( sObject story : stories )
		{
			storyMap.put( story.Id, story );
		}
		
		for( AgileTaskHelper.StorySummary storySummary : storiesSummaries )
		{
			sObject story = storyMap.get( storySummary.Id );
			Map<Id,sObject> taskMap = new Map<Id,sObject>();
			Set<Id> taskIds = new Set<Id>();
			for( sObject task : story.getSObjects( 'Agile_Tasks__r' ) )
			{
				taskIds.add( task.Id );
				taskMap.put( task.Id, task );
			}
			
			for( AgileTaskHelper.TaskSummary taskSummary : storySummary.Tasks )
			{
				// task deleted or now excluded?
				if( !taskMap.containsKey( taskSummary.Id ) || AgileTaskHelper.excludeBasedOnFilter( taskMap.get( taskSummary.Id ), ownerId, categoryName ) )
				{
					AgileTaskHelper.AgileTask agileTask = new AgileTaskHelper.AgileTask();
					agileTask.Id = taskSummary.Id;
					agileTask.StoryId = storySummary.Id;
					agileTask.ChangeAction = 'd';
					updatedTasks.add( agileTask );
				}
				else
				{
					// task has been updated?
					String version = string.valueOf( taskMap.get( taskSummary.Id ).get( 'Version__c' ) );
					if( version == null )
					{
						// old data - assume version 1
						version = '1';
					}
					 
					if( version != taskSummary.Version )
					{
						AgileTaskHelper.AgileTask agileTask = AgileTaskHelper.agileTaskFromSObject( taskMap.get( taskSummary.Id ), true );
						agileTask.ChangeAction = 'c';
						updatedTasks.add( agileTask );
					}
				}
				
				// mark it as processed
				taskIds.remove( taskSummary.Id );
			}
			
			// any new tasks left over?
			for( Id taskId : taskIds )
			{
				// firstly make sure the task isn't ignored as part of a filter
				sObject task = taskMap.get( taskId );
				if( AgileTaskHelper.excludeBasedOnFilter( task, ownerId, categoryName ) )
				{
					continue;
				}
				
				AgileTaskHelper.AgileTask agileTask = AgileTaskHelper.agileTaskFromSObject( taskMap.get( taskId ), true );
				agileTask.ChangeAction = 'a';
				updatedTasks.add( agileTask );
			}
		}
		
		return updatedTasks;
	}
}