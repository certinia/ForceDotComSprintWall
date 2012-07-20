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

@isTest
private class SprintControllerTests 
{
	static testMethod void TestSprintWallController1()
	{
		List<sObject> testStories = setupTestData();
		
		Schema.SObjectType taskType = Schema.getGlobalDescribe().get( 'Agile_Task__c' );
        sObject task = taskType.newSObject();
		
		task.put( 'Title__c', 'My Test Task' );
		task.put( 'Description__c', 'This is a test description' );
		task.put( 'Story__c', testStories[0].Id );
			
		insert task;
		
		Test.startTest();
		
		List<AgileTaskHelper.Sprint> sprints = SprintWallController.getSprints();
		system.assert( sprints.size() > 0 );
		
		AgileTaskHelper.Sprint sprint = SprintWallController.getSprint( (Id)testStories[0].get( 'Sprint__c' ), 'Loading...', 'Loading...', 'All' );
		
		String taskId = SprintWallController.changeTaskStatus( task.Id, 'Blocked' );
		sObject task1 = database.query( 'Select Id,Status__c from Agile_Task__c where Id = :taskId' );
		system.assert( (String)task1.get( 'Status__c' ) == 'Blocked' );
		
		taskId = SprintWallController.changeTaskStatus( task.Id, 'In Progress' );
		sObject task2 = database.query( 'Select Id,Status__c from Agile_Task__c where Id = :taskId' );
		system.assert( (String)task2.get( 'Status__c' ) == 'In Progress' );
		
		AgileTaskHelper.AgileTask aTask = SprintWallController.getTaskForEdit( task.Id );
		
		aTask.Description = 'Hello kitty';
		SprintWallController.updateTask( aTask );
		sObject task3 = database.query( 'Select Id,Description__c from Agile_Task__c where Id = :taskId' );
		system.assert( (String)task3.get( 'Description__c' ) == 'Hello kitty' );
		
		List<AgileTaskHelper.Person> people = SprintWallController.getPeople();
		system.assert( people.size() > 0 );
		
		Test.stopTest();
	}
	
	static testMethod void TestSprintWallController2()
	{
		List<sObject> testStories = setupTestData();
		
		Schema.SObjectType taskType = Schema.getGlobalDescribe().get( 'Agile_Task__c' );
        sObject t1 = taskType.newSObject();
        sObject t2 = taskType.newSObject();
        
        t1.put( 'Title__c', 'My Test Task' );
		t1.put( 'Description__c', 'This is a test description' );
		t1.put( 'Story__c', testStories[0].Id );
		
		t2.put( 'Title__c', 'My Test Task' );
		t2.put( 'Description__c', 'This is a test description' );
		t2.put( 'Story__c', testStories[0].Id );
		
		insert t1;
		insert t2;
			
		Id t1Id = t1.Id;
		sObject task = database.query( 'Select Id,Name,Title__c,Description__c,Story__c,Version__c from Agile_Task__c where Id = :t1Id ');
		AgileTaskHelper.Sprint sprint = SprintWallController.getSprint( (Id)testStories[0].get( 'Sprint__c' ), 'Loading...', 'Loading...', 'All' );
			
		Test.startTest();
		
		List<AgileTaskHelper.Team> teams = SprintWallController.getTeams();
		system.assert( teams.size() > 0 );
		
		AgileTaskHelper.StorySummary summary = new AgileTaskHelper.StorySummary();
		summary.Id = testStories[0].Id;
		summary.Tasks = new List<AgileTaskHelper.TaskSummary>();
		
		AgileTaskHelper.TaskSummary taskSum1 = new AgileTaskHelper.TaskSummary();
		taskSum1.Id = task.Id;
		taskSum1.Version = string.valueOf( (Decimal)task.get( 'Version__c' ) );
		summary.Tasks.add( taskSum1 );
		
		List<AgileTaskHelper.AgileTask> changes = SprintWallController.getChanges( 
			'all', 
			'All', 
			new List<AgileTaskHelper.StorySummary> { summary } );
			
		system.assert( changes.size() > 0 );
		
		Test.stopTest();
	}
	
	static testMethod void TestAgileTaskHandler()
	{
		List<sObject> stories = setupTestData();
		
		Schema.SObjectType taskType = Schema.getGlobalDescribe().get( 'Agile_Task__c' );
        sObject task = taskType.newSObject();
		
		task.put( 'Title__c', 'My Test Task' );
		task.put( 'Description__c', 'This is a test description' );
		task.put( 'Story__c', stories[0].Id );
			
		insert task;
		
		task.put( 'Estimated_Hrs__c', 10 );
		task.put( 'Remaining_Hrs__c', 10 );
		update task;
		
		task.put( 'Estimated_Hrs__c', 20 );
		task.put( 'Remaining_Hrs__c', 20 );
		update task;
	}
	
	private static List<sObject> setupTestData()
	{
		Schema.SObjectType teamType = Schema.getGlobalDescribe().get( 'Team__c' );
        sObject team = teamType.newSObject();
        
        team.put( 'Name', 'JDHGSAJDHGASJDHG' );
		insert team;
		
		Schema.SObjectType sprintType = Schema.getGlobalDescribe().get( 'Sprint__c' );
        sObject sprint = sprintType.newSObject();
        sprint.put( 'Name', 'KASJDKJSDHKAJDH' );
		insert sprint;
		
		Schema.SObjectType storyType = Schema.getGlobalDescribe().get( 'Story__C' );
        sObject story1 = storyType.newSObject();
        sObject story2 = storyType.newSObject();
        
        story1.put( 'StoryID__c', 123456788 );
		story1.put( 'Sprint__c', sprint.Id );
		story1.put( 'Team__c', team.Id );
		story1.put( 'StoryPointsAllocation__c', 10 );
		story1.put( 'Name', 'ASDAS Test Story 1' );
		
		story2.put( 'StoryID__c', 123456789 );
		story2.put( 'Sprint__c', sprint.Id );
		story2.put( 'Team__c', team.Id );
		story2.put( 'StoryPointsAllocation__c', 20 );
		story2.put( 'Name', 'ASDAS Test Story 2' );
		
		List<sObject> stories = new List<sObject>{ story1, story2 };
		insert stories;
		
		Set<Id> storyIds = new Set<Id>();
		for( sObject story : stories )
		{
			storyIds.add( story.Id );
		}
		
		// query back for the stories with their respective lookups
		return database.query( 
			'Select ' +
			'	Id, ' +
			'	Name, ' +
			'	Sprint__c, ' +
			'	Team__c ' +
			'From ' +
			'	Story__c ' +
			'Where ' +
			'	Id in :storyIds' );
	}
}