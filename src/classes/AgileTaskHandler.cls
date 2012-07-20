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

global class AgileTaskHandler 
{
	global static void handleTrigger()
	{
		if( trigger.isBefore && trigger.isUpdate )
		{
			handleBeforeUpdate( trigger.oldMap, trigger.new );
		}
		
		if( trigger.isAfter && trigger.isUpdate )
		{
			handleAfterUpdate( trigger.oldMap, trigger.new );
		}
		
		if( trigger.isBefore && trigger.isInsert )
		{
			handleBeforeInsert( trigger.new );
		}
		
		if( trigger.isAfter && trigger.isInsert )
		{
			handleAfterInsert( trigger.new );
		}
	}
	
	public static boolean historyTrackingDisabled()
	{
		if( ALM_Settings__c.getInstance() != null && ALM_Settings__c.getInstance().Disable_Agile_Task_History_Tracking__c != null )
		{
			if( ALM_Settings__c.getInstance().Disable_Agile_Task_History_Tracking__c )
			{
				return true;
			}
		}
		
		return false;
	}
	
	public static void handleBeforeUpdate( Map<Id,sObject> oldTaskMap, List<sObject> newTasks )
	{
		zeroNulls( newTasks );
		
		for( sObject task : newTasks ) 
		{
			if( AgileTaskHelper.hasTaskChanged( task, oldTaskMap.get( task.Id ) ) )
			{
				Decimal version = (Decimal)task.get( 'Version__c' );
				if( version == null )
				{
					// must be some old data, pretend it was at 1
					version = 1;
				}

				task.put( 'Version__c', version + 1 );
			}
		}
	}
	
	public static void handleBeforeInsert( List<sObject> newTasks )
	{
		zeroNulls( newTasks );
	}
	
	private static void zeroNulls( List<sObject> tasks )
	{
		for( sObject task : tasks )
		{
			Decimal est = (Decimal)task.get( 'Estimated_Hrs__c' );
			Decimal rem = (Decimal)task.get( 'Remaining_Hrs__c' );
			if( est == null )
			{
				task.put( 'Estimated_Hrs__c', 0 );
			}
			if( rem == null )
			{
				task.put( 'Remaining_Hrs__c', 0 );
			}
		}
	}
	
	public static void handleAfterInsert( List<sObject> newTasks )
	{
		if( historyTrackingDisabled() )
		{
			return;
		}
		
		Date thisDay = system.today();
		List<sObject> histories = new List<sObject>();
		List<sObject> remainings = new List<sObject>();
		
		for( sObject task : newTasks )
		{
			Schema.SObjectType hrsHistType = Schema.getGlobalDescribe().get( 'Agile_Task_Hours_History__c' );
        	sObject hist = hrsHistType.newSObject();
			
			hist.put( 'Old_Value__c', (Decimal)task.get( 'Estimated_Hrs__c' ) == null ? 0 : (Decimal)task.get( 'Estimated_Hrs__c' ) );
			hist.put( 'New_Value__c', (Decimal)hist.get( 'Old_Value__c' ) );
			hist.put( 'Change_in_Value__c', 0 );
			hist.put( 'Change_Date__c', thisDay );
			hist.put( 'Agile_Task__c', task.Id );
			histories.add( hist );
			
			Schema.SObjectType hrsRemType = Schema.getGlobalDescribe().get( 'Agile_Task_Hours_Remaining_History__c' );
        	sObject rem = hrsRemType.newSObject();
			
			rem.put( 'Old_Value__c', (Decimal)task.get( 'Remaining_Hrs__c' ) == null ? 0 : (Decimal)task.get( 'Remaining_Hrs__c' ) ); 
			rem.put( 'New_Value__c', (Decimal)rem.get( 'Old_Value__c' ) );
			rem.put( 'Change_in_Value__c', 0 );
			rem.put( 'Change_Date__c', thisDay );
			rem.put( 'Agile_Task__c', task.Id );
			remainings.add( rem );
		}
		
		if( histories.size() > 0 )
		{
			insert histories;
		}
		if( remainings.size() > 0 )
		{
			insert remainings;
		}
	}
	
	public static void handleAfterUpdate( Map<Id,sObject> oldTaskMap, List<sObject> newTasks )
	{
		if( historyTrackingDisabled() )
		{
			return;
		}
		
		Date thisDay = system.today();
		
		Set<Id> changedTaskIds = new Set<Id>();
		Set<Id> changedRemTaskIds = new Set<Id>();
		Map<Id,sObject> taskMap = new Map<Id,sObject>();
		
		for( sObject task : newTasks )
		{
			taskMap.put( task.Id, task );
			sObject oldTask = oldTaskMap.get( task.Id );
			
			if( (Decimal)task.get( 'Estimated_Hrs__c' ) != (Decimal)oldTask.get( 'Estimated_Hrs__c' ) )
			{
				changedTaskIds.add( task.Id );
			}
			if( (Decimal)task.get( 'Remaining_Hrs__c' ) != (Decimal)oldTask.get( 'Remaining_Hrs__c' ) )
			{
				changedRemTaskIds.add( task.Id );
			}
		}
		
		if( changedTaskIds.size() > 0 )
		{
			// get a map of tasks to history objects to see if there is one already
			Map<Id,sObject> taskToHoursHistoryMap = new Map<Id,sObject>();
			for( sObject hist : database.query( 
				'Select ' +
				'	Old_Value__c, ' + 
				'	New_Value__c, ' + 
				'	Id, ' +
				'	Change_in_Value__c, ' + 
				'	Change_Date__c, ' + 
				'	Agile_Task__c ' + 
				'From ' + 
				'	Agile_Task_Hours_History__c ' +
				'Where ' +
				'	Agile_Task__c in :changedTaskIds and ' +
				'	Change_Date__c = :thisDay ' ) )
			{
				taskToHoursHistoryMap.put( (Id)hist.get( 'Agile_Task__c' ), hist );
			}
			
			// edit or create new history objects to keep track
			List<sObject> newHistories = new List<sObject>();
			List<sObject> exHistories = new List<sObject>();
			for( Id taskId : changedTaskIds )
			{
				sObject task = taskMap.get( taskId );
				
				if( taskToHoursHistoryMap.containsKey( task.Id ) )
				{
					sObject hist = taskToHoursHistoryMap.get( task.Id );
					if( (Decimal)hist.get( 'New_Value__c' ) != (Decimal)task.get( 'Estimated_Hrs__c' ) )
					{
						hist.put( 'New_Value__c', (Decimal)task.get( 'Estimated_Hrs__c' ) );
						hist.put( 'Change_in_Value__c', (Decimal)hist.get( 'New_Value__c' ) - (Decimal)hist.get( 'Old_Value__c' ) );
						exHistories.add( hist );
					}
				}
				else
				{
					Schema.SObjectType hrsHistType = Schema.getGlobalDescribe().get( 'Agile_Task_Hours_History__c' );
        			sObject hist = hrsHistType.newSObject();
        	
					hist.put( 'Old_Value__c', (Decimal)oldTaskMap.get( task.Id ).get( 'Estimated_Hrs__c' ) == null ? 0 : (Decimal)oldTaskMap.get( task.Id ).get( 'Estimated_Hrs__c' ) );
					hist.put( 'New_Value__c', (Decimal)task.get( 'Estimated_Hrs__c' ) );
					hist.put( 'Change_in_Value__c',  (Decimal)hist.get( 'New_Value__c' ) - (Decimal)hist.get( 'Old_Value__c' ) );
					hist.put( 'Change_Date__c', thisDay );
					hist.put( 'Agile_Task__c', task.Id );
					newHistories.add( hist );
				}
			}
			
			if( newHistories.size() > 0 )
			{
				insert newHistories;
			}
			if( exHistories.size() > 0 )
			{
				update exHistories;
			}
		}
		
		if( changedRemTaskIds.size() > 0 )
		{
			Map<Id,sObject> taskToRemainingMap = new Map<Id,sObject>();
			for( sObject rem : database.query( 
				'Select ' +
				'	Old_Value__c, ' + 
				'	New_Value__c, ' + 
				'	Id, ' + 
				'	Change_in_Value__c, ' + 
				'	Change_Date__c, ' + 
				'	Agile_Task__c ' + 
				'From ' + 
				'	Agile_Task_Hours_Remaining_History__c ' +
				'Where ' +
				'	Agile_Task__c in :changedRemTaskIds and ' +
				'	Change_Date__c = :thisDay ' ) )
			{
				taskToRemainingMap.put( (Id)rem.get( 'Agile_Task__c' ), rem );
			}
			
			List<sObject> newRemainings = new List<sObject>();
			List<sObject> exRemainings = new List<sObject>();
			for( Id taskId : changedRemTaskIds )
			{
				sObject task = taskMap.get( taskId );
				
				if( taskToRemainingMap.containsKey( task.Id ) )
				{
					sObject rem = taskToRemainingMap.get( task.Id );
					if( (Decimal)rem.get( 'New_Value__c' ) != (Decimal)task.get( 'Remaining_Hrs__c' ) )
					{
						rem.put( 'New_Value__c', (Decimal)task.get( 'Remaining_Hrs__c' ) );
						rem.put( 'Change_in_Value__c', (Decimal)rem.get( 'New_Value__c' ) - (Decimal)rem.get( 'Old_Value__c' ) );
						exRemainings.add( rem );
					}
				}
				else
				{
					Schema.SObjectType hrsRemType = Schema.getGlobalDescribe().get( 'Agile_Task_Hours_Remaining_History__c' );
        			sObject rem = hrsRemType.newSObject();
					
					rem.put( 'Old_Value__c', (Decimal)oldTaskMap.get( task.Id ).get( 'Remaining_Hrs__c' ) == null ? 0 : (Decimal)oldTaskMap.get( task.Id ).get( 'Remaining_Hrs__c' ) );
					rem.put( 'New_Value__c', (Decimal)task.get( 'Remaining_Hrs__c' ) );
					rem.put( 'Change_in_Value__c', (Decimal)rem.get( 'New_Value__c' ) - (Decimal)rem.get( 'Old_Value__c' ) );
					rem.put( 'Change_Date__c', thisDay );
					rem.put( 'Agile_Task__c', task.Id );
					newRemainings.add( rem );
				}
			}
			
			if( newRemainings.size() > 0 )
			{
				insert newRemainings;
			}
			if( exRemainings.size() > 0 )
			{
				update exRemainings;
			}
		}
	}
}