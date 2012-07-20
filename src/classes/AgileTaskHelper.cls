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

global class AgileTaskHelper 
{
	// Classes used via Javascript remoting - you could call them ViewModels if you were a Microsoft guy
	
	global class AgileTask 
	{
		public string Id { get; set; }
		public string Name { get; set; }
		public string Title { get; set; }
		public string Description { get; set; }
		public string Status { get; set; }
		public string Priority { get; set; }
		public Decimal Estimate { get; set; }
		public Decimal Remaining { get; set; }
		public string Owner { get; set; }
		public string OwnerId { get; set; }
		public string Category { get; set; }
		public string StoryId { get; set; }
		public string Version { get; set; }
		public string ChangeAction { get; set; }
	}
	
	global class Story 
	{
		public Story()
		{
			Tasks = new List<AgileTask>();
		}
		
		public string Id { get; set; }
		public string Name { get; set; }
		public string StoryNumber { get; set; }
		public string Description { get; set; }
		public string Team { get; set; }
		public string TeamId { get; set; }
		public Decimal PointsAlloc { get; set; }
		public string SprintId { get; set; }
		public string StoryStatus { get; set; }
		public string Theme { get; set; }
		public string ThemePriority { get; set; }
		
		public List<AgileTask> Tasks { get; set; }
	}
	
	global class Sprint 
	{
		public Sprint( String id, String name )
		{
			this.Id = id;
			this.Name = name;
			init();
		}
		
		public Sprint()
		{
			init();
		}
		
		private void init()
		{
			this.Stories = new List<Story>();
		}
		
		public string Id { get; set; }
		public string Name { get; set; }
		public Decimal AllocationTotal { get; set; }
		public List<Story> Stories { get; set; }
	}
	
	global class Person
	{
		public string Id;
		public string Name;
	}
	
	global class Team
	{
		public string Id;
		public string Name;
	}
	
	global class StorySummary
	{
		public string Id { get; set; }
		public List<TaskSummary> Tasks { get; set; }
	}
	
	global class TaskSummary
	{
		public string Id { get; set; }
		public string Version { get; set; }
	}
	
	// helper methods to convert SObjects to our lightweight JSON classes
	
	public static AgileTask agileTaskFromSObject( sObject s, boolean truncateDescription )
	{
		AgileTask task = new AgileTask();
		task.Id = s.Id;
		task.Name = (string)s.get( 'Name' );
		task.Title = (string)s.get( 'Title__c' );
		
		if( truncateDescription && 
			getVal( s, 'Description__c' ) != null && 
			getVal( s, 'Description__c' ).length() > 100 )
		{
			task.Description = getVal( s, 'Description__c' ).subString( 0, 100 ) + '...';
		}
		else
		{
			task.Description = getVal( s, 'Description__c' );
		}
		
		task.Status = (string)s.get( 'Status__c' );
		if( task.Status == '' || task.Status == null || task.Status == 'Planned' )
		{
			// default to not started
			task.Status = 'Not Started';
		}
		
		task.Priority = (string)s.get( 'Priority__c' );
		task.Estimate = (Decimal)s.get( 'Estimated_Hrs__c' );
		task.Remaining = (Decimal)s.get( 'Remaining_Hrs__c' );
		
		if( task.Estimate == null )
		{
			task.Estimate = 0;
		}
		if( task.Remaining == null )
		{
			task.Remaining = 0;
		}
		
		task.Category = (string)s.get( 'Category__c' );
		task.StoryId = (string)s.get( 'Story__c' );
		if( (Decimal)s.get( 'Version__c' ) == null )
		{
			task.Version = '1';
		}
		else
		{
			Decimal version = (Decimal)s.get( 'Version__c' );
			task.Version = string.valueOf( (Integer)version );
		}
		
		if( (id)s.get( 'Owner__c' ) != null )
		{
			task.OwnerId = (string)s.get( 'Owner__c' );
			task.Owner = (string)s.get( 'Owner_Name__c' );
		}
		return task;
	}
	
	public static Story storyFromSObject( sObject s )
	{
		Story story = new Story();
		story.Id = s.Id;
		story.Name = (string)s.get( 'Name' );
		story.Description = (string)s.get( 'Description__c' );
		story.StoryNumber = (string)s.get( 'Story_Number__c' );
		story.Team = (string)s.getSObject( 'Team__r' ).get( 'Name' );
		story.TeamId = (string)s.get( 'Team__c' );
		story.PointsAlloc = (Decimal)s.get( 'StoryPointsAllocation__c' );
		story.SprintId = (string)s.get( 'Sprint__c' );
		story.StoryStatus = (string)s.get( 'Story_Status__c' );
		story.ThemePriority = string.valueOf( s.get( 'ThemePriority__c' ) );
		
		if( (Id)s.get( 'Theme__c' ) != null )
		{
			story.Theme = (string)s.getSObject( 'Theme__r' ).get( 'Name' );
		}
		
		return story;
	}
	
	public static Sprint sprintFromSObject( sObject s, boolean headerOnly )
	{
		Sprint sprint = new Sprint();
		sprint.Id = s.Id;
		sprint.Name = getVal( s, 'Name' );
		
		if( !headerOnly )
		{
			sprint.Stories = new List<Story>();
			if( s.getSObjects( 'Stories__r' ) != null )
			{
				for( sObject st : s.getSObjects( 'Stories__r' ) )
				{
					Story story = storyFromSObject( st );
					sprint.Stories.add( story );
				}
			}
		}
		
		return sprint;
	}
	
	public static Person personFromSObject( User u )
	{
		Person p = new Person();
		p.Id = u.Id;
		p.Name = u.Name;
		return p;
	}
	
	public static Team teamFromSObject( sObject s )
	{
		Team team = new Team();
		team.Id = s.Id;
		team.Name = (string)s.get( 'Name' );
		return team;
	}
	
	private static string getVal( sObject s, string name )
	{
		return (string)s.get( name );
	}
	
	private static Decimal getDVal( sObject s, string name )
	{
		return (Decimal)s.get( name );
	}
	
	public static boolean hasTaskChanged( sObject oldTask, sObject newTask )
	{
		if( getVal( oldTask, 'Category__c' ) != getVal( newTask, 'Category__c' ) ||
			getDVal( oldTask, 'Estimated_Hrs__c' ) != getDVal( newTask, 'Estimated_Hrs__c' ) ||
			getVal( oldTask, 'Owner__c' ) != getVal( newTask, 'Owner__c' ) ||
			getVal( oldTask, 'Priority__c' ) != getVal( newTask, 'Priority__c' ) ||
			getDVal( oldTask, 'Remaining_Hrs__c' ) != getDVal( newTask, 'Remaining_Hrs__c' ) ||
			getVal( oldTask, 'Status__c' ) != getVal( newTask, 'Status__c' ) )
		{
			return true;
		}
		
		if( areStringsUnequal( getVal( oldTask, 'Description__c' ), getVal( newTask, 'Description__c' ) ) ||
			areStringsUnequal( getVal( oldTask, 'Title__c' ), getVal( newTask, 'Title__c' ) ) )
		{
			return true;
		}
		
		return false;
	}
	
	public static boolean excludeBasedOnFilter( sObject task, String ownerId, String categoryName )
	{
		if( ownerId != '' && ownerId != null && ownerId != 'all' )
		{
			// specific owner set
			if( getVal( task, 'Owner__c' ) != ownerId )
			{
				return true;
			}
		}
		if( ownerId == '' || ownerId == null )
		{
			// showing tasks with no owner
			if( getVal( task, 'Owner__c' ) != null )
			{
				return true;
			}
		}
		if( categoryName != 'All' && categoryName != '' && categoryName != null )
		{
			if( getVal( task, 'Category__c' ) != categoryName )
			{
				return true;
			}
		}
		if( categoryName == '' || categoryName == null )
		{
			if( getVal( task, 'Category__c' ) != null )
			{
				return true;
			}
		}
		
		return false;
	}
	
	private static boolean areStringsUnequal( String s, String t )
	{
		// null comparisons
		if( ( s == null && t != null ) || ( s != null && t == null ) )
		{
			return true;
		}
		if( s == null && t == null )
		{
			return false;
		}
		
		return !s.equals( t );
	}
}