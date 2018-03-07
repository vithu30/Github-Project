package APIs;

import ballerina.data.sql;
import ballerina.config;


const string TOKEN = config:getGlobalValue("access_token");

string contributor;
int i;
sql:Parameter repoName;
sql:Parameter url;
sql:Parameter githubId;
sql:Parameter duration;
sql:Parameter day;
sql:Parameter week;
sql:Parameter[] params = [];
string gap;
int hours;
int days;
int weeks;

public function filterPullRequests (json jsonArray) {
    endpoint<sql:ClientConnector> testDB {
        create sql:ClientConnector(
        sql:DB.MYSQL, "localhost", 3306, "FilteredData", config:getGlobalValue("username"), config:getGlobalValue("password"), {maximumPoolSize:5,url:"jdbc:mysql://localhost:3306/FilteredData?useSSL=false"});
    }
    table wso2 = testDB.select("SELECT LOWER(GithubId) AS GithubId FROM WSO2contributors",null,null);
    json internalContributors;
    internalContributors,_ = <json>wso2;

    json dataType = jsonArray.data.organization.repository;
    if(dataType.pullRequests != null){
        i = 0;
        while (i< lengthof dataType.pullRequests.nodes){
            if(dataType.pullRequests.nodes[i].author !=null){
                contributor = dataType.pullRequests.nodes[i].author.login.toString();
            }
            else{
                contributor = "null";
            }

            if(isOutside(internalContributors,contributor)){
                repoName = {sqlType:sql:Type.VARCHAR, value:dataType.pullRequests.nodes[i].repository.name};
                url = {sqlType:sql:Type.VARCHAR, value:dataType.pullRequests.nodes[i].url};
                githubId = {sqlType:sql:Type.VARCHAR, value:dataType.pullRequests.nodes[i].author.login};
                gap = dataType.pullRequests.nodes[i].createdAt.toString();
                Time time = parse(gap,"yyyy-MM-dd'T'HH:mm:ss'Z'");
                hours = (currentTime().time - time.time)/(1000*3600);
                days = hours/24;
                weeks = days/7;
                duration = {sqlType:sql:Type.VARCHAR, value:hours};
                day = {sqlType:sql:Type.VARCHAR, value:days};
                week = {sqlType:sql:Type.VARCHAR, value:weeks};
                params = [repoName, url, githubId, duration,day,week];
                int ret = testDB.update("INSERT INTO pullRequests (RepositoryName, PullUrl, githubId, Duration, Days, Weeks) VALUES (?,?,?,?,?,?)",
                                    params);
            }
            i = i+1;
        }
    }
    testDB.close();
}

public function filterIssues (json jsonArray) {
    endpoint<sql:ClientConnector> testDB {
        create sql:ClientConnector(
        sql:DB.MYSQL, "localhost", 3306, "FilteredData", config:getGlobalValue("username"), config:getGlobalValue("password"), {maximumPoolSize:5,url:"jdbc:mysql://localhost:3306/FilteredData?useSSL=false"});
    }

    table wso2 = testDB.select("SELECT LOWER(GithubId) AS GithubId FROM WSO2contributors",null,null);
    json internalContributors;
    internalContributors,_ = <json>wso2;

    json dataType = jsonArray.data.organization.repository;
    if(dataType.issues != null){
        i = 0;

        while (i< lengthof dataType.issues.nodes){
            if(dataType.issues.nodes[i].author !=null){
                contributor = dataType.issues.nodes[i].author.login.toString();
            }
            else {
                contributor = "null";
            }

            if(isOutside(internalContributors,contributor)){
                repoName = {sqlType:sql:Type.VARCHAR, value:dataType.issues.nodes[i].repository.name};
                url = {sqlType:sql:Type.VARCHAR, value:dataType.issues.nodes[i].url};
                githubId = {sqlType:sql:Type.VARCHAR, value:contributor};
                gap = dataType.issues.nodes[i].createdAt.toString();
                Time time = parse(gap,"yyyy-MM-dd'T'HH:mm:ss'Z'");
                hours = (currentTime().time - time.time)/(1000*3600);
                duration = {sqlType:sql:Type.VARCHAR, value:hours};
                days = hours/24;
                weeks = days/7;
                duration = {sqlType:sql:Type.VARCHAR, value:hours};
                day = {sqlType:sql:Type.VARCHAR, value:days};
                week = {sqlType:sql:Type.VARCHAR, value:weeks};
                params = [repoName, url, githubId, duration,day,week];
                int ret = testDB.update("INSERT INTO issues (RepositoryName, issueUrl, githubId, Duration, Days, Weeks) VALUES (?,?,?,?,?,?)",
                                        params);
            }
            i = i+1;
        }
    }
    testDB.close();
}

public function isOutside(json internalContributors,string contributor)(boolean){
    boolean nonWso2Contributor = true;
    int i=0;
    while(i<lengthof internalContributors){
        if(internalContributors[i].GithubId.toString()==contributor.toLowerCase()){
            nonWso2Contributor = false;
        }
        i = i+1;
    }
    return nonWso2Contributor;
}

