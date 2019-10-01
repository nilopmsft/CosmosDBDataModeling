using System;
using System.Threading.Tasks;
using System.Configuration;
using System.Collections.Generic;
using System.Net;
using Microsoft.Azure.Cosmos;
using System.Web.UI;
using System.Diagnostics;
using System.Web.UI.WebControls;
using Newtonsoft.Json;
using System.IO;
using Microsoft.Ajax.Utilities;

namespace CosmosDataModelingv2
{
    public partial class _Default : Page
    {
        
        protected void Page_Load(object sender, EventArgs e)
        {

        }
        protected void dataModelOptions_SelectedIndexChanged(object sender, EventArgs e)
        {
            if (dataModelOptions.SelectedValue == "single")
            {
                singleQueryType.CssClass = "right visible";
            }
            else
            {
                singleQueryType.CssClass = "right hidden";
            }
            modelType.Value = dataModelOptions.SelectedValue;
        }

        protected void searchButton_Click(object sender, EventArgs e)
        {
            string searchValue = searchInput.Text;
            string containerName = modelType.Value;
            string queryType = "sql";
            processQuery(searchValue, containerName, queryType, "none");

        }

        protected void pointQueryId_ValueChanged(object sender, EventArgs e)
        {
            string searchValue = pointQueryId.Value;
            string containerName = modelType.Value;
            string objectType = pointObject.Value;
            string queryType = "point";
            processQuery(searchValue, containerName, queryType, objectType);
            pointQueryId.Value = "none";
            pointObject.Value = "none";
        }

        protected void personSearch_ValueChanged(object sender, EventArgs e)
        {
            string searchValue = personSearch.Value;
            string containerName = modelType.Value;
            string queryType = "sql";
            /*if (modelType.Value == "single")
            {
                singleQueryType.SelectedValue = "actor";
            }*/
            processQuery(searchValue, containerName, queryType, "none");
            personSearch.Value = "none";
        }

        private async void processQuery(string searchValue, string containerName, string queryType, string objectType)
        {

            Dictionary<string, string> queryData = new Dictionary<string, string>();
            string sqlQueryText = "";
            string docId = "";
            string movieTitle = "";
            string singleQuerySelected = singleQueryType.SelectedValue;

            if (queryType == "sql")
            {
                

                if (modelType.Value == "single" && singleQuerySelected != "movie")
                {
                    if (singleQuerySelected == "actor")
                    {
                        sqlQueryText = "SELECT c.id, c.title, c.year, c.genres, c.actors, c.directors, c.type FROM c JOIN a IN c.actors JOIN d IN c.directors where a.name = '" + searchValue + "' or d.name = '" + searchValue + "'";
                    }
                    else if (singleQuerySelected == "genre")
                    {
                        sqlQueryText = "SELECT c.id, c.title, c.year, c.genres, c.actors, c.directors, c.type FROM c JOIN g IN c.genres where g.name = '" + searchValue + "'";

                    }

                }
                else
                {

                    sqlQueryText = "SELECT * FROM c WHERE c.title = '" + searchValue + "'";
                }
                queryData = await runSqlQuery(sqlQueryText, containerName, singleQuerySelected);

            }
            else
            {
                docId = searchValue.Substring(0, searchValue.IndexOf(','));
                movieTitle = searchValue.Substring(searchValue.IndexOf(',') + 1);
                queryData = await runPointRead(docId, movieTitle, containerName, objectType);
                sqlQueryText = "Point Query on doc id " + docId + ", title '" + movieTitle + "'";

            }

            queryText.Text = "<div class=\"result-details-row\"><div class=\"result-details-property\">Query Text:</div><div class=\"result-details-value\">" + sqlQueryText + "</div></div>";
            queryModel.Text = "<div class=\"result-details-row\"><div class=\"result-details-property\">Collection/Model:</div><div class=\"result-details-value\">" + containerName + "</div></div>";
            queryResult.Text = "<div class=\"result-details-row\"><div class=\"result-details-property\">RU Cost:</div><div class=\"result-details-value\">" + queryData["requestCharge"] + "</div></div>";
            recordCount.Text = "<div class=\"result-details-row\"><div class=\"result-details-property\">Document Count:</div><div class=\"result-details-value\">" + queryData["recordCount"] + "</div></div>";
            queryRuntime.Text = "<div class=\"result-details-row\"><div class=\"result-details-property\">Execution time:</div><div class=\"result-details-value\">" + queryData["totalTime"] + "</div></div>";
            resultExample.Text = "<div class=\"result-details-row\"><div class=\"result-details-property\">Example Document:</div><pre class=\"doc-example\">" + queryData["exampleResult"] + "</pre></div>";
            searchResults.Text = queryData["searchResults"];

        }

        private async Task<Dictionary<string, string>> runSqlQuery(string sqlQueryText, string containerName, string singleQuerySelected)
        {

            Dictionary<string, string> queryData = new Dictionary<string, string>();

            cosmosConnection C = new cosmosConnection();
            C.connectionSetup();

            double totalRequestCharge = 0;
            QueryDefinition queryDefinition = new QueryDefinition(sqlQueryText);

            var container = C.database.GetContainer(containerName);

            QueryRequestOptions requestOptions;
            requestOptions = new QueryRequestOptions(); //use all default query options

            // Time the query
            Stopwatch stopWatch = new Stopwatch();
            stopWatch.Start();

            FeedIterator<dynamic> queryResultSetIterator = container.GetItemQueryIterator<dynamic>(queryDefinition, requestOptions: requestOptions);
            List<dynamic> movies = new List<dynamic>();

            int itemCount = 0;
            string exampleResult = "[No Results Found]";

            while (queryResultSetIterator.HasMoreResults)
            {
                FeedResponse<dynamic> currentResultSet = await queryResultSetIterator.ReadNextAsync();

                totalRequestCharge += currentResultSet.RequestCharge;
                //Console.WriteLine("another page");
                foreach (var item in currentResultSet)
                {
                    movies.Add(item);
                    if (itemCount == 0)
                    {
                        exampleResult = formatJson(item.ToString());
                        itemCount++;
                    }
                }
            }


            queryData.Add("exampleResult", exampleResult);
            
            queryData.Add("requestCharge", totalRequestCharge.ToString());

            stopWatch.Stop();
            TimeSpan ts = stopWatch.Elapsed;

            //Print results
            string elapsedTime = String.Format("{0:00}:{1:00}:{2:00}.{3:00}",
                ts.Hours, ts.Minutes, ts.Seconds,
                ts.Milliseconds / 10);

            //Total time to execute
            queryData.Add("totalTime", elapsedTime);

            //Total Records
            queryData.Add("recordCount", movies.Count.ToString());

            queryData.Add("searchResults", movieSQLResults(movies, containerName, singleQuerySelected));

            return queryData;
        }


        private async Task<Dictionary<string, string>> runPointRead(string docId, string objectTitle, string containerName, string objectType)
        {
            Dictionary<string, string> queryData = new Dictionary<string, string>();

            cosmosConnection C = new cosmosConnection();
            C.connectionSetup();

            var container = C.database.GetContainer(containerName);

            // Time the query
            Stopwatch stopWatch = new Stopwatch();
            stopWatch.Start();


            ItemResponse<dynamic> documentResponse = await container.ReadItemAsync<dynamic>(docId, new PartitionKey(objectTitle));
            var result = documentResponse.Resource;

            stopWatch.Stop();
            TimeSpan ts = stopWatch.Elapsed;

            //Print results
            string elapsedTime = String.Format("{0:00}:{1:00}:{2:00}.{3:00}",
                ts.Hours, ts.Minutes, ts.Seconds,
                ts.Milliseconds / 10);

            queryData.Add("exampleResult", documentResponse.Resource.ToString());
            queryData.Add("requestCharge", documentResponse.RequestCharge.ToString());
            queryData.Add("totalTime", elapsedTime);
            queryData.Add("recordCount", "1");
            if (objectType == "person")
            {
                queryData.Add("searchResults", actorPointResults(documentResponse.Resource, containerName));
            }
            else
            {
                queryData.Add("searchResults", moviePointResults(documentResponse.Resource, containerName));
            }
            return queryData;

        }

        private static string moviePointResults(dynamic movieDetails, string modelType)
        {
            string movieResults = "<div class=\"result-details-title\">" + movieDetails.title + "</div>";
            string onclick = "";
            movieResults = movieResults + "<div class=\"result-details-row\"><div class=\"result-details-property\">Year: </div><div class=\"result-details-value\" style=\"font-size:16px;\">" + movieDetails.year + "</div></div>";
            movieResults = movieResults + "<div class=\"result-details-row\"><div class=\"result-details-property\">Directed By: </div><div class=\"result-details-value\">";
            foreach (var director in movieDetails.directors)
            {
                if (modelType == "hybrid")
                {
                    onclick = "personPointQuery('" + director.id + "','" + director.name + "');";
                } else
                {
                    onclick = "personQuery('" + director.name + "');";
                }
                movieResults = movieResults + "<button class=\"result-details director\" onClick=\"" + onclick + "\">" + director.name + "<div class=\"person-year\">" + director.birth_year + "</div></button>";
            }
            movieResults = movieResults + "</div></div>";
            movieResults = movieResults + "<div class=\"result-details-row\"><div class=\"result-details-property\">Actors: </div><div class=\"result-details-value\">";
            foreach (var actor in movieDetails.actors)
            {
                if (modelType == "hybrid")
                {
                    onclick = "personPointQuery('" + actor.id + "','" + actor.name + "');";
                }
                else
                {
                    onclick = "personQuery('" + actor.name + "');";
                }
                movieResults = movieResults + "<button class=\"result-details actor\" onClick=\"" + onclick + "\">" + actor.name + "<div class=\"person-year\">" + actor.birth_year + "</div></button>";
            }
            movieResults = movieResults + "</div></div>";
            movieResults = movieResults + "<div class=\"result-details-row\"><div class=\"result-details-property\">Genres: </div><div class=\"result-details-value\">";
            foreach (var genre in movieDetails.genres)
            {
                movieResults = movieResults + "<div class=\"result-details genre\">" + genre.name + "</div>";
            }
            movieResults = movieResults + "</div></div>";
            return movieResults;
        }

        private static string actorPointResults(dynamic movieDetails, string modelType)
        {
            string searchResults = "";
            List<string> knownTitles = new List<string>();

            int movieCount = 0;
            foreach (var movieActed in movieDetails.acted)
            {
                if (!knownTitles.Contains(movieActed.movie_title.ToString()))
                {
                    searchResults = searchResults + "<button class=\"movie-object\" onClick=\"moviePointQuery('" + movieActed.movie_id + "," + movieActed.movie_title.ToString() + "');\">" + movieActed.movie_title.ToString() + "</button>";
                    movieCount++;
                    knownTitles.Add(movieActed.movie_title.ToString());
                }
            }
            foreach (var movieDirected in movieDetails.directed)
            {
                if (!knownTitles.Contains(movieDirected.movie_title.ToString()))
                {
                    searchResults = searchResults + "<button class=\"movie-object\" onClick=\"moviePointQuery('" + movieDirected.movie_id + "," + movieDirected.movie_title.ToString() + "');\">" + movieDirected.movie_title.ToString() + "</button>";
                    movieCount++;
                    knownTitles.Add(movieDirected.movie_title.ToString());
                }
            }
            searchResults = "<div class=\"result-count\">Showing " + movieCount + " movie results</div>" + searchResults;
            return searchResults;
        }


        private static string formatJson(string json)
        {
            dynamic parsedJson = JsonConvert.DeserializeObject(json);
            return JsonConvert.SerializeObject(parsedJson, Formatting.Indented);
        }

        public static string movieSQLResults(List<dynamic> movies, string queryType, string singleQuerySelected)
        {
            string searchResults = "";
            List<string> knownTitles = new List<string>();

            int movieCount = 0;
            foreach (var movie in movies)
            {
                if (movie.type == "movie")
                {
                    if (singleQuerySelected == "movie")
                    {
                        searchResults = searchResults + "<button class=\"movie-object\" onClick=\"moviePointQuery('" + movie.id + "," + movie.title.ToString() + "');\">" + movie.title.ToString() + "<div class=\"movie-year\">" + movie.year + "</div></button>";
                        movieCount++;
                    }
                    else if (!knownTitles.Contains(movie.title.ToString()))
                    {
                        searchResults = searchResults + "<button class=\"movie-object\" onClick=\"moviePointQuery('" + movie.id + "," + movie.title.ToString() + "');\">" + movie.title.ToString() + "<div class=\"movie-year\">" + movie.year + "</div></button>";
                        movieCount++;
                        knownTitles.Add(movie.title.ToString());
                    }

                }
                else
                {
                    if (queryType == "hybrid")
                    {
                        foreach (var movieActed in movie.acted)
                        {
                            if (!knownTitles.Contains(movieActed.movie_title.ToString()))
                            {
                                searchResults = searchResults + "<button class=\"movie-object\" onClick=\"moviePointQuery('" + movieActed.movie_id + "," + movieActed.movie_title.ToString() + "');\">" + movieActed.movie_title.ToString() + "<div class=\"movie-year\">" + movieActed.year + "</div></button>";
                                movieCount++;
                                knownTitles.Add(movieActed.movie_title.ToString());
                            }

                        }
                        foreach (var movieDirected in movie.directed)
                        {
                            if (!knownTitles.Contains(movieDirected.movie_title.ToString()))
                            {
                                searchResults = searchResults + "<button class=\"movie-object\" onClick=\"moviePointQuery('" + movieDirected.movie_id + "," + movieDirected.movie_title.ToString() + "');\">" + movieDirected.movie_title.ToString() + "<div class=\"movie-year\">" + movieDirected.year + "</div></button>";
                                movieCount++;
                                knownTitles.Add(movieDirected.movie_title.ToString());
                            }
                        }
                    }
                    else
                    {
                        if (!knownTitles.Contains(movie.movie_title.ToString()))
                        {
                            searchResults = searchResults + "<button class=\"movie-object\" onClick=\"moviePointQuery('" + movie.movie_id + "," + movie.movie_title.ToString() + "');\">" + movie.movie_title.ToString() + "<div class=\"movie-year\">" + movie.year + "</div></button>";
                            movieCount++;
                            knownTitles.Add(movie.movie_title.ToString());
                        }
                    }
                }
            }

            searchResults = "<div class=\"result-count\">Showing " + movieCount + " movie results</div>" + searchResults;
            return searchResults;

        }

    }

    public class cosmosConnection
    {
        // The Azure Cosmos DB endpoint for running this sample.
        private static readonly string EndpointUri = ConfigurationManager.AppSettings["EndPointUri"];

        // The primary key for the Azure Cosmos account.
        private static readonly string PrimaryKey = ConfigurationManager.AppSettings["PrimaryKey"];

        private string databaseId = ConfigurationManager.AppSettings["CosmosDB"];

        // The Cosmos client instance
        public CosmosClient cosmosClient;
        public Microsoft.Azure.Cosmos.Database database;
        public Container container;

        public void connectionSetup()
        {
            var cosmosClientOptions = new CosmosClientOptions()
            {
                ApplicationRegion = "Central US",

            };
            // Create a new instance of the Cosmos Client
            this.cosmosClient = new CosmosClient(EndpointUri, PrimaryKey, cosmosClientOptions);
            this.database = this.cosmosClient.GetDatabase(databaseId);
            //this.container = this.database.GetContainer(containerId);

        }

    }
}