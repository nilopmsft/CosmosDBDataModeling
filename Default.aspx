<%@ Page Title="Home Page" Language="C#" MasterPageFile="~/Site.Master" AutoEventWireup="true" CodeBehind="Default.aspx.cs" Inherits="CosmosDataModelingv2._Default" Async="true" %>

<asp:Content ID="BodyContent" ContentPlaceHolderID="MainContent" runat="server">
    <div class="demo-config-bar">
        <div class="demo-search-box">
            <div class="title">
                Data Model: 
            </div>
            <asp:DropDownList ID="dataModelOptions" runat="server" OnSelectedIndexChanged="dataModelOptions_SelectedIndexChanged" AutoPostBack="True" CssClass="left">
                <asp:ListItem Selected="True" Value="single"> Single </asp:ListItem>
                <asp:ListItem Value="embedded"> Embedded </asp:ListItem>
                <asp:ListItem Value="reference"> Reference </asp:ListItem>
                <asp:ListItem Value="hybrid"> Hybrid </asp:ListItem>
            </asp:DropDownList>
            <asp:Button ID="searchButton" runat="server" OnClick="searchButton_Click" Text="Search" />
            <asp:DropDownList ID="singleQueryType" runat="server" CssClass="right">
                <asp:ListItem Selected="True" Value="movie"> Movie </asp:ListItem>
                <asp:ListItem Value="actor"> Actor </asp:ListItem>
                <asp:ListItem Value="genre"> Genre </asp:ListItem>
            </asp:DropDownList>
            <asp:TextBox ID="searchInput" runat="server"></asp:TextBox>
            <asp:HiddenField ID="modelType" runat="server" Value="single" />
        </div>
    </div>
    <div class="result-body">
        <div class="title">
            Query Information
        </div>
        <div class="title">
            User Experience
        </div>
        <div class="result-content">
            <asp:Label ID="queryText" runat="server" Text=""></asp:Label>
            <asp:Label ID="queryModel" runat="server" Text=""></asp:Label>
            <asp:Label ID="queryResult" runat="server" Text=""></asp:Label>
            <asp:Label ID="recordCount" runat="server" Text=""></asp:Label>
            <asp:Label ID="queryRuntime" runat="server" Text=""></asp:Label>
            <asp:Label ID="resultExample" runat="server" Text=""></asp:Label>
        </div>
        <div class="result-content">
            <asp:Label ID="searchResults" runat="server" Text=""></asp:Label>
            <asp:HiddenField ID="pointQueryId" runat="server" Value="none" OnValueChanged="pointQueryId_ValueChanged" />
            <asp:HiddenField ID="pointObject" runat="server" Value="none"/>
            <asp:HiddenField ID="personSearch" runat="server" Value="none" OnValueChanged="personSearch_ValueChanged" />
        </div>
    </div>

    <script>
        function moviePointQuery(movieId) {
            document.getElementById("MainContent_pointQueryId").value = movieId;
        }

        function personPointQuery(personId, personName) {
            var e = document.getElementById("MainContent_dataModelOptions");
            var model = e.options[e.selectedIndex].value;
            alert
            if (model == "hybrid") {
                document.getElementById("MainContent_pointObject").value = "person";
                document.getElementById("MainContent_pointQueryId").value = personId + "," + personName;
            } else {
                personQuery(personName)
            }
        }

        function personQuery(personName) {
            var e = document.getElementById("MainContent_dataModelOptions");
            var model = e.options[e.selectedIndex].value;
            //Setting dropdown value to actor
            if (model == "single") {
                document.getElementById("MainContent_singleQueryType").value = "actor";
            }
            //Setting search box to actor name
            document.getElementById("MainContent_searchInput").value = personName;
            //Changing value to trigger search
            document.getElementById("MainContent_personSearch").value = personName;
        }
    </script>
</asp:Content>
