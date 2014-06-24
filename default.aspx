<%@ Page Language="VB" ContentType="text/html" ResponseEncoding="utf-8" %>
<%@ Import Namespace="system.data" %>
<%@ Import Namespace="system.data.sqlclient" %>
<%@ IMPORT namespace="System.Net.Mail" %>

<script language="vb" runat="server">
	
' <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<< GLOBAL VARIABLES >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>	
	
	' Determine the windows username so that the app knows who is using it - note that the username must be in the web.config file in order for this to work correctly
	Protected CurrentUser = HttpContext.Current.User.Identity.Name()
	
	'Determine today's date and create a property
	Protected CurrentDate = DateTime.Now.ToString("dd/MM/yyyy")
	
	'Determine the epoch date to begin overall reporting period (currently not used in this application)
	Protected EpochDate As DateTime = "06/05/2013"
	
	' Weekly hours required to work (currently not used in this application)
	Protected WeeklyHours = 36.25
	
	

' <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<< PAGE LOAD PROCEDURE >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
	
	' Procedure to run on page load
	Protected Sub Page_Load(ByVal sender As Object, ByVal e As EventArgs) _
      Handles MyBase.Load
	  
	  
	  

' <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<< SET UP PAGE USING URL ATTRIBUTES >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
	  
		' This page may be loaded as a redirect after successfully adding a new entry, updating an entry or deleting an entry. In that case the URL will contain a number which the below code will retrieve using the HTTP GET method. If there is no number because it is the first time the user has visited this page (i.e. hasn't try to add, update or delete an entry) then no message is displayed.
	  	Dim Code As String = Request.QueryString("result")
	  
	  		If Code = 1 Then
	  	 		lblStatus.Text = "Your entry was successfully added to the database"
				Reports.Visible = True
				Reports.Style.Add("background-color", "yellow")
				lblReload.Visible = True
				newJob.Visible = False

	  		Else If Code = 2 Then
	  	 		lblStatus.Text = "Your entry was successfully updated in the database"

	  		Else If Code = 3 Then
	  	 		lblStatus.Text = "Your entry was successfully deleted from the database"
				Reports.Visible = True
				Reports.Style.Add("background-color", "#FF6666")
				lblReload.Visible = True
				newJob.Visible = False
				
	  		Else If Code = 4 Then
	  	 		lblStatus.Text = "Your timesheet was successfully submitted"
				Reports.Visible = True
				Reports.Style.Add("background-color", "#99CC00")
				lblReload.Visible = True
				newJob.Visible = False
	  		End If
		
		
		' This code GETs an ID query sent with the link to open this timesheet from Details.aspx and uses it to automatically populate the job dropdown field in the form.		
		Dim currentjob As String = Request.QueryString("ID")
			' So that this code only executes when there is an ID value (i.e. and doesn't execute when the timesheet widget is opened directly)
			If currentjob <> "" Then
				Dim currentjobresult As String ' prepare variable for use shortly
				Dim myConnection As New SqlConnection() ' create connection
	  			myConnection.ConnectionString = ConfigurationManager.ConnectionStrings("TimesheetWidgetConnectionString").ConnectionString
				Dim currentjobselection As String
	  			currentjobselection = "SELECT TOP 1 JobName FROM import WHERE JobNumber=@currentjob" ' should only return a single value
				Dim currentjobcmd As New SqlCommand(currentjobselection, myConnection)
	  			' Add the parameters.
	  			currentjobcmd.Parameters.AddWithValue("@currentjob", currentjob)
				' Try to open the database and execute the update. Following variable helps track success of this task.
	  			Dim currentjobfetch As string = 0 ' prepare variable for use shortly
					Try
	  				myConnection.Open()
	  				currentjobfetch = currentjobcmd.ExecuteScalar()
					Catch err As Exception
					Finally
	  				' Close the database connection for good practice
	 				myConnection.Close()
					' concantenate the variables for display text
	  				currentjobresult = currentjob + " - " + currentjobfetch
	  				End Try
	  			' If the insert succeeded and variable increased to 1, provide the following message.
	  			If currentjobfetch > "" Then
	  				job.Items.Add(New ListItem(currentjobresult,currentjob)) ' populates dropdown list (first variable is display text, second variable is value to be entered into database)
	  				job.SelectedIndex = 1
	  			End If
			End If

		

' <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<< CHECK FOR COOKIES >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>		
		
		'Upon successful entry into database, a cookie is created with value of the date of that latest entry. This date will be used as new default date in entry field and total tally. If no cookie is present then Current date keeps its default value of today's date
		Dim CookieDisplayDate As HttpCookie = Request.Cookies("DisplayDate")
		If CookieDisplayDate Is Nothing Then
		lblDisplayDate.Text = CurrentDate
		Else
		lblDisplayDate.Text = (CookieDisplayDate.Value)
		CurrentDate = (CookieDisplayDate.Value)
		End If
		
	
	
' <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<< MAIN GRIDVIEW SETTINGS >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>	
		
		' Datasource2 contains no default select statement - the select statement is created using the CurrentUser so that only the current user's records are retreived.	
		SqlDataSource2.SelectCommand = "SELECT TOP 30 * FROM timesheet, Import WHERE username=@username AND job=JobNumber ORDER BY date DESC, id DESC"
		'Clearing parameters helps ensure variable names are unique within a query batch or stored procedure.
		SqlDataSource2.SelectParameters.Clear()
		SqlDataSource2.SelectParameters.Add("username", CurrentUser)
		

		

' <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<< SETTINGS FOR REPORTS & GRAPHS (Current Week) >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>		
		
		' Reporting - the following code determines the last Monday that the user submitted their timesheet for. 	
		Dim ReportDate As DateTime
		
		Dim myConnectionTimesheetUsers As New SqlConnection() ' create connection (to be used to determine which week the user is up to)
	  	myConnectionTimesheetUsers.ConnectionString = ConfigurationManager.ConnectionStrings("TimesheetWidgetConnectionString").ConnectionString

		Dim TimesheetUsersQuery As String
	  	TimesheetUsersQuery = "SELECT last_submitted_week FROM timesheet_users WHERE staff=@username" ' should only return a single value

		Dim TimesheetUsersQuerycmd As New SqlCommand(TimesheetUsersQuery, myConnectionTimesheetUsers)
	  	' Add the parameters.
	  	TimesheetUsersQuerycmd.Parameters.AddWithValue("@username", CurrentUser)

	  	Dim TimesheetUsersfetch As String = "" ' prepare variable for use shortly
			Try
	  			myConnectionTimesheetUsers.Open()
	  			TimesheetUsersfetch = TimesheetUsersQuerycmd.ExecuteScalar()
				Catch err As Exception

				Finally
	 			myConnectionTimesheetUsers.Close() ' Close the database connection for good practice
	  		End Try

	  		' If the query succeeded and variable is not empty, provide the following message.
	  		If TimesheetUsersfetch > "" Then
				ReportDate = TimesheetUsersfetch
			Else ReportDate = EpochDate
	  		End If

		' Current reporting period is 7 days (i.e. 1 week) after the last Monday submitted by user.
		Dim Monday As DateTime
		Monday = ReportDate.AddDays(7)
		Dim Tuesday As DateTime
		Tuesday = ReportDate.AddDays(8)
		Dim Wednesday As DateTime
		Wednesday = ReportDate.AddDays(9)
		Dim Thursday As DateTime
		Thursday = ReportDate.AddDays(10)
		Dim Friday As DateTime
		Friday = ReportDate.AddDays(11)
		MondayLabel.Text = Monday.ToString("dddd dd MMMM")
		TuesdayLabel.Text = Tuesday.ToString("dddd dd MMMM")
		WednesdayLabel.Text = Wednesday.ToString("dddd dd MMMM")
		ThursdayLabel.Text = Thursday.ToString("dddd dd MMMM")
		FridayLabel.Text = Friday.ToString("dddd dd MMMM")
		
		
		
		' Based on above calculated reporting period, the following values are retrieved for the applicable Monday through Friday.	
		Dim myConnectionWeekdays As New SqlConnection() ' create connection (to be used for each weekday)
	  	myConnectionWeekdays.ConnectionString = ConfigurationManager.ConnectionStrings("TimesheetWidgetConnectionString").ConnectionString
		
		' Weekday query strings based on current user and above calculated dates
		Dim MondayScore As String ' prepare variable for use shortly
		Dim MondayQuery As String
	  	MondayQuery = "SELECT SUM(hours) FROM timesheet WHERE username=@username AND date=@Monday" ' should only return a single value
		Dim TuesdayScore As String ' prepare variable for use shortly
		Dim TuesdayQuery As String
	  	TuesdayQuery = "SELECT SUM(hours) FROM timesheet WHERE username=@username AND date=@Tuesday" ' should only return a single value
		Dim WednesdayScore As String ' prepare variable for use shortly
		Dim WednesdayQuery As String
	  	WednesdayQuery = "SELECT SUM(hours) FROM timesheet WHERE username=@username AND date=@Wednesday" ' should only return a single value
		Dim ThursdayScore As String ' prepare variable for use shortly
		Dim ThursdayQuery As String
	  	ThursdayQuery = "SELECT SUM(hours) FROM timesheet WHERE username=@username AND date=@Thursday" ' should only return a single value
		Dim FridayScore As String ' prepare variable for use shortly
		Dim FridayQuery As String
	  	FridayQuery = "SELECT SUM(hours) FROM timesheet WHERE username=@username AND date=@Friday" ' should only return a single value

		Dim MondayQuerycmd As New SqlCommand(MondayQuery, myConnectionWeekdays)
	  	' Add the parameters.
	  	MondayQuerycmd.Parameters.AddWithValue("@username", CurrentUser)
		MondayQuerycmd.Parameters.AddWithValue("@Monday", Monday)
		' Try to open the database and execute the query. Following variable helps track success of this task.
	  	Dim Mondayfetch As string = 0 ' prepare variable for use shortly
			Try
	  			myConnectionWeekdays.Open()
	  			Mondayfetch = MondayQuerycmd.ExecuteScalar()
				Catch err As Exception
				End Try

		Dim TuesdayQuerycmd As New SqlCommand(TuesdayQuery, myConnectionWeekdays)
	  	' Add the parameters.
	  	TuesdayQuerycmd.Parameters.AddWithValue("@username", CurrentUser)
		TuesdayQuerycmd.Parameters.AddWithValue("@Tuesday", Tuesday)
		' Try to open the database and execute the query. Following variable helps track success of this task.
	  	Dim Tuesdayfetch As string = 0 ' prepare variable for use shortly
			Try
	  			Tuesdayfetch = TuesdayQuerycmd.ExecuteScalar()
				Catch err As Exception
				End Try

		Dim WednesdayQuerycmd As New SqlCommand(WednesdayQuery, myConnectionWeekdays)
	  	' Add the parameters.
	  	WednesdayQuerycmd.Parameters.AddWithValue("@username", CurrentUser)
		WednesdayQuerycmd.Parameters.AddWithValue("@Wednesday", Wednesday)
		' Try to open the database and execute the query. Following variable helps track success of this task.
	  	Dim Wednesdayfetch As string = 0 ' prepare variable for use shortly
			Try
	  			Wednesdayfetch = WednesdayQuerycmd.ExecuteScalar()
				Catch err As Exception
				End Try

		Dim ThursdayQuerycmd As New SqlCommand(ThursdayQuery, myConnectionWeekdays)
	  	' Add the parameters.
	  	ThursdayQuerycmd.Parameters.AddWithValue("@username", CurrentUser)
		ThursdayQuerycmd.Parameters.AddWithValue("@Thursday", Thursday)
		' Try to open the database and execute the query. Following variable helps track success of this task.
	  	Dim Thursdayfetch As string = 0 ' prepare variable for use shortly
			Try
	  			Thursdayfetch = ThursdayQuerycmd.ExecuteScalar()
				Catch err As Exception
				End Try

		Dim FridayQuerycmd As New SqlCommand(FridayQuery, myConnectionWeekdays)
	  	' Add the parameters.
	  	FridayQuerycmd.Parameters.AddWithValue("@username", CurrentUser)
		FridayQuerycmd.Parameters.AddWithValue("@Friday", Friday)
		' Try to open the database and execute the query. Following variable helps track success of this task.
	  	Dim Fridayfetch As string = 0 ' prepare variable for use shortly
			Try
	  			Fridayfetch = FridayQuerycmd.ExecuteScalar()
				Catch err As Exception
				
				Finally
	 			myConnectionWeekdays.Close() ' Close the database connection for good practice
	  		End Try
	  		' If the insert succeeded and variable increased to 1, provide the following message.
	  		If Mondayfetch > "" Then
				MondayScore = Mondayfetch
	  			MondayScoreLabel.Text = MondayScore		
	  		End If
	  		' If the insert succeeded and variable increased to 1, provide the following message.
	  		If Tuesdayfetch > "" Then
				TuesdayScore = Tuesdayfetch
	  			TuesdayScoreLabel.Text = TuesdayScore		
	  		End If
	  		' If the insert succeeded and variable increased to 1, provide the following message.
	  		If Wednesdayfetch > "" Then
				WednesdayScore = Wednesdayfetch
	  			WednesdayScoreLabel.Text = WednesdayScore		
	  		End If
	  		' If the insert succeeded and variable increased to 1, provide the following message.
	  		If Thursdayfetch > "" Then
				ThursdayScore = Thursdayfetch
	  			ThursdayScoreLabel.Text = ThursdayScore		
	  		End If
	  		' If the insert succeeded and variable increased to 1, provide the following message.
	  		If Fridayfetch > "" Then
				FridayScore = Fridayfetch
	  			FridayScoreLabel.Text = FridayScore	
				
				
				' Combine the M-F scores into URL string for graph
				ReportGraph.ImageUrl = "http://chart.googleapis.com/chart?chxr=0,0,12.00&chxt=x&chbh=a&chs=250x220&cht=bhs&chco=4D89F9,C6D9FD&chds=0,12.00,0,12.00&chd=t1:" + MondayScore + "," + TuesdayScore + "," + WednesdayScore + "," + ThursdayScore + "," + FridayScore	
				
				
				' Add the M-F scores together for the weekly tally
				WeeklyScoreLabel.Text = Convert.ToDecimal(MondayScore) + Convert.ToDecimal(TuesdayScore) + Convert.ToDecimal(WednesdayScore) + Convert.ToDecimal(ThursdayScore) + Convert.ToDecimal(FridayScore)
				
				' Values for hidden form fields (see below - PROCEDURE TO RUN AFTER SUBMITTING A COMPLETED WEEK)
				week.value = Monday.ToString("dddd dd MMMM")
				hours_to_submit.value = Convert.ToDecimal(MondayScore) + Convert.ToDecimal(TuesdayScore) + Convert.ToDecimal(WednesdayScore) + Convert.ToDecimal(ThursdayScore) + Convert.ToDecimal(FridayScore)
				
	  		End If
					



' <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<< SETTINGS TO DETERMINE LAST WEEK'S SCORE >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>

		Dim LastWeekScore As String
		Dim myConnectionTimesheetLastWeekScore As New SqlConnection() ' create connection (to be used to determine which week the user is up to)
	  	myConnectionTimesheetLastWeekScore.ConnectionString = ConfigurationManager.ConnectionStrings("TimesheetWidgetConnectionString").ConnectionString

		Dim TimesheetLastWeekScoreQuery As String
	  	TimesheetLastWeekScoreQuery = "SELECT hours_submitted FROM timesheet_users WHERE staff=@username" ' should only return a single value

		Dim TimesheetLastWeekScoreQuerycmd As New SqlCommand(TimesheetLastWeekScoreQuery, myConnectionTimesheetLastWeekScore)
	  	' Add the parameters.
	  	TimesheetLastWeekScoreQuerycmd.Parameters.AddWithValue("@username", CurrentUser)

	  	Dim TimesheetLastWeekScorefetch As String = "" ' prepare variable for use shortly
			Try
	  			myConnectionTimesheetLastWeekScore.Open()
	  			TimesheetLastWeekScorefetch = TimesheetLastWeekScoreQuerycmd.ExecuteScalar()
				Catch err As Exception

				Finally
	 			myConnectionTimesheetLastWeekScore.Close() ' Close the database connection for good practice
	  		End Try


	  		' If the query succeeded and variable is not empty, provide the following message.
	  		If TimesheetLastWeekScorefetch > "" Then
				LastWeekScore = TimesheetLastWeekScorefetch
			Else LastWeekScore = "Not available"
	  		End If
			
			LastWeekScoreLabel.Text = LastWeekScore
			
			
			
	
' <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<< ADMIN SETTINGS >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>	
	
		' If CurrentUser is not in the list below then the Admin Label is included on the page. The Admin Label contains CSS that hides any page element with a class of "AdminOnly"
		If CurrentUser = "GSO\jablyt2" OrElse CurrentUser = "GSO\sthamm2" OrElse CurrentUser = "GSO\jekett2" 
		Admin.Visible = False
		End If
		
		
		
		' Admin use only - DatasourceSearch contains no default select statement - the select statement is created using the CurrentUser and EntryDate so that only the current user's records for a particular day are retreived.	
		SqlDataSourceSearch.SelectCommand = "SELECT SUM(hours) FROM timesheet WHERE username=@username AND date=@date"
		'Clearing parameters helps ensure variable names are unique within a query batch or stored procedure.
		SqlDataSourceSearch.SelectParameters.Clear()
		SqlDataSourceSearch.SelectParameters.Add("username", CurrentUser)
		SqlDataSourceSearch.SelectParameters.Add("date", CurrentDate)	
	
	End Sub	

' <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<< END OF PAGE LOAD PROCEDURE >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>





' <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<< PROCEDURE AFTER NEW ENTRY SUBMITTED >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>

	Protected Sub Button1_Click(ByVal sender As Object, ByVal e As System.EventArgs)
		' Procedure to run when user clicks button1 to add a new entry to the database
		
		'Create variables from the posted data
		Dim EntryUserName As String = Request.Form("username")
		Dim EntryDate As String = Request.Form("date")
		Dim EntryJob As String = Request.Form("job")
		Dim EntryHours As String = Request.Form("hours")
		
		
		' This code sets the database connection and reference to the table to query
		Dim table As String = "timesheet"
		Dim dbconnectionstring As String = ConfigurationManager.ConnectionStrings("TimesheetWidgetConnectionString").ConnectionString

		
 		' Details of server, database, user ID & password
	  	Dim myConnection As New SqlConnection()
	  	myConnection.ConnectionString = dbconnectionstring	
		
		
		' Create SQL query to insert into database
	  	Dim insertSQL As String
	  	insertSQL = "INSERT INTO " + table + " (date, username, job, hours, datestamp) VALUES (@Date, @Username, @Job, @Hours, @Now)"

	  	Dim cmd As New SqlCommand(insertSQL, myConnection)
		
	  	' Add the parameters.
	  	cmd.Parameters.AddWithValue("@Date", EntryDate)
	  	cmd.Parameters.AddWithValue("@Username", EntryUserName)
  	  	cmd.Parameters.AddWithValue("@Job", EntryJob)
  	  	cmd.Parameters.AddWithValue("@Hours", EntryHours)
	  	cmd.Parameters.AddWithValue("@Now", Now)


	  	' Try to open the database and execute the update. Following variable helps track success of this task.
	  	Dim added As Integer = 0
	  
	  	Try
	  	myConnection.Open()
	  	added = cmd.ExecuteNonQuery()
	  
	  	Catch err As Exception
	  	lblStatus.Text = "Error inserting record. "
	  	lblStatus.Text & = err.Message
	  
	  	Finally
	  	' Close the database connection for good practice
	  	myConnection.Close()
	  	End Try

	  	' If the insert succeeded and variable increased to 1, provide the following message &/or do the following:
	  	If added > 0 Then
	  	lblStatus.Text = "New entry was successfully added"
		' Create cookie with a value of date of entry just entered - this cookie will be retrieved on page load so that CurrentDate defaults to cookie value instead of today's date
		Response.Cookies("DisplayDate").Expires = DateTime.Now.AddMinutes(120.0)
	    Response.Cookies("DisplayDate").Value = EntryDate
	  	Response.Redirect("default.aspx?result=1")
	  	End If
	
	End Sub
	
	
	
' <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<< PROCEDURE TO COMPLETE ADMIN SEARCH >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>	
	
	
	Protected Sub Button2_Click(ByVal sender As Object, ByVal e As System.EventArgs)
		' Procedure to run when user clicks button2 to search the database
		
		'Create variables from the posted data
		' Datasource2 contains no default select statement - the select statement is created using the entered username & dates so that only that user's records are retreived.	
		Dim SearchDateFrom As String = Request.Form("searchdatefrom")
		If SearchDateFrom = "" Then
		SearchDateFrom = "01/01/2013"
		End If
		
		Dim SearchDateTo As String = Request.Form("searchdateto")
		If SearchDateTo = "" Then
		SearchDateTo = CurrentDate
		End If
		
		Dim SearchEntryName As String = Request.Form("searchusername")
		If SearchEntryName <> "All users" Then
		SqlDataSource2.SelectCommand = "SELECT TOP 10 * FROM timesheet, Import WHERE username=@username AND job=JobNumber AND date>=@searchfrom AND date<=@searchto ORDER BY date DESC, id DESC"
		SqlDataSourceSearch.SelectCommand = "SELECT SUM(hours) FROM timesheet WHERE username=@username AND date>=@searchfrom AND date<=@searchto"
		lblDisplayDate.Text = SearchEntryName + " from " + SearchDateFrom + " to " + SearchDateTo
		End If
		If SearchEntryName = "All users" Then
		SqlDataSource2.SelectCommand = "SELECT TOP 10 * FROM timesheet, Import WHERE job=JobNumber AND date>=@searchfrom AND date<=@searchto ORDER BY date DESC, id DESC"
		SqlDataSourceSearch.SelectCommand = "SELECT SUM(hours) FROM timesheet WHERE date>=@searchfrom AND date<=@searchto"
		lblDisplayDate.Text = SearchEntryName + " from " + SearchDateFrom + " to " + SearchDateTo
		End If
		
		'Clearing parameters helps ensure variable names are unique within a query batch or stored procedure.
		SqlDataSource2.SelectParameters.Clear()
		SqlDataSource2.SelectParameters.Add("username", SearchEntryName)
		SqlDataSource2.SelectParameters.Add("searchfrom", SearchDateFrom)
		SqlDataSource2.SelectParameters.Add("searchto", SearchDateTo)
		
		'Clearing parameters helps ensure variable names are unique within a query batch or stored procedure.
		SqlDataSourceSearch.SelectParameters.Clear()
		SqlDataSourceSearch.SelectParameters.Add("username", SearchEntryName)
		SqlDataSourceSearch.SelectParameters.Add("searchfrom", SearchDateFrom)
		SqlDataSourceSearch.SelectParameters.Add("searchto", SearchDateTo)
		
	End Sub
	
	
	
' <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<< PROCEDURE TO RUN AFTER SUBMITTING A COMPLETED WEEK >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>	


	Protected Sub WeeklyScoreSubmitButton_Click(ByVal sender As Object, ByVal e As System.EventArgs)
		'Create variables from the posted data
		Dim Week_to_Submit As String = Request.Form("week")
		Dim Hours_to_Submit As String = Request.Form("hours_to_submit")	
		Dim Email_Report As String = Request.Form("emailreport")
		Dim Email_Yourself As String
		Email_Yourself = CurrentUser
		Email_Yourself = Email_Yourself.Remove(0,4)
		Dim Email_To As String = Request.Form("emailto")
			If Email_To = "" Then
				Email_To = "no-email@no-email.com"
				Else Email_To = Email_Yourself + "@xxx.com"
			End If

		Dim tableusers As String = "timesheet_users"
		Dim dbconnectionstringusers As String = ConfigurationManager.ConnectionStrings("TimesheetWidgetConnectionString").ConnectionString

		
 		' Details of server, database, user ID & password
	  	Dim myConnectionusers As New SqlConnection()
	  	myConnectionusers.ConnectionString = dbconnectionstringusers	
		
		
		' Create SQL query to update database
	  	Dim updateSQLusers As String
		updateSQLusers = "UPDATE " + tableusers + " SET last_submitted_week=@last_submitted_week, hours_submitted=@hours_submitted, last_modified=@datestamp WHERE staff=@staff"

	  	Dim cmdusers As New SqlCommand(updateSQLusers, myConnectionusers)
		
	  	' Add the parameters.
	  	cmdusers.Parameters.AddWithValue("@staff", CurrentUser)
	  	cmdusers.Parameters.AddWithValue("@last_submitted_week", Week_to_Submit)
  	  	cmdusers.Parameters.AddWithValue("@hours_submitted", Hours_to_Submit)
  	  	cmdusers.Parameters.AddWithValue("@datestamp",  Now)


	  	' Try to open the database and execute the update. Following variable helps track success of this task.
	  	Dim addedusers As Integer = 0
	  
	  	Try
	  	myConnectionusers.Open()
	  	addedusers = cmdusers.ExecuteNonQuery()
	  
	  	Catch err As Exception
	  	lblStatus.Text = "Error inserting record. "
	  	lblStatus.Text & = err.Message
	  
	  	Finally
	  	' Close the database connection for good practice
	  	myConnectionusers.Close()
	  	End Try

	  	' If the insert succeeded and variable increased to 1, provide the following message &/or do the following:
	  	If addedusers > 0 Then
	  'create an email confirmation message to send to manager
	  Dim mail As New MailMessage()

	  'set the addresses
	  mail.From = New MailAddress("Timesheet@Widget")
	  mail.[To].Add(Email_Report)

	  'set the content of the email
	  mail.Subject = "A new timesheet has been submitted by " + CurrentUser
	  mail.Body = "A new timesheet has been submitted by " + CurrentUser + " for the week that began on " + Week_to_Submit + " for a total of " + Hours_to_Submit + " hours."

	  'set the server for sending the email
	  Dim smtp As New SmtpClient

	  'send the email message
	  Try
    	  smtp.Send(mail)

	  Catch exc As Exception
    	  lblStatus.Text = "Send failure: " & exc.ToString()
	  End Try


	 'create a confirmation email message to send to the user
	  Dim mail2 As New MailMessage()

	  'set the addresses
	  mail2.From = New MailAddress("Timesheet@Widget")
	  mail2.[To].Add(Email_To)

	  'set the content of the email
	  mail2.Subject = "Your timesheet has been submitted for week " + Week_to_Submit
	  mail2.Body = "Thanks " + CurrentUser + ", your timesheet has been submitted for the week that began on " + Week_to_Submit + " for a total of " + Hours_to_Submit + " hours."
	  'set the server for sending the email
	  Dim smtp2 As New SmtpClient

	  'send the email message
	  Try
    	  smtp2.Send(mail2)
 	  Catch exc As Exception
    	  lblStatus.Text = "Send failure: " & exc.ToString()
	  End Try		
	  	Response.Redirect("default.aspx?result=4")
	  	
		End If

	End Sub




' <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<< END OF VB.NET LOGIC >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
</script>

<!DOCTYPE html>
<html>
<head runat="server">
	<title>iWIP Timesheet</title>
	<!--#include file="inc/stylesheet.aspx"-->
 		<script src="http://code.jquery.com/jquery-1.9.1.js"></script>
        
        <!-- Validation code -->
        <script src="inc/jquery.validate.min.js"></script>
        <script>
		$(document).ready(function() {
		$('#form1').validate({
		rules: {
			date: 'required',
			hours: 'required'
				}
		}); // end validate
		}); // end ready
		</script>
    
    	<!-- Datepicker code -->
  		<script src="http://code.jquery.com/ui/1.10.2/jquery-ui.js"></script>
     	<link href="http://ajax.googleapis.com/ajax/libs/jqueryui/1.8/themes/base/jquery-ui.css" rel="stylesheet" type="text/css"/>
  		<script>
  		$(function() {
    	$( "#datepicker" ).datepicker({ onSelect: function(date) {document.cookie = "DisplayDate" + "=" + (date); location.reload(); }, dateFormat: 'dd/mm/yy', maxDate: new Date });
		$( ".DateUpdate" ).datepicker({ dateFormat: 'dd/mm/yy', maxDate: new Date  });
		$( ".searchdate" ).datepicker({ dateFormat: 'dd/mm/yy', maxDate: new Date  });
  		});
  		</script>

</head>

<body>

<!--#include file="inc/background-image.aspx"-->

<form id="form1" runat="server">

	<!-- Code to add property so admin only divs are hidden from non-administrators -->
	<asp:Label id="Admin" runat="server"><style>.adminOnly {display:none;}</style></asp:Label>
	<style>.error{color:red;} .adminOnly2 {display:none;}</style>

<div id="container" runat="server" class="box">

<div id="header2" runat="server">

	<h1>Timesheet - <%=Me.CurrentUser%></h1>

</div>


<div id="newJob" runat="server" class="box">

 	<strong class="adminOnly">Name: </strong><input name="username" type="text" size="7" value="<%=Me.CurrentUser%>" class="adminOnly"/> <strong class="title">Add a new entry</strong>

		<table>
			<tr>
			<td>
			<strong>Date</strong> 
			</td>
			<td>
			<strong>iWip Job</strong>
			</td>
			<td>
			<strong>Hours</strong> 
			</td>
			<td>
			</td>
			</tr>
			<tr>
			<td>
 			<input name="date" id="datepicker" size="7" value="<%=Me.CurrentDate%>" title="Date required"/>
			</td>
			<td>
			<asp:DropDownList ID="job" AppendDataBoundItems="true" Width="290px" runat="server" DataSourceID="SqlDataSource1" DataTextField="Fullname" DataValueField="JobNumber" title="Please select an iWIP job">
            <asp:ListItem></asp:ListItem>
			</asp:DropDownList><br/>
            <asp:RequiredFieldValidator id="RequiredFieldValidatorJob" ControlToValidate="job" Display="Dynamic" ErrorMessage="Please select an iWIP job" ForeColor="red" runat="server"/>
			</td>
			<td>
			<select name="hours" type="number" value="" title="Hours required">
                            <option>0.25</option>
                            <option>0.50</option>
                            <option>0.75</option>
                            <option>1.00</option>
                            <option>1.25</option>
                            <option>1.50</option>
                            <option>1.75</option>
                            <option>2.00</option>
                            <option>2.25</option>
                            <option>2.50</option>
                            <option>2.75</option>
                            <option>3.00</option>
                            <option>3.25</option>
                            <option>3.50</option>
                            <option>3.75</option>
                            <option>4.00</option>
                            <option>4.25</option>
                            <option>4.50</option>
                            <option>4.75</option>
                            <option>5.00</option>
                            <option>5.25</option>
                            <option>5.50</option>
                            <option>5.75</option>
                            <option>6.00</option>
                            <option>6.25</option>
                            <option>6.50</option>
                            <option>6.75</option>
                            <option>7.00</option>
                            <option>7.25</option>
                            <option>7.50</option>
                            <option>7.75</option>
                            <option>8.00</option>
                            <option>8.25</option>
                            <option>8.50</option>
                            <option>8.75</option>
                            <option>9.00</option>
                            <option>9.25</option>
                            <option>9.50</option>
                            <option>9.75</option>
                            <option>10.00</option>
                            <option>10.25</option>
                            <option>10.50</option>
                            <option>10.75</option>
                            <option>11.00</option>
                            <option>11.25</option>
                            <option>11.50</option>
                            <option>11.75</option>
                            <option>12.00</option>
    						</select>
				</td>
				<td>
				<asp:Button ID="Button1" text="Add" runat="server" OnClick="Button1_Click" />
				</td>
				</tr>
			</table>          
</div>




<div id="Reports" runat="server" visible="false" class="box">

			<asp:Label id="lblStatus" runat="server"></asp:Label><br/><br/>

			<asp:Label id="lblReload" runat="server" visible="false"><a href="default.aspx">Add Another Job</a></asp:Label>
    
</div>




<div id="Search" runat="server" class="adminOnly box">

<strong class="title">Search - Admin Only</strong><br/><br/>

Username:</strong> <asp:DropDownList ID="searchusername" AppendDataBoundItems="true" Width="100px" runat="server" DataSourceID="SqlDataSource4" DataTextField="username" DataValueField="username">
    		<asp:ListItem></asp:ListItem>
            <asp:ListItem>All users</asp:ListItem>
			</asp:DropDownList>

From:</strong> <input name="searchdatefrom" type="text" size="7" class="searchdate" value=""/> to <input name="searchdateto" type="text" size="7" value="" class="searchdate" /> <asp:Button ID="Button2" text="Search" runat="server" OnClick="Button2_Click" class="cancel" CausesValidation="false"/>

<a id="opengridview" href="reports.aspx" target="_blank">View Reports</a>

Timesheets will be emailed to: <input id="emailreport" name="emailreport" value="xxx@xxx.com" size="30" />

</div>




<div id="oldJobs" runat="server" class="box">  
	
<strong class="title">Most recent entries</strong>

<div class="standardtable" style="height:200px;overflow-y:scroll;overflow-x:hidden;">
    <asp:GridView ID = "GridView1" runat = "server" DataSourceID = "SqlDataSource2" AutoGenerateColumns = "false" Gridlines="Both" >
    <HeaderStyle  CssClass="gridViewTableHeader"/>
	<rowstyle CssClass="gridViewTableRow"/>
    <alternatingrowstyle CssClass="gridViewTableAlternate"/>
	
		
        <Columns>
        
			<asp:BoundField DataField = "id" HeaderStyle-CssClass="adminOnly2" HeaderText = "ID"><ItemStyle CssClass="adminOnly2"></ItemStyle>
			</asp:BoundField>
        
        
        	<asp:BoundField DataField = "username" HeaderStyle-CssClass="adminOnly" HeaderText = "Username" ><ItemStyle CssClass="adminOnly"></ItemStyle>
			</asp:BoundField>
        
        
        	<asp:TemplateField HeaderText = "Date">
    		<ItemTemplate>
        	<asp:Label ID="DateLabel" runat="server" width="70px" Text='<%# Bind("date", "{0:dd/MM/yy}") %>'></asp:Label>
    		</ItemTemplate>
    		<EditItemTemplate runat="server">
			<asp:TextBox ID="DateUpdate" runat="server" size="7" CssClass="DateUpdate" Text='<%# Bind("date", "{0:dd/MM/yy}") %>'>
			</asp:TextBox>
			</EditItemTemplate>
			</asp:TemplateField>
        
        
            <asp:TemplateField HeaderText = "iWIP Job">
    		<ItemTemplate>
        	<asp:Label ID="JobLabel" runat="server" Text='<%# Eval("JobNumber").ToString() + " - " + Eval("JobName") %>'></asp:Label>
    		</ItemTemplate>
    		<EditItemTemplate runat="server" >
			<asp:DropDownList ID="JobUpdate" runat="server" width="290px" DataSourceID="SqlDataSource1" Text='<%# Bind("job") %>' DataTextField="FullName" DataValueField="JobNumber" AppendDataBoundItems="true" AutoPostBack="True">
            <asp:ListItem Selected="True" Value="%" Text=""/>
            </asp:DropDownList>
			</EditItemTemplate>
			</asp:TemplateField>
        
        
        	<asp:TemplateField HeaderText = "Hours">
    		<ItemTemplate>
        	<asp:Label ID="HoursLabel" runat="server" Text='<%# Bind("hours") %>'></asp:Label>
    		</ItemTemplate>
            <EditItemTemplate runat="server" >
            <asp:DropDownList ID="HoursUpdate" runat="server"  width="50px" Text='<%# Bind("hours") %>' AutoPostBack="true">
            <asp:ListItem Selected="True" Value="%" Text=""/>
            <asp:ListItem>0.25</asp:ListItem>
            <asp:ListItem>0.50</asp:ListItem>
            <asp:ListItem>0.75</asp:ListItem>
                        <asp:ListItem>1.00</asp:ListItem>
            <asp:ListItem>1.25</asp:ListItem>
            <asp:ListItem>1.50</asp:ListItem>
            <asp:ListItem>1.75</asp:ListItem>
                        <asp:ListItem>2.00</asp:ListItem>
            <asp:ListItem>2.25</asp:ListItem>
            <asp:ListItem>2.50</asp:ListItem>
            <asp:ListItem>2.75</asp:ListItem>
                        <asp:ListItem>3.00</asp:ListItem>
            <asp:ListItem>3.25</asp:ListItem>
            <asp:ListItem>3.50</asp:ListItem>
            <asp:ListItem>3.75</asp:ListItem>
                        <asp:ListItem>4.00</asp:ListItem>
            <asp:ListItem>4.25</asp:ListItem>
            <asp:ListItem>4.50</asp:ListItem>
            <asp:ListItem>4.75</asp:ListItem>
                        <asp:ListItem>5.00</asp:ListItem>
            <asp:ListItem>5.25</asp:ListItem>
            <asp:ListItem>5.50</asp:ListItem>
            <asp:ListItem>5.75</asp:ListItem>
                        <asp:ListItem>6.00</asp:ListItem>
            <asp:ListItem>6.25</asp:ListItem>
            <asp:ListItem>6.50</asp:ListItem>
            <asp:ListItem>6.75</asp:ListItem>
                        <asp:ListItem>7.00</asp:ListItem>
            <asp:ListItem>7.25</asp:ListItem>
            <asp:ListItem>7.50</asp:ListItem>
            <asp:ListItem>7.75</asp:ListItem>
                                    <asp:ListItem>8.00</asp:ListItem>
            <asp:ListItem>8.25</asp:ListItem>
            <asp:ListItem>8.50</asp:ListItem>
            <asp:ListItem>8.75</asp:ListItem>
                     <asp:ListItem>9.00</asp:ListItem>
            <asp:ListItem>9.25</asp:ListItem>
            <asp:ListItem>9.50</asp:ListItem>
            <asp:ListItem>9.75</asp:ListItem>
                     <asp:ListItem>9.00</asp:ListItem>
            <asp:ListItem>9.25</asp:ListItem>
            <asp:ListItem>9.50</asp:ListItem>
            <asp:ListItem>9.75</asp:ListItem>
                     <asp:ListItem>10.00</asp:ListItem>
            <asp:ListItem>10.25</asp:ListItem>
            <asp:ListItem>10.50</asp:ListItem>
            <asp:ListItem>10.75</asp:ListItem>
                     <asp:ListItem>11.00</asp:ListItem>
            <asp:ListItem>11.25</asp:ListItem>
            <asp:ListItem>11.50</asp:ListItem>
            <asp:ListItem>11.75</asp:ListItem>
            		<asp:ListItem>12.00</asp:ListItem>
            </asp:DropDownList>
            </EditItemTemplate>
            </asp:TemplateField>
		
        
        	<asp:CommandField ShowEditButton = "True" buttontype="Image" editimageurl="inc/edit-button.jpg" updateimageurl="inc/edit-confirm.jpg" cancelimageurl="inc/edit-cancel.jpg"  CausesValidation="false"/>
		
        
        	<asp:TemplateField >
    		<ItemTemplate>
        	<a href="delete-entry.aspx?id=<%#Eval("id") %>"><img src="inc/delete-button.jpg" style="border:none;width:15px;"/></a>
       		</ItemTemplate> 
       		</asp:TemplateField>
        
        
		</Columns>
	</asp:GridView> 
</div>
    
    </div>
	<br/>
    <div id="Summary">
    
    	<!--<div id="TotalHoursLabel">Total Hours for <asp:Label id="lblDisplayDate" runat="server"></asp:Label> 
    	</div>

    	<p><asp:GridView ID = "GridView2" runat = "server" AutoGenerateColumns = "true" ShowHeader="false" DataSourceID = "SqlDataSourceSearch" /></p>
                
        <p>Week # <asp:Label ID="ReportDateLabel" runat="server"></asp:Label></p>-->
        
        <table>
        <tr><td>
        <table id="SummaryTable">
        <tr height="40px"><td width="200px"><asp:Label ID="MondayLabel" runat="server"></asp:Label>
        </td><td><asp:Label ID="MondayScoreLabel" runat="server"></asp:Label>
        </td></tr>
		<tr height="40px"><td><asp:Label ID="TuesdayLabel" runat="server"></asp:Label>
        </td><td><asp:Label ID="TuesdayScoreLabel" runat="server"></asp:Label>
        </td></tr>
        <tr height="40px"><td><asp:Label ID="WednesdayLabel" runat="server"></asp:Label>
        </td><td><asp:Label ID="WednesdayScoreLabel" runat="server"></asp:Label>
        </td></tr>
        <tr height="40px"><td><asp:Label ID="ThursdayLabel" runat="server"></asp:Label>
        </td><td><asp:Label ID="ThursdayScoreLabel" runat="server"></asp:Label>
        </td></tr>
        <tr height="40px"><td><asp:Label ID="FridayLabel" runat="server"></asp:Label>
        </td><td><asp:Label ID="FridayScoreLabel" runat="server"></asp:Label>
        </td></tr> 
                <tr height="35px"></tr>       
        </table>
        </td><td>
        <asp:Image ID="ReportGraph" runat="server" ImageUrl="logo.png"></asp:Image>
        </tr>
        </table>
        
        
        <div id="submission">
        
        <p class="currentscore">This week's score is <asp:Label ID="WeeklyScoreLabel" runat="server"></asp:Label></p>
             
        <p><asp:Button ID="WeeklyScoreSubmitButton" runat="server" OnClick="WeeklyScoreSubmitButton_Click" Text="Submit & finalise week" CausesValidation="false" OnClientClick="return confirm('Are you sure you want to submit your hours? You will move onto the next week and not be able to edit this current week!')"></asp:Button>
        
        <input runat="server" id="week" name="week" value="" type="hidden"/>
		<input runat="server" id="hours_to_submit" name="hours_to_submit" value="" type="hidden"/></p>
        
       <p class="emailconfirmation"> Send email confirmation to yourself? <input type="checkbox" id="emailto" name="emailto" value="yes" /></p>
        
        
        <p class="lastscore">Last week's score was <asp:Label ID="LastWeekScoreLabel" runat="server"></asp:Label></p>
        
        </div>
         
    	<p><a id="reportissue" href="mailto:xxx@xxx.com?subject=Timesheet%20Widget">Report issue or request change</a></p>
        

    </div>
    
   
   
</div> 




	<asp:SqlDataSource ID="SqlDataSource1" runat="server" ConnectionString="<%$ ConnectionStrings:TimesheetWidgetConnectionString %>" 
    SelectCommand="SELECT TOP 600 JobNumber, datelogged, CASE WHEN admin <> 'Yes' OR admin is NULL THEN CONVERT(VARCHAR(50),JobNumber) + ' - ' + JobName WHEN admin = 'Yes' THEN JobName END AS FullName FROM import ORDER BY Admin DESC, JobNumber DESC" />

	<asp:SqlDataSource ID="SqlDataSource2" runat="server" ConnectionString="<%$ ConnectionStrings:TimesheetWidgetConnectionString %>" 

	UpdateCommand = "UPDATE timesheet SET username = @username, date = @date, job = @job, hours = @hours WHERE id=@id"/>
    
	<asp:SqlDataSource ID="SqlDataSourceSearch" runat="server" ConnectionString="<%$ ConnectionStrings:TimesheetWidgetConnectionString %>" />
    
    <asp:SqlDataSource ID="SqlDataSource4" runat="server" ConnectionString="<%$ ConnectionStrings:TimesheetWidgetConnectionString %>"
    SelectCommand="SELECT DISTINCT username FROM timesheet" />
    
</form>
      

</body>
</html>