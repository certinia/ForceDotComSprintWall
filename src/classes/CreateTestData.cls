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

public with sharing class CreateTestData 
{
	public static void CleanAndCreateData()
	{
		// use this method to empty out team / sprint / task data and create new data for playing / testing
		
		// remove everything
		delete [Select Id from Theme__c];
		delete [Select Id from Team__c];
		delete [Select Id from Sprint__c];
		delete [Select Id from Story__c];
		delete [Select Id from Agile_Task__c];
		
		// and now create a bunch of random data
		Theme__c theme = new Theme__c( Name = 'Reporting', Description__c = 'This is a description' );
		insert theme;
		
		Team__c team1 = new Team__c( Name = 'J1' );
		Team__c team2 = new Team__c( Name = 'J2' );
		insert new List<Team__c>{ team1, team2 };
		
		Sprint__c sprint1 = new Sprint__c( Name = 'Sprint 666', Current_Sprint__c = true );
		Sprint__c sprint2 = new Sprint__c( Name = 'Sprint 667' );
		insert new List<Sprint__c>{ sprint1, sprint2 };
		
		Story__c story1 = new Story__c( 
			Name = 'The never ending story', 
			Sprint__c = sprint1.Id, 
			Theme__c = theme.Id, 
			Team__c = team1.Id,
			ThemePriority__c = 1, 
			StoryID__c = 1234, 
			StoryPointsAllocation__c = 17 );
			
		Story__c story2 = new Story__c( 
			Name = 'Another long running story', 
			Sprint__c = sprint1.Id, 
			Theme__c = theme.Id, 
			Team__c = team2.Id,
			ThemePriority__c = 2, 
			StoryID__c = 1235, 
			StoryPointsAllocation__c = 21 );
			
		insert new List<Story__c>{ story1, story2 };
		
		insert new List<Agile_Task__c>
		{
			new Agile_Task__c( Title__c = 'This is a test task', Description__c = 'And a test description', Category__c = 'Design', Status__c = 'Not Started', Estimated_Hrs__c = 10, Remaining_Hrs__c = 10, Story__c = story1.Id ),
			new Agile_Task__c( Title__c = 'This is another test task', Description__c = 'And a test description', Category__c = 'Analysis', Status__c = 'Not Started', Estimated_Hrs__c = 10, Remaining_Hrs__c = 10, Story__c = story1.Id ),
			new Agile_Task__c( Title__c = 'This is yet another test task', Description__c = 'And a test description', Category__c = 'Development	', Status__c = 'In Progress', Estimated_Hrs__c = 10, Remaining_Hrs__c = 10, Story__c = story1.Id ),
			new Agile_Task__c( Title__c = 'This is a test task', Description__c = 'And a test description', Category__c = 'QA', Status__c = 'Blocked', Estimated_Hrs__c = 10, Remaining_Hrs__c = 10, Story__c = story1.Id ),
			new Agile_Task__c( Title__c = 'This is a test task', Description__c = 'And a test description', Category__c = 'Documentation', Status__c = 'Completed', Estimated_Hrs__c = 10, Remaining_Hrs__c = 10, Story__c = story1.Id ),
			new Agile_Task__c( Title__c = 'This is a test task', Description__c = 'And a test description', Category__c = 'Bug', Status__c = 'In Progress', Estimated_Hrs__c = 10, Remaining_Hrs__c = 10, Story__c = story1.Id ),
			new Agile_Task__c( Title__c = 'This is a test task', Description__c = 'And a test description', Category__c = '', Status__c = 'Not Started', Estimated_Hrs__c = 10, Remaining_Hrs__c = 10, Story__c = story1.Id ),
			new Agile_Task__c( Title__c = 'This is a test task', Description__c = 'And a test description', Category__c = 'Design', Status__c = 'Not Started', Estimated_Hrs__c = 10, Remaining_Hrs__c = 10, Story__c = story1.Id ),
			new Agile_Task__c( Title__c = 'This is a test task', Description__c = 'And a test description', Category__c = 'Design', Status__c = 'Not Started', Estimated_Hrs__c = 10, Remaining_Hrs__c = 10, Story__c = story1.Id ),
			new Agile_Task__c( Title__c = 'This is a test task', Description__c = 'And a test description', Category__c = 'Design', Status__c = 'Not Started', Estimated_Hrs__c = 10, Remaining_Hrs__c = 10, Story__c = story1.Id )
			
		};
	}
}