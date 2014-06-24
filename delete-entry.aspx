<%@ Page Language="VB" %>

<script language="vb" runat="server">

    Protected Sub Page_Load(ByVal sender As Object, ByVal e As EventArgs) _
      Handles MyBase.Load
	  		
		' This code sets the database connection and reference to the table to query
		Dim dbconnectionstring As String = ConfigurationManager.ConnectionStrings("TimesheetWidgetConnectionString").ConnectionString
		
		
		' Retreive the id from the URL and create a variable
	  	Dim PageID As String = Request.Querystring("id")


		' Add the variable to the SQL datasource query so that the correct blog entry is retrieved and displayed on the page
	 	SqlDataSource.SelectParameters.Add("variablename", PageID)
		SqlDataSource.SelectCommand = "SELECT * FROM timesheet, Import WHERE id=@variablename AND job=JobNumber"
		SqlDataSource.ConnectionString = dbconnectionstring

		End Sub

</script>

<!DOCTYPE html>
<html>
<head id="Head1" runat="server">
<!--#include file="inc/stylesheet.aspx"-->
    <title>Delete Entry</title>
</head>
<body>
<!--#include file="inc/background-image.aspx"-->
<div id="container" class="box">

<div id="content">

		<br/>

		<form id="form1" runat="server">
       
        <asp:Repeater ID="RepeaterListing" runat="server" datasourceid="SqlDataSource">
          <itemtemplate>
          <p id="delete">Delete this entry?</p>
            <p><%# Eval("JobNumber").ToString() + " - " + Eval("JobName") %><br/><br/>
			<%#Eval("date", "{0:dd/MM/yy}") %>&nbsp;&nbsp;
			<%#Eval("hours") %> hours</p>
            <br/>
            <a href="delete-entry-confirm.aspx?id=<%#Eval("id") %>" id="delete-yes">Yes</a>
            <a href="default.aspx" id="delete-no">No</a>
          </itemtemplate>
        </asp:Repeater>
         

		<asp:SqlDataSource ID="SqlDataSource" runat="server" />

    	</form>
        <br/><br/>
    

</div>

</div>
</body>
</html>
