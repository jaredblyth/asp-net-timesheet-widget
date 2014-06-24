The Timesheet Widget is designed to record staff hours worked against specific jobs in a workflow system.

Key features of the Timesheet Widget

• The Timesheet Widget runs on .NET

• Its logic is written in visual basic

• It works in conjunction with an existing .NET workflow system

• The timesheet widget records the data in a SQLServer database table (see the schema design at https://github.com/jaredblyth/asp-net-timesheet-widget/blob/master/Schema.png)

• Timesheet data can be monitored or exported to MS Excel for analysis

• The timesheet widget automatically detects the correct user through MS Windows framework

•This means that staff can only enter their own timesheet data. Administrators can add & edit data on behalf of other staff

• The timesheet widget automatically creates a drop-down list of jobs from the workflow system

• A calendar-style datepicker widget makes selecting the date very easy

• The current date is automatically selected. A cookie is set so that a changed date remains selected for subsequent entries (makes it easy if entering multiple jobs from a previous day)

• Hours can be selected in 0.25 increments up to 12 hours for a single entry

•Data validation prevents an entry being submitted without a selected workflow job

• Data validation also requires a date for every entry

• When all fields are completed, the user can submit the entry

• Users can view their last thirty entries

• These entries can be edited or deleted in case of a mistake

•The number of hours entered are displayed in a weekly bar graph image (created dynamically using the Google Chart API)

• At the end of the week, the user submits the timesheet to their manager

• The manager receives an email

• At this point, their entries are finalised and cannot be edited or deleted

• The user is given a warning to this effect

• The user can opt to receive an email confirming successful submission of their timesheet data

• The timesheet widget confirms that the timesheet was successfully submitted

• The manager receives an email advising that the timesheet has been submitted for the week


Please visit http://jaredblyth.com/page.php?id=73 for further information and a video of the Timesheet Widget in action. 