// Copyright (c) 2018 WSO2 Inc. (http://www.wso2.org) All Rights Reserved.
//
// WSO2 Inc. licenses this file to you under the Apache License,
// Version 2.0 (the "License"); you may not use this file except
// in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing,
// software distributed under the License is distributed on an
// "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
// KIND, either express or implied. See the License for the
// specific language governing permissions and limitations
// under the License.

package org.WSO2.Ballerina;

import ballerina.data.sql;
import ballerina.time;
import ballerina.log;
import ballerina.config;

int openFor;
int pullRequestArrayIndex;
int issueArrayIndex;
int[] update;
string createdAt;
string username = config:getGlobalValue("username");
string password = config:getGlobalValue("password");
time:Time createdTime;
sql:Parameter[][] issueArray = [];
sql:Parameter[][] pullRequestArray = [];

public function writeRawData(){
    endpoint<sql:ClientConnector> databaseConnector {
             create sql:ClientConnector(sql:DB.MYSQL, "localhost", 3306, "FilteredData", username, password,
                            {maximumPoolSize:5, url:"jdbc:mysql://localhost:3306/FilteredData?useSSL=false"});
    }
    
    try{
        int output = databaseConnector.update("TRUNCATE pullRequests",null);
        output = databaseConnector.update("TRUNCATE issues",null);
    }
    catch (error e) {
        log:printInfo("Error caused in deletion of existing data : " + e.message);
    }
    
    try{
        update = databaseConnector.batchUpdate("INSERT INTO pullRequests
        (RepositoryName, Url, GithubId, Days, Weeks, State) VALUES (?,?,?,?,?,?)", pullRequestArray);
    }
    catch(error e){
        log:printInfo("Error caused in batch update : " + e.message);
    }
    
    try{
        update = databaseConnector.batchUpdate("INSERT INTO issues
        (RepositoryName, Url, GithubId, Days, Weeks) VALUES (?,?,?,?,?)", issueArray);
    }
    catch (error e) {
        log:printInfo("Error caused in batch update : " + e.message);
    }
    databaseConnector.close();
    
}

public function readData(string tableName)(json){
    endpoint<sql:ClientConnector> databaseConnector {
        create sql:ClientConnector(sql:DB.MYSQL, "localhost", 3306, "FilteredData", username, password,
                                   {maximumPoolSize:5, url:"jdbc:mysql://localhost:3306/FilteredData?useSSL=false"});
    }
    string state = "";
    if(tableName == "pullRequests"){
        state = "State,";
    }

    table filteredData = databaseConnector.select("SELECT RepositoryName,Url,Days,Weeks," + state +
                                                  "githubId,product FROM "  + tableName +
                                                  " LEFT OUTER JOIN WSO2contributors ON " + tableName +
                                                  ".GithubId=WSO2contributors.userId LEFT OUTER JOIN product ON "+
                                                  tableName + ".RepositoryName=product.RepoName WHERE
                                                  WSO2contributors.userId is null",null,null);

   
    var jsonData, typeConversionError = <json>filteredData;
    if(typeConversionError != null){
        log:printInfo("Error in converting table to json : " + typeConversionError.message);
    }
    return jsonData;
}

public function generateData(json jsonPayload, string dataType){
    int iterator;
    sql:Parameter repoName;
    sql:Parameter url;
    sql:Parameter githubId;
    sql:Parameter openDays;
    sql:Parameter openWeeks;
    sql:Parameter state;
    sql:Parameter[] prParams = [];
    sql:Parameter[] issueParams = [];
    string githubID;
    string stringState;
    
    while(iterator < lengthof jsonPayload.nodes){
        repoName = {sqlType:sql:Type.VARCHAR, value:jsonPayload.nodes[iterator].repository.name.toString()};
        url = {sqlType:sql:Type.VARCHAR, value:jsonPayload.nodes[iterator].url.toString()};

        githubID = jsonPayload.nodes[iterator].author != null ?
                   jsonPayload.nodes[iterator].author.login.toString() : "null";
        githubId = {sqlType:sql:Type.VARCHAR, value:githubID};

        createdAt = jsonPayload.nodes[iterator].createdAt.toString();
        createdTime = time:parse(createdAt,"yyyy-MM-dd'T'HH:mm:ss'Z'");
        openFor = (time:currentTime().time - createdTime.time)/(1000*3600);
        openDays = {sqlType:sql:Type.INTEGER, value:(openFor/24)};
        openWeeks = {sqlType:sql:Type.INTEGER, value:(openFor/(24*7))};
        
        if(dataType=="pullRequest"){
            if(lengthof jsonPayload.nodes[iterator].reviews.nodes == 1){
                stringState = jsonPayload.nodes[iterator].reviews.nodes[0].state.toString();
            }
            else{
                stringState = "REVIEW_REQUIRED";
            }
            state = {sqlType:sql:Type.VARCHAR, value:stringState};
            prParams = [repoName,url,githubId,openDays,openWeeks,state];
            pullRequestArray[pullRequestArrayIndex] = prParams;
            pullRequestArrayIndex = pullRequestArrayIndex + 1;
        }
        else{
            issueParams = [repoName,url,githubId,openDays,openWeeks];
            issueArray[issueArrayIndex] = issueParams;
            issueArrayIndex = issueArrayIndex + 1;
        }
        iterator = iterator + 1;
    }
}
