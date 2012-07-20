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

public with sharing class AgileTaskMapper 
{
	public static List<sObject> getSprints()
	{
		return database.query( 
			'Select ' +
			'	Id, ' +
			'	Name ' +
			'From ' +
			'	Sprint__c ' +
			'Order by Name Desc ' );
	}
	
	public static sObject getTask( Id taskId )
	{
		List<sObject> tasks = database.query(
			'Select ' + 
			getAgileTaskQueryFields() +
			'From ' +
			'	Agile_Task__c ' +
			'Where ' +
			'	Id = :taskId ' );
				
		if( tasks.size() > 0 )
		{
			return tasks[0];
		}
		
		return null;
	}
	
	public static List<sObject> getTasksForStory( Set<Id> storyIds, String ownerId, String categoryName )
	{
		string query = 
			'Select ' +
			getAgileTaskQueryFields() +
			'From ' +
			'	Agile_Task__c ' +
			'Where ' +
			'	Story__c in :storyIds ';
			
		
		if( ownerId != '' && ownerId != null && ownerId != 'all' )
		{
			query += ' and Owner__c = :ownerId';
		}
		if( ownerId == '' || ownerId == null )
		{
			query += ' and Owner__c = null';
		}
		if( categoryName != 'All' && categoryName != '' && categoryName != null )
		{
			query += ' and Category__c = :categoryName';
		}
		if( categoryName == '' || categoryName == null )
		{
			query += ' and Category__c = null';
		}
		
		query +=
			' Order by ' +
			'	Priority__c, Name ASC';
		
		return database.query( query );
	}
	
	public static List<sObject> getStoriesAndTasks( Set<Id> storyIds )
	{
		List<sObject> stories = database.query(
			'Select ' + 
			'	Name, ' + 
			'	Id, ' +
			'	(Select ' +
			 getAgileTaskQueryFields() +
			'	From ' + 
			'		Agile_Tasks__r ' +
			'	Order by ' +
			'		Priority__c, Name ASC) ' + 
			'From ' + 
			'	Story__c where Id in :storyIds' );
			
		return stories; 
	}
	
	public static string getStoryFieldQuery()
	{
		return 
			'	Id, ' + 
			'	Name, ' + 
			'	Description__c, ' +
			'	Story_Number__c, ' +
			'	Team__c, ' +
			'	Team__r.Name, ' +
			'	StoryPointsAllocation__c, ' +
			'	Sprint__c, ' +
			'	Story_Status__c, ' +
			'	Theme__c, ' +
			'	Theme__r.Name, ' +
			'	ThemePriority__c ';
	}
	
	private static string getAgileTaskQueryFields()
	{
		return
			'	Title__c, ' + 
			'	Story__c, ' + 
			'	Status__c, ' + 
			'	Remaining_Hrs__c, ' + 
			'	Priority__c, ' + 
			'	Name, ' + 
			'	Id, ' + 
			'	Estimated_Hrs__c, ' + 
			'	Description__c, ' +
			'	Owner__c, ' +
			'	Owner_Name__c, ' +
			'	Category__c, ' +
			'	Version__c ';
	}
}