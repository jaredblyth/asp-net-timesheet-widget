<%@ Page Language="VB" ContentType="text/html" EnableEventValidation ="false" ResponseEncoding="utf-8"%>
<%@ Import Namespace="system.IO" %>

<script runat="server">

		Protected job = 0 ' for use with the timesheet widget
		
		' The following code exports the gridview to an excel workbook - note that you must use .xls rather than .xlsx etc as ASP.NET and Office 2010 do not work correctly together unless changes are made to the file system registry. Using .xls will generate a dialog box warning when opening excel but if you select "yes" then the data will be exported - this cannot be fixed.
        Protected Sub Button1_Click(ByVal sender As Object,      ByVal e As EventArgs)
		
        	Response.AddHeader("content-disposition", "attachment;filename=iWIP Timesheet Raw Data.xls")
        	Response.Charset = String.Empty
        	Response.ContentType = "application/vnd.xls"
        	Dim sw As System.IO.StringWriter = New System.IO.StringWriter()
        	Dim hw As System.Web.UI.HtmlTextWriter = New HtmlTextWriter(sw)
        	GridView1.RenderControl(hw)
        	Response.Write(sw.ToString())
        	Response.End()
    	End Sub
	
		' This code prevents several errors including opening blank excel workbooks and runat=server errors.
		Public Overloads Overrides Sub VerifyRenderingInServerForm(ByVal control As Control)
	    End Sub
		
		
        Protected Sub Button2_Click(ByVal sender As Object,      ByVal e As EventArgs)
		
        	Response.AddHeader("content-disposition", "attachment;filename=iWIP Timesheet User Records.xls")
        	Response.Charset = String.Empty
        	Response.ContentType = "application/vnd.xls"
        	Dim sw As System.IO.StringWriter = New System.IO.StringWriter()
        	Dim hw As System.Web.UI.HtmlTextWriter = New HtmlTextWriter(sw)
        	GridView2.RenderControl(hw)
        	Response.Write(sw.ToString())
        	Response.End()
    	End Sub
		

</script>

<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd">
<html xmlns="http://www.w3.org/1999/xhtml">
<head runat="server">
	<title>iWIP Timesheet Gridview</title>
	<!--#include file="/inc/metadata.aspx"-->
	<!--#include file="/inc/stylesheet-app-wide.aspx"-->
</head>
<body>

<form id="form1" runat="server">
<div id="wrap"> 
	<webapp:qHeader id="qhead" runat="server" />
	<div id="pagebody">
		<webapp:qNavigation id="qnav" runat="server"  />
		<div id="mainbody">
			<webapp:qBreadcrumb id="qbread" runat="server" />

        <!--#include file="/iWip/timesheet/inc/open-widget.aspx"-->   

    	<h1>iWIP Timesheet Reports</h1>
        
        	<h3>Timesheet Data</h3>
        
        		<p><asp:Button ID="Button1" runat="server" OnClick="Button1_Click" Text="Export Timesheet Data to Excel"></asp:Button></p>
        
            	<asp:GridView ID = "GridView1" runat = "server" DataSourceID = "SqlDataSourceAllTimesheet" AutoGenerateColumns = "true" Gridlines="Both">
   			 	<HeaderStyle BackColor = "#0088CE" Font-Bold = "True" ForeColor = "#F7F7F7" />
				<rowstyle backcolor="#F0F0F0"/>
    			<alternatingrowstyle backcolor="#FFFFFF"/>
                
                <Columns>
                <asp:CommandField ShowEditButton = "True" />
                </Columns>
                
                </asp:GridView>
        
       		<h3>Timesheet Users</h3>
                
            	<asp:GridView ID = "GridView2" runat = "server" DataSourceID = "SqlDataSourceTimesheetUsers" AutoGenerateColumns = "true" Gridlines="Both">
   			 	<HeaderStyle BackColor = "#0088CE" Font-Bold = "True" ForeColor = "#F7F7F7" />
				<rowstyle backcolor="#F0F0F0"/>
    			<alternatingrowstyle backcolor="#FFFFFF"/>
                
                <Columns>
                <asp:CommandField ShowEditButton = "True" />
                </Columns>
                
                </asp:GridView>
                
                <p><asp:Button ID="Button2" runat="server" OnClick="Button2_Click" Text="Export Timesheet Users to Excel"></asp:Button></p>

		</div>
  </div>
	<webapp:qFooter id="footer" runat="server" />
</div>

	<asp:SqlDataSource ID="SqlDataSourceAllTimesheet" runat="server" ConnectionString="<%$ ConnectionStrings:TimesheetWidgetConnectionString %>"
    SelectCommand="SELECT * FROM timesheet" 
    
    UpdateCommand = "UPDATE timesheet SET username = @username, date = @date, job = @job, hours = @hours WHERE id=@id"/>
    
    <asp:SqlDataSource ID="SqlDataSourceTimesheetUsers" runat="server" ConnectionString="<%$ ConnectionStrings:TimesheetWidgetConnectionString %>"
    SelectCommand="SELECT * FROM timesheet_users" 
    
    UpdateCommand = "UPDATE timesheet_users SET staff=@staff, role=@role, last_submitted_week=@last_submitted_week, hours_submitted=@hours_submitted WHERE id=@id" />


</form>
</body>
</html>