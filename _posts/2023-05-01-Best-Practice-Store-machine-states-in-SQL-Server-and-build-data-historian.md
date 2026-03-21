---
layout: post
title: Store machine states in SQL Server and build a data historian (best practice)
date: 2023-05-01 12:00:00 +0200
tags: sqlserver bestpractice
image: /assets/2023-05-01/title.png
---
## What are machine states and why would I want to build a data historian?

It is common to use Peakboard to collect various states for artefacts. This includes the state of a machine (running, stopped), the state of person (working, having a break), or the state of a door (open, closed). In the industrial applications space, there are countless examples where having a state change history is useful. Usually, this is because data analysis can be performed on the state change history in order to answer questions like, "How long has the machine been running in total," or, "What was the aggregated working time of this person this week".

This article explains the basic pattern behind storing a machine's state in a database. Real world use could be a bit more complicated, but the basic pattern will always remain the same.

## What tables do I need?

For the basic pattern, we need two tables.

The first table we need is `Machines`, where we store machine information. It has one row per machine, to store things like the machine name and the current state. The other columns in this screenshot can be ignored as they are for another example.

![image](/assets/2023-05-01/title.png)


Here is a bit of sample data. We're describing three machines, one of which is currently running.

![](/assets/2023-05-01/011.png)

The second table we need is `MachineStateHistory`, where we store the state changes. As you see in the screenshot, we have an abstract identity column `ID` that serves as an abstract primary key. `TS` is the time stamp when a new state is set, `MachineName` is the name of the machine that is having the state change, and `State` is the new state itself.

![](/assets/2023-05-01/020.png)

## How do I set a new state?

When a machine enters a new state, we _could_ just send UPDATE and INSERT commands to the database to add the new state to the data. However, we won't do this. We will instead build and call a stored procedure (SP) to do this job for you. If you have never built an SP, feel free to google how to do that.

Here's the code for our simple SP. The caller provides the machine name and the new state. Then, the SP changes the machine's state in the `Machines` table and adds a row to the `MachineStateHistory` table, which represents the new state change.

{% highlight sql %}
CREATE PROCEDURE [dbo].[SetNewState]
	@MachineName nvarchar(20),
	@State nvarchar(20)
AS
BEGIN
	
	Update Machines set state=@State where machinename=@MachineName
	insert into MachineStateHistory (TS, MachineName, State) 
  	values(getdate(),@MachineName, @State)

END
{% endhighlight %}

## Why are we using a stored procedure instead of direct updates?

SPs have many advantages over direct updates:

* The logic of a state change is implemented and maintained in exactly one place. In a perfect world, no callers would be allowed to change the data directly. Instead, they would all have to go through the SP. This would ensure that the SP has full control and maintains consistency.
* The state change is a single transaction. Either both data changes happen or neither of them do. So, you can be sure that every state change always has an entry in the state change tracking table.
* This is the fastest way to record the state change, in terms of database resources, because calling this SP only takes a single call. In real life, these kinds of SPs are a bit more complicated and sometimes do tens of DB calls in a single state change. So saving DB resources can have a big impact when speed matters.

## How do I call the stored procedure from Peakboard?

Now that we've set up the DB part, let's have a look at the Peakboard part. A typical pattern is to access the `Machines` table in a data source. You probably need the data for your visualization anyway.

![](/assets/2023-05-01/030.png)

Here's an example where we call our SP with a Start / Stop button. There's a special block for calling the SPs. You simply select the SP and then enter the machine name and the new state (the Start button will send a RUN state and the stop button with send a STOP state).
After calling the SP, we do a data source refresh to make sure that the new state is re-fetched from the DB:

![](/assets/2023-05-01/032.png)

After playing around with Start / Stop and calling our SP a couple of times, you will see that the history table fills up with data like his:

![](/assets/2023-05-01/035.png)

## Conclusion

The example above shows how to build and fill a table to store state changes. It is clear that real world data may be a bit more complicated (more states, more logic, more restrictions), but the basic pattern is usually the same. For these kinds of data changes, SPs are a very powerful and easy to understand tool.

