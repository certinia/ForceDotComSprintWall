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
private class AgileTaskTriggerTest 
{
	static testMethod void TestAgileTaskTrigger()
	{
		Team__c team = new Team__c( Name = 'JDHGSAJDHGASJDHG' );
		insert team;
		
		Sprint__c sprint = new Sprint__c( Name = 'KASJDKJSDHKAJDH' );
		insert sprint;
		
		List<Story__c> stories = new List<Story__c>{ 
			new Story__c( 
				StoryID__c = 123456788,
				Sprint__c = sprint.Id,
				Team__c = team.Id,
				StoryPointsAllocation__c = 10,
				Name = 'ASDAS Test Story 1' ),
			new Story__c( 
				StoryID__c = 123456789,
				Sprint__c = sprint.Id,
				Team__c = team.Id,
				StoryPointsAllocation__c = 20,
				Name = 'ASDAS Test Story 2' )
		};
			
		insert stories;
		
		Agile_Task__c task = new Agile_Task__c(
			Title__c = 'My Test Task',
			Description__c = 'This is a test description',
			Story__c = stories[0].Id );
			
		insert task;
		
		task.Estimated_Hrs__c = 10;
		task.Remaining_Hrs__c = 10;
		update task;
		
		task.Estimated_Hrs__c = 20;
		task.Remaining_Hrs__c = 20;
		update task;
	}
}