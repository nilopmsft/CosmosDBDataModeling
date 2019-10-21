<%@ Page Title="Data Modeling Demo" Language="C#" MasterPageFile="~/Site.Master" AutoEventWireup="true" CodeBehind="DataModeling.aspx.cs" Inherits="CosmosDataModelingv2.DataModeling" Async="true" %>

<asp:Content ID="BodyContent" ContentPlaceHolderID="MainContent" runat="server">

    <div id="popup-box">
        <div class="popup-body">
            <div class="title">Data model Demo Instructions</div>
            <div id="close-popup" class="close-button">X</div>
            <div class="content">
                The 'Data Model' dropdown provides the different models used for the documents stored in our Cosmos DB. Enter a movie, actor or genre name in the search.  
                Movies will generally have the same query cost so an actor is highly recommended for demoing. Note that the search value is literal i.e. case, spaces, characters, etc matter. 
                <br />
                <br />
                For overall discussion on the demo scroll down on the demo page.
            </div>
        </div>
    </div>

    <div id="popup-blackout"></div>

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
            <div id="demo-help">Help</div>

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
    <div class="main-body-content">

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
            <asp:HiddenField ID="pointObject" runat="server" Value="none" />
            <asp:HiddenField ID="personSearch" runat="server" Value="none" OnValueChanged="personSearch_ValueChanged" />
        </div>
        <div class="clear"></div>
        <div class="about_content">

            <h3>About Data Modeling in Cosmos DB</h3>

            <p>
                While there are multiple considerations in Cosmos DB for optimizing performance understanding
    data modeling can be critical in getting the best experience. This site was to create a scenario where different <a
        href="https://docs.microsoft.com/en-us/azure/cosmos-db/modeling-data" target="_blank">methods of modeling in Cosmos</a>
                demonstrates the benefits of thinking in a non-relational way. Note there is no one size fits all and the demo
    itself unveiled multiple methods as we progressed through it.
            </p>
            <h3>Summary</h3>
            <p>
                A media streaming company wanted to have a fast browsing experience for their users, that was accessible around
    the world. As the information of the movies are created by the studios, even though generally consistent, the
    flexibility
    of being schema less was also of benefit since we could add new data without redefining the document format. The
    service will likely have users increase faster than media releases so the ability to scale compute and storage
    separate of each other was another desire. All of this made CosmosDB an
    attractive service.
            </p>
            <h3>Scenario</h3>
            <p>
                The media streaming company developed the site with CosmosDB driving the search and browsing experience. Certain
    aspects of browsing are less than desirable in performance increasing the <a
        href="https://docs.microsoft.com/en-us/azure/cosmos-db/request-units" target="_blank">request units</a> needed to provide
    good performance but also the browsing experience as a user was less than ideal. We found that at any given time
    there is 1000 people who are performing searches so for costs calculations, consider the query cost x 1000. Further
    take a browsing scenario of a user searches a movie title, the results show an actor which they
    look for other movies starring the actor to select another movie from that actors results.
            </p>
            <h3>Starting Model – "Single"</h3>
            <p>
                To try and balance our partitions, we went with a <a
                    href="https://docs.microsoft.com/en-us/azure/cosmos-db/partitioning-overview#choose-partitionkey" target="_blank">partitioning</a>
                method of using the movie title as our partition key. Each document in our collection is a single movie. Example:
            </p>
            <div class="result_tables">
                <pre>
    {
        "id": "1234567890",
        "title": "Single Doc Movie",
        "year": "2001",
        "type": "movie"
        "genres": [
            {
                "name": "Best Genre"
             }
        ],
        "directors": [
            {
                "id": "0987654321",
                "name": "Best Director",
                "birth_year": "2000"
            }
        ],
        "actors": [
            {
                "id": "1029384576",
                "name": "Best Actor"
                "birth_year": "1900"
            }
        ]
    }
</pre>
            </div>

            <p>
                This presented little to no duplicates of the documents and since a user is not going to know a unique ID of a
    movie, searching on a movie title is able to allow a partition based query and thus lower RU cost. However, as the
    other information such as an actor, director or even Genre is embedded we cannot directly query on that. It in fact
    requires unique queries to do this due to not knowing the value type. This made the site
    have users put in the type of value they are searching on. Below shows the RU cost of searching on 'Con Air' as a
    Movie, selecting 'Nicolas Cage' to see his other movies and then selecting 'The Rock' from the results.
            </p>
            <div class="result_tables">

                <table>
                    <tr>
                        <th>Movie Search</th>
                        <th>Actor Search</th>
                        <th>Movie Select</th>
                        <th>Total RU Cost</th>
                    </tr>
                    <tr>
                        <td>3</td>
                        <td>15</td>
                        <td>1</td>
                        <td>19</td>
                    </tr>
                </table>
            </div>
            <p>
                Since the initial query is not a 
                <a href="https://docs.microsoft.com/en-us/dotnet/api/microsoft.azure.cosmos.container.readitemasync?view=azure-dotnet" target="_blank">point read</a>
                as we are using a partition value but not partition value + ID of the document, we are going to see general cost of about 3 RU's even on a single small document result. Searching on an
    actor results in a fanout query across all partitions as we do not know which documents contains those values
    increasing RU Cost.
    The Movie Select portion is very cheap because we are able to know the exact movie the user
    selected and thus can do a point query on that document with the ID and Title of the movie, this will always be the
    cheapest cost possible. Note, we have a genre option which on the larger genres presents two problems, the biggest
    being the RU cost gets into the 100's if not 1000's depending on the commonality of the genre so is not even
    demonstrated. Second, there are thousands in some case hundreds of thousands of results for something like "Drama"
    so there is no valid way of sharing this as a good user experience.
            </p>

            <h3>Embedded Model</h3>
            <p>
                We then decided to improve searching by creating a collocated document of each Actor and Genre for a given
    movie. The data is embedded just like the movie document with some minor changes to some properties. This simplified
    application logic and improved user experience in comparison to the Single model as we do not have to specify the
    type of value we are searching. The movie documents remained unchanged. Example:
            </p>

            <div class="result_tables">
                <pre>
    {
        "id" : "12345678900987654321",
        "title" : "Embedded Doc Actor",
        "actor_id" : "0987654321",
        "movie_id": "1234567890",
        "movie_title": "Best Movie",
        "year": "2001",
        "type": "actor"
        "genres": [
            {
                "name": "Best Genre"
            }
        ],
        "directors": [
            {
                "id": "0987654321",
                "name": "Best Director",
                "birth_year": "2000"
            }
        ],
        "actors": [
            {
                "id": "1029384576",
                "name": "Best Actor",
                "birth_year": "1900"
            }
        ]
    }
</pre>
            </div>

            <p>
                We see a large improvement on the Actor search for the same above scenario but others remain the same given the
    existing optimal design.
            </p>
            <div class="result_tables">

                <table>
                    <tr>
                        <th>Movie Search</th>
                        <th>Actor Search</th>
                        <th>Movie Select</th>
                        <th>Total RU Cost</th>
                    </tr>
                    <tr>
                        <td>3</td>
                        <td>8</td>
                        <td>1</td>
                        <td>12</td>
                    </tr>
                </table>
            </div>
            <p>
                As we are embedding the data and querying on a partition value always, the cost was reduced by almost half for the
    same lookup. We came to realize that the data in those documents was in many ways waste since we rely on the
    movie itself to give us the details when browsing. As RU's are expressed as 1 RU the time to read a single 1KB
    document, having a
    document that is larger, is only going to increase the cost to some degree. We do also increase the amount of
    documents and given their bigger size our storage jumped from about 500MB to 3GB for this model. However in
    comparison to Compute, the cost of storage is almost nothing in the Cosmos space. This increase in storage results
    in only about $0.75. This is worth it considering the performance gains we see and quickly recovered in less RU
    needed
    which is majority of the service cost.
            </p>
            <h3>Reference Model</h3>
            <p>
                To try and reduce the RU cost further and present information that is only going to be used at the time of, we used
    the same collocation method in the embedded model however changed the documents to only represent the partitioned
    data and
    some basic information for the movie. This greatly reduced the size of the documents in many cases and made them far
    more consistent in size. Example:
            </p>
            <div class="result_tables">
                <pre>
    {
        "id" : "12345678900987654321",
        "title" : "Reference Doc Actor",
        "actor_id" : "0987654321",
        "birth_year": "1900",
        "movie_id": "1234567890",
        "movie_title": "Best Movie",
        "year" : "2000",
        "type": "actor"
    }
    </pre>
            </div>
            <p>
                While not as large of an improvement as before, there was still gains in reduction on the RU cost. At scale this can
    still be of benefit. We did however lose information such as genres of a movie but as we could not present that in a
    usable fashion before, it was not as of much of a concern. Something of consideration if we wanted to provide that
    information, it would require additional queries.
            </p>
            <div class="result_tables">

                <table>
                    <tr>
                        <th>Movie Search</th>
                        <th>Actor Search</th>
                        <th>Movie Select</th>
                        <th>Total RU Cost</th>
                    </tr>
                    <tr>
                        <td>3</td>
                        <td>7</td>
                        <td>1</td>
                        <td>11</td>
                    </tr>
                </table>
            </div>
            <p>
                Taking the learnings from each of these models we felt we could arrive at something that was even more performant.
            </p>
            <h3>Hybrid Model</h3>
            <p>
                By taking the always query on a partition value approach by collocating documents with embedded, reducing the amount
    of content in
    the documents to make them smaller with reference data, we designed a hybrid document that provides reference data
    for each movie of an actor while embedding it
    into a single document which we can obtained with a partition query and even a Point Read Query. Example:
            </p>
            <div class="result_tables">
                <pre>
    {
        "id": "0987654321",
        "title": "Hybrid Doc Actor",
        "birth_year": "1900",
        "type": "person",
        "acted": [
            {
                "movie_id": "13579",
                "movie_title": "Movie 1",
                "year": "1901",
                "genres": [
                    {
                        "name": "Genre 1"
                    }
                ]
            },
            {
                "movie_id": "24680",
                "movie_title": "Movie 2",
                "year": "1902",
                "genres": [
                    {
                        "name": "Genre 1"
                    },
                    {
                        "name": "Genre 2"
                    },
                    {
                        "name": "Genre 3"
                    }
                ]
            }
        ],
        "directed": [
            {
                "movie_id": "10293",
                "movie_title": "Movie 3",
                "year": "1903",
                "genres": [
                    {
                        "name": "Genre 1"
                    },
                    {
                        "name": "Genre 2"
                    }
                ]
            }
        ]
    }
</pre>
            </div>
            <p>
                Looking at the results we can see a large improvement in RU cost that gets us basically the same movie search  RU cost for
    querying on an actor.
            </p>
            <div class="result_tables">

                <table>
                    <tr>
                        <th>Movie Search</th>
                        <th>Actor Search</th>
                        <th>Movie Select</th>
                        <th>Total RU Cost</th>
                    </tr>
                    <tr>
                        <td>3</td>
                        <td>3</td>
                        <td>1</td>
                        <td>7</td>
                    </tr>
                </table>
            </div>
            <p>
                In addition, we are returning some more results that are relavent such as the genre for the given movies or year
    created. This can allow for a more rich user experience if they wanted to group or filter on these values without
    excessive results being returned or even extra queries. So not only do we get better performance, we are actually
    able to
    enrich the user experience at the same time.
            </p>
            <h3>Summary</h3>
            <p>Lets take a look at the overall results and financial impact of the data modeling.</p>
            <div class="result_tables">
                <table>
                    <tr>
                        <th>Model Type</th>
                        <th>Movie Search</th>
                        <th>Actor Search</th>
                        <th>Movie Select</th>
                        <th>Total RU Cost</th>
                        <th>Service Cost</th>
                    </tr>
                    <tr>
                        <td>Single</td>
                        <td>3</td>
                        <td>15</td>
                        <td>1</td>
                        <td>19</td>
                        <td><b>$1100</b></td>
                    </tr>
                    <tr>
                        <td>Embedded</td>
                        <td>3</td>
                        <td>8</td>
                        <td>1</td>
                        <td>12</td>
                        <td><b>$700</b></td>

                    </tr>
                    <tr>
                        <td>Reference</td>
                        <td>3</td>
                        <td>7</td>
                        <td>1</td>
                        <td>11</td>
                        <td><b>$640</b></td>

                    </tr>
                    <tr>
                        <td>Hybrid</td>
                        <td>3</td>
                        <td>3</td>
                        <td>1</td>
                        <td>7</td>
                        <td><b>$410</b></td>

                    </tr>
                </table>
            </div>
            <p>
                By rethinking our data model and taking advantage of the schema less design of CosmosDB, we were able to take the
    same data and even the same partition key we started with and get a vastly improved performance experience by
    modeling it in a way
    that fit our use case. Given the scenario of 1000 users performing these actions we are seeing an over <b>2.5x</b>
                performance improvement i.e. less RU's needed which resulted in an over <b>60%</b> service cost reduction on the to provide
    not only the same performance experience but in fact an improved application features. Again, there is not one size fits all but you
    will find there are many ways to get great performance out of CosmosDB with data modeling. If you want to see a fun
    use case, search on the actor 'Brahmanandam'
    for the different models<br />
                <br />
                A side note there was also the idea of
    putting all of the actors of a common name into a document and having an array of each individual actor's
    information as well as movies. We could then do the id and partition key for the document. When someone would search
    it would always be Point Read Query which is going to be the least cost. However on large documents with multiple
    actors and long resumes, it was almost negligible compared to the hybrid, that being said still more gains to be
    made. It did require more logic on the application which with the already spaghetti code of this trying to present
    so many methods of doing the same thing it was not worth implementing. Currently if a user searches on a single value
    in the Hybrid model, if all other browsing is done by clicking different presented results, queries are done as Point Read Queries.
    So roughly 3-4 RU's to start and 1-2 RU's for every other search, pretty impressive compared to the first model.
            </p>
        </div>
    </div>



    <script>

        $(document).ready(function () {
            $("#demo-help").click(function () {
                $("#popup-blackout").show();
                $("#popup-box").show();
            });
            $("#close-popup").click(function () {
                $("#popup-blackout").hide();
                $("#popup-box").hide();
            });
        });
        $(document).on('keyup', function (event) {
            if (event.key == "Escape") {
                $("#popup-blackout").hide();
                $("#popup-box").hide();
            }
        });

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
